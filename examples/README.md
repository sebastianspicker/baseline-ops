# Example Configurations

This directory contains example JSON configuration files for the security hardening scripts.

## Available Examples

| File | Script | Description |
|------|--------|-------------|
| `asr-defender-allowlist.json` | `01-ASR-Defender-Allowlist.ps1` | ASR rules and Defender exclusions |
| `local-admins-allowlist.json` | `03-LocalAdmins-Guardrail.ps1` | Local administrators allowlist |
| `firewall-baseline.json` | `18-Firewall-Baseline.ps1` | Firewall rules baseline |
| `wufb-proofing.json` | `05-WUFB-Proofing.ps1` | Windows Update for Business settings |

## Usage

### Basic Usage
```powershell
.\scripts\01-ASR-Defender-Allowlist.ps1 -ConfigPath ".\examples\configs\asr-defender-allowlist.json"
```

### With Remediation
```powershell
.\scripts\03-LocalAdmins-Guardrail.ps1 -ConfigPath ".\examples\configs\local-admins-allowlist.json" -Remediate
```

### Preview Changes (WhatIf)
```powershell
.\scripts\18-Firewall-Baseline.ps1 -ConfigPath ".\examples\configs\firewall-baseline.json" -Remediate -WhatIf
```

## Configuration Structure

Most configuration files follow this general structure:

```json
{
  "Settings": {
    "Setting1": "value1",
    "Setting2": "value2"
  },
  "Findings": {
    "CODE001": {
      "Severity": "Medium",
      "Enabled": true
    }
  },
  "Proof": {
    "OutFile": "C:\\ProgramData\\SecurityHardening\\proof.json"
  }
}
```

### Common Sections

- **Settings**: Script-specific configuration values
- **Findings**: Override default severity levels for specific finding codes
- **Proof**: Output file paths for audit proof

## Creating Custom Configs

1. Copy an example config to your desired location
2. Modify the values to match your environment
3. Validate the JSON syntax
4. Test with the script using `-WhatIf` first

### Best Practices

- Store configs in a version-controlled location
- Use environment-specific configs (dev, test, prod)
- Document any custom configurations
- Test configs in a non-production environment first

## Finding Severity Overrides

You can customize the severity of findings in any config:

```json
{
  "Findings": {
    "REMOTE-RDPEnabled": {
      "Severity": "High",
      "Enabled": true
    },
    "REMOTE-RDPDisabled": {
      "Severity": "Info",
      "Enabled": true
    }
  }
}
```

## Path Placeholders

All example configs use realistic paths. When creating your own configs:

- Use absolute paths for production
- Ensure paths exist or the script has permission to create them
- Use environment variables where appropriate: `%ProgramData%`, `%TEMP%`, etc.
