## Purpose

Define how **port cmdlets** report the outcome of the vcpkg process they launch, so callers can rely on the **result object**'s `Status` to detect failed vcpkg operations.

## ADDED Requirements

### Requirement: Status reflects the vcpkg exit status
For every **port cmdlet** invocation that attempts to launch vcpkg, the `Status` entry of the **result object** SHALL be `$true` if and only if vcpkg started and its **vcpkg exit status** was zero. Parameter validation errors that stop a **port cmdlet** before it attempts to launch vcpkg are outside this requirement.

#### Scenario: vcpkg exits with code zero
- **GIVEN** a **port cmdlet** invocation whose vcpkg process exits with code 0
- **WHEN** the **port cmdlet** completes
- **THEN** the **result object** has `Status` equal to `$true`

#### Scenario: vcpkg exits with a non-zero code
- **GIVEN** a **port cmdlet** invocation whose vcpkg process exits with code 1
- **WHEN** the **port cmdlet** completes
- **THEN** the **result object** has `Status` equal to `$false`

#### Scenario: Status applies to every port cmdlet
- **GIVEN** vcpkg exits with a non-zero code
- **WHEN** each of `Install-NhcVcpkgPort`, `Export-NhcVcpkgPort`, and `Remove-NhcVcpkgPort` is invoked
- **THEN** each returns a **result object** with `Status` equal to `$false`

### Requirement: Failed vcpkg operations are reported through the result object
When vcpkg exits with a non-zero code or a **launch failure** occurs, the **port cmdlet** SHALL still return its complete **result object** with `Status` equal to `$false`, and SHALL NOT throw a terminating error, write an error record of its own, or write a warning because of that outcome.

#### Scenario: Non-zero exit returns the result object without an exception
- **GIVEN** a **port cmdlet** invocation whose vcpkg process exits with a non-zero code
- **WHEN** the **port cmdlet** completes
- **THEN** it returns the **result object** with all of its usual entries
- **AND** `Status` is `$false`
- **BUT** no terminating error is thrown

#### Scenario: Launch failure returns a failed result object
- **GIVEN** the vcpkg command resolved by a **port cmdlet** cannot be started
- **WHEN** the **port cmdlet** is invoked
- **THEN** it returns the **result object** with `Status` equal to `$false`
- **BUT** no terminating error is thrown

### Requirement: Launch failures write no error records
When a **launch failure** occurs, a **port cmdlet** SHALL NOT write error records to the PowerShell error stream, whether or not `-Quiet` is specified; the failure is reported only through the `Status` entry of the **result object**.

#### Scenario: Launch failure without Quiet writes no error records
- **GIVEN** the vcpkg command cannot be started
- **WHEN** a **port cmdlet** is invoked without `-Quiet`
- **THEN** no error records are written to the PowerShell error stream
- **AND** the **result object** has `Status` equal to `$false`

#### Scenario: Launch failure with Quiet writes no error records
- **GIVEN** the vcpkg command cannot be started
- **WHEN** a **port cmdlet** is invoked with `-Quiet`
- **THEN** no error records are written to the PowerShell error stream
- **AND** the **result object** has `Status` equal to `$false`

### Requirement: Quiet changes neither console output nor Status
A **port cmdlet**'s `-Quiet` switch SHALL NOT suppress vcpkg's own console output and SHALL NOT change the `Status` entry of the **result object**.

#### Scenario: Quiet does not hide vcpkg console output
- **GIVEN** a vcpkg process that writes progress and error text to its standard output and standard error
- **WHEN** a **port cmdlet** is invoked with `-Quiet`
- **THEN** vcpkg's text still appears on the console

#### Scenario: Quiet does not change Status
- **GIVEN** a vcpkg process that exits with a non-zero code
- **WHEN** a **port cmdlet** is invoked once with `-Quiet` and once without
- **THEN** both **result objects** have `Status` equal to `$false`

### Requirement: vcpkg output goes to the console
vcpkg's standard output and standard error SHALL be shown on the console of the PowerShell host running the **port cmdlet**. A **port cmdlet** SHALL NOT capture vcpkg's output into the **result object** or re-emit it as PowerShell error records.

#### Scenario: vcpkg error text is visible on the console
- **GIVEN** a vcpkg process that writes an error message to standard error and exits with a non-zero code
- **WHEN** a **port cmdlet** runs that process
- **THEN** the error message appears on the console
- **AND** no PowerShell error record is written for that message
- **AND** the **result object** has `Status` equal to `$false`
