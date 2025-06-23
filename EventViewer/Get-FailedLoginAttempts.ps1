# Get-FailedLoginAttempts.ps1
# Script to retrieve the last 5 failed login attempts from Windows Security Event Log

# Check if running as administrator (required for Security log access)
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges to access the Security Event Log."
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Retrieving last 5 failed login attempts..." -ForegroundColor Yellow
    Write-Host "=" * 60

    # Query Security Event Log for failed logon attempts (Event ID 4625)
    $failedLogins = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625
    } -MaxEvents 5 -ErrorAction Stop

    if ($failedLogins.Count -eq 0) {
        Write-Host "No failed login attempts found in the Security Event Log." -ForegroundColor Green
        exit 0
    }

    # Process and display each failed login attempt
    foreach ($event in $failedLogins) {
        $eventXML = [xml]$event.ToXml()
        $eventData = $eventXML.Event.EventData.Data
        
        # Extract relevant information from the event data
        $targetUserName = ($eventData | Where-Object {$_.Name -eq 'TargetUserName'}).'#text'
        $targetDomainName = ($eventData | Where-Object {$_.Name -eq 'TargetDomainName'}).'#text'
        $workstationName = ($eventData | Where-Object {$_.Name -eq 'WorkstationName'}).'#text'
        $sourceNetworkAddress = ($eventData | Where-Object {$_.Name -eq 'IpAddress'}).'#text'
        $sourcePort = ($eventData | Where-Object {$_.Name -eq 'IpPort'}).'#text'
        $logonType = ($eventData | Where-Object {$_.Name -eq 'LogonType'}).'#text'
        $failureReason = ($eventData | Where-Object {$_.Name -eq 'SubStatus'}).'#text'
        
        # Convert logon type to human-readable format
        $logonTypeDescription = switch ($logonType) {
            "2" { "Interactive (Local)" }
            "3" { "Network" }
            "4" { "Batch" }
            "5" { "Service" }
            "7" { "Unlock" }
            "8" { "NetworkCleartext" }
            "9" { "NewCredentials" }
            "10" { "RemoteInteractive (RDP)" }
            "11" { "CachedInteractive" }
            default { "Unknown ($logonType)" }
        }
        
        # Convert failure reason to human-readable format
        $failureDescription = switch ($failureReason) {
            "0xC0000064" { "User name does not exist" }
            "0xC000006A" { "Wrong password" }
            "0xC0000234" { "Account locked out" }
            "0xC0000072" { "Account disabled" }
            "0xC000006F" { "Login outside allowed time" }
            "0xC0000070" { "Workstation restriction" }
            "0xC0000193" { "Account expired" }
            "0xC0000071" { "Password expired" }
            "0xC0000133" { "Clocks out of sync" }
            "0xC0000224" { "Password change required" }
            default { "Other failure ($failureReason)" }
        }
        
        # Display the information
        Write-Host ""
        Write-Host "Failed Login Attempt #$($failedLogins.IndexOf($event) + 1)" -ForegroundColor Red
        Write-Host "Date/Time: $($event.TimeCreated)" -ForegroundColor White
        Write-Host "Username: $targetDomainName\$targetUserName" -ForegroundColor White
        Write-Host "Workstation: $workstationName" -ForegroundColor White
        Write-Host "Source IP: $sourceNetworkAddress" -ForegroundColor White
        Write-Host "Source Port: $sourcePort" -ForegroundColor White
        Write-Host "Logon Type: $logonTypeDescription" -ForegroundColor White
        Write-Host "Failure Reason: $failureDescription" -ForegroundColor White
        Write-Host "-" * 60
    }

    Write-Host ""
    Write-Host "Total failed login attempts shown: $($failedLogins.Count)" -ForegroundColor Yellow
    
} catch [System.Exception] {
    if ($_.Exception.Message -like "*No events were found*") {
        Write-Host "No failed login attempts found in the Security Event Log." -ForegroundColor Green
    } else {
        Write-Error "Error accessing Security Event Log: $($_.Exception.Message)"
        Write-Host "Make sure you're running as Administrator and that auditing is enabled." -ForegroundColor Yellow
    }
}

# Optional: Export to CSV for further analysis
$exportChoice = Read-Host "`nWould you like to export these results to a CSV file? (y/n)"
if ($exportChoice -eq 'y' -or $exportChoice -eq 'Y') {
    try {
        $csvData = @()
        foreach ($event in $failedLogins) {
            $eventXML = [xml]$event.ToXml()
            $eventData = $eventXML.Event.EventData.Data
            
            $csvData += [PSCustomObject]@{
                DateTime = $event.TimeCreated
                Username = "$(($eventData | Where-Object {$_.Name -eq 'TargetDomainName'}).'#text')\$(($eventData | Where-Object {$_.Name -eq 'TargetUserName'}).'#text')"
                Workstation = ($eventData | Where-Object {$_.Name -eq 'WorkstationName'}).'#text'
                SourceIP = ($eventData | Where-Object {$_.Name -eq 'IpAddress'}).'#text'
                LogonType = ($eventData | Where-Object {$_.Name -eq 'LogonType'}).'#text'
                FailureReason = ($eventData | Where-Object {$_.Name -eq 'SubStatus'}).'#text'
            }
        }
        
        $csvPath = "C:\Tools\FailedLoginAttempts_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $csvData | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "Results exported to: $csvPath" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to export CSV: $($_.Exception.Message)"
    }
}
