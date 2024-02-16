#Script for termed employees.
#Prompts user for termed employee name and compares it to AD users.
#Once confirmed, it disables the user, scrambles their password, moves them to "DISABLED USER" OU, and logs this to a csv file

Import-Module ActiveDirectory

#-ResourceContext server should be changed to domain (i.e. "theCorporation.com")
$resourceContextServer = ""

Write-Host "Active Directory offboarding script"

$terminatedUserInput = Read-Host "Enter the name of the terminated employee you would like to disable in Active Directory"
$adCompare = Get-ADUser -Filter "Name -like '*$terminatedUserInput*'"

if ($adCompare.Count -eq 0) {
    Write-Host "No users were matched with your input"
} else {
    Write-Host "Here is a list of matched users based on your input"

    # Ensure $adCompare is always treated as an array
    $adCompare = @($adCompare)

    #path to .csv log
    $csvPath = ""

    #if the .csv doesnt exist, make it
    if (-not (Test-Path $csvPath)) {
        "Name,SamAccountName,DateDisabled" | Out-File -FilePath $csvPath
    }

    for ($i = 0; $i -lt $adCompare.Count; $i++) {
        $user = $adCompare[$i]
        #-ResourceContext server should be changed to domain (i.e. "theCorporation.com")
        $groups = Get-ADPrincipalGroupMembership -ResourceContextServer $resourceContextServer -Identity $user

        Write-Host "$i. $($adCompare[$i].Name), $($adCompare[$i].SamAccountName)"
        Write-Host "   Member of Groups:"
        foreach ($group in $groups) {
            Write-Host "      $($group.Name)"
        }
    }

    $indexInput = Read-Host "Enter the number of the user you want to offboard"

    if ($indexInput -ge 0 -and $indexInput -lt $adCompare.Count) {
        $terminatedUser = $adCompare[$indexInput]
        Write-Host "You have selected $($terminatedUser.Name), $($terminatedUser.SamAccountName)"

        $confirmation = Read-Host "If this is the correct user, press 'Y'. If not, press 'N'"
        if ($confirmation -eq "Y" -or $confirmation -eq "y") {
            Write-Host "You confirmed the selection."

            # Generate a random password
            $randomPassword = New-Guid

            # Set the random password for the user
            Set-ADAccountPassword -Identity $terminatedUser -NewPassword (ConvertTo-SecureString -AsPlainText $randomPassword -Force)
            Set-ADUser -Identity $terminatedUser -ChangePasswordAtLogon $true
            Set-ADUser -Identity $terminatedUser -PasswordNeverExpires $false

            Disable-ADAccount -Identity $terminatedUser

            #log the date of the user being disabled into csv
            $dateDisabled = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "$($terminatedUser.Name), $($terminatedUser.SamAccountName), $dateDisabled"
            $logEntry | Out-File -Append -FilePath $csvPath

            Get-ADUser -Identity $terminatedUser -Properties MemberOf | ForEach-Object {
                $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false
            }

            $disabledOU = "OU=DISABLED USERS,DC=medlinkmanagement,DC=com"

            Move-ADObject -Identity $terminatedUser.DistinguishedName -TargetPath $disabledOU

            Write-Host "User $($terminatedUser.Name) has been moved to the 'DISABLED USERS' OU, account has been disabled, and the date of disablement has been recorded in the log."
        } else {
            Write-Host "You did not confirm the selection, exiting script..."
            exit
        }
    }
}
