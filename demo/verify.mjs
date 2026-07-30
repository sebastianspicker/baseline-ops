import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = dirname(fileURLToPath(import.meta.url));
const site = join(root, "site");
const [html, css, js, favicon] = await Promise.all([
  readFile(join(site, "index.html"), "utf8"),
  readFile(join(site, "styles.css"), "utf8"),
  readFile(join(site, "app.js"), "utf8"),
  readFile(join(site, "favicon.svg"), "utf8")
]);

for (const asset of ["styles.css", "app.js", "favicon.svg"]) assert.match(html, new RegExp(`(?:href|src)="${asset.replace(".", "\\.")}"`));
assert.match(favicon, /<svg[\s\S]*viewBox="0 0 32 32"/);
assert.equal((html.match(/<h1\b/g) || []).length, 1, "the demo must expose one page heading");
assert.match(html, /href="https:\/\/github\.com\/sebastianspicker\/baseline-ops"/);
for (const disclosure of ["STATIC DEMO", "No commands run", "Sanitized fixture data"]) assert.ok(html.includes(disclosure), `missing disclosure: ${disclosure}`);
for (const action of ["Browse kit", "Refresh", "Validate profile", "Run audit", "Stop run", "Clear view", "Save fixture output"]) {
  const actionWindow = html.slice(Math.max(0, html.indexOf(action) - 80), html.indexOf(action) + 180);
  assert.match(actionWindow, /SIMULATED/, `${action} must be visibly marked simulated`);
}
assert.match(html, /Remediate[\s\S]{0,120}simulated · disabled/);
assert.match(html, /Real audits can write reports or evidence/);
assert.match(js, /LAB-WS-042 \[FIXTURE\]/);
assert.match(js, /no endpoint was inspected/i);
assert.match(js, /baselineops-simulated-fixture\.txt/);
assert.doesNotMatch(html + css + js, /fetch\s*\(|XMLHttpRequest|WebSocket\s*\(/);
assert.match(css, /@media \(max-width: 900px\)/);
assert.match(css, /prefers-reduced-motion/);

console.log("Static demo verification passed.");
