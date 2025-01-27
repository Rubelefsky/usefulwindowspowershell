# Gets windows SYSTEM logs for Event ID 1074 and prints to console
Get-WinEvent -FilterHashtable @{logname = 'System'; id = 1074} | Format-Table -wrap
