
#begin with try statement for error catching and handling
try {

#Begin by adding variables to commands in order to avoid collisions and automate initial process
Write-Host "Starting Active Directory Tasks"
$AdRoot = (Get-ADDomain).DistinguishedName
$OUCanonicalName = "Finance"
$OUDisplayName = "Finance"
$ADPath = "OU=$($OUCanonicalName), $($AdRoot)"

# Check if ADDO exists and delete if needed. It is important to use the recirsive switch to also delete child OUs if needed
if (([ADSI]::Exists("LDAP://$($ADPath)"))) {
        Write-Host "$($OUCanonicalName) Already Exists and will be deleted"
            Remove-ADOrganizationalUnit -Identity "$ADPath" -Confirm:$False -Recursive
                Write-Host "$($OUCanonicalName) Deleted"

}
#Create new ADDO as required
if (-Not([ADSI]::Exists("LDAP://$($ADPath)"))) {
        New-ADOrganizationalUnit -Path $AdRoot -Name $OUCanonicalName -DisplayName $OUDisplayName -ProtectedFromAccidentalDeletion $False 
            Write-Host "[AD]: $($OUCanonicalName) OU Created"
            }

#Importing the CSV file with new users' data
$NewADUsers = Import-csv -Path $PSScriptRoot\financePersonnel.csv
$count = 1

#Iterate over rows to add data
ForEach ($ADUser in $NewADUsers) 
{
#Assigning to varables to cols
    $First = $ADUser.First_Name 
    $Last = $ADUser.Last_Name 
    $Name = $First + " " + $Last 
    $SamAcct = $ADUser.samAccount 
    $Postal = $ADUser.PostalCode 
    $Office = $ADUser.OfficePhone 
    $Mobile = $ADUser.MobilePhone

#use variables to create each user 
    New-ADUser  -GivenName $First `
                -Surname $Last `
                -Name $Name `
                -SamAccountName $SamAcct `
                -DisplayName $Name `
                -PostalCode $Postal `
                -MobilePhone $Mobile `
                -OfficePhone $Office `
                -Path $ADPath `

#counter increment to update reporting
$count++
}

#Generate outputfile as required
Get-ADUser -Filter * -SearchBase "ou=Finance,dc=consultingfirm,dc=com" -Properties DisplayName,PostalCode,OfficePhone,MobilePhone > .\AdResults.txt

#Generate Last Message
Write-Host "Active Directory Task completed"
}

#End with catch statement with potential action when recieving an error
catch{
    
}
