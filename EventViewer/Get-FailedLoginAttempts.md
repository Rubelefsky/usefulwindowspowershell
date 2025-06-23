# Get-FailedLoginAttempts.ps1 - Script Documentation

## Overview
This PowerShell script retrieves and displays the last 5 failed login attempts from the Windows Security Event Log. It provides detailed information about each failed attempt and optionally exports the results to a CSV file.

## Prerequisites
- **Administrator privileges** - Required to access the Security Event Log
- Windows Event Logging must be enabled
- Security auditing must be configured to log failed login attempts

## Line-by-Line Explanation

### Lines 1-3: Script Header and Description
```powershell
# Get-FailedLoginAttempts.ps1
# Script to retrieve the last 5 failed login attempts from Windows Security Event Log
```
- **Line 1-2**: Comment block providing the script name and purpose
- Sets up the script's documentation

### Lines 5-10: Administrator Privilege Check
```powershell
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges to access the Security Event Log."
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}
```
- **Line 5**: Checks if the current user has Administrator privileges
  - `[Security.Principal.WindowsIdentity]::GetCurrent()` - Gets the current Windows identity
  - `[Security.Principal.WindowsPrincipal]` - Creates a principal object to check roles
  - `.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")` - Checks for admin role
  - `-NOT` - Negates the result (true if NOT administrator)
- **Line 6**: Displays a warning message if not running as administrator
- **Line 7**: Shows a red-colored message instructing to run as administrator
- **Line 8**: Exits the script with error code 1 if not administrator

### Lines 12-15: Script Initialization and User Feedback
```powershell
try {
    Write-Host "Retrieving last 5 failed login attempts..." -ForegroundColor Yellow
    Write-Host "=" * 60
```
- **Line 12**: Begins a try-catch block for error handling
- **Line 13**: Displays a yellow status message to inform the user of the operation
- **Line 14**: Prints a separator line of 60 equal signs for visual formatting

### Lines 16-20: Query Security Event Log
```powershell
    $failedLogins = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625
    } -MaxEvents 5 -ErrorAction Stop
```
- **Line 16-19**: Queries the Windows Event Log using `Get-WinEvent`
  - `-FilterHashtable` - Uses a hashtable to filter events efficiently
  - `LogName = 'Security'` - Targets the Security event log
  - `ID = 4625` - Filters for Event ID 4625 (failed logon attempts)
- **Line 19**: 
  - `-MaxEvents 5` - Limits results to the 5 most recent events
  - `-ErrorAction Stop` - Causes the script to stop if an error occurs

### Lines 21-25: Check for Results
```powershell
    if ($failedLogins.Count -eq 0) {
        Write-Host "No failed login attempts found in the Security Event Log." -ForegroundColor Green
        exit 0
    }
```
- **Line 21**: Checks if no failed login events were found
- **Line 22**: Displays a green success message if no failed logins exist
- **Line 23**: Exits the script successfully with code 0

### Lines 26-33: Process Each Failed Login Event
```powershell
    foreach ($event in $failedLogins) {
        $eventXML = [xml]$event.ToXml()
        $eventData = $eventXML.Event.EventData.Data
        
        # Extract relevant information from the event data
        $targetUserName = ($eventData | Where-Object {$_.Name -eq 'TargetUserName'}).'#text'
        $targetDomainName = ($eventData | Where-Object {$_.Name -eq 'TargetDomainName'}).'#text'
        $workstationName = ($eventData | Where-Object {$_.Name -eq 'WorkstationName'}).'#text'
```
- **Line 27**: Starts a loop to process each failed login event
- **Line 28**: Converts the event to XML format for easier data extraction
- **Line 29**: Extracts the EventData section containing detailed information
- **Line 32-34**: Extract specific data fields from the event:
  - `TargetUserName` - The username that failed to log in
  - `TargetDomainName` - The domain of the target account
  - `WorkstationName` - The computer where the login attempt occurred

### Lines 34-38: Extract Additional Event Data
```powershell
        $sourceNetworkAddress = ($eventData | Where-Object {$_.Name -eq 'IpAddress'}).'#text'
        $sourcePort = ($eventData | Where-Object {$_.Name -eq 'IpPort'}).'#text'
        $logonType = ($eventData | Where-Object {$_.Name -eq 'LogonType'}).'#text'
        $failureReason = ($eventData | Where-Object {$_.Name -eq 'SubStatus'}).'#text'
```
- **Line 34**: Extracts the source IP address of the failed login attempt
- **Line 35**: Extracts the source port number
- **Line 36**: Extracts the logon type (how the login was attempted)
- **Line 37**: Extracts the failure reason code (why the login failed)

### Lines 39-50: Convert Logon Type to Human-Readable Format
```powershell
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
```
- **Line 40-50**: Uses a switch statement to convert numeric logon type codes to descriptive text:
  - **Type 2**: Interactive login (local console)
  - **Type 3**: Network login (file shares, etc.)
  - **Type 4**: Batch job login
  - **Type 5**: Service account login
  - **Type 7**: Screen unlock attempt
  - **Type 8**: Network login with cleartext password
  - **Type 9**: Login with different credentials
  - **Type 10**: Remote Desktop Protocol (RDP) login
  - **Type 11**: Cached credential login
  - **default**: Shows original code if unknown

### Lines 52-65: Convert Failure Reason to Human-Readable Format
```powershell
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
```
- **Line 53-64**: Converts hexadecimal failure codes to descriptive error messages:
  - **0xC0000064**: Username doesn't exist in the system
  - **0xC000006A**: Incorrect password provided
  - **0xC0000234**: Account is currently locked out
  - **0xC0000072**: Account is disabled
  - **0xC000006F**: Login attempted outside allowed hours
  - **0xC0000070**: Login restricted from this workstation
  - **0xC0000193**: User account has expired
  - **0xC0000071**: Password has expired
  - **0xC0000133**: Time synchronization issue between client and server
  - **0xC0000224**: User must change password before logging in

