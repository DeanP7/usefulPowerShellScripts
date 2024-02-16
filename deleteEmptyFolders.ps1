#Created this script to help clean up our on-prem file server
#It looks for empty directories older than a set threshold and deletes them.

# Set a directory to look through, an output CSV path, the day threshold, and any excluded directories.
$rootFolderPath = ""
$csvFilePath = ""
$daysThreshold = 90
$excludedFolderPath = ""

# Check if a folder is empty and get its last modified date
function Get-EmptyFolderInfo {
    param (
        [string]$folderPath
    )

    $folderItems = Get-ChildItem -Path $folderPath
    if ($folderItems.Count -eq 0 -and $folderPath -ne $excludedFolderPath) {
        $lastModified = (Get-Item -Path $folderPath).LastWriteTime
        $daysDifference = (Get-Date) - $lastModified
        if ($daysDifference.Days -ge $daysThreshold) {
            return [PSCustomObject]@{
                FolderPath = $folderPath
                LastModified = $lastModified
            }
        }
    }
    return $null
}

# Recursively find and list empty folders
function Find-EmptyFolders {
    param (
        [string]$currentFolder
    )

    $emptyFolderInfo = Get-EmptyFolderInfo -folderPath $currentFolder
    if ($emptyFolderInfo -ne $null) {
        $emptyFolderInfo
    }

    $subFolders = Get-ChildItem -Path $currentFolder -Directory
    foreach ($subFolder in $subFolders) {
        Find-EmptyFolders -currentFolder $subFolder.FullName
    }
}

# Start searching for empty folders from the root folder and store the results in an array
$emptyFolders = Find-EmptyFolders -currentFolder $rootFolderPath

# Export the results to a CSV file with proper headers
if ($emptyFolders.Count -gt 0) {
    $emptyFolders | Export-Csv -Path $csvFilePath -NoTypeInformation
}

# Delete the empty folders
$emptyFolders | ForEach-Object {
    $folderPath = $_.FolderPath
    if ($folderPath -ne $excludedFolderPath) {
        Remove-Item -Path $folderPath -Force -Recurse
    }
}

# Modify permissions to allow everyone to read the CSV file
icacls $csvFilePath /grant:r "Everyone:(R)"
