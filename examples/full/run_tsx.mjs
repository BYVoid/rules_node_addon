import { spawnSync } from "node:child_process";

const tsxCli = process.env.TSX_CLI_PATH ?? "./node_modules/tsx/dist/cli.mjs";
const result = spawnSync("node", [tsxCli, ...process.argv.slice(2)], {
  env: process.env,
  stdio: "inherit",
});

process.exit(result.status ?? 1);