### Lines 66-76: Display Event Information
```powershell
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
```
- **Line 67**: Prints blank line for spacing
- **Line 68**: Shows the attempt number in red (calculates position in array + 1)
- **Line 69-75**: Displays all extracted information in white text:
  - Date and time of the attempt
  - Full username (domain\username format)
  - Source workstation name
  - Source IP address and port
  - Human-readable logon type and failure reason
- **Line 76**: Prints a separator line of 60 dashes

### Lines 78-80: Display Summary
```powershell
    Write-Host ""
    Write-Host "Total failed login attempts shown: $($failedLogins.Count)" -ForegroundColor Yellow
```
- **Line 79**: Prints a blank line
- **Line 80**: Shows the total count of failed login attempts in yellow

### Lines 82-90: Error Handling
```powershell
} catch [System.Exception] {
    if ($_.Exception.Message -like "*No events were found*") {
        Write-Host "No failed login attempts found in the Security Event Log." -ForegroundColor Green
    } else {
        Write-Error "Error accessing Security Event Log: $($_.Exception.Message)"
        Write-Host "Make sure you're running as Administrator and that auditing is enabled." -ForegroundColor Yellow
    }
}
```
- **Line 82**: Catches any exceptions that occur during execution
- **Line 83-84**: If the specific "No events found" error occurs, shows a friendly green message
- **Line 85-87**: For other errors:
  - Displays the actual error message
  - Provides troubleshooting guidance about administrator rights and auditing

### Lines 92-119: Optional CSV Export Feature
```powershell
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
```

#### Lines 92-93: User Prompt for Export
- **Line 92**: Prompts user to choose whether to export results to CSV
- **Line 93**: Checks if user responded with 'y' or 'Y'

#### Lines 94-107: CSV Data Preparation
- **Line 95**: Starts another try-catch block for export operations
- **Line 96**: Initializes an empty array to store CSV data
- **Line 97-107**: Loops through events again to create CSV-formatted objects:
  - Converts each event to XML and extracts data
  - Creates a PowerShell custom object with clean property names
  - Combines domain and username for the Username field
  - Stores raw codes for LogonType and FailureReason (for data analysis)

#### Lines 109-112: CSV File Creation and Export
- **Line 109**: Creates a timestamped filename in C:\Tools\ directory
  - Uses `Get-Date -Format 'yyyyMMdd_HHmmss'` for unique timestamp
- **Line 110**: Exports the data array to CSV format without type information
- **Line 111**: Confirms successful export with green text showing file path

#### Lines 112-115: Export Error Handling
- **Line 113-114**: Catches and displays any errors that occur during CSV export

## Key Features

### Security Event Analysis
- Targets Windows Security Event ID 4625 (failed logon attempts)
- Extracts comprehensive details from each failed attempt
- Converts technical codes to human-readable descriptions

### User-Friendly Output
- Color-coded console output for easy reading
- Organized display with clear separators
- Summary information showing total attempts

### Data Export Capability
- Optional CSV export for further analysis
- Timestamped filenames to avoid overwrites
- Clean column headers for spreadsheet compatibility

### Error Handling
- Validates administrator privileges before execution
- Graceful handling of missing events
- Informative error messages with troubleshooting tips

## Usage Examples

### Basic Usage
```powershell
.\Get-FailedLoginAttempts.ps1
```

### Running as Administrator
```powershell
# Right-click PowerShell and select "Run as Administrator", then:
.\Get-FailedLoginAttempts.ps1
```

## Output Format

### Console Output
```
Retrieving last 5 failed login attempts...
============================================================

Failed Login Attempt #1
Date/Time: 6/23/2025 2:15:30 PM
Username: DOMAIN\testuser
Workstation: WORKSTATION01
Source IP: 192.168.1.100
Source Port: 54321
Logon Type: RemoteInteractive (RDP)
Failure Reason: Wrong password
------------------------------------------------------------
```

### CSV Output Columns
- **DateTime**: Timestamp of the failed attempt
- **Username**: Domain\Username format
- **Workstation**: Source computer name
- **SourceIP**: IP address of the attempt
- **LogonType**: Numeric logon type code
- **FailureReason**: Hexadecimal failure code

## Security Considerations

1. **Privilege Requirements**: Script requires administrator access to read Security logs
2. **Audit Policy**: Ensure "Audit Logon Events" is enabled in Group Policy
3. **Log Retention**: Consider Security log size and retention policies
4. **Sensitive Information**: Failed login data may contain sensitive usernames

## Troubleshooting

### Common Issues
1. **"Access Denied"**: Run PowerShell as Administrator
2. **"No events found"**: Check if audit logging is enabled
3. **"Log not found"**: Verify Windows Event Log service is running
4. **CSV export fails**: Ensure C:\Tools\ directory exists and is writable

### Enabling Failed Logon Auditing
1. Open Group Policy Editor (gpedit.msc)
2. Navigate to: Computer Configuration > Windows Settings > Security Settings > Local Policies > Audit Policy
3. Enable "Audit logon events" for both Success and Failure

## Modifications and Enhancements

### Possible Improvements
- Increase the number of events retrieved (change `-MaxEvents 5`)
- Add date range filtering
- Include successful logon events for comparison
- Add email notifications for suspicious activity
- Create scheduled task for automated monitoring

### Custom Date Range Example
```powershell
# Modify the FilterHashtable to include date range
$failedLogins = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4625
    StartTime = (Get-Date).AddDays(-7)  # Last 7 days
    EndTime = Get-Date
} -MaxEvents 50
```
