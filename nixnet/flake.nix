{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixnet.url = "github:birneee/nixnet";
    incast.url = "path:/home/felix/incast/app";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = inputs.nixnet.supportedSystems;
      perSystem =
        {
          pkgs,
          inputs',
          lib,
          ...
        }:
        let
          nixnet = inputs'.nixnet.legacyPackages;
          incast = inputs.incast.packages."x86_64-linux".default;
          n = 2;

          mkAddress = i: "10.${toString (i / (254 * 254))}.${toString (i / 254)}.${toString ((lib.mod i 254) + 1)}";

          mkServer = i: {
            nodes."server${toString i}" = {
              packages = [ incast ];
              networking.interfaces.${"eth${toString (i + 1)}"} = { 
                ipv4.addresses = [
                  {
                    address = mkAddress i;
                    prefixLength = 8;
                  }
                ];
                netem.delayMs = 50;
              };
              scripts.main = {
                exec =
                  ''
                    echo "Starting server on address ${mkAddress i}"
                    server
                  '';
                await = false;
              };
              workDir = null;
            };
            veths.${"eth${toString (i + 1)}"} = {
              a.node = "server${toString i}";
              b.node = "br0";
            };
          };
          clientSet =
          {
            nodes.client = {
            packages = [ incast ];
              networking.interfaces."eth0" = { 
                ipv4.addresses = [
                  {
                    address = "10.0.0.1";
                    prefixLength = 8;
                  }
                ];
                netem.delayMs = 50;
              };
              scripts.main = {
                exec =
                  let serverNamesFile = pkgs.writeText "server_names.txt" 
                  (builtins.concatStringsSep "\n" (map mkAddress (lib.range 1 n)));
                  in
                  ''
                    sleep 1
                    client ${toString n} ${serverNamesFile} 65125 1000 100 100 | tee ./stdout.txt
                  '';
                foreground = true;
                await = true;
              };
            };
            veths."eth0" = {
              a.node = "client";
              b.node = "br0";
            };
          };

          nodeList = [ clientSet ] ++ map mkServer (lib.range 1 n);
          config = {
            arp = true;
            bridges = [ "br0" ];
            nodes = lib.mergeAttrsList (map (node: node.nodes) nodeList);
            veths = lib.mergeAttrsList (map (node: node.veths) nodeList);
          };
        in
        {
          packages.default = nixnet.mkExperiment config;
          packages.mermaid = nixnet.mkMermaid config;
          packages.mermaid-svg = nixnet.mkMermaidSvg config;
        };
    };
}