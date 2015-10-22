#region Private Funcions

function Get-EncodedDataFromFile()
{
    param
    (
        [System.IO.FileInfo]$file = $null
    )
    process
    {
        $data = $null;
        $codePageName = "iso-8859-1";
 
        if ($file -and [System.IO.File]::Exists($file.FullName))
        {
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName);
            if ($bytes)
            {
                $enc = [System.Text.Encoding]::GetEncoding($codePageName);
                $data = $enc.GetString($bytes);
            }
        }
        else
        {
            Write-Host "ERROR; File '$file' does not exist";
        }
        $data;
    }
}

function Get-BoundaryId
{
    $uniqueId = [System.Guid]::NewGuid().ToString().Replace("-","")
    return "----FormBoundary{0}" -f $uniqueId
}

function Get-FormData([string[]]$dataArray, [string]$boundaryId)
{
    $header = "--{0}" -f $boundaryId
    $footer = "--{0}--" -f $boundaryId
    
    [System.Text.StringBuilder]$contents = New-Object System.Text.StringBuilder
    if ($dataArray.Count -gt 0)
    {
        foreach ($data in $dataArray)
        {
            [void]$contents.AppendLine($header)
            [void]$contents.AppendLine($data)
        }
        [void]$contents.AppendLine($footer)
    }

    return $contents.ToString()
}

#endregion

#region Public Functions

function Invoke-SitecoreShipAboutRequest
{
    <#
    .SYNOPSIS
    Issue a GET request to /services/about

    .DESCRIPTION
    This function returns an HtmlWebResponseObject from the specified web site that contains meta information about Sitecore.Ship
    
    .EXAMPLE
    PS C:\>Invoke-SitecoreShipAboutRequest www.mysitecoresite.com
    
    This command creates an HtmlWebResponseObject that contains information about Sitecore.Ship
    
    .EXAMPLE
    PS C:\>Invoke-SitecoreShipAboutRequest www.mysitecoresite.com -UseHttps
    
    This command creates an HtmlWebResponseObject via a secure request to Sitecore.Ship's web service
    
    .PARAMETER HostName
    The host name of a Sitecore web site. Example www.mysitecore.com

    .PARAMETER UseHttps
    The web service request should use HTTPS to connect to the Sitecore server.

    .PARAMETER Timeout
    Duration in seconds before the web service request times out. The default value is 600 seconds.
    #>
    [CmdletBinding()]
    param
    (
        [parameter(Position=0, Mandatory=$true)]
        [string]$HostName,
        [parameter(Mandatory=$false, HelpMessage="Make web service request using HTTPS scheme.")]
        [switch]$UseHttps,
        [parameter(Mandatory=$false, HelpMessage="Duration to wait in seconds before timing out the request to Sitecore.Ship.")]
        [int]$Timeout = 600
    )
    process
    {
        $scheme = "http"
        if ($UseHttps)
        {
            $scheme = "https"
        }

        $servicePath = "/services/about"
        $url = "{0}://{1}{2}" -f $scheme,$HostName,$servicePath
        $webResponse = Invoke-WebRequest $url -TimeoutSec $Timeout
        return $webResponse
    }
}

function Get-SitecoreShipVersion
{
    <#
    .SYNOPSIS
    Get the version of Sitecore.Ship

    .DESCRIPTION
    This function makes a request to Sitecore.Ship's web service to discover the version installed on the Sitecore server. While this is nice-to-know information, it's not 100% reliable. The information obtained relies upon a screen scrape of HTML, and the HTML is static, i.e. the version number in the HTML isn't obtained by reflection or some other technique that would guarantee accurancy.
    
    .EXAMPLE
    PS C:\>Get-SitecoreShipVersion www.mysitecoresite.com
    
    Returns version number.
    
    .EXAMPLE
    PS C:\>Get-SitecoreShipVersion www.mysitecoresite.com -UseHttps
    
    Returns version number.
    
    .PARAMETER HostName
    The host name of a Sitecore web site. Example www.mysitecore.com

    .PARAMETER UseHttps
    The web service request should use HTTPS to connect to the Sitecore server.

    .PARAMETER Timeout
    Duration in seconds before the web service request times out. The default value is 600 seconds.
    #>
    [CmdletBinding()]
    param
    (
        [parameter(Position=0, Mandatory=$true)]
        [string]$HostName,
        [parameter(Mandatory=$false, HelpMessage="Make web service request using HTTPS scheme.")]
        [switch]$UseHttps,
        [parameter(Mandatory=$false, HelpMessage="Duration to wait in seconds before timing out the request to Sitecore.Ship.")]
        [int]$Timeout = 600
    )
    process
    {
        if ($UseHttps)
        {
            $webResponse = Invoke-SitecoreShipAboutRequest $HostName -UseHttps -Timeout $Timeout
        }
        else
        {
            $webResponse = Invoke-SitecoreShipAboutRequest $HostName -Timeout $Timeout
        }
        $bodyText = ($webResponse.ParsedHtml.getElementsByTagName("body") | select innerText).innerText
        [string]$versionText = $bodyText.Split("`r`n") | Select-String "Current release"
        $versionNumber = $versionText.Trim().Split(" ") | Select-Object -Last 1
        return $versionNumber
    }
}

