# Specify the path to the folder containing user accounts
$userFolderPath = "\\W-LBH-wow13\c$\Users"

# Specify an array of folder names to ignore
$foldersToIgnore = @("LBAdmin", "Public", "Default")

# Specify an array of distinguished names for the target OUs in Active Directory
$ouDNs = @(
    "OU=DOMAIN ADMINISTRATORS,OU=LBH USERS,DC=medlinkmanagement,DC=com",
    "OU=DOMAIN USERS,OU=LBH USERS,DC=medlinkmanagement,DC=com",
    "OU=HOSPITAL ADMINISTRATORS,OU=LBH USERS,DC=medlinkmanagement,DC=com",
    "OU=Service Accounts,OU=LBH USERS,DC=medlinkmanagement,DC=com",
    "OU=Test Users,OU=LBH USERS,DC=medlinkmanagement,DC=com"
)

# Get all folder names in the C:\Users directory
$folderNames = Get-ChildItem $userFolderPath -Directory | Select-Object -ExpandProperty Name

# Initialize an array to collect folders without matching usernames (without domain)
$foldersWithoutMatchingUsername = @()

# Iterate through each folder in the directory
foreach ($folderName in $folderNames) {
    # Check if the folder name is in the list of folders to ignore
    if ($foldersToIgnore -contains $folderName) {
        continue
    }

    # Initialize a flag to check if a matching username is found
    $matchingUsernameFound = $false

    # Iterate through each OU to check for a matching username
    foreach ($ouDN in $ouDNs) {
        # Get all user logon names (UserPrincipalName) in the current OU
        $usersInOU = Get-ADUser -Filter {Enabled -eq $true} -SearchBase $ouDN | Select-Object -ExpandProperty SamAccountName

        # Check if the folder name matches any username (without domain) within the OU
        if ($usersInOU -contains $folderName) {
            $matchingUsernameFound = $true
            break  # Exit the inner loop once a match is found
        }
    }

    # If no matching username is found for the folder, add it to the collection
    if (-not $matchingUsernameFound) {
        $foldersWithoutMatchingUsername += $folderName
    }
}

# Delete folders without matching usernames (without domain) excluding specified folders
if ($foldersWithoutMatchingUsername.Count -gt 0) {
    Write-Host "Deleting folders (excluding 'LBAdmin' and 'Public') without matching usernames:"
    foreach ($folderName in $foldersWithoutMatchingUsername) {
        $folderPathToDelete = Join-Path -Path $userFolderPath -ChildPath $folderName
        try {
            Remove-Item -Path $folderPathToDelete -Recurse -Force -ErrorAction Stop
            Write-Host "Deleted folder: $folderPathToDelete"
        } catch {
            Write-Host "Failed to delete folder: $folderPathToDelete - $($_.Exception.Message)"
        }
    }
} else {
    Write-Host "All folders (excluding 'LBAdmin' and 'Public') correspond to a username (without domain) in the specified OUs."
}