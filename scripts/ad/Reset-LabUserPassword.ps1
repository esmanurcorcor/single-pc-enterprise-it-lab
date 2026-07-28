Import-Module ActiveDirectory

$SamAccountName = Read-Host "Enter the user logon name"

try {
    $User = Get-ADUser `
        -Identity $SamAccountName `
        -Properties LockedOut `
        -ErrorAction Stop
}
catch {
    Write-Host "User not found: $SamAccountName" -ForegroundColor Red
    exit
}

$NewPassword = Read-Host `
    "Enter the temporary password" `
    -AsSecureString

try {
    Set-ADAccountPassword `
        -Identity $User `
        -Reset `
        -NewPassword $NewPassword `
        -ErrorAction Stop

    Set-ADUser `
        -Identity $User `
        -ChangePasswordAtLogon $true `
        -ErrorAction Stop

    if ($User.LockedOut) {
        Unlock-ADAccount `
            -Identity $User `
            -ErrorAction Stop
    }

    Write-Host `
        "Password reset completed for $SamAccountName." `
        -ForegroundColor Green

    Write-Host `
        "The user must change the password at the next logon." `
        -ForegroundColor Yellow
}
catch {
    Write-Host `
        "Password reset failed: $($_.Exception.Message)" `
        -ForegroundColor Red
}