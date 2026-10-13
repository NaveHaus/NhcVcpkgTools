| Term | Definition | Use When | Avoid |
| --- | --- | --- | --- |
| port cmdlet | Any of the public commands `Install-NhcVcpkgPort`, `Export-NhcVcpkgPort`, or `Remove-NhcVcpkgPort` that wrap a vcpkg operation. | Referring to the module's public vcpkg-wrapping commands collectively. | "port function", "wrapper", "public function" when only the vcpkg-wrapping commands are meant |
| canonical command name | The singular-noun function name a port cmdlet is exported under (for example `Install-NhcVcpkgPort`). | Naming the primary, documented name of a port cmdlet. | "new name", "singular function" |
| legacy alias | A plural-noun alias (for example `Install-NhcVcpkgPorts`) exported for backward compatibility that resolves to a canonical command name. | Referring to the pre-rename plural command names. | "old function", "plural cmdlet", "deprecated name" |
| result object | The hashtable a port cmdlet returns describing the vcpkg invocation, including its `Status` entry. | Describing what a port cmdlet returns. | "return value", "config", "output" |
| vcpkg exit status | The process exit code of the vcpkg executable launched by a port cmdlet. | Discussing success or failure of the vcpkg process itself. | "return code", "error code", "`$?`" |
| launch failure | A port cmdlet invocation in which the vcpkg process cannot be started at all. | Distinguishing "vcpkg never ran" from "vcpkg ran and failed". | "vcpkg error", "crash" |
| source-mode import | Importing the module from `NhcVcpkgTools/NhcVcpkgTools.psm1` in the source tree rather than from the built module. | Discussing module loading without a prior build. | "dev import", "unbuilt module" |
| built module | The module assembled by `./build.ps1 -Tasks build` and imported from the build output. | Discussing the packaged module that tests and consumers import. | "compiled module", "release module" |
