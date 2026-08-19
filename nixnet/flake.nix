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
        
        config = import ./experiment.nix { 
          inherit pkgs nixnet incast;
          lib = pkgs.lib;
        };
      in
      {
        packages.${system} = {
          default = nixnet.mkExperiment config;
          mermaid = nixnet.mkMermaid config;
          mermaid-svg = nixnet.mkMermaidSvg config;
        };
      };
}