# TODO: Future Audit Scripts

The following security audit areas are not yet covered by dedicated scripts:

*(All items below have been implemented — see scripts 50–52.)*

- **AMSI (Antimalware Scan Interface) Audit** ✅ `50-AMSI-Audit.ps1`: Verify AMSI providers are registered and
  functioning, detect AMSI bypass attempts, and validate AMSI integration with PowerShell
  and other scripting hosts.

- **AppLocker Audit** ✅ `51-AppLocker-Audit.ps1`: Enumerate AppLocker policies, verify enforcement mode per rule
  collection (Exe, Script, MSI, DLL, Packaged), detect gaps in coverage, and report
  on audit-only vs. enforced rules.

- **DNS-over-HTTPS (DoH) Audit** ✅ `52-DoH-Audit.ps1`: Check Windows DNS client DoH configuration, verify
  DoH server endpoints, audit whether plaintext DNS fallback is permitted, and validate
  alignment with organizational DNS security policy.
