# Simple script to update existing DNS records based on .csv file

# Choose common variables:
$Recordstoloadfilename = ".\DnsServerARecords.csv"
$TTLTimeSpan = New-TimeSpan -Hours 0 -Minutes 5 -Seconds 0


# Load Records
$DataFileRecords = Import-Csv -path $Recordstoloadfilename

cls
Write-Host "`nDatafile Record Summary..." 
$DataFileRecords | ft -AutoSize

# Show new TTL
Write-host "Proposed TTL..." 
$TTLTimeSpan | Select-Object -Property Days,Hours,Minutes,Seconds| ft -AutoSize

$ExistingRecords = @()

foreach ($Record in $DataFileRecords) {
     
     Write-Host "Gathering data for:$($Record.Name) in Zone:$($Record.ZoneName) on ADDNSServer:$($Record.ADDNSServer) ..." -ForegroundColor Cyan
     $ExistingRecord = Get-DnsServerResourceRecord -Name $Record.Name -ZoneName $Record.ZoneName -ComputerName $Record.ADDNSServer
     $ExistingRecords += @{
                        ExistingRecordObject = $ExistingRecord
                        ZoneName = $Record.ZoneName
                        ADDNSServer = $Record.ADDNSServer
                        }
}

Write-Host "`nExisting Record Summary..." 
$ExistingRecords.ExistingRecordObject | ft -AutoSize


$HostInput = $Null 
$HostInput = Read-Host "Choose update data as [P]rimary,[S]econdary IPS or [T]TL Only"  
If ($HostInput -like "P" ) { 
    $ChoosenRecords = $DataFileRecords | Select-Object -Property Name,@{N=’IP’; E={$_.IP_Primary}},ZoneName,ADDNSServer
    $TTLOnly = $false 
} ElseIf ($HostInput -like "S") {
    $ChoosenRecords = $DataFileRecords | Select-Object -Property Name,@{N=’IP’; E={$_.IP_Secondary}},ZoneName,ADDNSServer
    $TTLOnly = $false 
} ElseIf ($HostInput -like "T") {
    $TTLOnly = $True
} Else {"Stopping" ; break}


# Show new 
If (!$TTLOnly) {
    Write-host "`nExisting Records will be udpated to the below New Information..." 
    $ChoosenRecords | ft -AutoSize
    Write-host "New TTL..." 
    $TTLTimeSpan | Select-Object -Property Days,Hours,Minutes,Seconds| ft -AutoSize
} Else {
    Write-host "`nNew TTL..." 
    $TTLTimeSpan | Select-Object -Property Days,Hours,Minutes,Seconds| ft -AutoSize
}


Write-Host "`nType ""Yes"" to process DNS updates ($($ChoosenRecords.Count) Total), or Ctrl-C to Exit" -ForegroundColor Green 
$HostInput = $Null 
$HostInput = Read-Host "Final Answer"  
If ($HostInput -ne "Yes" ) { 
     Break 
} 

ForEach ($ExistingRecord in $ExistingRecords) {
    $OldIP = $ExistingRecord.ExistingRecordObject.RecordData.IPv4Address.IPAddressToString
    $NewIP = $ChoosenRecords | 
        Where-Object {
            $_.Name -like $ExistingRecord.ExistingRecordObject.Hostname -and
            $_.ZoneName -like $ExistingRecord.ZoneName -and 
            $_.ADDNSServer -like $ExistingRecord.ADDNSServer
            } | ForEach-Object {$_.IP}
    
    Write-Host "`nProcessing Record:$($ExistingRecord.ExistingRecordObject.Hostname) in Zone:$($ExistingRecord.ZoneName) on ADDNSServer:$($ExistingRecord.ADDNSServer) ..." -ForegroundColor Cyan
    If (!$TTLOnly) {
        Write-Host "`Changing to New IP $($NewIP) and TTL in seconds $($TTLTimeSpan.TotalSeconds)" -ForegroundColor Cyan
    } Else { Write-Host "`Only Changing TTL in seconds $($TTLTimeSpan.TotalSeconds)" -ForegroundColor Cyan }
    
    $NewRecord = $ExistingRecord.ExistingRecordObject.Clone()
    If (!$TTLOnly) { $NewRecord.RecordData.IPv4Address=[ipaddress]$NewIP}
    $NewRecord.TimeToLive = $TTLTimeSpan
    Set-DnsServerResourceRecord -NewInputObject $NewRecord -OldInputObject $ExistingRecord.ExistingRecordObject  -ZoneName $ExistingRecord.ZoneName -ComputerName $ExistingRecord.ADDNSServer
}    

Write-Host "`nDone!"