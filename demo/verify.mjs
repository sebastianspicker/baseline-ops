// Verifies the static demo's assets, safety disclosures, and offline contract.
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

for (const asset of ["styles.css", "app.js", "favicon.svg"]) assert.ok(html.includes(`="${asset}"`), `missing asset reference: ${asset}`);
assert.match(favicon, /<svg[\s\S]*viewBox="0 0 32 32"/);
assert.equal((html.match(/<h1\b/g) || []).length, 1, "the demo must expose one page heading");
assert.ok(html.includes('href="https://github.com/sebastianspicker/baseline-ops"'));
for (const disclosure of ["STATIC DEMO", "No commands run", "Sanitized fixture data"]) assert.ok(html.includes(disclosure), `missing disclosure: ${disclosure}`);
for (const action of ["Browse kit", "Refresh", "Validate profile", "Run audit", "Stop run", "Clear view", "Save fixture output"]) {
  const actionWindow = html.slice(Math.max(0, html.indexOf(action) - 80), html.indexOf(action) + 180);
  assert.ok(actionWindow.includes("SIMULATED"), `${action} must be visibly marked simulated`);
}
const remediateStart = html.indexOf("Remediate");
assert.ok(html.slice(remediateStart, remediateStart + 120).includes("simulated · disabled"));
assert.ok(html.includes("Real audits can write reports or evidence"));
assert.ok(js.includes("LAB-WS-042 [FIXTURE]"));
assert.ok(js.toLowerCase().includes("no endpoint was inspected"));
assert.ok(js.includes("baselineops-simulated-fixture.txt"));
for (const networkApi of ["fetch(", "XMLHttpRequest", "WebSocket("]) assert.ok(!(html + css + js).includes(networkApi));
assert.ok(css.includes("@media (max-width: 900px)"));
assert.ok(css.includes("prefers-reduced-motion"));

console.log("Static demo verification passed.");
