import {
  fetchOfficialCatalogs,
  validateLocalCatalogsAgainstOfficial,
} from "./color-catalog.mjs";

async function main() {
  const officialCatalogs = await fetchOfficialCatalogs();
  const validation = await validateLocalCatalogsAgainstOfficial(officialCatalogs);

  console.log(
    JSON.stringify(
      {
        status: "ok",
        benjaminMoore: {
          localCount: validation.benjaminMoore.localCount,
          officialCount: validation.benjaminMoore.officialCount,
        },
        sherwinWilliams: {
          localCount: validation.sherwinWilliams.localCount,
          officialCount: validation.sherwinWilliams.officialCount,
        },
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
