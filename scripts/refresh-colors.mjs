import {
  buildRefreshReport,
  fetchOfficialCatalogs,
  validateLocalCatalogsAgainstOfficial,
  writeCanonicalCatalogs,
  writeRefreshReport,
} from "./color-catalog.mjs";

async function main() {
  const generatedAt = new Date().toISOString();
  const officialCatalogs = await fetchOfficialCatalogs();

  await writeCanonicalCatalogs(officialCatalogs);
  const validation = await validateLocalCatalogsAgainstOfficial(officialCatalogs);

  const report = buildRefreshReport({
    generatedAt,
    ...officialCatalogs,
    validation,
  });

  await writeRefreshReport(report);

  console.log(
    JSON.stringify(
      {
        status: "ok",
        generatedAt,
        benjaminMoore: officialCatalogs.benjaminMoore.colors.length,
        sherwinWilliams: officialCatalogs.sherwinWilliams.colors.length,
      },
      null,
      2
    )
  );
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
