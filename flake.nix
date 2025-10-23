{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      commonModule =
        { pkgs, lib, ... }:
        {
          options.programs.godsvg = {
            enable = lib.mkEnableOption "GodSVG editor" // {
              default = true;
            };
            package = lib.mkOption {
              type = lib.types.package;
              default = self.outputs.packages.${pkgs.system}.default;
              defaultText = lib.literalExpression "godsvg";
              description = "The GodSVG package to use";
            };
          };
        };
    in
    flake-utils.lib.eachDefaultSystem (system: {
      packages = {
        godsvg = nixpkgs.legacyPackages.${system}.callPackage ./package.nix { };
        default = self.packages.${system}.godsvg;
      };
    })
    // {
      homeModules.default =
        { config, lib, ... }:
        {
          imports = [ commonModule ];
          config = lib.mkIf config.programs.godsvg.enable {
            home.packages = [ config.programs.godsvg.package ];
          };
        };
      nixosModules.default =
        { config, lib, ... }:
        {
          imports = [ commonModule ];
          config = lib.mkIf config.programs.godsvg.enable {
            environment.systemPackages = [ config.programs.godsvg.package ];
          };
        };
    };
}
