# Fork packaging test

The `Package release (fork test)` workflow builds the same three asset names as
[upstream v3.0.70](https://github.com/BlueMystical/EDHM_UI/releases/tag/v3.0.70):

- `edhm-ui-v3-windows-x64.exe`: the existing Advanced Installer project and UI.
- `edhm-ui-v3-linux-x64.zip`: contains `edhm-ui-v3-linux-x64/edhm-ui-v3` and its resources.
- `linux_installer.sh`: the existing installer script, with Unix line endings.

The version comes from `source_v3/package.json`. The workflow checks the lockfile,
sets the Windows installer version automatically, and labels the artifacts with
the detected version. Advanced Installer generates a new product code when its
version changes and retains the existing upgrade code.

Push to `codex/release-workflow-test` to run it in `Fenris159/EDHM_UI`. Download both
artifacts from the Actions run page and extract their outer artifact ZIPs. Place
the Linux ZIP and shell script together, as described in upstream's release.
Artifacts expire after 14 days. The workflow does not create tags, releases, or PRs.
Manual dispatch is available once the workflow exists on the fork's default branch.

The Windows test installer is unsigned. The author's workstation signing settings
are removed only from the generated CI project. Set the `ADVINST_LICENSE_KEY`
Actions secret for a licensed build; never put the key in source. The optional
`ADVINST_VERSION` repository variable selects a licensed version (default 18.8.1,
matching the checked-in project). Without a license, the vendor's trial restrictions
apply; trial-built packages are for evaluation, not production distribution.

CI synchronizes the package folder into a copy of the installer project, so changed
shader archive names, new resources, and Vite asset hashes do not need manual edits.
The original project is retained. Linux uses the active Forge plugins, including
the settings renderer, with the executable and folder names expected by the shell
installer. No Windows installation or live-game changes run on CI.

Before proposing this upstream: test install, launch, upgrade and uninstall on Windows,
and test the shell installer on Linux; configure a suitable Advanced Installer license
and signing; then agree the publishing trigger and replace the fork-only repository
and branch guards. Keep this experiment out of the EDHM v22.02 application PR.
