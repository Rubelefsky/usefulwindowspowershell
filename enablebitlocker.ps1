# Check if BitLocker is already enabled
$bitlockerStatus = Get-BitLockerVolume -MountPoint "C:"
 
if ($bitlockerStatus.ProtectionStatus -eq "Off") {
    # Enable BitLocker
    Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector
 
    # Add a recovery password protector
    $recoveryPasswordProtector = Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryPasswordProtector -PassThru
 
    Write-Output "BitLocker has been enabled on the C: drive."
} else {
    Write-Output "BitLocker is already enabled on the C: drive."
}
 
# Verify BitLocker is enabled and print the identifier and key
$bitlockerStatus = Get-BitLockerVolume -MountPoint "C:"
 
if ($bitlockerStatus.ProtectionStatus -eq "On") {
    # Retrieve all key protectors
    $keyProtectors = Get-BitLockerVolume -MountPoint "C:" | Select-Object -ExpandProperty KeyProtector
 
    # Filter for recovery password protector
    $recoveryPasswordProtector = $keyProtectors | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
 
    if ($null -ne $recoveryPasswordProtector) {
        Write-Output "BitLocker Identifier: $($recoveryPasswordProtector.KeyProtectorId)"
        Write-Output "BitLocker Recovery Key: $($recoveryPasswordProtector.RecoveryPassword)"
    } else {
        Write-Output "No recovery password protector found."
    }
}
