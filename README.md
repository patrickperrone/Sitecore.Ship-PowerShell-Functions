Sitecore.Ship-PowerShell-Functions
==================================
[Sitecore.Ship][3] is a great tool for setting up continuous delivery with Sitecore. With it, you can install packages over HTTP, but until now the easiest tool to use for scripting those HTTP requests was cURL. With this PowerShell module, you can eliminate that dependency from your suite of tools. 

Package installation can be as simple as `ssinstall www.mysite.com mypackage.update`

The functions in this module support all operations of Sitecore.Ship, and are self-documented so that `Get-Help` commands provide descriptions, syntax, and examples. Use these functions to build a repeatable deployment script for any environment!

Installation
------------
*Note:* I've only tested this module with PowerShell version 3. Older operating systems may only have PowerShell version 2. [How to update PowerShell.][1]

**Recommended Method:** Install with [PsGet][2] (the NuGet of PowerShell modules).
```
Install-Module SitecoreShipFunctions
```

Alternatively, you can download and install the module manually.

1. Download the latest release.
2. Open properties for zip file and click "Unblock" button if you have one.
3. Unzip 
4. Open a PowerShell console
5. Run `.\Install.ps1` You may need to allow remote scripts by running 
`Set-ExecutionPolicy -RemoteSigned`. You may also have to right-click `Install.ps1` and Unblock it from the properties window. **Alternative:** Add line `Import-Module $modules\SitecoreShipFunctions\SitecoreShipFunctions.psd1` to your `$PROFILE`, where `$modules\SitecoreShipFunctions` is a path to the folder with the contents extracted from downloaded zip.



[1]: http://social.technet.microsoft.com/wiki/contents/articles/21016.how-to-install-windows-powershell-4-0.aspx
[2]: http://psget.net/
[3]: https://github.com/kevinobee/Sitecore.Ship
