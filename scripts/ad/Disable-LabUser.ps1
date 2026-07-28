Import-Module ActiveDirectory

$SamAccountName = Read-Host "Devre disi birakilacak kullanici adini girin"

$User = Get-ADUser `
    -Identity $SamAccountName `
    -Properties MemberOf, DistinguishedName `
    -ErrorAction SilentlyContinue

if (-not $User) {
    Write-Error "$SamAccountName adli kullanici bulunamadi."
    exit
}

try {
    # Kullanıcının sisteme giriş yapmasını engeller.
    Disable-ADAccount `
        -Identity $User `
        -ErrorAction Stop

    # Kullanıcının üye olduğu departman gruplarını bulur.
    $DepartmentGroups = $User.MemberOf |
        ForEach-Object {
            Get-ADGroup -Identity $_
        } |
        Where-Object {
            $_.Name -like "GRP-*-Users"
        }

    # Kullanıcıyı bulunan departman gruplarından çıkarır.
    foreach ($Group in $DepartmentGroups) {
        Remove-ADGroupMember `
            -Identity $Group `
            -Members $User `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "$SamAccountName, $($Group.Name) grubundan cikarildi."
    }

    # Hesabın açıklama alanına kapatılma tarihini yazar.
    $OffboardingDate = Get-Date -Format "yyyy-MM-dd"

    Set-ADUser `
        -Identity $User `
        -Description "Offboarded on $OffboardingDate" `
        -ErrorAction Stop

    # Devre dışı bırakılan kullanıcıların tutulduğu OU.
    $DisabledUsersOU = `
        "OU=DisabledUsers,OU=NovaLab,DC=novalab,DC=test"

    $CurrentParentOU = $User.DistinguishedName.Substring(
        $User.DistinguishedName.IndexOf(",") + 1
    )

    # Kullanıcı henüz DisabledUsers OU'sunda değilse taşır.
    if ($CurrentParentOU -ne $DisabledUsersOU) {
        Move-ADObject `
            -Identity $User.DistinguishedName `
            -TargetPath $DisabledUsersOU `
            -ErrorAction Stop
    }

    Write-Host ""
    Write-Host "$SamAccountName icin offboarding islemi tamamlandi."
}
catch {
    Write-Error "Offboarding islemi basarisiz: $($_.Exception.Message)"
}