function Test-SitecoreShipIsInstalled
{
    <#
    .SYNOPSIS
    Return a boolean value indicating if Sitecore.Ship is installed on the target Sitecore server.

    .DESCRIPTION
    This function makes a request to Sitecore.Ship's web service, if the web service has a status code of 200 (OK) then the Sitecore.Ship is considered to be installed.
    
    .EXAMPLE
    PS C:\>Test-SitecoreShipIsInstalled www.mysitecoresite.com
    
    .EXAMPLE
    PS C:\>Test-SitecoreShipIsInstalled www.mysitecoresite.com -UseHttps

    .PARAMETER HostName
    The host name of a Sitecore web site. Example www.mysitecore.com

    .PARAMETER UseHttps
    The web service request should use HTTPS to connect to the Sitecore server.

    .PARAMETER Timeout
    Duration in seconds before the web service request times out. The default value is 600 seconds.
    #>
    [CmdletBinding()]
    param
    (
        [parameter(Position=0, Mandatory=$true)]
        [string]$HostName,
        [parameter(Mandatory=$false, HelpMessage="Make web service request using HTTPS scheme.")]
        [switch]$UseHttps,
        [parameter(Mandatory=$false, HelpMessage="Duration to wait in seconds before timing out the request to Sitecore.Ship.")]
        [int]$Timeout = 600
    )
    process
    {
        try
        {
            if ($UseHttps)
            {
                $webResponse = Invoke-SitecoreShipAboutRequest $HostName -UseHttps -Timeout $Timeout
            }
            else
            {
                $webResponse = Invoke-SitecoreShipAboutRequest $HostName -Timeout $Timeout
            }

            if ($webResponse.StatusCode -eq 200)
            {
                return $true
            }
            else
            {
                return $false
            }
        }
        catch
        {
            return $false
        }
    }
}

