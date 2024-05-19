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

For official web exports, after this is done, you'll get a lot of files. Normally, only `web-build/GodSVG.pck` needs to be changed to the new .pck file between builds. `web-build/GodSVG.wasm` file may need to be updated too if there's a new version of Godot.

If web exports need to be tested without pushing any changes to the repository, you should run `python3 -m http.server` to run a local server inside the root folder (it won't have any effect on the git repository) and then visit the `http://localhost:8000/web-build/` URL.

## Commands

Profile path should be adjusted

- `scons p=linuxbsd arch=x86_64 optimize=speed profile=../GodSVG/xport/custom.py`

- `scons p=windows arch=x86_64 optimize=speed profile=../GodSVG/xport/custom.py`

- `scons p=web arch=wasm32 optimize=size javascript_eval=no profile=../GodSVG/xport/custom.py`

(If the web one doesn't work, type it out - currently that's `scons p=web arch=wasm32 javascript_eval=no target=template_release lto=full production=yes dev_build=no optimize=size deprecated=no minizip=no brotli=no vulkan=no openxr=no use_volk=no disable_3d=yes modules_enabled_by_default=no module_freetype_enabled=yes module_gdscript_enabled=yes module_svg_enabled=yes module_jpg_enabled=yes module_text_server_adv_enabled=yes graphite=no module_webp_enabled=yes`)

## Misc:

`scons --help` on the godot source lists its modules.

