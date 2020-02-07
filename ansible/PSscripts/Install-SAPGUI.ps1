param(
    [string] $DownloadDirectory = "C:\Temp\SAPWorkdir",

    [string] $UserConfigDirectory = "C:\Temp\configFiles",

    [string] $DownloadURL = "https://presalesdemobuild.blob.core.windows.net/binaries/SAPGUI_Installer.zip", #"https://presalesceinternalautoma.blob.core.windows.net/binaries/SAPGUI_Installer.zip"

    [string] $ProductsToInstall = "SAPGUI+NWBC65"
)

$MainZip = "SAPGUI_Installer.zip"
$InstallerZip = "1_SAPGUI7.50_WINDOWS.zip"
$PatchFile = "2_PATCH_gui750_3-80001468.exe"
$Hotfix = "3_HotFix_gui750_05_1-80001468.exe"
$SapInstallerPath = [System.Io.Path]::Combine($DownloadDirectory, "SAPGUI7.50_WINDOWS", "SAPGUI7.50_WINDOWS", "Win32", "Setup", "NwSapSetup.exe")

#Create work directory
if (!(Test-Path $DownloadDirectory)) {
    [System.Io.Directory]::CreateDirectory($DownloadDirectory)
}

#Download binaries and the template for user configuration
$webClinet = New-Object System.Net.WebClient
$webClinet.DownloadFile($DownloadURL, $(Join-Path $DownloadDirectory $MainZip));

#Extract zipped files
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($(Join-Path $DownloadDirectory $MainZip), $DownloadDirectory)
[System.IO.Compression.ZipFile]::ExtractToDirectory($(Join-Path $DownloadDirectory $InstallerZip), $DownloadDirectory)

#Install and patch
Start-Process -FilePath $SapInstallerPath -ArgumentList "/Product=$ProductsToInstall /Silent"  -Wait -NoNewWindow
Start-Process -FilePath $(Join-Path $DownloadDirectory $PatchFile) -ArgumentList "/Silent"  -Wait -NoNewWindow
Start-Process -FilePath $(Join-Path $DownloadDirectory $Hotfix) -ArgumentList "/Silent"  -Wait -NoNewWindow


#Cleanup
Remove-Item $DownloadDirectory -Recurse


