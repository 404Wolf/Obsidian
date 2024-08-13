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
        reSnap = inputs.resnap.packages.${system}.reSnap;
        python = pkgs.python3.withPackages (ps:
          with ps; [
            numpy
            pillow
            scikit-image
            scipy
            opencv4
          ]);
        postProcess = pkgs.writeShellScriptBin "postProcess" ''
          ${python}/bin/python3 ${./postprocess.py} $@
        '';
      in rec {
        packages = rec {
          default = obsidian;
          obsidian = pkgs.symlinkJoin {
            name = "obsidian";
            paths = [pkgs.obsidian reSnap postProcess];
            buildInputs = [pkgs.makeWrapper];
            postBuild = ''
              wrapProgram $out/bin/obsidian \
                --set PATH $PATH:${pkgs.lib.makeBinPath [
                reSnap
                postProcess
                pkgs.openssh
              ]}
            '';
          };
          inherit postProcess;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = packages.default;
        };
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.feh
            reSnap
            python
            postProcess
          ];
        };
      }
    );
}
