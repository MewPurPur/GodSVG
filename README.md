# GodSVG

![image](https://user-images.githubusercontent.com/85438892/273739933-717e67dc-e944-4d12-bcce-3dfd70196ff3.png)

GodSVG is an application in very early development built with Godot for creating optimized Scalable Vector Graphics (SVG) files. It is specifically designed for programmers, allowing them to easily edit individual SVG elements and view the corresponding code in real-time.
GodSVG is inspired by the need for an editor for programmers that produces optimized SVG without using unnecessary attributes or metadata.

## Features

- **Interactive SVG editing:** Modify individual elements of a SVG file using a user-friendly interface.
- **Real-time code:** As you manipulate elements in the UI, you can instantly view generated code and even edit it.
- **Optimized SVG output:** Generate clean and efficient SVG files. _(Planned: Ways to minify the output)_

| Name | Support level | Notes |
| --- | --- | --- |
| circle | Supported | |
| clipPath | Not yet supported | Probably never, will evaluate later |
| ellipse | Supported | |
| g | Not yet supported | |
| line | Supported |
| linearGradient | Not yet supported | |
| mask | Not yet supported | |
| path | Supported | |
| polygon | Not yet supported | May not support directly |
| polyline | Not yet supported | May not support directly |
| radialGradient | Not yet supported | |
| rect | Supported | |
| stop | Not yet supported | |

All other elements are currently not planned.

## Installation

Currently, there are no pre-built binaries available for GodSVG. However, you can still run it by following these steps:

1. Clone the repository: `git clone https://github.com/MewPurPur/GodSVG.git`
2. Open the project in the Godot Engine.
3. Build and run the project within the Godot Engine editor.

## Contributing

Contributions to GodSVG are very welcome! To do so, do the following:

1. Fork the repository.
2. Create a new branch: `git checkout -b implement-gradients`
3. Make your modifications.
4. Commit your changes: `git commit -m "Implement linear gradients"`
5. Push to the branch: `git push origin implement-gradients`
6. Create a new pull request and describe your changes in detail.

Since the app is in early development, tidiness is not as important as work being done, so feel free to use a different PR workflow you're comfortable with.
To report bugs, use Github's issue form. Before contributing features, please make sure to first post a proposal in Issues and have it approved.

## License

GodSVG is licensed under the MIT License.
