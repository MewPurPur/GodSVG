This is a tutorial on exporting with a custom template, which makes the executable smaller by removing unused features.

## Getting the export templates

- Go to the "Actions" tab on Github, find the "export-optimized" workflow, and run it.
- Wait for it to finish.
- Open the workflow file and find the artifact.
- Get all of the export templates that are generated.

## Getting the export templates for Web

I couldn't get Github actions to generate the web template, unfortunately. So the optimized export template has to be compiled manually.

<details>

<summary>Here's how far I got:</summary>

```yaml
  build-web:
    name: Export GodSVG for Web
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Install dependencies
        run: sudo apt-get install -y scons python3

      - name: Install Emscripten
        run: |
          git clone https://github.com/emscripten-core/emsdk.git
          cd emsdk
          ./emsdk install latest
          ./emsdk activate latest
          source ./emsdk_env.sh
        shell: bash

      - name: Clone Godot repository
        run: git clone $GODOT_REPO godot

      - name: Checkout specific commit
        run: |
          cd godot
          git fetch
          git checkout $GODOT_COMMIT_HASH

      - name: Build Godot template for Web
        run: |
          cd godot
          source ../emsdk/emsdk_env.sh
          scons p=web arch=wasm32 ${BUILD_OPTIONS}

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: godot_template_web.zip
          path: godot/bin/godot.web.template_release.wasm32.zip
          if-no-files-found: error
          retention-days: 1
```

</details>

- Clone or fork the Godot repository: https://github.com/godotengine/godot
- While in a CLI, go in the root folder of the Godot source code.
- Set up scons.
- Sync the local repo. For a minor version, fetching its branch might be necessary, i.e. `git fetch upstream 4.2`
- Find the commit hash of the Godot version GodSVG is using: https://github.com/godotengine/godot/releases
- `git checkout <commit hash>`
- Read the documentation on how to set up scons for web: https://docs.godotengine.org/en/latest/contributing/development/compiling/compiling_for_web.html
- Use `scons p=list` to check if the web platform is set up.
- `scons p=web arch=wasm32 target=template_release lto=full production=yes dev_build=no deprecated=no minizip=no brotli=no vulkan=no openxr=no use_volk=no disable_3d=yes modules_enabled_by_default=no module_freetype_enabled=yes module_gdscript_enabled=yes module_svg_enabled=yes module_jpg_enabled=yes module_text_server_adv_enabled=yes graphite=no module_webp_enabled=yes`
- Wait for it to finish. The template will be in the bin directory, but avoid moving it inside the GodSVG project.

## Exporting

- While in a CLI, go in the root folder of the Godot source code.
- Sync the local repo. For a minor version, fetching its branch might be necessary, i.e. `git fetch upstream 4.2`
- Find the commit hash of the Godot version GodSVG is using: https://github.com/godotengine/godot/releases
- `git checkout <commit hash>`
- Run the scons command; see below.

For most platforms, to export, you'd need to find the relevant template in your file system to fill in the Custom Template field, then use "Export Project".

For official web exports, after this is done, you'll get a lot of files. Normally, only `GodSVG.pck` and `GodSVG.wasm` need to be changed between builds.

## Misc:

`scons --help` on the godot source lists its modules.

