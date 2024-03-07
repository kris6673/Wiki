# Download latest release of something off GitHub 

# GitHub repository details
$repoOwner = 'rustdesk'
$repoName = 'rustdesk'
$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"

# Make a request to the GitHub API
$response = Invoke-RestMethod -Uri $apiUrl

# Get the download URL for the latest release
$downloadUrl = $response.assets.browser_download_url | Where-Object { $_ -like '*x86_64.exe' }

# Specify the output path for the downloaded file
$outputPath = "$env:TEMP\rustdesk-latest.exe"

# Download the latest release
Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath
Write-Host "Latest release of RustDesk downloaded to: $outputPath"