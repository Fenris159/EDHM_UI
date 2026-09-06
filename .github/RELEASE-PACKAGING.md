# Release packaging

Two independent workflows build the Windows and Linux packages from the same commit:

- **Package release (Velopack)** replaces the obsolete Advanced Installer workflow.
- **Package release (free installer)** retains the WiX/NSIS installer and its MSI migration tests.

Neither workflow requires a paid installer license. Both read the application version
from `source_v3/package.json`, verify the lockfile, and obtain matching EDHM patch notes.
The experiment remains in the fork, separate from the EDHM v22.02 application PR.

## Velopack: one-time setup for the maintainer

1. Find the **existing Velopack package ID** in the local `vpk pack --packId` command,
   build script, or the `<id>` element of the `.nuspec` inside an existing full `.nupkg`
   (open it as a ZIP). Preserve the exact value. The EXE download filename and GitHub
   repository name do not establish this identity.
2. In GitHub **Settings → Secrets and variables → Actions → Variables**, create
   `VELOPACK_PACK_ID` with that value. It is not a secret or license key. The workflow
   fails early with setup guidance when it is absent or invalid.
3. Run **Package release (Velopack)** with **Publish release** unchecked. Download the
   Windows installer from the completed run's `windows-velopack-test` artifact and
   test an upgrade over the maintainer's actual previous Velopack installer.
4. Once validated, increment the app version and run with **Publish release** checked.
   It publishes a normal stable GitHub release, with installers, patch notes, and
   GitHub's automatic source archives. Existing published versions cannot be replaced.

