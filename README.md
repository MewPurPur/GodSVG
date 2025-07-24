# GodSVG

<p align="center">
  <img src="godot_only/source_assets/splash.svg" width="480" alt="GodSVG logo">
</p>

**[GodSVG](https://godsvg.com) is a structured SVG editor.** Unlike other editors, GodSVG represents the SVG code directly, doesn't add any metadata, and even lets you edit the code in real time. It aims to be a structured SVG editor with low abstraction, producing clean, precise, optimized files.

>[!IMPORTANT]
>GodSVG is not officially released, it's currently in late alpha.
>
>GodSVG is almost entirely made by my work in my free time. If you like this project and want to help secure it through its development, you can donate on one of the platforms listed to the right and make it a less financially stupid endeavor for me.

## Features

- **Interactive SVG editing:** Modify individual elements of an SVG file using a user-friendly interface.
- **Real-time code:** As you manipulate elements in the UI, code is instantly generated and can be edited. Generated code is human-readable, since no metadata is added.
- **Optimized SVGs:** The generated SVG files are small and efficient, and GodSVG provides various options to assist with optimization.

![image](https://github.com/user-attachments/assets/d40e4de8-12ba-483b-ac41-878047c8e4f7)

## Downloads and links

Download the version you want from [the list of GodSVG releases](https://github.com/MewPurPur/GodSVG/releases). Android versions are currently experimental. For MacOS, you'll have to [disable Gatekeeper](https://disable-gatekeeper.github.io/), as I don't have the time or money to deal with Apple's gatekeeping.

To verify the APK signature of the experimental Android build, check if the release APK is signed with the correct certificate by comparing the following fingerprints:
```
SHA1: BC:78:C1:A1:90:B4:5E:5A:13:49:4C:07:22:2E:F5:0B:5D:88:5E:5B
SHA256: 68:39:C3:D4:9B:74:DF:30:C5:0B:32:B8:81:04:05:A7:45:80:7B:D5:A8:0B:64:D1:9A:46:89:38:28:5A:DB:5D
```

You can use this command to display the certificate details, including the SHA-1 and SHA-256 fingerprints:
```
keytool -printcert -jarfile <APK-file>
```

GodSVG also runs on web - here's a link to the official web editor: https://godsvg.com/editor

To run the latest unreleased version, you can download Godot from https://godotengine.org (development is currently happening in v4.5 beta 3). After getting the repository files on your machine, you must open Godot, click on the "Import" button, and import the `project.godot` folder.

Another way to run the latest dev build is to open a recent commit and download its artifacts (Checks > export-optimized > Summary > Artifacts). You must log into Github for that.

To report bugs or propose features, look through the open Github issues to see if it's already been discussed, and if not, [create a new issue](https://github.com/MewPurPur/GodSVG/issues/new/choose).

For more casual discussion around the tool or contributing to it, find me on [GodSVG's Discord](https://discord.gg/R8pM6vXWTY). All official communities are actively moderated.

## How to use it

Documentation for GodSVG is likely eventually going to be built-in. Meanwhile, the basics of using it will be outlined below.

GodSVG is something between an SVG editor and an assisted code editor for SVG files. SVGs are a text-based format, and to understand how to be efficient with the tool, it would really help to first familiarize with the SVG basics (Check out [the first few tutorials here](https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial/Introduction)).

To add new elements (shape, group, gradient...), press the "+ Add new element" button, right-click inside the viewport to add shapes, or right-click inside the elements list. You can then select from the dropdown. You can manipulate the geometry of shapes in the viewport, or in the elements list where you can also change its other properties, like fill and stroke. You can also always modify the SVG code directly.

In the inspector, you can hover each element's fields to see which attribute they represent. You may select elements in the viewport on the right or the elements list on the left, and right-click to do operations on them such as deleting or moving them. You can also find and configure all available shortcuts in the Settings menu.

Pathdata attributes have a more complex editor that allows for selecting individual path commands with a lot of similarities to elements. You can right-click the path command and click "Insert After", then pick the one you want. If you're used to SVG paths, you can also use the M, L, H, V, Z, A, Q, T, C, S keys to insert a new path command after a selected one; pressing Shift will also make the new command absolute instead of relative.

Multiple elements or path commands can be selected as usual with Ctrl+Click and Shift+Click. Additionally, double-clicking a path command will select the whole subpath it's in.

## License

GodSVG is licensed under the MIT License:

- You are free to use GodSVG for any purpose.
- Content created in GodSVG is completely yours, as it doesn't contain any of GodSVG's code.
- You may freely study GodSVG's code and modify it for personal use.
- You may use GodSVG's code in your own product and even distribute it under a different license, but you must clearly document that you've derived from the MIT-licensed GodSVG.

The above explanation reflects my understanding of my own license terms and does not constitute legal advice.
