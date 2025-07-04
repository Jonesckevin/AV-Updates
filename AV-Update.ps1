
$today = Get-Date -Format "yyyy-MM-dd"
$todayone = Get-Date -Format "yyyyMMdd"
$destinationPath = ".\$today"
$HASHFILE = ".\hash-md5-sha256.txt"

New-Item -ItemType Directory -Path $destinationPath -Force
New-Item -ItemType File -Path $HASHFILE -Force
if (Test-Path $destinationPath) {
    Write-Host "Directory already exists." -ForegroundColor Cyan
    Remove-Item -Path $destinationPath\hash-md5-sha256.txt -Force -ErrorAction SilentlyContinue
}
else {
    New-Item -ItemType Directory -Path $destinationPath -Force
    Write-Host "Directory created." -ForegroundColor Cyan
}

if (Test-Path $HASHFILE) {
    Write-Host "Hash file already exists." -ForegroundColor Cyan
}
else {
    New-Item -ItemType File -Path $HASHFILE -Force
    Write-Host "Hash file created." -ForegroundColor Cyan
}

function Get-McAfeeDefinitions {
    # https://www.mcafee.com/enterprise/en-us/downloads/security-updates.html
    $mcAfeeUrl = "https://download.nai.com/products/datfiles/4.x/nai/"
    $mcAfeePage = Invoke-WebRequest -Uri $mcAfeeUrl
    $mcAfeeDefName = $mcAfeePage.Links | Where-Object { $_.href -like "*xdat.exe" } | Select-Object -First 1 -ExpandProperty href
    $mcAfeeDefUrl = "$mcAfeeUrl$mcAfeeDefName"
    $mcAfeeDefPath = "$destinationPath\$todayone-$mcAfeeDefName"
    if (Test-Path $mcAfeeDefPath) {
        Write-Host "McAfee Definitions already downloaded: $mcAfeeDefPath" -ForegroundColor Red
        return
    }
    Write-Host "Downloading McAfee Definitions..." -ForegroundColor Red
    Invoke-WebRequest -Uri $mcAfeeDefUrl -OutFile $mcAfeeDefPath
    if (Test-Path $mcAfeeDefPath) {
        Write-Host "McAfee Definitions downloaded successfully." -ForegroundColor Red
    }
    else {
        Write-Host "McAfee Definitions download failed." -ForegroundColor Red
    }
}
Get-McAfeeDefinitions

function Get-SEPDefinitions {
    $url = "https://definitions.symantec.com/defs/sds/index.html"
    $htmlFile = "./SEP-Definitions.html"
    Invoke-WebRequest -Uri $url -OutFile $htmlFile -UseBasicParsing
    $SEP_DEF_FILENAME = $null
    for ($i = 0; $i -le 6; $i++) {
        $date = (Get-Date).AddDays(-$i).ToString('yyyyMMdd')
        $pattern = "$date-\d{3}-CORE15_IU_SEP_14.0_X64.exe"
        $match = Get-Content $htmlFile | Select-String -Pattern $pattern | Select-Object -First 1 | ForEach-Object { $_.Matches.Value }
        if ($match) { $SEP_DEF_FILENAME = $match; break }
    }
    if (-not $SEP_DEF_FILENAME) {
        Write-Output "SEP definitions file name not found for today or recent days. Exiting SEP download."
        Remove-Item $htmlFile -Force -ErrorAction SilentlyContinue
        return
    }
    $localPath = "$destinationPath\$SEP_DEF_FILENAME"
    if (Test-Path $localPath) {
        Write-Host "SEP definitions already downloaded: $localPath" -ForegroundColor Yellow
        Remove-Item $htmlFile -Force -ErrorAction SilentlyContinue
        return
    }
    $downloadUrl = "https://definitions.symantec.com/defs/sds/$SEP_DEF_FILENAME"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $localPath -Headers @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3" }
    if (Test-Path $localPath) {
        Write-Output "SEP definitions downloaded successfully."
    }
    else {
        Write-Output "SEP definitions download failed."
    }
    Remove-Item $htmlFile -Force -ErrorAction SilentlyContinue
}
Get-SEPDefinitions

function Get-WinDefenderDefinitions {
    # https://www.microsoft.com/en-us/wdsi/defenderupdates#Manually
    $defenderUrl = "https://go.microsoft.com/fwlink/?LinkID=121721&arch=x64"
    $DefenderFileName = "$todayone-windefend-definitions.exe"
    $FilePath = "$destinationPath\$DefenderFileName"
    if (Test-Path $FilePath) {
        Write-Host "Windows Defender Definitions already downloaded. $FilePath" -ForegroundColor Green
    }
    else {
        Write-Host "Downloading Windows Defender Definitions..." -ForegroundColor Green
        Invoke-WebRequest -Uri $defenderUrl -OutFile $FilePath
        # Check if the file was downloaded
        if (Test-Path $FilePath) {
            Write-Output "Windows Defender Definitions downloaded successfully."
        }
        else {
            Write-Output "Windows Defender Definitions download failed."
        }
    }
}
Get-WinDefenderDefinitions

function Get-ClamAVDefinitions {
    ## Broken, CloudFlare Blocks this type of download.

    # https://www.clamav.net/downloads
    if (Test-Path "$destinationPath\$todayone-clamav-definitions.cvd") {
        Write-Host "ClamAV Definitions already downloaded." -ForegroundColor Magenta
    }
    else {
        # Bypass Cloudflare protection
        $bypassParams = @{
            Uri     = "https://database.clamav.net/main.cvd"
            OutFile = "$destinationPath\$todayone-clamav-definitions.cvd"
            Headers = @{
                "User-Agent"      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
                "Referer"         = "https://www.clamav.net/downloads"
                "Accept-Language" = "en-US,en;q=0.9"
            }
        }
        Invoke-WebRequest @bypassParams
        Write-Host "Downloading ClamAV Definitions..." -ForegroundColor Magenta
        $clamavUrl = "https://database.clamav.net/main.cvd"
        $clamavPath = "$destinationPath\clamav-definitions.cvd"
        Invoke-WebRequest -Uri $clamavUrl -OutFile $clamavPath

        # Check if the file was downloaded
        if (Test-Path $clamavPath) {
            Write-Output "ClamAV Definitions downloaded successfully."
        }
        else {
            Write-Output "ClamAV Definitions download failed."
        }
    }
}
#Get-ClamAVDefinitions

function Get-Hash {
    # Hash the file and Output to the hash file
    Write-Host "Hashing the file...For MD5" -ForegroundColor White
    $hashMD5 = Get-FileHash -Path "$destinationPath\*" -Algorithm MD5
    $hashMD5 | Out-File $HASHFILE -Append

    Write-Host "Hashing the file...For SHA256" -ForegroundColor White
    $hashSHA256 = Get-FileHash -Path "$destinationPath\*" -Algorithm SHA256
    $hashSHA256 | Out-File $HASHFILE -Append

    #Move the hash file to the destination folder
    Move-Item -Path $HASHFILE -Destination $destinationPath -Force
    Write-Host "Hash file moved to the destination folder." -ForegroundColor White
}
Get-Hash

Remove-Item -Path "./SEP-Definitions.html" -Force -ErrorAction SilentlyContinue
