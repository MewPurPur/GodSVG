# GodSVG

<p align="center">
  <img src="visual/splash.svg" width="480" alt="GodSVG logo">
</p>

**GodSVG is an editor for Scalable Vector Graphics (SVG) files.** Unlike other editors, it represents the SVG code directly, doesn't add any metadata, and even lets you edit the SVG code in real time. GodSVG is inspired by the need for an SVG editor without abstractions that produces clean and optimized SVG files.

>[!IMPORTANT]
>GodSVG is not officially released, it's currently in late alpha.
>
>GodSVG is almost entirely made by my work in my free time. If you like this project and want to help secure it through its development, you can use GitHub Sponsorship and make it a less financially stupid endeavor for me.

## Features

- **Interactive SVG editing:** Modify individual elements of an SVG file using a user-friendly interface.
- **Real-time code:** As you manipulate elements in the UI, code is instantly generated and can be edited.
- **Optimized SVGs:** The generated SVG files are small and efficient, and there are many options to assist with optimization.
- **Accessible on mobile:** GodSVG aims to be usable on mobile devices.

![image](https://github.com/MewPurPur/GodSVG/assets/85438892/4c2de628-4284-4d4a-b9de-a8521c2b74a5)

## How to get it

Download the version you want from [the list of GodSVG releases](https://github.com/MewPurPur/GodSVG/releases).

Note that if you're on MacOS, you need to [disable Gatekeeper](https://disable-gatekeeper.github.io/) if you haven't yet. I don't have the time or money to deal with Apple's gatekeeping.

Link to the web build: https://mewpurpur.github.io/GodSVG/web-build (Currently experimental)

To run the latest unreleased version, you can download Godot from https://godotengine.org (development is currently happening in v4.2.2.rc3). After getting the repository files on your machine, you must open Godot, click on the "Import" button, and import the `project.godot` folder. If there are a lot of errors as some people have reported, it's Godot's fault. Try closing and opening the project a few times, changing small things on the code that errors out, etc. until the errors hopefully clear.

## How to use it

Documentation for GodSVG is likely eventually going to be built-in. In the meantime, the basics of using it will be outlined here. This documentation is for the current master, which is a little ahead of the alpha 2 release.

If you want to import an existing graphic from scratch, use the Import button on top of the code editor or drag-and-drop an SVG file into the app.

To add new shapes, press the "+ Add new tag" button, right-click inside the viewport, or right-click inside the tags container. You can then select your shape from the dropdown. After your shape is added, you can drag its handles in the viewport to change its geometry, or modify the attributes in the inspector to change its other properties, like fill and stroke. You can also always modify the SVG code directly.

In the inspector, you can hover each tag's fields to see which attribute they represent. You may select tags in the viewport on the right or the inspector on the left, and right-click to do operations on them such as deleting or moving them. Some of these actions shortcuts, you can find them in the settings menu.

Pathdata attributes have a very complex editor that allows for selecting individual path commands with a lot of similarities to tags. You can right-click the path command and click "Insert After", then pick the one you want. If you're used to SVG paths, you can also use the M, L, H, V, Z, A, Q, T, C, S keys to insert a new path command after a selected one; pressing Shift will also make the new command absolute instead of relative.

Multiple tags or path commands can be selected as usual with Ctrl+Click and Shift+Click. Additionally, double-clicking a path command will select the whole subpath it's in.

To export the graphic, use the Export button on top of the code editor.

## Community and contributing

Contributions are very welcome! GodSVG is built in [Godot](https://github.com/godotengine/godot). For code contributions, read [Contributing Guidelines](CONTRIBUTING.md). Before starting work on features, first propose them by using the issue form and wait for approval.

To report bugs or propose features, use Github's issue form. For more casual discussion around the tool or contributing to it, find me on [GodSVG's Discord](https://discord.gg/R8pM6vXWTY).

## License

GodSVG is licensed under the MIT License:

- You are free to use GodSVG for any purpose. GodSVG's license terms and copyright do not apply to the content created with it.
- You can study how GodSVG works and change it.
- You may distribute modified versions of GodSVG. Derivative products may use a different license, but they must still document that they derive from the MIT-licensed GodSVG.

The above explanation reflects my understanding of my own license terms and does not constitute legal advice.
