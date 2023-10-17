# GodSVG

![image](https://user-images.githubusercontent.com/85438892/275994100-90544358-5d7a-415b-b6d9-ebbf01c9b4bd.png)

GodSVG is an application in early development built with Godot for creating optimized Scalable Vector Graphics (SVG) files. It is mainly designed for programmers, allowing them to easily edit individual SVG elements and view the corresponding code in real-time.
GodSVG is inspired by the need for a SVG editor without abstractions that produces optimized SVG without unnecessary attributes or metadata.

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
| linearGradient | Planned soon | |
| mask | Not yet supported | |
| path | Supported | |
| polygon | Not yet supported | May not support directly |
| polyline | Not yet supported | May not support directly |
| radialGradient | Planned soon | |
| rect | Supported | |
| stop | Planned soon | |

All other elements are currently not planned.

## Installation

Currently, there are no pre-built binaries available for GodSVG. However, you can still run it by following these steps:

1. Clone the repository: `git clone https://github.com/MewPurPur/GodSVG.git`
2. Open the project in Godot Engine. (4.2.dev5 minimum needed)
3. Build and run the project within the Godot Engine editor.

## Contributing

Contributions to GodSVG are very welcome! To do so, do the following:

1. Fork the repository.
2. Create a new branch: `git checkout -b implement-gradients`
3. Make your modifications, add them with `git add .`
4. Commit your changes: `git commit -m "Implement linear gradients"`
5. Push to the branch: `git push origin implement-gradients`
6. Create a new pull request and describe your changes in detail.

This is the preferred workflow, but tidiness is not as important as work being done, so feel free to do whatever you're comfortable with.
To report bugs, use Github's issue form. Before contributing a feature, please make sure to first propose it in Issues and have it approved.

## License

GodSVG is licensed under the MIT License:

- You are free to use GodSVG for any purpose. GodSVG's license terms and copyright do not apply to the content created with it.
- You can study how GodSVG works and change it.
- You may distribute modified versions of GodSVG. Derivative products may use a different license, but they must still document that they derive from the MIT-licensed GodSVG.
