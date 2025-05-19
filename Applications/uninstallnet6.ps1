$displayName = 'Microsoft .NET Runtime - 6.0.36 (x64)'
$uninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$uninstallKeyWow = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

$keys = Get-ChildItem $uninstallKey, $uninstallKeyWow

foreach ($key in $keys) {
    $name = (Get-ItemProperty $key.PSPath).DisplayName
    if ($name -eq $displayName) {
        $uninstallString = (Get-ItemProperty $key.PSPath).UninstallString
        if ($uninstallString) {
            # Add /quiet if not already present
            if ($uninstallString -notmatch '/quiet') {
                $uninstallString += ' /quiet'
            }
            Write-Output "Running: $uninstallString"
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c $uninstallString" -Wait
            Write-Output "$displayName has been uninstalled."
        }
    }
}