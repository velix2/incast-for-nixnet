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
          n = 10;
          mkClient = i: {
            nodes.${"client${toString i}"} = {
              packages = [ incast ];
              networking.interfaces.${"eth${toString (i + 1)}"}.ipv4.addresses = [
                {
                  address = "10.0.0.${toString (i + 1)}";
                  prefixLength = 24;
                }
              ];
              scripts.main = {
                exec =
                  ''
                    echo "10.0.0.1" > server_names.txt
                    sleep 1
                    client 1 server_names.txt 65125 1000 100 100 | tee ./stdout.txt
                  '';
                await = true;
              };
            };
            veths.${"eth${toString (i + 1)}"} = {
              a.node = "client${toString i}";
              b.node = "br0";
            };
          };
          serverSet =
          {
            nodes.server = {
            packages = [ incast ];
              networking.interfaces.${"eth0"}.ipv4.addresses = [
                {
                  address = "10.0.0.1";
                  prefixLength = 24;
                }
              ];
              scripts.main = {
                exec =
                  ''
                    echo test
                    server
                  '';
                foreground = true;
                await = true;
              };
            };
            veths."eth0" = {
              a.node = "server";
              b.node = "br0";
            };
          };

          nodeList = [ serverSet ] ++ map mkClient (lib.range 1 n);
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