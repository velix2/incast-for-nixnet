{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixnet.url = "github:birneee/nixnet";
    incast.url = "path:../app";
  };

  outputs =
    inputs:
      let
        system = "x86_64-linux";
        pkgs = import inputs.nixpkgs { inherit system; };
        nixnet = inputs.nixnet.legacyPackages.${system};
        incast = inputs.incast.packages.${system}.default;
        
        defaultConfig = import ./experiment.nix { 
          inherit pkgs nixnet incast;
          lib = pkgs.lib;
        };
      in
      {
        packages.${system} = {
          default = nixnet.mkExperiment defaultConfig;
          mkGraphs = import ./graphing/graphing.nix { inherit pkgs nixnet incast; };
          mermaid = nixnet.mkMermaid defaultConfig;
          mermaid-svg = nixnet.mkMermaidSvg defaultConfig;
        };
      };
}