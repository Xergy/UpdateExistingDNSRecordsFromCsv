# Simple script to update existing DNS records based on .csv file
# Be sure to start in the root of the script folder

# load required function, you must be in the script directory!
. .\Helpers.ps1

# Choose common variables:
$Recordstoloadfilename = ".\DnsServerARecords_Texas.csv"
$DNSServersNamefilename = ".\DnsServers.csv"
$Force = $false
$TTLTimeSpan = New-TimeSpan -Hours 0 -Minutes 2 -Seconds 0

cls ; Write-Host "Starting DNS Updates...`n"

# Load Records
Write-Host "Loading new records...`n"
$Records = Import-Csv -path $Recordstoloadfilename | Out-GridView -OutputMode Multiple -Title "Choose Records to Query and Update"
$DNSServerData = Import-Csv -path $DNSServersNamefilename | Out-GridView -OutputMode Multiple -Title "Choose Servers/DNSZone to Query"
$DNSServersGrouped = $DNSServerData | Group-Object -Property ComputerName

Foreach ( $DNSServer in $DNSServersGrouped ) {
    $DNSServer.Name

    Foreach ($Zonename in $DNSServer.Group.ZoneName) {
        $Zonename

        Foreach ($Record in $Records){
                # Get the current resource record. 
                try { 
                    $OldRR = Get-DnsServerResourceRecord -ComputerName $Computer -Name $Name -RRType $RecordType -ZoneName $ZoneName -ErrorAction Stop 
                    $NewRR = Get-DnsServerResourceRecord -ComputerName $Computer -Name $Name -RRType $RecordType -ZoneName $ZoneName -ErrorAction Stop 
                    
                    If($TTL) {$NewRR.TimeToLive = $TTL}                    
                     
                    # Ensure that the resource record exists before proceeding. 
                    if ($NewRR -and $OldRR) { 
                        if ($OldRR.Count) { 
                            # More than one record found. 
                            $NewRR[$RRIndex].RecordData.IPv4Address=[ipaddress]$IPAddress 
                            $UpdatedRR = Set-DnsServerResourceRecord -NewInputObject $NewRR[$RRIndex] -OldInputObject $OldRR[$RRIndex] -ZoneName $ZoneName -ComputerName $Computer -PassThru 
                            $UpdatedRR 
                            } 
                        else { 
                            $NewRR.RecordData.IPv4Address=[ipaddress]$IPAddress 
                            $UpdatedRR = Set-DnsServerResourceRecord -NewInputObject $NewRR -OldInputObject $OldRR -ZoneName $ZoneName -ComputerName $Computer -PassThru 
                            $UpdatedRR 
                            } 
                        } 
                    } 
                catch { 
                    # If it doesn't exist create it if the -Force parameter. 
                    if ($Force) { 
                        $NewRR = Add-DnsServerResourceRecordA -ComputerName $Computer -Name $Name -ZoneName $ZoneName -IPv4Address $IPAddress -PassThru 
                        $NewRR 
                        } 
                    else { 
                        Write-Error "Existing record $Name.$ZoneName does not exist. Use -Force to create it." 
                        } 
                    } 
        
        }


    }
}



# Show new TTL
Write-host "New TTL..."
$TTLTimeSpan | Select-Object -Property Days,Hours,Minutes,Seconds| ft -AutoSize

# Show new record data
Write-host "New record data..."
$Records | Sort-Object Name | ft -AutoSize

# Show all existing records
Write-host "Query current record data..."
#$Records | Get-DnsServerResourceRecord | Sort-Object Name | ft -AutoSize


foreach ($Record in $Records){
Write-Host "Starting query job for DNS Record $($Record.Name) on AD DNS Server $($Record.ComputerName)"
    $Record | Get-DnsServerResourceRecord -AsJob | out-null
}
$Results = Get-Job | Wait-job | Receive-Job

Write-host "Summary of current queried record data..."
$Results

Write-Host "`nType ""Yes"" to process DNS updates ($($Records.Count) Total), or Ctrl-C to Exit" -ForegroundColor Green 
$HostInput = $Null 
$HostInput = Read-Host "Final Answer"  
If ($HostInput -ne "Yes" ) { 
     Break 
} 

# Execute Update
Write-host "`nUpdating Records...`n"
$Records | Update-DnsServerResourceRecordA -ComputerName $ComputerName -ZoneName $ZoneName -RRIndex 0 -RecordType "A" -Force:$Force -TTL $TTLTimeSpan | Sort-Object Name | ft -AutoSize

foreach ($Computer in $ComputerName) { 
    if (Test-Connection -ComputerName $Computer -Count 1 -Quiet) { 
                 
        # Get the current resource record. 
        try { 
            $OldRR = Get-DnsServerResourceRecord -ComputerName $Computer -Name $Name -RRType $RecordType -ZoneName $ZoneName -ErrorAction Stop 
            $NewRR = Get-DnsServerResourceRecord -ComputerName $Computer -Name $Name -RRType $RecordType -ZoneName $ZoneName -ErrorAction Stop 
                    
            If($TTL) {$NewRR.TimeToLive = $TTL}                    
                     
            # Ensure that the resource record exists before proceeding. 
            if ($NewRR -and $OldRR) { 
                if ($OldRR.Count) { 
                    # More than one record found. 
                    $NewRR[$RRIndex].RecordData.IPv4Address=[ipaddress]$IPAddress 
                    $UpdatedRR = Set-DnsServerResourceRecord -NewInputObject $NewRR[$RRIndex] -OldInputObject $OldRR[$RRIndex] -ZoneName $ZoneName -ComputerName $Computer -PassThru 
                    $UpdatedRR 
                    } 
                else { 
                    $NewRR.RecordData.IPv4Address=[ipaddress]$IPAddress 
                    $UpdatedRR = Set-DnsServerResourceRecord -NewInputObject $NewRR -OldInputObject $OldRR -ZoneName $ZoneName -ComputerName $Computer -PassThru 
                    $UpdatedRR 
                    } 
                } 
            } 
        catch { 
            # If it doesn't exist create it if the -Force parameter. 
            if ($Force) { 
                $NewRR = Add-DnsServerResourceRecordA -ComputerName $Computer -Name $Name -ZoneName $ZoneName -IPv4Address $IPAddress -PassThru 
                $NewRR 
                } 
            else { 
                Write-Error "Existing record $Name.$ZoneName does not exist. Use -Force to create it." 
                } 
            } 
        } 
    else { 
        Write-Error "Unable to connect to $Computer" 
        } 
    } 






# Double verify current DNS Record info
Write-Host "Double verify current DNS Record info...`n"

$Records | Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $ComputerName | Sort-Object Name | ft -AutoSize

Write-Host "Done!"