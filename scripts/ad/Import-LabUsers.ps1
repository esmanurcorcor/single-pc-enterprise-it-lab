Import-Module ActiveDirectory

$CsvPath = "C:\Lab\users.csv"
$DomainName = "novalab.test"
$BaseOU = "OU=Users,OU=NovaLab,DC=novalab,DC=test"

# Kullanıcılara verilecek geçici parolayı ekranda güvenli biçimde sorar.
$TemporaryPassword = Read-Host "Gecici kullanici parolasini girin" -AsSecureString

$Users = Import-Csv -Path $CsvPath

foreach ($User in $Users) {

    $FirstName  = $User.FirstName
    $LastName   = $User.LastName
    $Department = $User.Department
    $Title      = $User.Title

    $SamAccountName = (
        "$FirstName.$LastName"
    ).ToLower()

    $UserPrincipalName = "$SamAccountName@$DomainName"
    $UserOU = "OU=$Department,$BaseOU"
    $GroupName = "GRP-$Department-Users"

    $ExistingUser = Get-ADUser `
        -Filter "SamAccountName -eq '$SamAccountName'" `
        -ErrorAction SilentlyContinue

    if ($ExistingUser) {
        Write-Warning "$SamAccountName zaten mevcut. Kullanici atlandi."
        continue
    }

    try {
        New-ADUser `
            -Name "$FirstName $LastName" `
            -GivenName $FirstName `
            -Surname $LastName `
            -DisplayName "$FirstName $LastName" `
            -SamAccountName $SamAccountName `
            -UserPrincipalName $UserPrincipalName `
            -Department $Department `
            -Title $Title `
            -Path $UserOU `
            -AccountPassword $TemporaryPassword `
            -ChangePasswordAtLogon $true `
            -Enabled $true

        Add-ADGroupMember `
            -Identity $GroupName `
            -Members $SamAccountName

        Write-Host "$SamAccountName olusturuldu ve $GroupName grubuna eklendi."
    }
    catch {
        Write-Error "$SamAccountName olusturulamadi: $($_.Exception.Message)"
    }
}