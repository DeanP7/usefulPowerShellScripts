# Prompt the user for new user information
$newUserFirstName = Read-Host "Enter new user's first name"
$newUserLastName = Read-Host "Enter new user's last name"
$newUsername = Read-Host "Enter new user's username"
$newUserJob = Read-Host "Enter new user's job description"
$newUserEmail = Read-Host "Enter new user's email"
$ou = "OU=OU,DC=domain,DC=com"

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
    -GivenName $newUserFirstName `
    -Surname $newUserLastName `
    -SamAccountName $newUsername `
    -UserPrincipalName "$newUsername@domain.com" `
    -EmailAddress "$newUserEmail@domain.com" `
    -Description $newUserJob `
    -Path $ou `
    -Enabled $true `
    -AccountPassword $newUserPassword

# Prompt for existing user's CN (Common Name)
$existingUserCN = Read-Host "Enter the name of the existing user to reference"

# Get the existing user's information based on CN
$existingUser = Get-ADUser -Filter { CN -eq $existingUserCN } -Properties distinguishedName

if ($existingUser -eq $null) {
    Write-Host "Existing user not found with the provided CN."
    Exit
}

# Get the groups of the existing user
$existingUserGroups = Get-ADPrincipalGroupMembership -Identity $existingUser

# Create an array to hold group objects
$groupObjects = @()

foreach ($group in $existingUserGroups) {
    $groupObjects += Get-ADGroup $group
}

# Add the new user to the same groups as the existing user
foreach ($groupObject in $groupObjects) {
    Add-ADPrincipalGroupMembership -Identity $newUsername -MemberOf $groupObject
}

# Output success message
Write-Host "New user $newUserFirstName $newUserLastName has been created and added to the same groups as $existingUserCN."
