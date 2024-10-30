
$today = Get-Date -Format "yyyy-MM-dd"
$todayone = Get-Date -Format "yyyyMMdd"
$destinationPath = ".\$today"
$HASHFILE = ".\hash-md5-sha256.txt"

New-Item -ItemType Directory -Path $destinationPath -Force
New-Item -ItemType File -Path $HASHFILE -Force
if (Test-Path $destinationPath) {
    Write-Host "Directory already exists." -ForegroundColor Cyan
    Remove-Item -Path $destinationPath\hash-md5-sha256.txt -Force -ErrorAction SilentlyContinue
} else {
    New-Item -ItemType Directory -Path $destinationPath -Force
    Write-Host "Directory created." -ForegroundColor Cyan
}

if (Test-Path $HASHFILE) {
    Write-Host "Hash file already exists." -ForegroundColor Cyan
} else {
    New-Item -ItemType File -Path $HASHFILE -Force
    Write-Host "Hash file created." -ForegroundColor Cyan
}




function Get-McAfeeDefinitions {
    # https://www.mcafee.com/enterprise/en-us/downloads/security-updates.html
    if (Test-Path "$destinationPath\*xdat.exe") {
        Write-Host "McAfee Definitions already downloaded." -ForegroundColor Red
    } else {
        Write-Host "Downloading McAfee Definitions..." -ForegroundColor Red
        $mcAfeeUrl = "https://download.nai.com/products/datfiles/4.x/nai/"
        $mcAfeePage = Invoke-WebRequest -Uri $mcAfeeUrl
        $mcAfeeDefPath = $mcAfeePage.Links | Where-Object { $_.href -like "*xdat.exe" } | Select-Object -First 1 -ExpandProperty href
        $mcAfeeDefUrl = "$mcAfeeUrl$mcAfeeDefPath"
        $mcAfeeDefPath = "$destinationPath\$todayone-$mcAfeeDefPath"
        Invoke-WebRequest -Uri $mcAfeeDefUrl -OutFile $mcAfeeDefPath
        # Check if the file was downloaded
        if (Test-Path $mcAfeeDefPath) {
            Write-Host "McAfee Definitions downloaded successfully." -ForegroundColor Red
        } else {
            Write-Host "McAfee Definitions download failed." -ForegroundColor Red
        }
    }
}
Get-McAfeeDefinitions





function Get-SEPDefinitions {
    # https://www.broadcom.com/support/security-center/definitions/download/detail?gid=sep14
    # https://definitions.symantec.com/defs/sds/index.html

    $URL_LIST = "https://definitions.symantec.com/defs/sds/index.html"
    $SEP_URL = Invoke-WebRequest -Uri $URL_LIST -OutFile "./SEP-Definitions.html" -UseBasicParsing
    $SEP_DEF_URL = Get-Content "./SEP-Definitions.html" | Select-String -Pattern "$todayone-\d{3}-CORE15_IU_SEP_14.0_X64.exe" | Select-Object -Skip 1 -First 1 | ForEach-Object { $_.Matches.Value }
    if (Test-Path "$destinationPath\$SEP_DEF_URL") {
        Write-Host "SEP Definitions already downloaded." -ForegroundColor Yellow
    } else {
        $SEP_DEF_URLS = "https://definitions.symantec.com/defs/sds/$SEP_DEF_URL"
        Write-Output "SEP definitions available for $SEP_DEF_URL. Downloading..."
        $webRequestParams = @{
            Uri         = $SEP_DEF_URLS
            OutFile     = "$destinationPath\$SEP_DEF_URL"
            Headers     = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3" }
        }
        Invoke-WebRequest @webRequestParams

        # Check if the file was downloaded
        if (Test-Path "$destinationPath\$SEP_DEF_URL") {
            Write-Output "SEP definitions downloaded successfully."
        } else {
            Write-Output "SEP definitions download failed."
        }
        # Delete the HTML file
    }
}
Get-SEPDefinitions




function Get-WinDefenderDefinitions {
    # https://www.microsoft.com/en-us/wdsi/defenderupdates#Manually
    if (Test-Path "$destinationPath\$todayone-windefend-definitions.exe") {
        Write-Host "Windows Defender Definitions already downloaded." -ForegroundColor Green
    } else {
        Write-Host "Downloading Windows Defender Definitions..." -ForegroundColor Green
        $defenderUrl = "https://go.microsoft.com/fwlink/?LinkID=121721&arch=x64"
        $FilePath = "$destinationPath\$todayone-windefend-definitions.exe"
        Invoke-WebRequest -Uri $defenderUrl -OutFile $FilePath

        # Check if the file was downloaded
        if (Test-Path $FilePath) {
            Write-Output "Windows Defender Definitions downloaded successfully."
        } else {
            Write-Output "Windows Defender Definitions download failed."
        }
    }
}
Get-WinDefenderDefinitions



function Get-BitDefenderDefinitions {
    # https://www.bitdefender.com/consumer/support/answer/10690/
    if (Test-Path "$destinationPath\bitdefender-definitions.exe") {
        Write-Host "Bitdefender Definitions already downloaded." -ForegroundColor Blue
    } else {
        Write-Host "Downloading Bitdefender Definitions..." -ForegroundColor Blue
        $bitdefenderUrl = "https://download.bitdefender.com/updates/cl_2022/x64/weekly.exe"
        $bitdefenderPath = "$destinationPath\$todayone-bitdefender-definitions.exe"
        Invoke-WebRequest -Uri $bitdefenderUrl -OutFile $bitdefenderPath

        # Check if the file was downloaded
        if (Test-Path $bitdefenderPath) {
            Write-Output "Bitdefender Definitions downloaded successfully."
        } else {
            Write-Output "Bitdefender Definitions download failed."
        }
}
}
#Get-BitDefenderDefinitions




function Get-MalwareBytesDefinitions {
    # MalwareBytes does not support direct download of definitions
}
#Get-MalwareBytesDefinitions




function Get-ClamAVDefinitions {
## Broken, CloudFlare Blocks this type of download.

    # https://www.clamav.net/downloads
    if (Test-Path "$destinationPath\$todayone-clamav-definitions.cvd") {
        Write-Host "ClamAV Definitions already downloaded." -ForegroundColor Magenta
    } else {
        # Bypass Cloudflare protection
        $bypassParams = @{
            Uri         = "https://database.clamav.net/main.cvd"
            OutFile     = "$destinationPath\$todayone-clamav-definitions.cvd"
            Headers     = @{
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
        } else {
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