function Invoke-SitecoreShipPackageInstallRequest
{
    <#
    .SYNOPSIS
    Install an .update package to a Sitecore server.

    .DESCRIPTION
    This function POSTs a web request to a Sitecore server. If successful, the function will return the JSON object the web service responsds with. This function supports installing a file on the Sitecore server's local file system or uploading the .update package to the remote server.
    
    .EXAMPLE
    PS C:\>Invoke-SitecoreShipPackageInstallRequest www.mysitecoresite.com c:\temp\mypackage.update

    This command installs the package found on the Sitecore server's file system at the path provided.
    
    .EXAMPLE
    PS C:\>Invoke-SitecoreShipPackageInstallRequest www.mysitecoresite.com c:\temp\mypackage.update -FileUpload

    This command uploads the package at the path provided and then installs it.

    .EXAMPLE
    PS C:\>Invoke-SitecoreShipPackageInstallRequest www.mysitecoresite.com c:\temp\mypackage.update -FileUpload -DisableIndexing

    This command is the same as example 3, except it also disables search index updates during the installation.

    .PARAMETER HostName
    The host name of a Sitecore web site. Example www.mysitecore.com

    .PARAMETER FilePath
    This is the path to the .update package

    .PARAMETER FileUpload
    This switch will upload the local package to the Sitecore server.

    .PARAMETER UseHttps
    The web service request should use HTTPS to connect to the Sitecore server.

    .PARAMETER Timeout
    Duration in seconds before the web service request times out. The default value is 600 seconds.

    .PARAMETER DisableIndexing
    Suspend search index updates during installation.
    #>
    [CmdletBinding()]
    param
    (
        [parameter(Position=0, Mandatory=$true)]
        [string]$HostName,
        [parameter(Position=1, Mandatory=$true)]
        [string]$FilePath,
        [parameter(Mandatory=$false, HelpMessage="Send the .update package over HTTP.")]
        [switch]$FileUpload,
        [parameter(Mandatory=$false, HelpMessage="Make web service request using HTTPS scheme.")]
        [switch]$UseHttps,
        [parameter(Mandatory=$false, HelpMessage="Duration to wait in seconds before timing out the request to Sitecore.Ship.")]
        [int]$Timeout = 600,
        [parameter(Mandatory=$false, HelpMessage="Suspends search index updates during install; improves installation speed.")]
        [switch]$DisableIndexing
    )
    process
    {
        $Timeout = $Timeout * 1000
        if ($FileUpload -and !(Test-Path $FilePath))
        {
            throw [System.IO.FileNotFoundException] "$FilePath not found."
        }

        $scheme = "http"
        if ($UseHttps)
        {
            $scheme = "https"
        }
        $servicePath = "/services/package/install"
        if ($FileUpload)
        {
            $servicePath = $servicePath + "/fileupload"
        }
        $serviceUrl = "{0}://{1}{2}" -f $scheme,$HostName,$servicePath

        # Generate Form Data
        [System.Text.StringBuilder]$inputTextBuilder = New-Object System.Text.StringBuilder
        if ($FileUpload)
        {
            # Create a filestream and encode it as text
            [System.IO.FileInfo]$file = (Get-Item -Path $FilePath)
            $filedata = Get-EncodedDataFromFile -file $file

            [void]$inputTextBuilder.AppendLine("Content-Disposition: form-data; name=`"path`"; filename=`"{0}`"" -f (Split-Path $FilePath -Leaf))
            [void]$inputTextBuilder.AppendLine("Content-Type: application/octet-stream")
            [void]$inputTextBuilder.AppendLine("")
            [void]$inputTextBuilder.AppendLine($filedata)
        }
        else
        {
            [void]$inputTextBuilder.AppendLine("Content-Disposition: form-data; name=`"path`"")
            [void]$inputTextBuilder.AppendLine("")
            [void]$inputTextBuilder.Append($FilePath)

        }
        $textArray = @()
        $textArray += $inputTextBuilder.ToString()
        if ($DisableIndexing)
        {
            [void]$inputTextBuilder.Clear()
            [void]$inputTextBuilder.AppendLine("Content-Disposition: form-data; name=`"DisableIndexing`"")
            [void]$inputTextBuilder.AppendLine("")
            [void]$inputTextBuilder.Append("true")
            $textArray += $inputTextBuilder.ToString()
        }
        $boundaryId = Get-BoundaryId
        $bodyText = [byte[]][char[]](Get-FormData $textArray $boundaryId)

        # Form web request
        $request = [System.Net.HttpWebRequest]::CreateHttp($serviceUrl)
        $request.Method = 'POST'
        $request.Timeout = $Timeout
        $request.Accept = "application/json, text/javascript, */*"
        $request.KeepAlive = $true
        $request.ContentType = "multipart/form-data; boundary={0}" -f $boundaryId
        $request.Headers.Add("Accept-Encoding", "gzip,deflate")
        $request.Headers.Add("Accept-Language", "en-US,en;q=0.8")
        $requestStream = $request.GetRequestStream()
        $requestStream.Write($bodyText, 0, $bodyText.Length)

        # Get response
        $response = $request.GetResponse()
        $requestStream = $response.GetResponseStream()
        $readStream = New-Object System.IO.StreamReader $requestStream
        $data = $readStream.ReadToEnd()

        $response.Close()
        $response.Dispose()

        $requestStream.Close()
        $requestStream.Dispose()

        $readStream.Close()
        $readStream.Dispose()

        $results = $data | ConvertFrom-Json
        return $results
    }
}

function Invoke-SitecoreShipPublishRequest
{
    <#
    .SYNOPSIS
    Initiate a publish operation on the target Sitecore server.

    .DESCRIPTION
    This function POSTs a web request to a Sitecore server that will start a publish operation. If successful, the function will return a DateTime object that represents the time on the server. By default, this universal time is converted to the local time of the machine running the PowerShell function.
    
    .EXAMPLE
    PS C:\>Invoke-SitecoreShipPublishRequest www.mysitecoresite.com full

    This command starts a full publish. Other possible values are 'smart' and 'incremental'
    
    .EXAMPLE
    PS C:\>Invoke-SitecoreShipPublishRequest www.mysitecoresite.com full -ResultAsUniversalTime

    This command is the same as the first example except the time will be returned as Universal.

    .EXAMPLE
    PS C:\>Invoke-SitecoreShipPublishRequest smart -PublishSource master -PublishTargets @("web", "Web2") -Languages @("en", "da")

    This command starts a smart publish from the 'master' database to the 'web' and 'web2' databases for the 'en' and 'da' languages.

    .EXAMPLE
    PS C:\>Invoke-SitecoreShipPublishRequest -$PublishItems $json

    This commands will publish the items described in the $json variable. See https://github.com/kevinobee/Sitecore.Ship for the format of the JSON object.

    .PARAMETER HostName
    The host name of a Sitecore web site. Example www.mysitecore.com

    .PARAMETER UseHttps
    The web service request should use HTTPS to connect to the Sitecore server.

    .PARAMETER Timeout
    Duration in seconds before the web service request times out. The default value is 600 seconds.

    .PARAMETER PublishMode
    Accepted values are full, smart, or incremental

    .PARAMETER PublishSource
    This is the name of the source database.

    .PARAMETER PublishTargets
    A string array of target database names.

    .PARAMETER Languages
    A string array of language names.

    .PARAMETER ResultAsUniversalTime
    The returned DateTime object will be in Universal time.
    #>
    [CmdletBinding(DefaultParameterSetName="mode")]
    param
    (
        [parameter(ParameterSetName="mode", Position=0, Mandatory=$true)]
        [parameter(ParameterSetName="items", Position=0, Mandatory=$true)]
        [string]$HostName,

        [parameter(Mandatory=$false, HelpMessage="Make web service request using HTTPS scheme.")]
        [switch]$UseHttps,

        [parameter(Mandatory=$false, HelpMessage="Duration to wait in seconds before timing out the request to Sitecore.Ship.")]
        [int]$Timeout = 600,

        [parameter(ParameterSetName="mode", Position=1, Mandatory=$true, HelpMessage="Valid values are full, smart, or incremental")]
        [ValidateSet("full", "smart", "incremental")]
        [string]$PublishMode,

        [parameter(ParameterSetName="mode", Mandatory=$false, HelpMessage="The source database.")]
        [string]$PublishSource,

        [parameter(ParameterSetName="mode", Mandatory=$false, HelpMessage="The target database(s).")]
        [string[]]$PublishTargets,

        [parameter(ParameterSetName="mode", Mandatory=$false, HelpMessage="The languages to publish (e.g. en, da)")]
        [string[]]$Languages,

        [parameter(ParameterSetName="items", Mandatory=$true, HelpMessage="JSON object that represents items to publish.")]
        [string]$PublishItems,

        [parameter(Mandatory=$false, HelpMessage="TODO.")]
        [switch]$ResultAsUniversalTime
    )
    process
    {
        $Timeout = $Timeout * 1000
        $scheme = "http"
        if ($UseHttps)
        {
            $scheme = "https"
        }

        if ($PsCmdlet.ParameterSetName -eq "mode")
        {
            $serviceUrl = "{0}://{1}/services/publish/{2}" -f $scheme,$HostName,$PublishMode.ToLower()

            # Generate Form Data
            [System.Text.StringBuilder]$inputTextBuilder = New-Object System.Text.StringBuilder
            $textArray = @()
            if (![string]::IsNullOrWhiteSpace($PublishSource))
            {
                [void]$inputTextBuilder.AppendLine("Content-Disposition: form-data; name=`"source`"")
                [void]$inputTextBuilder.AppendLine("")
                [void]$inputTextBuilder.Append($PublishSource)
                $textArray += $inputTextBuilder.ToString()
            }
            if ($PublishTargets.Count -gt 0)
            {
                $targetText = $PublishTargets -join ", "
                [void]$inputTextBuilder.Clear()
                [void]$inputTextBuilder.AppendLine("Content-Disposition: form-data; name=`"targets`"")
                [void]$inputTextBuilder.AppendLine("")
                [void]$inputTextBuilder.Append($targetText)
                $textArray += $inputTextBuilder.ToString()
            }
            if ($Languages.Count -gt 0)
            {
                $languageText = $Languages -join ", "
                [void]$inputTextBuilder.Clear()
                [void]$inputTextBuilder.AppendLine("Content-Disposition: form-data; name=`"languages`"")
                [void]$inputTextBuilder.AppendLine("")
                [void]$inputTextBuilder.Append($languageText)
                $textArray += $inputTextBuilder.ToString()
            }
            $boundaryId = Get-BoundaryId
            $bodyText = [byte[]][char[]](Get-FormData $textArray $boundaryId)

            # Form web request
            $request = [System.Net.HttpWebRequest]::CreateHttp($serviceUrl)
            $request.Method = 'POST';
            $request.Timeout = $Timeout
            $request.Accept = "application/json, text/javascript, */*"
            $request.KeepAlive = $true
            $request.ContentType = "multipart/form-data; boundary={0}" -f $boundaryId
            $request.Headers.Add("Accept-Language", "en-US,en;q=0.8")
            $requestStream = $request.GetRequestStream()
            $requestStream.Write($bodyText, 0, $bodyText.Length)
        }
        else
        {
            $serviceUrl = "{0}://{1}/services/publish/listofitems" -f $scheme,$HostName
            $bodyText = [byte[]][char[]]($json)

            # Form web request
            $request = [System.Net.HttpWebRequest]::CreateHttp($serviceUrl)
            $request.Method = 'POST'
            $request.Timeout = $Timeout
            $request.Accept = "application/json, text/javascript, */*"
            $request.KeepAlive = $true
            $request.ContentType = "application/json"
            $request.Headers.Add("Accept-Language", "en-US,en;q=0.8")
            $requestStream = $request.GetRequestStream()
            $requestStream.Write($bodyText, 0, $bodyText.Length)
        }

        # Get response
        $response = $request.GetResponse()
        $requestStream = $response.GetResponseStream()
        $readStream = New-Object System.IO.StreamReader $requestStream
        $data = $readStream.ReadToEnd()

        $response.Close()
        $response.Dispose()

        $requestStream.Close()
        $requestStream.Dispose()

        $readStream.Close()
        $readStream.Dispose()

        $time = $data | ConvertFrom-Json
        if (!$ResultAsUniversalTime)
        {
            $time = $time.ToLocalTime()
        }

        return $time
    }
}

function Get-SitecoreShipLastCompletedPublish
{
    <#
    .SYNOPSIS
    Returns the time of the last completed publish on the target Sitecore server.

    .DESCRIPTION
    This function GETs a web request to a Sitecore server.. If successful, the function will return a DateTime object that represents the time of the last completed publish operation on the target Sitecore server. The -PublishSource, -PublishTarget and -Language parameters are optional and will default to master, web and en respectively if not specified in the request.

    .EXAMPLE
    PS C:\>Get-SitecoreShipLastCompletedPublish www.mysitecoresite.com full

    Get the time of the last publish operation for 'master' source database with a 'web' target for the 'en' language.
    
    .EXAMPLE
    PS C:\>Get-SitecoreShipLastCompletedPublish www.mysitecoresite.com full

    This command is the same as the first example except the time will be returned as Universal.

    .PARAMETER HostName
    The host name of a Sitecore web site. Example www.mysitecore.com

    .PARAMETER UseHttps
    The web service request should use HTTPS to connect to the Sitecore server.

    .PARAMETER Timeout
    Duration in seconds before the web service request times out. The default value is 600 seconds.

    .PARAMETER PublishSource
    This is the name of the source database.

    .PARAMETER PublishTarget
    Name of target database. You must specify the -PublishSource parameter to use.

    .PARAMETER Language
    Name of language, e.g. 'en'. You must specifiy the -PublishSource and -PublishTarget parameters to use.

    .PARAMETER ResultAsUniversalTime
    The returned DateTime object will be in Universal time.
    #>
    [CmdletBinding(DefaultParameterSetName="base")]
    param
    (
        [parameter(ParameterSetName="base", Position=0, Mandatory=$true)]
        [parameter(ParameterSetName="source", Position=0, Mandatory=$true)]
        [parameter(ParameterSetName="target", Position=0, Mandatory=$true)]
        [parameter(ParameterSetName="language", Position=0, Mandatory=$true)]
        [string]$HostName,

        [parameter(ParameterSetName="base", Mandatory=$false, HelpMessage="Make web service request using HTTPS scheme.")]
        [parameter(ParameterSetName="source", Mandatory=$false, HelpMessage="Make web service request using HTTPS scheme.")]
        [parameter(ParameterSetName="target", Mandatory=$false, HelpMessage="Make web service request using HTTPS scheme.")]
        [parameter(ParameterSetName="language", Mandatory=$false, HelpMessage="Make web service request using HTTPS scheme.")]
        [switch]$UseHttps,

        [parameter(ParameterSetName="base", Mandatory=$false, HelpMessage="Duration to wait in seconds before timing out the request to Sitecore.Ship.")]
        [parameter(ParameterSetName="source", Mandatory=$false, HelpMessage="Duration to wait in seconds before timing out the request to Sitecore.Ship.")]
        [parameter(ParameterSetName="target", Mandatory=$false, HelpMessage="Duration to wait in seconds before timing out the request to Sitecore.Ship.")]
        [parameter(ParameterSetName="language", Mandatory=$false, HelpMessage="Duration to wait in seconds before timing out the request to Sitecore.Ship.")]
        [int]$Timeout = 600,

        [parameter(ParameterSetName="source", Mandatory=$true, HelpMessage="TODO")]
        [parameter(ParameterSetName="target", Mandatory=$true, HelpMessage="TODO")]
        [parameter(ParameterSetName="language", Mandatory=$true, HelpMessage="TODO")]
        [string]$PublishSource,

        [parameter(ParameterSetName="target", Mandatory=$true, HelpMessage="TODO")]
        [parameter(ParameterSetName="language", Mandatory=$true, HelpMessage="TODO")]
        [string]$PublishTarget,

        [parameter(ParameterSetName="language", Mandatory=$true, HelpMessage="TODO")]
        [string]$Language,

        [parameter(ParameterSetName="base", Mandatory=$false, HelpMessage="TODO.")]
        [parameter(ParameterSetName="source", Mandatory=$false, HelpMessage="TODO.")]
        [parameter(ParameterSetName="target", Mandatory=$false, HelpMessage="TODO.")]
        [parameter(ParameterSetName="language", Mandatory=$false, HelpMessage="TODO.")]
        [switch]$ResultAsUniversalTime
    )
    process
    {
        $scheme = "http"
        if ($UseHttps)
        {
            $scheme = "https"
        }

        $servicePath = "/services/publish/lastcompleted"
        if (![string]::IsNullOrWhiteSpace($PublishSource))
        {
            $servicePath += "/" + $PublishSource.ToLower()
        }
        if (![string]::IsNullOrWhiteSpace($PublishTarget))
        {
            $servicePath += "/" + $PublishTarget.ToLower()
        }
        if (![string]::IsNullOrWhiteSpace($Language))
        {
            $servicePath += "/" + $Language.ToLower()
        }
        $serviceUrl = "{0}://{1}{2}" -f $scheme,$HostName,$servicePath

        $time = Invoke-RestMethod $serviceUrl -Method GET -TimeoutSec $Timeout
        if (!$ResultAsUniversalTime)
        {
            $time = $time.ToLocalTime()
        }
        return $time
    }
}

#endregion

New-Alias -Name ssversion -Value Get-SitecoreShipVersion
New-Alias -Name ssinstall -Value Invoke-SitecoreShipPackageInstallRequest
New-Alias -Name sspublish -Value Invoke-SitecoreShipPublishRequest
New-Alias -Name sslastpublish -Value Get-SitecoreShipLastCompletedPublish

Export-ModuleMember -Alias * -Function *
