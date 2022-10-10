param (
    [Parameter(Mandatory)] [String] $version,
    [Parameter(Mandatory)] [String] $ts,
    [Parameter(Mandatory)] [String] $arch
)

$ErrorActionPreference = "Stop"

$versions = @{
    "7.0" = "vc14"
    "7.1" = "vc14"
    "7.2" = "vc15"
    "7.3" = "vc15"
    "7.4" = "vc15"
    "8.0" = "vs16"
    "8.1" = "vs16"
    "8.2" = "vs16"
}

$vs = $versions.$version
if (-not $vs) {
    throw "unsupported version"
}

$toolsets = @{
    "vc14" = "14.0"
}

$dir = vswhere -latest -find "VC\Tools\MSVC"
foreach ($toolset in (Get-ChildItem $dir)) {
    $tsv = "$toolset".split(".")
    if ((14 -eq $tsv[0]) -and (9 -ge $tsv[1])) {
        $toolsets."vc14" = $toolset
    } elseif ((14 -eq $tsv[0]) -and (19 -ge $tsv[1])) {
        $toolsets."vc15" = $toolset
    } elseif ((14 -eq $tsv[0]) -and (29 -ge $tsv[1])) {
        $toolsets."vs16" = $toolset
    } elseif (14 -eq $tsv[0]) {
        $toolsets."vs17" = $toolset
    }
}

$toolset = $toolsets.$vs
if (-not $toolset) {
    throw "toolset not available"
}

$baseurl = "https://windows.php.net/downloads/releases/archives"
$releases = @{
    "7.0" = "7.0.33"
    "7.1" = "7.1.33"
    "7.2" = "7.2.34"
    "7.3" = "7.3.33"
}
$phpversion = $releases.$version

if (-not $phpversion) {
    $baseurl = "https://windows.php.net/downloads/releases"
    $url = "$baseurl/releases.json"
    $releases = Invoke-WebRequest $url | ConvertFrom-Json
    $phpversion = $releases.$version.version
    if (-not $phpversion) {
        $baseurl = "https://windows.php.net/downloads/qa"
        $url = "$baseurl/releases.json"
        $releases = Invoke-WebRequest $url | ConvertFrom-Json
        $phpversion = $releases.$version.version
        if (-not $phpversion) {
            throw "unknown version"
        }
    }
}

$tspart = if ($ts -eq "nts") {"nts-Win32"} else {"Win32"}
$phpzip = "php-$phpversion-$tspart-$vs-$arch.zip"
$dpzip = "php-devel-pack-$phpversion-$tspart-$vs-$arch.zip"
$dpdir = "php-$phpversion-devel-$vs-$arch"

$sdkbin = "$pwd\php-sdk\bin"
$sdkusrbin = "$pwd\php-sdk\msys2\usr\bin"
$phpbin = "$pwd\php-bin"
$devbin = "$pwd\php-dev"

Add-Content $Env:GITHUB_PATH "$sdkbin"
Add-Content $Env:GITHUB_PATH "$sdkusrbin"
Add-Content $Env:GITHUB_PATH "$phpbin"
Add-Content $Env:GITHUB_PATH "$devbin"

Write-Output "----------"
Write-Output "Determined toolset version $toolset ($vs)."
Write-Output "Determined PHP version $phpversion ($arch, $tspart)."
Write-Output "URL: $baseurl"
Write-Output "PHP archive: $phpzip"
Write-Output "Devpack archive: $dpzip"
Write-Output "Added path: $sdkbin"
Write-Output "Added path: $sdkusrbin"
Write-Output "Added path: $phpbin"
Write-Output "Added path: $devbin"
Write-Output "----------"

Write-Output "::set-output name=prefix::$phpbin"
Write-Output "::set-output name=toolset::$toolset"
Write-Output "::set-output name=vs::$vs"
Write-Output "::set-output name=phpversion::$phpversion"
Write-Output "::set-output name=tspart::$tspart"
Write-Output "::set-output name=baseurl::$baseurl"
Write-Output "::set-output name=phpzip::$phpzip"
Write-Output "::set-output name=dpzip::$dpzip"
Write-Output "::set-output name=dpdir::$dpdir"