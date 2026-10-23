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
        inherit pkgs incast;
        lib = pkgs.lib;
      };
      mkGraphs = import ./graphing/graphing.nix { inherit pkgs nixnet incast; };
    in
    {
      inherit mkGraphs;
      packages.${system} = {
        default = nixnet.mkExperiment defaultConfig;
        mkAllGraphs =
          let
            experimentAttrs = pkgs.lib.filterAttrs (name: _: pkgs.lib.hasPrefix "incast-" name) mkGraphs;
            experimentScripts = builtins.attrValues experimentAttrs;
          in
          pkgs.writeShellScriptBin "incast-makeAll" (
            pkgs.lib.concatMapStringsSep "\n" (ex: "echo \"Running experiment: ${ex.name}...\"; ${pkgs.lib.getExe ex} > /dev/null 2>&1") experimentScripts
          );

        mermaid = nixnet.mkMermaid defaultConfig;
        mermaid-svg = nixnet.mkMermaidSvg defaultConfig;
      };
    };
}
