# Automated Log Validation — Playbook Skeleton

Mirrors the process described in the Automated Log Validation risk
assessment doc: pull the device list from Archer + SharePoint ERT (API),
pull the current week's log review files via SSH from the SFTP relay,
compare, produce a Found/Not Found report, and email missing devices per
device type.

**This is a skeleton, not a working playbook.** Every file has `CHANGE_ME`
placeholders, illustrative field names, and a few clearly-marked
not-yet-implemented pieces (see `filter_plugins/log_lookup.py`).

## Layout

```
playbook.yml                          # orchestrates the 3 plays
inventory/hosts.yml                   # sftp_relay host group
group_vars/all.yml                    # config, credential references, device-type map
tasks/get_archer_devices.yml          # Archer API pull
tasks/get_sharepoint_devices.yml      # SharePoint ERT (Graph API) pull
tasks/fetch_log_files.yml             # SSH pull from SFTP relay
tasks/compare_devices.yml             # per-device-type comparison
tasks/generate_report.yml             # renders the CSV report
tasks/notify_missing_devices.yml      # emails missing devices per device type
templates/validation_report.csv.j2
templates/missing_devices_email.j2
filter_plugins/log_lookup.py          # placeholder for per-log-format parsing
```

## Before this is runnable

1. **Credentials** — replace every `vault_*` variable with real values sourced
   from AAP's credential store (or an encrypted vault file for local testing).
   Never commit real secrets into `group_vars/all.yml`.
2. **Archer / Graph API contracts** — the request/response shapes in
   `get_archer_devices.yml` and `get_sharepoint_devices.yml` are illustrative;
   replace with the actual Archer REST/OData and SharePoint list schemas.
3. **Log file parsing** — `filter_plugins/log_lookup.py` needs real CSV
   parsing per log format (column layout and match key vary by technology —
   see the existing Excel macro logic for the field mappings to port over).
4. **Inventory** — point `sftp_relay` at the real SFTP relay host and
   supply a real SSH key/service account.
5. **Collections** — this playbook uses `ansible.posix.synchronize` and
   `community.general.mail` / `community.general.json_query`; make sure
   those collections are installed in the AAP execution environment.
6. **Testing** — recommend a `--check`/dry-run pass against a non-production
   Archer report and a small sample log file set before scheduling this
   for real weekly runs.
