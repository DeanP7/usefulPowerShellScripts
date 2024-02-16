#Script for adding new employees to Active Directory domain.
#Prompts user for new user's information, new password, and a reference employee to mirror their groups.


#Enter the OU path you want the new user to reside in. Example: "OU=DOMAIN USERS,DC=theCorporation,DC=com"
$ou = "OU=,DC=,DC=com"

# Prompt the user for new user information
$newUserFirstName = Read-Host "Enter new user's first name"
$newUserLastName = Read-Host "Enter new user's last name"
$newUserId = Read-Host "Enter new user's employee ID#"
$newUserJob = Read-Host "Enter new user's job description"
$newUsername = $newUserFirstName.substring(0,1)+$newUserLastName.substring(0,1)+$newUserId
$newUserEmail = $newUserFirstName.substring(0,1)+$newUserLastName


# Prompt for new user password
do {
    $newUserPassword = Read-Host "Enter new user's password" -AsSecureString
    $confirmPassword = Read-Host "Confirm new user's password" -AsSecureString

    $passwordMatch = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newUserPassword)) -eq [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmPassword))

    if (-not $passwordMatch) {
        Write-Host "Passwords do not match. Please try again."
    }
} while (-not $passwordMatch)

# Create a new user
New-ADUser -Name "$newUserFirstName $newUserLastName" `
    -DisplayName "$newUserFirstName $newUserLastName" `
    -GivenName $newUserFirstName `
    -Surname $newUserLastName `
    -SamAccountName $newUsername `
    -UserPrincipalName "$newUsername@lakebutlerhospital.com" `
    -EmailAddress "$newUserEmail@lakebutlerhospital.com" `
    -Description $newUserJob `
    -Path $ou `
    -Enabled $true `
    -AccountPassword $newUserPassword `
    -ChangePasswordAtLogon $true

# Prompt for existing user selection
$existingUserInput = Read-Host "Enter the name of the existing user to reference"

# Get matching users based on input
$adCompare = Get-ADUser -Filter "Name -like '*$existingUserInput*'"

if ($adCompare.Count -eq 0) {
    Write-Host "No users were matched with your input."
    Exit
}

# Display matched users and their groups
Write-Host "Here is a list of matched users based on your input"

# Ensure $adCompare is always treated as an array
$adCompare = @($adCompare)

for ($i = 0; $i -lt $adCompare.Count; $i++) {
    $user = $adCompare[$i]
    $groups = Get-ADPrincipalGroupMembership -ResourceContextServer medlinkmanagement.com -Identity $user

    Write-Host "$i. $($adCompare[$i].Name), $($adCompare[$i].SamAccountName)"
    Write-Host "   Member of Groups:"
    foreach ($group in $groups) {
        Write-Host "      $($group.Name)"
    }
}


$indexInput = Read-Host "Enter the number of the user you want to reference"

if ($indexInput -ge 0 -and $indexInput -lt $adCompare.Count) {
    $existingUser = $adCompare[$indexInput]
    Write-Host "You have selected $($existingUser.Name), $($existingUser.SamAccountName)"

    # Get the groups of the existing user
    $existingUserGroups = Get-ADPrincipalGroupMembership -Identity $existingUser

    # Create an array to hold group objects
    $groupObjects = @()

    foreach ($group in $existingUserGroups) {
        # Exclude specific groups (e.g., "Domain Users")
        if ($group.Name -ne "Domain Users") {
            $groupObjects += Get-ADGroup $group
        }
    }

    # Add the new user to the same groups as the existing user (excluding specified groups)
    foreach ($groupObject in $groupObjects) {
        Add-ADPrincipalGroupMembership -Identity $newUsername -MemberOf $groupObject
    }

    # Output success message
    Write-Host "New user $newUserFirstName $newUserLastName has been created and added to the same groups as $($existingUser.Name)."
} else {
    Write-Host "Invalid selection. Exiting."
    Exit
}
