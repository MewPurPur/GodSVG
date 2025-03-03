# GodSVG

<p align="center">
  <img src="godot_only/source_assets/splash.svg" width="480" alt="GodSVG logo">
</p>

**[GodSVG](https://godsvg.com) is an editor for Scalable Vector Graphics (SVG) files.** Unlike other editors, it represents the SVG code directly, doesn't add any metadata, and even lets you edit the SVG code in real time. GodSVG aims to be an editor for SVG code with low abstraction, producing clean and optimized files.

>[!IMPORTANT]
>GodSVG is not officially released, it's currently in late alpha.
>
>GodSVG is almost entirely made by my work in my free time. If you like this project and want to help secure it through its development, you can donate on one of the platforms listed to the right and make it a less financially stupid endeavor for me.

## Features

- **Interactive SVG editing:** Modify individual elements of an SVG file using a user-friendly interface.
- **Real-time code:** As you manipulate elements in the UI, code is instantly generated and can be edited.
- **Optimized SVGs:** The generated SVG files are small and efficient, and there are many options to assist with optimization.

![usage](https://github.com/user-attachments/assets/51171c0c-cd88-4b69-b1a1-495b3f45f5bf)

## How to get it

Download the version you want from [the list of GodSVG releases](https://github.com/MewPurPur/GodSVG/releases). If you have issues with the download, look for a TROUBLESHOOTING.txt file.

Link to the web editor: https://godsvg.com/editor

To run the latest unreleased version, you can download Godot from https://godotengine.org (development is currently happening in v4.4). After getting the repository files on your machine, you must open Godot, click on the "Import" button, and import the `project.godot` folder. If there are a lot of errors as some people have reported, it's Godot's fault. Try closing and opening the project a few times, changing small things on the code that errors out, etc. until the errors hopefully clear.

## How to use it

Documentation for GodSVG is likely eventually going to be built-in. Meanwhile, the basics of using it will be outlined below.

GodSVG is something between an SVG editor and an assisted code editor for SVG files. SVGs are a text-based format, and to understand how to be efficient with the tool, it would really help to first familiarize with the SVG basics (Check out [the first few tutorials here](https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial/Introduction)).

If you want to import an existing graphic from scratch, use the Import button on top of the code editor or drag-and-drop an SVG file into the app.

To add new shapes, press the "+ Add new element" button, right-click inside the viewport, or right-click inside the elements list. You can then select your shape from the dropdown. After your shape is added, you can drag its handles in the viewport to change its geometry, or modify the attributes in the inspector to change its other properties, like fill and stroke. You can also always modify the SVG code directly.

In the inspector, you can hover each element's fields to see which attribute they represent. You may select elements in the viewport on the right or the inspector on the left, and right-click to do operations on them such as deleting or moving them. Some of these actions shortcuts, you can find them in the settings menu.

Pathdata attributes have a very complex editor that allows for selecting individual path commands with a lot of similarities to elements. You can right-click the path command and click "Insert After", then pick the one you want. If you're used to SVG paths, you can also use the M, L, H, V, Z, A, Q, T, C, S keys to insert a new path command after a selected one; pressing Shift will also make the new command absolute instead of relative.

Multiple elements or path commands can be selected as usual with Ctrl+Click and Shift+Click. Additionally, double-clicking a path command will select the whole subpath it's in.

To export the graphic, use the Export button on top of the code editor.

## Community and contributing

Contributions are very welcome! GodSVG is built in [Godot](https://github.com/godotengine/godot). For code contributions, read [Contributing Guidelines](CONTRIBUTING.md). Before starting work on features, first propose them by using the issue form and wait for approval.

To report bugs or propose features, use Github's issue form. For more casual discussion around the tool or contributing to it, find me on [GodSVG's Discord](https://discord.gg/R8pM6vXWTY).

GodSVG is free for everyone to use however they want. This is not to say that the official communities are anarchy: All of them, including this Github repository, are actively moderated.

## License

GodSVG is licensed under the MIT License:

- You are free to use GodSVG for any purpose.
- Content created in GodSVG is completely yours, as it doesn't contain any of GodSVG's code.
- You may freely study GodSVG's code and modify it for personal use.
- You may use GodSVG's code in your own product and even distribute it under a different license, but you must clearly document that you've derived from the MIT-licensed GodSVG.

The above explanation reflects my understanding of my own license terms and does not constitute legal advice.
