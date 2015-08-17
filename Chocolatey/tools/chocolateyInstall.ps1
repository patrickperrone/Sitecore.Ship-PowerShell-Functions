$name = "SitecoreShipFunctions"
$url = "https://github.com/patrickperrone/Sitecore.Ship-PowerShell-Functions/archive/v1.1.0.zip"
$unzipLocation = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

Install-ChocolateyZipPackage $name $url $unzipLocation

$installer = Join-Path $unziplocation 'Sitecore.Ship-PowerShell-Functions-1.1.0\Install.ps1'
& $installer
