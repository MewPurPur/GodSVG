{
  pkgs,
  system,
  lib,
  ...
}:

let
  godot = pkgs.godot_4_5;

  presets = {
    "x86_64-linux" = "Linux";
    "aarch64-darwin" = "macOS";
  };
  preset = presets.${system};
in

pkgs.stdenv.mkDerivation {
  pname = "godsvg";
  version = "1.0-alpha11";
  src = ./.;

  strictDeps = true;
  nativeBuildInputs = [
    godot
    pkgs.makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    # Cannot create file `/homeless-shelter/.config/godot/projects/...`
    export HOME=$TMPDIR
    # Link the export-templates to the expected location. The `--export` option expects the templates in the home directory.
    mkdir -p $HOME/.local/share/godot
    ln -s ${godot}/share/godot/templates $HOME/.local/share/godot

    mkdir -p $out/share/godsvg
    godot4 --headless --export-pack ${preset} $out/share/godsvg/godsvg.pck
    makeWrapper ${godot}/bin/godot4 $out/bin/godsvg \
    --add-flag "--main-pack" \
    --add-flag "$out/share/godsvg/godsvg.pck"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/applications/
    install -Dm644 ./assets/logos/icon.svg $out/share/icons/hicolor/scalable/apps/godsvg.svg
    install -Dm644 ./assets/logos/icon.png $out/share/icons/hicolor/256x256/apps/godsvg.png
    install -Dm644 ./assets/GodSVG.desktop $out/share/applications/GodSVG.desktop

    runHook postInstall
  '';

  meta = {
    homepage = "https://www.godsvg.com/";
    description = "A vector graphics application for structured SVG editing.";
    changelog = "https://www.godsvg.com/releases/";
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    mainProgram = "godsvg";
  };
}
