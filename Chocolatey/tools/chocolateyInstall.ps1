$name = "SitecoreShipFunctions"
$url = "https://github.com/patrickperrone/Sitecore.Ship-PowerShell-Functions/archive/v1.0.1.zip"
$unzipLocation = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

Install-ChocolateyZipPackage $name $url $unzipLocation

$installer = Join-Path $unziplocation 'Sitecore.Ship-PowerShell-Functions-1.0.1\Install.ps1'
& $installer
