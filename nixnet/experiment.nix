{
  pkgs,
  lib,
  nixnet,
  incast,
  
  n ? 16,
  blocks ? 200,
  blockSizeBytes ? 1000000, # divided by n, it must be multiple of 1000  
  rtoMinUs ? 200000,
  bufferSizeKB ? 32,

  measureRtt ? false,
  writeClientCapture ? false,
}:
let 
  mkAddress = i: "10.${toString (i / (254 * 254))}.${toString (i / 254)}.${toString ((lib.mod i 254) + 1)}";

  mkServer = i:
  let address = mkAddress i; in
  {
    nodes."server${toString i}" = {
      packages = [ incast ];
      networking.interfaces.${"eth${toString i}"} = { 
        ipv4.addresses = [
          {
            inherit address;
            prefixLength = 8;
          }
        ];
      };
      scripts.main = {
        exec =
          ''
            echo "Starting server on address ${address}"
            server > /dev/null
          '';
        await = false;
      };
      workDir = null;
    };
    veths."eth${toString i}" = {
      a.node = "server${toString i}";
      b.node = "br0";
      netem.rateMbit = 1000;
      netem.limit = bufferSizeKB * 1000 / 1500; # roughly simulates buffer size
      ethtool = {
        tcpSegmentationOffload = false;
        genericSegmentationOffload = false;
        genericReceiveOffload = false;
      };
    };
  };

  clientConfig =
  {
    nodes.client = {
    packages = [ incast ] ++ lib.optional measureRtt pkgs.iputils  ++ lib.optional writeClientCapture pkgs.tcpdump;
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
          stripeUnit = (((blockSizeBytes / n) + 500) / 1000) * 1000; # round to nearest 1000
          in
          lib.optionalString measureRtt ''
            ping -c 5 10.0.0.2 | grep "rtt" | tee ./rtt.txt
          '' +
          lib.optionalString writeClientCapture ''
            tcpdump -i eth0 -w capture.cap &
            TD_PID=$!
            cleanup() {
              kill $TD_PID
              wait $TD_PID
            }
            trap cleanup EXIT
          '' +
          ''
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
      netem.limit = bufferSizeKB * 1000 / 1500; # roughly simulates buffer size
      ethtool = {
        tcpSegmentationOffload = false;
        genericSegmentationOffload = false;
        genericReceiveOffload = false;
      };
    };
  };

nodeList = [ clientConfig ] ++ map mkServer (lib.range 1 n);
in
{
  arp = true;
  arpPrefill = true;
  mtu = 1500;
  sysctl = {
      "net.ipv4.tcp_rto_min_us" = rtoMinUs;
      "net.ipv4.tcp_rmem" = "${toString (8 * 1024)} 87380 ${toString (4 * 1024 * 1024)}"; # Old 2.6.28 kernel parameters - 8KiB, 87380B, 4MiB
      "net.ipv4.tcp_early_retrans" = 0; # disables TCP TLP
      "net.ipv4.tcp_autocorking" = 0; # disables TCP autocorking
  };
  bridges = [ "br0" ];
  nodes = lib.mergeAttrsList (map (node: node.nodes) nodeList);
  veths = lib.mergeAttrsList (map (node: node.veths) nodeList);
}