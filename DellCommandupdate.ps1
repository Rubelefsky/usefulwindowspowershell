# URL to download from
$downloadUrl = "https://downloads.dell.com/FOLDER11563484M/1/Dell-Command-Update-Windows-Universal-Application_P83K5_WIN_5.3.0_A00.EXE" 
# Path to save the installer
$installerPath = "$env:TEMP\Dell-Command-Update-Installer.exe" 


# Start the download
Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath # Download the installer


#Install the download
Start-Process -FilePath $installerPath -ArgumentList "/s" -Wait -NoNewWindow


# Remove download file 
Remove-Item -Path $installerPath -Force


# Verify install
Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Dell Command*Update*"}
