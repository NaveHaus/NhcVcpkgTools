# Capability: install-ports-tests

## Purpose
TBD: Tests for `Install-NhcVcpkgPorts` to validate argument construction and output directory shaping.

## Requirements

### Requirement: Install tests validate real argument construction
Unit tests for `Install-NhcVcpkgPorts` SHALL exercise the real `Get-CommonArguments` and `Get-TaggedOutputDir` implementations to validate the generated command-line arguments.

#### Scenario: Ports invocation builds classic arguments
- **WHEN** the test invokes `Install-NhcVcpkgPorts -Ports zlib` with a valid test vcpkg root
- **THEN** the resulting `Start-Process` argument list contains `install`, `zlib`, and `--classic` along with `--vcpkg-root`, `--triplet`, and `--host-triplet` entries

### Requirement: Tests remain hermetic and vcpkg-free
Unit tests for `Install-NhcVcpkgPorts` SHALL NOT require an installed vcpkg binary or network access and SHALL mock executable validation where needed.

#### Scenario: External process invocation is mocked
- **WHEN** the tests execute `Install-NhcVcpkgPorts`
- **THEN** `Start-Process` is mocked so no external vcpkg process is launched

### Requirement: Test fixtures provide a minimal vcpkg root
Tests SHALL construct a minimal fake vcpkg root that satisfies `Test-VcpkgRoot` while mocking `Test-Executable` to avoid real executable validation.

#### Scenario: Fake root satisfies validation
- **WHEN** the tests create a directory with a `.vcpkg-root` marker and mock `Test-Executable` to return true
- **THEN** `Install-NhcVcpkgPorts` resolves the command and root without requiring a real vcpkg installation

### Requirement: Output directory shaping is verified
Tests SHALL verify the output directory shaping behavior when `OutputDir` and `Tag` are provided.

#### Scenario: OutputDir with Tag becomes ParentDir
- **WHEN** the test invokes `Install-NhcVcpkgPorts -OutputDir <dir> -Tag release`
- **THEN** the resulting configuration uses `<dir>\release` as the parent directory and derives download/build/package/install paths under it
