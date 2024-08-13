{
  description = "Obsidian wrapper with Python";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    resnap.url = "github:404wolf/nix-resnap";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        reSnap = inputs.resnap.packages.${system};
      in rec {
        packages = rec {
          default = obsidian;
          obsidian = pkgs.symlinkJoin {
            name = "obsidian";
            paths = [pkgs.obsidian reSnap.reSnap reSnap.postProcess];
            buildInputs = [pkgs.makeWrapper];
            postBuild = ''
              wrapProgram $out/bin/obsidian \
                --set PATH $PATH:${pkgs.lib.makeBinPath [
                reSnap.reSnap
                reSnap.postProcess
                pkgs.openssh
                pkgs.git
              ]}
            '';
          };
        };

        apps.default = flake-utils.lib.mkApp {
          drv = packages.default;
        };
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.feh
            reSnap.reSnap
            reSnap.postProcess
          ];
          inputsFrom = [
            reSnap.reSnap
            reSnap.postProcess
          ];
        };
      }
    );
}
