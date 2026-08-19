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
          
          n = 16;
          blocks = 200;
          blockSizeBytes = 1040000; # divided by n, it must be multiple of 1000  

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
              };
              scripts.main = {
                exec =
                  ''
                    echo "Starting server on address ${mkAddress i}"
                    server > /dev/null
                  '';
                await = false;
              };
              workDir = null;
            };
            veths."eth${toString (i + 1)}" = {
              a.node = "server${toString i}";
              b.node = "br0";
              netem.rateMbit = 1000;
              netem.limit = 22; # roughly simulates 32 KB buffer
            };
          };
          clientConfig =
          {
            nodes.client = {
            packages = [ incast pkgs.iputils ];
              networking.interfaces."eth0" = { 
                ipv4.addresses = [
                  {
                    address = "10.0.0.1";
                    prefixLength = 8;
                  }
                ];
              };
              scripts.main = {
                exec =
                  let serverNamesFile = pkgs.writeText "server_names.txt" 
                  (builtins.concatStringsSep "\n" (map mkAddress (lib.range 1 n)));
                  stripeUnit = blockSizeBytes / n;
                  in
                  ''
                    ping -c 5 10.0.0.2 | grep "rtt" | tee ./rtt.txt
                    sleep 1
                    # client [num of servers] [server names file] [port] [stripe unit] [server request unit] [num blocks]
                    client ${toString n} ${serverNamesFile} 65125 ${toString stripeUnit} 1 ${toString blocks} | tee ./stdout.txt   
                  '';
                foreground = true;
                await = true;
              };
            };
            veths."eth0" = {
              a.node = "client";
              b.node = "br0";
              netem.rateMbit = 1000;
              netem.limit = 22; # roughly simulates 32 KB buffer
            };
          };

          nodeList = [ clientConfig ] ++ map mkServer (lib.range 1 n);
          config = {
            arp = true;
            arpPrefill = true;
            sysctl = {
               "net.ipv4.tcp_rto_min_us" = 200000;
            };
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