`.github/installers/velopack/sdk.json` pins the native Velopack SDK version and the
SHA-256 of its official release archive. CI installs that same CLI version. Update
both fields together when changing Velopack versions; the app version still comes
automatically from `source_v3/package.json`.
Authors, display name, app version, icon, and executable are read from existing app
metadata or set in `build-velopack-installer.ps1`. The workflow YAML exposes the package
ID variable and publish toggle; no developer has to edit version strings each release.
The build currently produces unsigned installers, like the free path. Optional signing
should use the documented [Velopack signing options](https://docs.velopack.io/reference/cli/content/vpk-windows)
with CI credentials, never workstation passwords committed to source.

### Fork testing and upstream adoption

The fork uses **`Fenris.EDHMUI.PackagingTest`** only for build testing. Publication with
that test identity is rejected. It is not the maintainer's known package ID and does
not establish upgrade compatibility with their installer.

The fork's `main` has two small launchers so Actions shows **Run workflow**. They
forward the publish checkbox to the full workflow on `codex/release-workflow-test`.
Pushes build artifacts only. Manual runs can publish (Velopack defaults to build-only
while compatibility is being verified; the free installer defaults to publishing).

For upstream adoption, copy the **full workflow and supporting scripts/application
changes from the test branch**, not the fork-main launcher. Then:

- Set the real `VELOPACK_PACK_ID` repository variable.
- Change the workflow's push branch from `codex/release-workflow-test` to the desired
  upstream trigger and its repository guard from `Fenris159/EDHM_UI` to `BlueMystical/EDHM_UI`.
- Update the repository guard in `publish-package-release.cjs` and its matching test.
- Run build-only first and validate upgrade/launch on Windows 11 before publishing.

Only one Windows installer variant should publish a given app version. Build logs,
Velopack packages/feed, and note provenance stay in Actions artifacts for 14 days.

## Matching EDHM patch notes

Both workflows run `.github/scripts/release-notes.cjs` before packaging. It derives
the EDHM version from the same `source_v3/src/data/ODYSS/ODYSS_EDHM-v*.zip` filename
used by the application. It searches `psychicEgg/EDHM` main history for that
version's archive and an exact `EDHM vVERSION` commit-title token. It fails for
missing or ambiguous matches, empty notes, or failed API requests. It never falls
back to the latest release, which may be newer than the bundled shaders.

For v22.02 the source is
[`a0d14ec`](https://github.com/psychicEgg/EDHM/commit/a0d14ec51117be9052f1cb337dad33178b7b7525).
The matching commit's complete message body is retained with a source link.
Optional UI-specific changes can be added in `.github/release-notes/vAPP_VERSION.md`.
Both sets of notes precede `----`, the existing application's update-notification
separator; installation instructions follow it. No updater endpoint or application
code change is needed when these notes are eventually published upstream.

The `release-notes` Actions artifact contains `release-notes.md` and
`release-metadata.json`. Metadata records the app commit, bundled ZIP SHA-256,
EDHM version, upstream commit, and upstream archive blob. The UI ZIP is repackaged,
so its bytes need not equal the upstream ZIP; version matching does not claim a
byte-for-byte payload comparison.

When publication is selected and both platform jobs succeed, a job with
`contents: write` publishes a stable release titled and tagged `vAPP_VERSION`, marked Latest, with exactly three assets:
`edhm-ui-v3-windows-x64.exe`, `edhm-ui-v3-linux-x64.zip`, and `linux_installer.sh`.
Notes are the release body; the notes and metadata files remain in Actions artifacts
and are not attached to the public release. GitHub automatically adds Source code
(zip) and Source code (tar.gz) links from the release tag.

The publisher stages files in a temporary draft, then publishes automatically only
after upload succeeds. An interrupted upload can leave a draft for the next attempt
to resume. Both installer paths share a publishing concurrency group for each app
version. Choose one Windows path for a release; an already published version cannot
be overwritten by the other path or by a rerun. Increment the app version to publish
another release. Existing tags or drafts pointing at another build commit are
rejected, keeping the source archives consistent with the installer payload.
A failed or skipped build cannot publish. All publication remains restricted to
the fork while this workflow is tested for upstream adoption.

## Windows installer behavior

### Velopack

`build-velopack-installer.ps1` packages the Forge output and copies its Setup EXE to
`edhm-ui-v3-windows-x64.exe`, preserving the updater's download name. Desktop shortcut
creation and hotfix paths follow the running executable, including Velopack's `current`
subdirectory. Existing user settings locations are unchanged.

`build-velopack-launcher.ps1` builds a small native **asInvoker** entry point,
`EDHM-UI-V3.Launcher.exe`, with Velopack's official C++ SDK. `vpk --mainExe` points
to this launcher. Install, update, obsolete-version, and uninstall hooks run there
and exit before starting Electron or accessing application settings. This avoids
error 740 without elevating the per-user installer or changing its installation
scope, package ID, folder, or registry ownership.

For ordinary launches, the launcher calls Windows ShellExecuteEx with the `open`
verb and the original arguments and working directory. The existing `EDHM-UI-V3.exe`
keeps its **highestAvailable** manifest: administrators receive the normal consent
prompt; standard users retain the original non-elevated behavior. Cancelling UAC
closes the launcher without retrying or undoing installation. Other launch errors
are reported. The launcher does not force alternate administrator credentials.

The main app executable and its resources keep their names and locations. Only the
launcher and `velopack_libc.dll` are added to the Velopack payload. The free installer
and Linux build do not need this launcher or a JavaScript Velopack dependency.
The native launcher uses MSVC/CMake already available on the hosted Windows runner;
its runtime is linked statically and the SDK DLL depends only on Windows libraries.
For local packaging, install Visual Studio C++ build tools with CMake.

The application still checks GitHub releases and downloads the **full installer**.
This work does not switch it to Velopack's UpdateManager or delta updates. Consequently,
the `.nupkg` and feed are retained in the `velopack-build-packages` Actions artifact,
not attached to the release. The public release still has exactly the three familiar
application downloads plus GitHub's source archives.

Velopack is a different installer family from the legacy MSI. It does not inherit the
MSI upgrade code, maintenance UI, rollback behavior, or uninstall registration.
Matching the existing Velopack package ID is necessary for Velopack-to-Velopack upgrades;
it does not migrate an Advanced Installer/WiX installation automatically. Do not point
Velopack at an old MSI-owned directory as a shortcut to migration. The maintainer's
current Velopack package ID and any local migration customizations are still needed
before claiming compatibility with their existing users.

Official references: [GitHub Actions](https://docs.velopack.io/distributing/github-actions),
[C++ SDK integration](https://docs.velopack.io/getting-started/cpp),
[Setup options](https://docs.velopack.io/reference/cli/content/setup-windows).

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

The free path retains compatibility with the legacy MSI family; Velopack is a separate
installer family and must not be described as interchangeable.
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

[Free installer run 34001691787](https://github.com/Fenris159/EDHM_UI/actions/runs/34001691787)
passed all 32 application tests, 11 release tests, both platform builds, and the full
MSI lifecycle checks below.
[Velopack run 34001691802](https://github.com/Fenris159/EDHM_UI/actions/runs/34001691802)
passed those application/release tests, both platform builds, the native launcher
tests, all four real SDK hooks, full installed payload hashes, registration, shortcut
targets, repeated installation, and uninstallation. Hook tests also verify that no
application settings are created. The same four hooks passed locally without elevation,
where the original direct Electron hook failed with Windows error 740.
[Manual launcher run 34000177845](https://github.com/Fenris159/EDHM_UI/actions/runs/34000177845)
verified dispatch from the fork's default branch with publication disabled.
This does not replace a live upgrade test using the maintainer's existing Velopack installer.

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
The original direct Electron hook was reproduced locally in a non-elevated Windows
session: CreateProcess returned error 740 before the SDK could run. The new native
entry point passes all four real SDK hooks in that same non-elevated session.
`test-velopack-hooks.ps1` provides that repeatable check without installing anything.
Native tests also verify ShellExecute parameters, argument/path preservation, error
propagation, and cancellation without retry. The two old JavaScript bootstrap tests
were replaced by these native checks; the remaining 32 application tests pass.
An interactive Windows 11 consent/cancel test is still needed to verify the visible
secure-desktop experience, alongside upgrading the maintainer's previous installer.

The initial fork test verified Linux ZIP integrity, executable permissions, settings
renderer, and packaged app version. Live Linux installation remains untested.

Before proposing upstream: inspect the successful test run; manually test dialogs,
launch, and files-in-use behavior; validate the existing Velopack upgrade path; configure signing if desired; then agree the publishing
trigger and replace the fork-only repository/branch guards.
