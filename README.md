Subject: RE: SecureBoot 2023 check within Windows

Hi Team,

Just to confirm — Ansible is running the exact same PowerShell checks you provided against all servers simultaneously. The following scripts are included in the playbook:

1. Secure Boot status check:
Confirm-SecureBootUEFI

2. Platform Key (PK) certificate check:
$pk = Get-SecureBootUEFI -Name PK
$bytes = $pk.Bytes
$cert = $bytes[44..($bytes.Length-1)]
$tmpFile = "$env:TEMP\PK.der"
[IO.File]::WriteAllBytes($tmpFile, $cert)
$dump = certutil -dump $tmpFile
if ($dump -match '2023') { Write-Output '2023_CERT_FOUND' } else { Write-Output '2023_CERT_NOT_FOUND' }

3. DB certificate checks:
([System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI DB).bytes) -match 'Microsoft UEFI CA 2023')
([System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI DB).bytes) -match 'Windows UEFI CA 2023')
([System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI DB).bytes) -match 'Microsoft Option ROM UEFI CA 2023')

4. KEK certificate check:
([System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI KEK).bytes) -match 'Microsoft Corporation KEK 2K CA 2023')

5. Registry status check (via Ansible win_reg_stat module):
Reads UEFICA2023Status value from HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing

All results are captured per host and consolidated into a single CSV report.

Thanks,
Nico
