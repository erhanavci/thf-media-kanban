import fs from "node:fs/promises";
import path from "node:path";

const root = process.cwd();
const outDir = path.join(root, "public");

await fs.rm(outDir, { recursive: true, force: true });
await fs.mkdir(path.join(outDir, "src"), { recursive: true });

const files = [
  ["index.html", "index.html"],
  ["preview.html", "preview.html"],
  ["src/styles.css", "src/styles.css"],
  ["src/supabase-kanban.js", "src/supabase-kanban.js"],
];

await Promise.all(
  files.map(([from, to]) => fs.copyFile(path.join(root, from), path.join(outDir, to))),
);

console.log("Static site built to public/");
