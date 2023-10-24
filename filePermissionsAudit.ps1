# Set the root directory you want to audit
$rootDirectory = "C:\Path"

# Define an array of excluded identities
$excludedIdentities = @(
    "DOMAIN\GROUP1",
    "DOMAIN\GROUP2"
)

# Set the export file path
$exportFilePath = "C:\Path\FolderPermissionsAudit.csv"

# Create a function to recursively audit folder permissions
function Get-FolderPermissions {
    param (
        [string]$path
    )

    # Get the ACL (Access Control List) for the folder
    $acl = Get-Acl -Path $path

    # Initialize an array to store the results for this folder
    $results = @()

    # Iterate through the access rules
    foreach ($accessRule in $acl.Access) {
        $identity = $accessRule.IdentityReference
        $type = $accessRule.AccessControlType

        # Check if the identity is a group or user
        if ($identity.GetType().Name -eq "SecurityIdentifier") {
            $identityType = "User"
        } else {
            $identityType = "Group"
        }

        # Check if the identity matches any of the excluded values
        if ($excludedIdentities -notcontains $identity) {
            # Add the information to the results
            $results += [PSCustomObject]@{
                Path = $path
                Identity = $identity
                Type = $identityType
                Access = $type
            }
        }
    }

    return $results
}

# Start the audit and store the results in an array
$auditResults = @()
$folders = Get-ChildItem -Path $rootDirectory -Directory -Recurse

foreach ($folder in $folders) {
    $auditResults += Get-FolderPermissions -path $folder.FullName
}

# Display the results
$auditResults | Format-Table -AutoSize

# Export the results to the specified CSV file
$auditResults | Export-Csv -Path $exportFilePath -NoTypeInformation
