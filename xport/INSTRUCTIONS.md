This is a tutorial on exporting with a custom template, which makes the executable smaller by removing unused features. It might be a bad way of doing things. I can only hope the open-sourcedness of the project will help polish up the workflow eventually.

## Initial setup

This will be needed the first time.

- Clone or fork the Godot repository: https://github.com/godotengine/godot
- Set up scons.
- For each platform you want to export for, read the documentation on how to set up scons for it. For example, https://docs.godotengine.org/en/latest/contributing/development/compiling/compiling_for_windows.html#cross-compiling-for-windows-from-other-operating-systems explains how to setup the windows platform from Linux. Use `scons p=list` to check if the platform is set up.

## Exporting

- While in a CLI, go in the root folder of the Godot source code.
- Sync the local repo. For a minor version, fetching its branch might be necessary, i.e. `git fetch upstream 4.2`
- Find the commit hash of the Godot version GodSVG is using: https://github.com/godotengine/godot/releases
- `git checkout <commit hash>`
- Run the scons command; see below.
- Wait for the compilation to finish. The template will be in the bin directory, but avoid moving it inside the GodSVG project.

For most platforms, to export, you'd need to find the relevant template in your file system to fill in the Custom Template field, then use "Export Project".

For official web exports, web-build/GodSVG.pck should be replaced with the latest .pck using web export and "Export PCK/ZIP". If a new engine version is used, the web-build/GodSVG.wasm file must be updated too.

## Commands

Profile path should be adjusted

- `scons p=linuxbsd arch=x86_64 profile=../GodSVG/xport/custom.py`

- `scons p=windows arch=x86_64 profile=../GodSVG/xport/custom.py`

- `scons p=web arch=wasm32 javascript_eval=no profile=../GodSVG/xport/custom.py`

## Misc:

`scons --help` on the godot source lists its modules.

