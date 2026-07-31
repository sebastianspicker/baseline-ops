const scripts = [
  { number: "01", task: "ASR Defender Allowlist", file: "01-ASR-Defender-Allowlist.ps1", modes: "Audit, Remediate", description: "Audits Defender exclusions and Attack Surface Reduction policy against a reviewed allow-list." },
  { number: "15", task: "Hardware TPM Audit", file: "15-HardwareTPM-Audit.ps1", modes: "Audit", description: "Collects fixture TPM and hardware-readiness evidence." },
  { number: "18", task: "Firewall Baseline", file: "18-Firewall-Baseline.ps1", modes: "Audit, Remediate", description: "Audits Windows Firewall profile state and reviewed baseline settings." },
  { number: "23", task: "BitLocker Operations Audit", file: "23-BitLocker-Operations-Audit.ps1", modes: "Audit", description: "Collects BitLocker operational status for review." },
  { number: "27", task: "Defender Health Audit", file: "27-Defender-Health-Audit.ps1", modes: "Audit", description: "Creates a Microsoft Defender health report covering status, signatures, real-time protection, tamper protection, and scan age." },
  { number: "31", task: "PowerShell Logging Baseline", file: "31-PowerShell-Logging-Baseline.ps1", modes: "Audit, Remediate", description: "Audits Windows PowerShell 5.1 logging policies through registry policy keys." },
  { number: "37", task: "Remote Surface Audit", file: "37-Remote-Surface-Audit.ps1", modes: "Audit", description: "Reviews enabled remote-access surfaces and related configuration." },
  { number: "43", task: "App Control for Business Audit", file: "43-AppControlForBusiness-Audit.ps1", modes: "Audit", description: "Audits WDAC and App Control for Business indicators on a best-effort basis." },
  { number: "44", task: "Defender Ransomware & Network Protection", file: "44-Defender-Ransomware-NetworkProtection-AuditRemediate.ps1", modes: "Audit, Remediate", description: "Audits selected Defender ransomware and network-protection controls." },
  { number: "51", task: "AppLocker Audit", file: "51-AppLocker-Audit.ps1", modes: "Audit", description: "Collects AppLocker policy and service state." }
];

const initialOutput = `BaselineOps for Windows - Operator Console (Alpha)
--------------------------------------------------
STATIC FIXTURE VIEW

No command has run. No endpoint has been inspected.

Select a fixture script or profile, then choose
“Run audit · SIMULATED” to preview the result contract.`;

const scriptOutput = `BaselineOps for Windows - Operator Console (Alpha)
--------------------------------------------------
Simulated audit run
Host:          LAB-WS-042 [FIXTURE]
Script:        27-Defender-Health-Audit.ps1
Mode:          Audit
TimestampUtc:  2026-07-30T08:15:00Z [FIXTURE]

SchemaVersion: 2.0
Result: WARN
Exit code: 2 [SIMULATED]

Findings (2 sanitized fixtures)
--------------------------------
1. Code: DEF-SignatureAge
   Severity: Medium
   Message: Defender signatures are older than the fixture threshold.

2. Code: DEF-ExclusionReview
   Severity: Info
   Message: One fixture exclusion requires operator review.

Summary: 12 checks OK; 2 fixture findings; 0 failures.

--- Simulated run complete · no endpoint was inspected ---`;

const profileOutput = `BaselineOps for Windows - Operator Console (Alpha)
--------------------------------------------------
Simulated profile run
Host:          LAB-WS-042 [FIXTURE]
Profile:       baseline-audit 2.0 [FIXTURE]
Mode:          Audit
TimestampUtc:  2026-07-30T08:15:00Z [FIXTURE]

Step 1  01-ASR-Defender-Allowlist.ps1       WARN
Step 2  31-PowerShell-Logging-Baseline.ps1  OK
Step 3  43-AppControlForBusiness-Audit.ps1  OK

Result: WARN
Exit code: 2 [SIMULATED]
Summary: 3 fixture steps; 1 warning; 0 failures.

--- Simulated run complete · no endpoint was inspected ---`;

const rows = document.querySelector("#script-rows");
const filter = document.querySelector("#script-filter");
const output = document.querySelector("#output");
const runButton = document.querySelector("#run-button");
const stopButton = document.querySelector("#stop-button");
const statusText = document.querySelector("#status-text");
const toast = document.querySelector("#toast");
const tabs = [...document.querySelectorAll("[role=tab]")];
let selectedScript = scripts.find((item) => item.number === "27");
let activeTarget = "script";
let runTimer;
let toastTimer;

function renderScripts(query = "") {
  const normalized = query.trim().toLowerCase();
  const visible = scripts.filter((item) => [item.number, item.task, item.file, item.description, item.modes].join(" ").toLowerCase().includes(normalized));
  rows.replaceChildren(...visible.map(createScriptRow));
}

