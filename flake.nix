{
  description = "Independent packages for experimental Wayland compositors";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zwwm = {
      url = "github:binarylinuxx/zwwm/3f50507155fabe7701c651eec31db499d694cdff";
      flake = false;
    };
    shojiwm = {
      url = "github:bea4dev/ShojiWM/3fef0c862caab18332947f5e4ede83ff446312a7";
      flake = false;
    };
    driftwm = {
      url = "github:malbiruk/driftwm/352333a8fa1b22171492d4b71a54102045c9a19d";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, zwwm, shojiwm, driftwm }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      overlays.default = final: _: {
        zwwm = final.callPackage ./pkgs/zwwm.nix { src = zwwm; };
        shojiwm = final.callPackage ./pkgs/shojiwm.nix { src = shojiwm; };
        driftwm = final.callPackage ./pkgs/driftwm.nix { src = driftwm; };
      };

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          inherit (pkgs) zwwm shojiwm driftwm;
          default = pkgs.zwwm;
        });
    };
}
