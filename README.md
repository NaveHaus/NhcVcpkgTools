# NhcVcpkgTools

Tools for working with vcpkg from PowerShell.

## Running Tests

This module uses [Pester](https://pester.dev/) v5+ for unit testing. To run tests:

1. Ensure Pester v5 or newer is installed:
   ```powershell
   Install-Module Pester -Force
   ```
2. Run all tests from the module root:
   ```powershell
   Invoke-Pester -Path tests
   ```