function createScriptRow(item) {
  const row = document.createElement("tr");
  const selected = item.number === selectedScript.number;
  row.tabIndex = 0;
  row.dataset.number = item.number;
  row.classList.toggle("is-selected", selected);
  row.setAttribute("aria-selected", String(selected));
  for (const value of [item.number, item.task, item.modes]) {
    const cell = document.createElement("td");
    cell.textContent = value;
    row.append(cell);
  }
  row.addEventListener("click", () => selectScript(item.number));
  row.addEventListener("keydown", (event) => selectScriptFromKeyboard(event, item.number));
  return row;
}

function selectScriptFromKeyboard(event, number) {
  if (event.key !== "Enter" && event.key !== " ") return;
  event.preventDefault();
  selectScript(number);
}

function selectScript(number) {
  selectedScript = scripts.find((item) => item.number === number) || selectedScript;
  document.querySelector("#detail-number").textContent = selectedScript.number;
  document.querySelector("#detail-task").textContent = selectedScript.task;
  document.querySelector("#detail-description").textContent = selectedScript.description;
  document.querySelector("#detail-modes").textContent = selectedScript.modes;
  document.querySelector("#detail-path").textContent = `scripts\\${selectedScript.file}`;
  renderScripts(filter.value);
}

function showToast(message) {
  window.clearTimeout(toastTimer);
  toast.textContent = message;
  toast.classList.add("is-visible");
  toastTimer = window.setTimeout(() => toast.classList.remove("is-visible"), 2800);
}

function setStatus(text, running = false) {
  const dot = document.createElement("span");
  dot.className = "status-dot";
  dot.style.background = running ? "#c77700" : "#27883c";
  statusText.replaceChildren(dot, document.createTextNode(` ${text}`));
}

function activateTab(target) {
  activeTarget = target;
  tabs.forEach((tab) => {
    const active = tab.id === `${target}-tab`;
    tab.classList.toggle("is-active", active);
    tab.setAttribute("aria-selected", String(active));
    document.querySelector(`#${tab.getAttribute("aria-controls")}`).hidden = !active;
  });
  runButton.textContent = target === "profile" ? "Run profile · SIMULATED" : "Run audit · SIMULATED";
}

function finishRun() {
  runTimer = undefined;
  output.textContent = activeTarget === "profile" ? profileOutput : scriptOutput.replace("27-Defender-Health-Audit.ps1", selectedScript.file);
  runButton.disabled = false;
  stopButton.disabled = true;
  setStatus("Completed with warnings · Simulated exit 2");
  showToast("Simulation complete. No endpoint was inspected.");
}

function startRun() {
  window.clearTimeout(runTimer);
  output.textContent = `Validating fixture request… [SIMULATED]\nPreparing sanitized output… [SIMULATED]\n\nNo command or endpoint connection is being made.`;
  runButton.disabled = true;
  stopButton.disabled = false;
  setStatus("Running fixture · SIMULATED", true);
  runTimer = window.setTimeout(finishRun, 800);
}

filter.addEventListener("input", () => renderScripts(filter.value));
tabs.forEach((tab) => tab.addEventListener("click", () => activateTab(tab.id.replace("-tab", ""))));
runButton.addEventListener("click", startRun);
stopButton.addEventListener("click", () => {
  window.clearTimeout(runTimer);
  runTimer = undefined;
  output.textContent += "\n\nSimulation stopped. No command was running.";
  runButton.disabled = false;
  stopButton.disabled = true;
  setStatus("Stopped · Static demo");
  showToast("Simulated run stopped.");
});

document.querySelector("#clear-button").addEventListener("click", () => {
  output.textContent = "Output view cleared [SIMULATED]\nNo log or endpoint data was removed.";
  showToast("Fixture view cleared. No file was changed.");
});

document.querySelector("#save-button").addEventListener("click", () => {
  const blob = new Blob([`${output.textContent}\n\nSTATIC DEMO FIXTURE — NOT ENDPOINT EVIDENCE\n`], { type: "text/plain" });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = "baselineops-simulated-fixture.txt";
  link.click();
  URL.revokeObjectURL(link.href);
  showToast("Downloaded sanitized fixture output. No endpoint log was accessed.");
});

document.querySelectorAll("[data-sim-action]").forEach((button) => button.addEventListener("click", () => {
  showSimulatedAction(button.dataset.simAction);
}));

function showSimulatedAction(action) {
  switch (action) {
    case "browse":
      showToast("Browse is simulated. The fixture kit root does not change.");
      break;
    case "refresh":
      showToast("Catalog refresh is simulated. No files were scanned.");
      break;
    case "validate":
      showToast("Fixture profile validated in the browser. No PowerShell command ran.");
      setStatus("Profile valid · SIMULATED");
      break;
  }
}

output.textContent = initialOutput;
selectScript("27");
