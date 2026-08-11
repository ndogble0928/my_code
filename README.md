# Automated Log Validation Integration with Central Services Ansible Automation Platform

**IT Compliance Operations (ITCO) Risk Assessment**

| | |
|---|---|
| **Document Name** | Automated Log Validation Integration with Central Services Ansible Automation Platform |
| **Ver. #** | 2.0 |
| **Effective Date** | 08/11/2026 |

## Glossary

| Term | Description |
|---|---|
| **Ansible Automation Platform (AAP)** | Enterprise-grade automation solution provided by Red Hat which offers a comprehensive framework for building, managing, and scaling IT automation across diverse environments |
| **Central Services (CS)** | Firewalled network space for OT systems |
| **Archer** | GRC platform of record; exposes a device list via API for devices where device data is maintained directly in Archer |
| **SharePoint ERT** | SharePoint site maintaining device lists not yet present in Archer; exposed via Microsoft Graph API |
| **Device Type** | Field on the device list record used to identify which log review file a given device's events should appear in |
| **SFTP Server** | Intermediary server that relays the current week's log review files to AAP via SSH; sits between the log source network and the AAP network |
| **Log Review File** | Weekly export of logged events for a given technology stack, used to confirm that expected devices generated log events during the review period |

## Purpose

To evaluate the risk posed to systems administered by the IT Compliance Operations team if the Automated Log Validation process running on the Central Services Ansible Automation Platform is allowed.

## Proposal

ITCO Compliance Operations proposes an automation pattern in which the CS Ansible Automation Platform gets the device list from Archer and SharePoint ERT via API, processes it, and compares it against the current week's log review files. It produces a Found/Not Found validation report per device type. Devices not found in their expected log review file are reported by email to the responsible SME, replacing the current manual Excel-macro-based validation process.

## Log File Location

The current week's log review files reside on a network share that is outside the AAP network. AAP retrieves them via SSH from an intermediary SFTP server, which serves as the file relay between the log source and AAP.

## Service Accounts Requirements

1. **Archer / SharePoint ERT (API)**
   - A. Read-only API access, scoped to the device list data required for validation — not tenant-wide read access
   - B. Non-interactive service account; API credentials (Client ID/Client Secret) stored in AAP's credential vault, never inline in playbooks
   - C. Credential rotation policy defined and an owner assigned for periodic access review

2. **SFTP Server (Log File Relay)**
   - A. AAP connects via SSH using a non-interactive service account scoped to read-only file retrieval
   - B. SSH credentials (key or password) stored in AAP's credential vault, never inline in playbooks
   - C. Access scoped to the specific directory/path containing the current week's log review files — not broader filesystem or shell access

3. **Ansible**
   - A. Service account scoped to only the systems/actions the automation is authorized to touch
   - B. Non-interactive, MFA-exempt with compensating controls (IP allow-list, credential vaulting, audit logging)
   - C. Execution and decision logic auditable — which device list and log file drove which validation result, with timestamp and outcome

## Known Risks

1. Dependency on Archer/SharePoint API availability; an outage, expired OAuth token, or revoked Azure AD app credential would block device list retrieval entirely.
2. The comparison relies on the Device Type field to route each device to the correct log file; a mistyped or blank value would cause a valid device to be reported as missing (false positive) or skipped entirely.
3. Log file location and naming on the SFTP server must stay consistent; a renamed path, moved relay, or off-schedule log drop would break the weekly file retrieval.
4. Email is the only alerting mechanism for missing devices; if the notification step fails silently, a gap in log coverage could go unnoticed until the next review cycle.
5. The SFTP server is an added dependency and trust boundary between the log source and AAP; its availability, credential validity, and connectivity to AAP are all additional points of failure for the weekly validation.
