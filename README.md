# NhcVcpkgTools

<!-- [![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/NhcVcpkgTools.svg?style=flat&logo=powershell&label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/NhcVcpkgTools) -->
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Tools for working with vcpkg from PowerShell.

## Synopsis

NhcVcpkgTools is a PowerShell module that provides helper functions for interacting with the vcpkg C++ package manager.

## Requirements

- PowerShell 7.4+
- Pester 5.7+ (for testing)
- PSScriptAnalyzer 1.24+ (for linting)

## Description

This module simplifies common vcpkg tasks by providing a set of functions to manage your vcpkg environment. It helps with installing and exporting vcpkg ports, locating vcpkg roots, and other common tasks. The module is designed for PowerShell 7.4+ and follows standard module practices.

The following functions are exported by this module:

*   `Install-NhcVcpkgPort`: Installs one or more vcpkg ports.
*   `Export-NhcVcpkgPort`: Exports installed vcpkg ports to a specified format.
*   `Remove-NhcVcpkgPort`: Removes installed or outdated vcpkg ports.

## Installation

Since this module is not yet published to the PowerShell Gallery, you can install it by cloning the repository and importing the module directly.

```powershell
git clone https://github.com/NaveHaus/NhcVcpkgTools.git
Import-Module ./NhcVcpkgTools
```

## Usage

### Install-NhcVcpkgPort

This function installs one or more vcpkg ports for a specified triplet.

```powershell
# Example: Install the 'fmt' port for the default triplet
Install-NhcVcpkgPort -Ports "fmt"

# Example: Install multiple ports for a specific triplet
Install-NhcVcpkgPort -Ports "fmt", "gtest" -Triplet "x64-windows-static"
```

### Export-NhcVcpkgPort

This function exports all installed vcpkg ports to a specified format, such as zip or 7zip.

```powershell
# Example: Export all installed ports to a zip file
Export-NhcVcpkgPort -All -Format zip

# Example: Export all installed ports to a 7z file in a specific directory
Export-NhcVcpkgPort -All -Format 7zip -OutputDir "C:\vcpkg_exports"
```

### Remove-NhcVcpkgPort

This function removes installed or outdated vcpkg ports.

```powershell
# Example: Remove specific ports
Remove-NhcVcpkgPort -Ports "zlib", "fmt"

# Example: Remove all outdated ports
Remove-NhcVcpkgPort -Outdated
```

## Running Tests

This module uses [Pester](https://pester.dev/) v5+ for unit testing. To run tests:

1.  Ensure Pester v5 or newer is installed:
    ```powershell
    Install-Module Pester -Force
    ```
2.  Run the full suite the way CI does — this builds the module and puts it
    on `PSModulePath` so the QA tests under `tests/QA` are discovered:
    ```powershell
    ./build.ps1 -Tasks test
    ```
    For a fast inner loop on unit tests, `Invoke-Pester -Path tests` also
    works, but the module must already be built (`./build.ps1 -Tasks build`);
    otherwise the QA tests in `tests/QA` fail discovery because the built
    module is not on `PSModulePath`.

## Running Lint

This repository uses [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) for linting PowerShell sources under `NhcVcpkgTools/`, `tests/`, and `tools/`.

1. Install the linting module:
   ```powershell
   Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
   ```
2. Run lint locally with readable output:
   ```powershell
   ./tools/lint.ps1
   ```

For CI/GitHub Actions usage, run:

```powershell
./tools/lint.ps1 -Mode github
```
