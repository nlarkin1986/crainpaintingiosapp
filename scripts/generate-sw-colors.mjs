import { mkdir, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import { PATHS, fetchSherwinWilliamsCatalog } from "./color-catalog.mjs";

async function main() {
  const sherwinWilliams = await fetchSherwinWilliamsCatalog();
  const output = `${JSON.stringify(sherwinWilliams.colors, null, 2)}\n`;
  await mkdir(dirname(PATHS.webSw), { recursive: true });
  await mkdir(dirname(PATHS.iosSw), { recursive: true });
  await Promise.all([
    writeFile(PATHS.webSw, output),
    writeFile(PATHS.iosSw, output),
  ]);
  console.log(`Wrote ${sherwinWilliams.colors.length} official Sherwin-Williams colors`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
