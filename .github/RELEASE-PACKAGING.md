# Fork release packaging test

Two independent workflows read `source_v3/package.json`, check the version against
the lockfile, and build Windows and Linux from the same commit. Neither creates
tags, releases, or PRs. This experiment is separate from the EDHM v22.02 application PR.

- **Package release (free installer)**: `.github/workflows/package-release-free-installer.yml`.
- **Package release (Advanced Installer)**: `.github/workflows/package-release-advanced-installer.yml`.

Each can be run or adopted independently; the free workflow never reads a license
secret and does not install or invoke Advanced Installer.

Push to `codex/release-workflow-test` in `Fenris159/EDHM_UI` to run it. Manual dispatch
is available once the workflow exists on the default branch. Download and extract
the artifact ZIPs from Actions; artifacts expire after 14 days.

## Two Windows paths

| Path | Tools | Configuration | Artifact suffix |
| --- | --- | --- | --- |
| Existing installer | Advanced Installer Professional | `ADVINST_LICENSE_KEY` Actions secret; optional `ADVINST_VERSION` variable (default 22.0) | `windows-advanced-installer-test` |
| Free installer | WiX 5.0.2 MSI compiler, NSIS 3.12 EXE wrapper | No license key or paid build service | `windows-free-test` |

Both artifacts contain **`edhm-ui-v3-windows-x64.exe`**, matching upstream's release
filename. Choose **one** Windows variant per release. They install the same app,
and must not be advertised as separate side-by-side products.

The free path always builds and runs installation tests. Advanced Installer builds
when its secret is present; otherwise it is explicitly skipped. No trial key
belongs in source. Its hosted-runner trial previously expired, so the licensed path
cannot be fully validated without a valid key.

Both test installers are unsigned. The Advanced Installer script strips the
workstation signing configuration only from its generated copy of the project.
An Advanced Installer license does not provide a signing certificate.

### Existing installer

`build-windows-installer.ps1` copies `source_v3/out/Installer/EDHM-UI-V3.aip`, updates
the version, removes obsolete file entries, and synchronizes the actual packaged
files. It retains the original dialogs, custom actions, shortcuts, and upgrade
identity. New Vite hashes and shader ZIP names need no manual file-list edits.

### Free installer

`build-free-windows-installer.ps1` generates one MSI component per packaged file,
with stable component IDs and a fresh product code for each build. It reads
the upgrade code from the original `.aip`. The test artifact includes a SHA-256
payload manifest for checking installed files.

The NSIS EXE only carries and launches this MSI. Windows Installer handles
elevation, repair, rollback, upgrades, downgrade rejection, and uninstallation.
NSIS registers no second uninstaller. It retains the source MSI in
`%LOCALAPPDATA%\Blue Mystic\EDHM-UI-V3\Installer\VERSION\PRODUCT-CODE` for maintenance. That cache
remains after uninstall; it contains no user settings.

WiX **5.0.2** is intentionally pinned: WiX 6 and later introduced a maintenance fee
with additional terms. WiX 5 is an older, out-of-support build tool, so updating
this pin requires reviewing licensing and compatibility. Only its MSI compiler
and dialog definitions are used; the older WiX Burn bootstrapper and native
custom-action DLLs are **not shipped**. The EXE wrapper uses NSIS 3.12.
See [WiX version lifecycle](https://docs.firegiant.com/wix/) and
[maintenance fee details](https://docs.firegiant.com/wix/osmf/).

### Compatibility and differences

| Behavior | Free path |
| --- | --- |
| Payload, version, publisher, icon, help/update links | Same packaged application and metadata |
| Default location | `%LOCALAPPDATA%\EDHM-UI-V3`, matching upstream's machine-scoped MSI |
| Existing install location | Reads upstream's 32-bit `HKLM\Software\Blue Mystic\EDHM-UI-V3\Path` value |
| Product family | Same MSI upgrade code; old product removed inside the transaction to support rollback and changed component layout |
| Shortcuts | Desktop and Start Menu, same names and targets, selectable on initial install |
| User settings/files | No recursive cleanup; only installer-owned files/values removed |
| Maintenance | Repair and uninstall; one Apps & Features entry |
| Launch after installation | Completion checkbox uses a small NSIS helper and Windows ShellExecuteEx, allowing the app's normal UAC prompt; no launch in silent mode |
| Silent use | MSI arguments, e.g. `/qn /norestart`, `/l*v "log.txt"`, `APPDIR="path"` |
| Installer UI | New MSI dialogs, not a pixel-identical copy of Advanced Installer |
| Running application | Windows Installer Restart Manager handles files in use; upstream has its own stop-process action |
| Bootstrapper-specific options | Advanced Installer's proprietary extraction/bootstrapper switches are not implemented |

The paths target the same installation outcome. They are **not identical in every
behavior**, and a PR must not claim otherwise. A future Advanced Installer release
upgrading a free installation still needs a live test with a licensed build.
Re-running the same EXE offers maintenance. A rebuilt EXE replaces an earlier
package at the same app version so installer-only fixes reach the cached MSI;
its separate cache folder preserves the previous package's source for rollback.
Increment the app version when publishing changed application files.

## Linux

The Linux artifact contains `edhm-ui-v3-linux-x64.zip` (rooted at
`edhm-ui-v3-linux-x64/`) and `linux_installer.sh` with Unix line endings, matching
upstream's other two asset names. Place the two assets together for installation.
The active Forge configuration includes both renderers and uses the executable
name expected by the existing shell script.

## Validation

[Fork run 33993776371](https://github.com/Fenris159/EDHM_UI/actions/runs/33993776371)
passed all 31 application tests and the full installer lifecycle checks below.
The separate Advanced Installer run verified its missing-secret skip behavior;
it did not produce or test a licensed installer.

The Windows job runs application regression tests and real installer tests on a
disposable GitHub-hosted runner. `test-windows-installers.ps1` refuses local or
self-hosted execution to avoid replacing a developer's installation. It uses the
checksum-pinned upstream 3.0.70 EXE as an upgrade fixture and checks installed
payload hashes, registered version, custom/default locations, downgrade rejection,
rollback after a failed upgrade, repair, shortcut options, uninstall, and user-file
preservation. Logs upload on failure.
No Elite Dangerous installation is required or modified.

The Finish action has a separate regression check: the actual compiled MSI action
launches a harmless probe from a path with spaces and Unicode in the correct working
directory. The test uses a temporary MSI copy with a unique product identity and
runs no installation or uninstallation actions. Direct MSI EXE actions fail
with Windows error 740 for EDHM-UI's elevation manifest; ShellExecuteEx lets Windows
request consent normally. Cancelling consent does not undo the completed install.
Hosted CI cannot validate the interactive Windows 11 secure-desktop UAC prompt.

The initial fork test verified Linux ZIP integrity, executable permissions, settings
renderer, and packaged app version. Live Linux installation remains untested.

Before proposing upstream: inspect the successful test run; manually test dialogs,
launch, and files-in-use behavior; validate the licensed path and reverse upgrade
when a key is available; configure signing if desired; then agree the publishing
trigger and replace the fork-only repository/branch guards.
