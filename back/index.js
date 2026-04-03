const { createApp } = require("./src/app");

const PORT = Number(process.env.PORT ?? 3000) || 3000;

async function main() {
  const app = createApp();
  app.listen(PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`Diary API listening on http://localhost:${PORT}`);
  });
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e);
  process.exit(1);
});

