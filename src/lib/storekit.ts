import { createHash, createVerify, X509Certificate } from "crypto";

export interface StoreKitTransactionPayload {
  bundleId?: string;
  productId?: string;
  transactionId?: string;
  originalTransactionId?: string;
  type?: string;
  environment?: string;
  expiresDate?: number;
  revocationDate?: number;
}

export interface VerifiedStoreKitTransaction {
  productId: string;
  transactionId: string;
  originalTransactionId: string;
  expiresAt: Date | null;
  payload: StoreKitTransactionPayload;
}

export class StoreKitVerificationError extends Error {
  code: string;

  constructor(message: string, code: string) {
    super(message);
    this.name = "StoreKitVerificationError";
    this.code = code;
  }
}

function base64urlDecode(value: string): Buffer {
  const padded = value.padEnd(value.length + ((4 - (value.length % 4)) % 4), "=");
  return Buffer.from(padded.replace(/-/g, "+").replace(/_/g, "/"), "base64");
}

function allowedVisualizerProductIds(): Set<string> {
  const configured = process.env.IAP_VISUALIZER_PRODUCT_IDS
    ?.split(",")
    .map((value) => value.trim())
    .filter(Boolean);

  return new Set(
    configured?.length
      ? configured
      : ["com.crainpainting.visualizer.pro.lifetime"]
  );
}

export function hashDeviceId(deviceId: string): string {
  return createHash("sha256")
    .update(`${process.env.DEVICE_ID_SALT ?? "crain-paint"}:${deviceId}`)
    .digest("hex");
}

export function verifyStoreKitTransaction(
  signedTransactionJWS: string
): VerifiedStoreKitTransaction {
  const parts = signedTransactionJWS.split(".");
  if (parts.length !== 3) {
    throw new StoreKitVerificationError("Invalid transaction format.", "INVALID_JWS");
  }

  const [encodedHeader, encodedPayload, encodedSignature] = parts;
  const header = JSON.parse(base64urlDecode(encodedHeader).toString("utf8")) as {
    alg?: string;
    x5c?: string[];
  };

  if (header.alg !== "ES256") {
    throw new StoreKitVerificationError("Unsupported transaction signature.", "UNSUPPORTED_ALG");
  }

  const leafCertificate = header.x5c?.[0];
  if (!leafCertificate) {
    throw new StoreKitVerificationError("Missing transaction certificate.", "MISSING_CERT");
  }

  const certificate = new X509Certificate(
    `-----BEGIN CERTIFICATE-----\n${leafCertificate.match(/.{1,64}/g)?.join("\n")}\n-----END CERTIFICATE-----`
  );

  const verifier = createVerify("SHA256");
  verifier.update(`${encodedHeader}.${encodedPayload}`);
  verifier.end();

  const signatureValid = verifier.verify(
    certificate.publicKey,
    base64urlDecode(encodedSignature)
  );
  if (!signatureValid) {
    throw new StoreKitVerificationError("Invalid transaction signature.", "BAD_SIGNATURE");
  }

  const payload = JSON.parse(base64urlDecode(encodedPayload).toString("utf8")) as StoreKitTransactionPayload;
  const expectedBundleId = process.env.IOS_BUNDLE_ID ?? "com.crainpainting.visualizer";
  if (payload.bundleId !== expectedBundleId) {
    throw new StoreKitVerificationError("Transaction bundle does not match this app.", "BUNDLE_MISMATCH");
  }

  if (!payload.productId || !allowedVisualizerProductIds().has(payload.productId)) {
    throw new StoreKitVerificationError("Transaction product is not a visualizer entitlement.", "PRODUCT_MISMATCH");
  }

  if (!payload.transactionId && !payload.originalTransactionId) {
    throw new StoreKitVerificationError("Transaction is missing an id.", "MISSING_TRANSACTION_ID");
  }

  if (payload.revocationDate) {
    throw new StoreKitVerificationError("Transaction has been revoked.", "REVOKED");
  }

  const expiresAt = payload.expiresDate ? new Date(payload.expiresDate) : null;
  if (expiresAt && expiresAt.getTime() <= Date.now()) {
    throw new StoreKitVerificationError("Transaction has expired.", "EXPIRED");
  }

  return {
    productId: payload.productId,
    transactionId: payload.transactionId ?? payload.originalTransactionId!,
    originalTransactionId: payload.originalTransactionId ?? payload.transactionId!,
    expiresAt,
    payload,
  };
}
