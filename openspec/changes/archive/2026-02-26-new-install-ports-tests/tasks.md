## 1. Test Scaffolding

- [x] 1.1 Create a new Pester test file for Install-NhcVcpkgPorts under tests/
- [x] 1.2 Add shared test helpers/fixtures (TestDrive fake vcpkg root, dummy vcpkg.exe)

## 2. Core Unit Tests

- [x] 2.1 Add tests that validate argument construction for -Ports (classic mode)
- [x] 2.2 Add tests that validate argument construction for -All (manifest feature flags)
- [x] 2.3 Add tests for OutputDir/Tag shaping and derived download/build/package/install paths
- [x] 2.4 Add tests for option flags (BinarySources, CachedOnly, Editable, ExactVersions)

## 3. Verification

- [x] 3.1 Run Pester suite and ensure all tests pass
