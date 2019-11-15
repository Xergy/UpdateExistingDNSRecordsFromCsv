# Simple script to update existing DNS records based on .csv file
# Be sure to start in the root of the script folder

# load required function, you must be in the script directory!
. .\Helpers.ps1

# Choose common variables:
$Recordstoloadfilename = ".\DnsServerARecords_Texas.csv"
$ComputerName = "rp-ad.agile.devops"
$ZoneName = "agile.devops"
$Force = $false
$TTLTimeSpan = New-TimeSpan -Hours 0 -Minutes 2 -Seconds 0

cls ; Write-Host "Starting DNS Updates...`n"

# Load Records
$Records = Import-Csv -path $Recordstoloadfilename

# Show all existing records
Write-host "Current record data..."
$Records | Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $ComputerName | Sort-Object Name | ft -AutoSize

# Show all records
Write-host "New record data..."
$Records | Sort-Object Name | ft -AutoSize

# Show new TTL
Write-host "New TTL..."
$TTLTimeSpan | Select-Object -Property Days,Hours,Minutes,Seconds| ft -AutoSize

Write-Host "`nType ""Yes"" to process DNS updates ($($Records.Count) Total), or Ctrl-C to Exit" -ForegroundColor Green 
$HostInput = $Null 
$HostInput = Read-Host "Final Answer"  
If ($HostInput -ne "Yes" ) { 
     Break 
} 


# Execute Update
Write-host "`nUpdating Records...`n"
$Records | Update-DnsServerResourceRecordA -ComputerName $ComputerName -ZoneName $ZoneName -RRIndex 0 -RecordType "A" -Force:$Force -TTL $TTLTimeSpan | Sort-Object Name | ft -AutoSize

# Double verify current DNS Record info
Write-Host "Double verify current DNS Record info...`n"

$Records | Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $ComputerName | Sort-Object Name | ft -AutoSize

Write-Host "Done!"