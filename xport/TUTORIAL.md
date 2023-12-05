This is a tutorial on exporting with a custom template, which makes the executable smaller by removing unused features. It might be a bad way of doing things. I can only hope the open-sourcedness of the project will help polish up the workflow eventually.

Before compiling custom export templates, a bit of setup will be needed:

- Download Godot's source code. https://github.com/godotengine/godot
- Set up scons.
- For each platform you want to export for, read the documentation on how to set up scons for it. For example, https://docs.godotengine.org/en/latest/contributing/development/compiling/compiling_for_windows.html#cross-compiling-for-windows-from-other-operating-systems explains how to setup the windows platform from Linux. Use `scons p=list` to check if the platform is set up.


Exporting GodSVG:

- While in a CLI, go in the root folder of the Godot source code.
- Find the commit hash of the Godot version GodSVG is using: https://github.com/godotengine/godot/releases
- `git checkout <commit hash>`
- Run the scons command - for example `scons p=linuxbsd profile=../GodSVG/xport/custom.py`.
- Wait for the compilation to finish. The template will be in the bin directory, but avoid moving it inside the GodSVG project.
- While exporting, find the relevant template in your file system to fill in the Custom Template field for each platform.


Misc:

`scons --help` on the godot source lists its modules.
