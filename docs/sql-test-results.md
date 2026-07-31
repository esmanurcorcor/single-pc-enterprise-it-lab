# Lab Test Results

## Environment

- Domain: `novalab.test`
- Domain Controller: `DC01` — `192.168.100.10`
- Client Computer: `CLIENT01` — `192.168.100.20`
- SQL Server: `SQL01` — `192.168.100.30`
- SQL Instance: `SQL01\SQLEXPRESS`
- Database: `NovaITInventory`

## Verified Tests

### Active Directory and DNS

- `CLIENT01` successfully joined the `novalab.test` domain.
- `SQL01` successfully joined the `novalab.test` domain.
- DNS resolution from the client and SQL server to `DC01` succeeded.
- Domain user `NOVALAB\selin.yildiz` successfully signed in to `CLIENT01`.

### Group Policy

- Control Panel access restriction was applied to the IT user OU.
- Screen-lock policy was applied and verified on `CLIENT01`.

### SQL Server

- SQL Server Express was installed on the dedicated `SQL01` virtual machine.
- Instance `SQLEXPRESS` started successfully.
- TCP/IP was enabled for the SQL instance.
- SQL Server was configured to listen on TCP port `1433`.
- Windows Firewall allowed inbound TCP `1433` on the Domain profile.
- `CLIENT01` successfully reached `SQL01` on TCP port `1433`.

### Database

- Database `NovaITInventory` was created.
- The following tables were created:
  - `Departments`
  - `Employees`
  - `ActiveDirectoryAccounts`
  - `Devices`
  - `DeviceAssignments`
  - `OperationLogs`

### Test Data

| Record Type | Record Count |
|---|---:|
| Departments | 5 |
| Employees | 105 |
| Active Directory Accounts | 105 |
| Devices | 53 |
| Device Assignments | 51 |
| Operation Logs | 200 |

### Authorization Test

- The Active Directory group `NOVALAB\GRP-IT-Users` was added to SQL Server.
- The group was granted read-only access through the `db_datareader` database role.
- `NOVALAB\selin.yildiz` connected from `CLIENT01` to `NovaITInventory` using Windows Integrated Authentication.
- The client query returned an employee count of `105`.

## Result

The lab successfully demonstrated a separated client-server architecture:

`CLIENT01` → `SQL01:1433` → `NovaITInventory`

The client accessed the database with a domain identity and group-based read-only authorization.
