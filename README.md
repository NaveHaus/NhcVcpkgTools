# NhcVcpkgTools

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/NhcVcpkgTools.svg?style=flat&logo=powershell&label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/NhcVcpkgTools)
[![License](https://img.shields.io/github/license/NaveHaus/NhcVcpkgTools.svg?style=flat)](LICENSE)

Tools for working with vcpkg from PowerShell.

## Synopsis

NhcVcpkgTools is a PowerShell module that provides helper functions for interacting with the vcpkg C++ package manager.

## Requirements

- PowerShell 7.4+

## Description

This module simplifies common vcpkg tasks by providing a set of functions to manage your vcpkg environment. It helps with installing and exporting vcpkg ports, locating vcpkg roots, and other common tasks. The module is designed for PowerShell 7.4+ and follows standard module practices.

The following functions are exported by this module:

*   `Install-NhcVcpkgPorts`: Installs one or more vcpkg ports.
*   `Export-NhcVcpkgPorts`: Exports installed vcpkg ports to a specified format.

## Installation

Since this module is not yet published to the PowerShell Gallery, you can install it by cloning the repository and importing the module directly.

```powershell
git clone https://github.com/NaveHaus/NhcVcpkgTools.git
Import-Module ./NhcVcpkgTools
```

## Usage

### Install-NhcVcpkgPorts

This function installs one or more vcpkg ports for a specified triplet.

```powershell
# Example: Install the 'fmt' port for the default triplet
Install-NhcVcpkgPorts -PortName "fmt"

# Example: Install multiple ports for a specific triplet
Install-NhcVcpkgPorts -PortName "fmt", "gtest" -Triplet "x64-windows-static"
```

### Export-NhcVcpkgPorts

This function exports all installed vcpkg ports to a specified format, such as zip or 7zip.

```powershell
# Example: Export all installed ports to a zip file
Export-NhcVcpkgPorts -Format zip

# Example: Export all installed ports to a 7z file in a specific directory
Export-NhcVcpkgPorts -Format 7zip -OutputDir "C:\vcpkg_exports"
```

## Running Tests

This module uses [Pester](https://pester.dev/) v5+ for unit testing. To run tests:

1.  Ensure Pester v5 or newer is installed:
    ```powershell
    Install-Module Pester -Force
    ```
2.  Run all tests from the module root:
    ```powershell
    Invoke-Pester -Path tests
    ```

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
