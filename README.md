# UpdateExistingDNSRecordsFromCsv
Powershell scripts to assist with bulk updates to existing DNS records in Active Directory DNS from .Csv file

## Design Thoughts

- Add comments
- Needs separate script for TTL updates
- Maybe use file picker for opening .csv
- Allow for different Zones

## Proposed files and Modules

- Start-DNSRecordUpdate.ps1
    - Flow
    - Comments
    - Common Variables
    - Import CSV
    - Show existing Records in OGV
    - [Optional] Ask to save existing Record data?
    - Select Records to Update in OGV
    - Prompt final for change conformation
    - Perform work
      - Loop Computer, Computer's Zone, Record Update
    - Prompt to show Results in OGV?

- Helpers.ps1
- Functions
  - Set-DNSARecordIP
  - Set-DNSARecordTTL
  - Get-ADDNSServer 
