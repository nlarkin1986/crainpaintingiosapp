import XCTest
import UIKit
@testable import CrainPaintVisualizer

final class APIClientTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        MockURLProtocol.requestHandler = nil
    }

    func testGetJSONDecodesISO8601DatesWithFractionalSeconds() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/visualizations/test")

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {
              "status": "completed",
              "created_at": "2026-03-10T18:14:22.123Z"
            }
            """.data(using: .utf8)!
            return (response, body)
        }

        let session = makeSession()
        let client = APIClient(baseURL: URL(string: "https://example.com")!, session: session)

        let payload: PreviewPayload = try await client.getJSON("/api/visualizations/test")

        XCTAssertEqual(payload.status, "completed")
        XCTAssertEqual(
            payload.createdAt.timeIntervalSince1970,
            try expectedTimestamp(for: "2026-03-10T18:14:22.123Z"),
            accuracy: 0.001
        )
    }

    func testGetJSONDecodesISO8601DatesWithoutFractionalSeconds() async throws {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {
              "status": "queued",
              "created_at": "2026-03-10T18:14:22Z"
            }
            """.data(using: .utf8)!
            return (response, body)
        }

        let session = makeSession()
        let client = APIClient(baseURL: URL(string: "https://example.com")!, session: session)

        let payload: PreviewPayload = try await client.getJSON("/api/visualizations/test")

        XCTAssertEqual(payload.status, "queued")
        XCTAssertEqual(
            payload.createdAt.timeIntervalSince1970,
            try expectedTimestamp(for: "2026-03-10T18:14:22Z"),
            accuracy: 0.001
        )
    }

    func testPostMultipartColorMatchDecodesExpandedDiagnosticsAndMatchMethod() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/api/color-match")
            XCTAssertEqual(request.httpMethod, "POST")

            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {
              "sample_hex": "A4AE9F",
              "quality": "good",
              "warnings": [],
              "diagnostics": {
                "coverage_pct": 84.12,
                "glare_pct": 1.03,
                "variance": 4.82,
                "ocr_text_found": true,
                "pre_correction_hex": "B3BAA5",
                "post_correction_hex": "A4AE9F",
                "awb_model": "deepwb",
                "delta_e_top1": 1.92,
                "delta_e_gap_top2": 2.34
              },
              "match_method": "learned_awb_vlm_rerank",
              "matches": [
                {
                  "name": "Saybrook Sage",
                  "number": "HC-114",
                  "family": "Green",
                  "hex": "A4AE9F",
                  "brand": "benjamin_moore",
                  "confidence": 96,
                  "rationale": "Re-ranked from shortlist."
                }
              ]
            }
            """.data(using: .utf8)!
            return (response, body)
        }

        let session = makeSession()
        let service = RemoteColorMatchService(baseURL: URL(string: "https://example.com")!, session: session)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor(red: 0.64, green: 0.68, blue: 0.62, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        let response = try await service.match(
            image: image,
            focusRect: ColorMatchFocusRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4),
            captureContext: ColorMatchCaptureContext(
                flashUsed: false,
                exposureBias: 0.15,
                whiteBalanceMode: "continuous_auto",
                whiteBalanceTemperature: 5100,
                whiteBalanceTint: 8,
                whiteBalanceRedGain: 2.1,
                whiteBalanceGreenGain: 1.0,
                whiteBalanceBlueGain: 1.8,
                iso: 64,
                exposureDurationSeconds: 0.008,
                deviceModel: "iPhone17,1",
                capturedAt: Date(timeIntervalSince1970: 1_741_628_800),
                latitude: 43.0389,
                longitude: -87.9065,
                source: "ios_camera"
            )
        )

        XCTAssertEqual(response.matchMethod, .learnedAwbVlmRerank)
        XCTAssertEqual(response.diagnostics.preCorrectionHex, "B3BAA5")
        XCTAssertEqual(response.diagnostics.postCorrectionHex, "A4AE9F")
        XCTAssertEqual(response.diagnostics.awbModel, "deepwb")
        XCTAssertEqual(try XCTUnwrap(response.diagnostics.deltaETop1), 1.92, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(response.diagnostics.deltaEGapTop2), 2.34, accuracy: 0.001)
        XCTAssertEqual(response.matches.first?.color.number, "HC-114")
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func expectedTimestamp(for value: String) throws -> TimeInterval {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = value.contains(".")
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return try XCTUnwrap(formatter.date(from: value)).timeIntervalSince1970
    }
}

private struct PreviewPayload: Decodable {
    let status: String
    let createdAt: Date
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            XCTFail("Missing request handler.")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
