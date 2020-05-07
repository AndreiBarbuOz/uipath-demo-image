param(
    [string] $DownloadDirectory = "C:\Temp\O365Workdir",

    [string] $DownloadURL = "https://presalesdemobuild.blob.core.windows.net/binaries/office365tools.zip"
)
try {
    $MainZip = "office365tools.zip"
    $OfficeTool = "officedeploymenttool_11901-20022.exe"
    $XMLConfigFile = "conf.xml"
    $OfficeToolSetup = "setup.exe"

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

    #Unzip Office tool
    Start-Process -FilePath $(Join-Path $DownloadDirectory $OfficeTool) -ArgumentList "/extract:$DownloadDirectory /quiet" -Wait -NoNewWindow

    #Edit the XML file
    [xml]$TemplateXML = Get-Content $(Join-Path $DownloadDirectory $XMLConfigFile)
    $TemplateXML.Configuration.Add.SourcePath = $DownloadDirectory
    $TemplateXML.Save($(Join-Path $DownloadDirectory $XMLConfigFile))

    #Download
    Start-Process -FilePath $(Join-Path $DownloadDirectory $OfficeToolSetup) -ArgumentList "/download $(Join-Path $DownloadDirectory $XMLConfigFile)" -Wait -NoNewWindow

    #Install
    Start-Process -FilePath $(Join-Path $DownloadDirectory $OfficeToolSetup) -ArgumentList "/configure $(Join-Path $DownloadDirectory $XMLConfigFile)" -Wait -NoNewWindow

    #Cleanup
    Remove-Item $DownloadDirectory -Recurse
} catch {
    exit 1
}
