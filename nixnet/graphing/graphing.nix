{
  pkgs,
  nixnet,
  incast,
}:
let
  mkConfig =
    {
      blockSizeBytes,
      n,
      rto,
      quickack,
      linkspeed ? 1000,
      useSysctl ? true,
      disableOffloading ? true,
      mtu ? 1500
    }:
    (import ../experiment.nix {
      inherit
        pkgs
        incast
        n
        blockSizeBytes
        quickack
        linkspeed
        useSysctl
        disableOffloading
        mtu
        ;
      rtoMinUs = rto;
      lib = pkgs.lib;
    })
    // {
      workDir = "out-graphs/{run}/${toString n}-servers/rto${toString rto}";
    };
  mkCommand =
    {
      blockSizeBytes,
      n,
      rto,
      quickack,
      linkspeed ? 1000,
      useSysctl ? true,
      disableOffloading ? true,
      mtu ? 1500
    }@params:
    ''
      ${pkgs.lib.getExe (nixnet.mkExperiment (mkConfig params))} $@
        grep -h 'Goodput' out-graphs/*/${toString n}-servers/rto${toString rto}/client/stdout.txt | sed 's/^/Server Count = ${toString n}, RTOmin = ${toString rto}: /' >> out-graphs/summary.txt
    '';
  python3 = pkgs.python3.withPackages (ps: with ps; [ matplotlib ]);
  rtoStepsFig23 = [
    200
    1000
    5000
    10000
    50000
    100000
    200000
  ];
  serverCountsFig2 = [
    4
    8
    16
    32
    64
    128
  ];
  serverCountsFig3 = [
    4
    8
    16
  ];

  rtoStepsFig9 = [
    1
    5000
    200000
  ];
  serverCountsFig9_14 = pkgs.lib.range 1 16;
in
{
  incast-figure-2 = pkgs.writeShellScriptBin "incast-figure-2" (
    "rm -rf out-graphs && mkdir -p out-graphs"
    + "\n"
    + (builtins.concatStringsSep "\n" (
      builtins.concatMap (
        n:
        map (
          rto:
          mkCommand {
            blockSizeBytes = 1000000;
            n = n;
            rto = rto;
            quickack = false;
          }
        ) rtoStepsFig23
      ) serverCountsFig2
    ))
    + "\n"
    + "${python3}/bin/python3 ${./recreate-figure-2.py}"
  );

  plot-figure-2 = pkgs.writeShellScriptBin "plot-figure-2" (
    "${python3}/bin/python3 ${./recreate-figure-2.py}"
  );

  incast-figure-3-base = pkgs.writeShellScriptBin "incast-figure-3-base" (
    "rm -rf out-graphs && mkdir -p out-graphs"
    + "\n"
    + (builtins.concatStringsSep "\n" (
      builtins.concatMap (
        n:
        map (
          rto:
          mkCommand {
            blockSizeBytes = 1000000;
            n = n;
            rto = rto;
            quickack = false;
            useSysctl = false;
            disableOffloading = false;
          }
        ) rtoStepsFig23
      ) serverCountsFig3
    ))
    + "\n"
    +  "${python3}/bin/python3 ${./recreate-figure-3.py} base-figure-3-output_servers_rto_vs_goodput.png"
  );

  plot-figure-3-base = pkgs.writeShellScriptBin "plot-figure-3-base" (
    "${python3}/bin/python3 ${./recreate-figure-3.py} base-figure-3-output_servers_rto_vs_goodput.png"
  );

  incast-figure-3-no-offloading = pkgs.writeShellScriptBin "incast-figure-3-no-offloading" (
    "rm -rf out-graphs && mkdir -p out-graphs"
    + "\n"
    + (builtins.concatStringsSep "\n" (
      builtins.concatMap (
        n:
        map (
          rto:
          mkCommand {
            blockSizeBytes = 1000000;
            n = n;
            rto = rto;
            quickack = false;
            useSysctl = false;
            disableOffloading = true;
          }
        ) rtoStepsFig23
      ) serverCountsFig3
    ))
    + "\n"
    +  "${python3}/bin/python3 ${./recreate-figure-3.py} no-offloading-figure-3-output_servers_rto_vs_goodput.png"
  );

  plot-figure-3-no-offloading = pkgs.writeShellScriptBin "plot-figure-3-no-offloading-with-sysctl" (
    "${python3}/bin/python3 ${./recreate-figure-3.py} no-offloading-figure-3-output_servers_rto_vs_goodput.png"
  );

  incast-figure-3-no-offloading-with-sysctl = pkgs.writeShellScriptBin "incast-figure-3-no-offloading-with-sysctl" (
    "rm -rf out-graphs && mkdir -p out-graphs"
    + "\n"
    + (builtins.concatStringsSep "\n" (
      builtins.concatMap (
        n:
        map (
          rto:
          mkCommand {
            blockSizeBytes = 1000000;
            n = n;
            rto = rto;
            quickack = false;
            useSysctl = true;
            disableOffloading = true;
          }
        ) rtoStepsFig23
      ) serverCountsFig3
    ))
    + "\n"
    +  "${python3}/bin/python3 ${./recreate-figure-3.py} no-offloading-with-sysctl-figure-3-output_servers_rto_vs_goodput.png"
  );

  plot-figure-3-no-offloading-with-sysctl = pkgs.writeShellScriptBin "plot-figure-3-jumbo-frames" (
    "${python3}/bin/python3 ${./recreate-figure-3.py} no-offloading-with-sysctl-figure-3-output_servers_rto_vs_goodput.png"
  );

    incast-figure-3-jumbo-frames = pkgs.writeShellScriptBin "incast-figure-3-jumbo-frames" (
    "rm -rf out-graphs && mkdir -p out-graphs"
    + "\n"
    + (builtins.concatStringsSep "\n" (
      builtins.concatMap (
        n:
        map (
          rto:
          mkCommand {
            blockSizeBytes = 1000000;
            n = n;
            rto = rto;
            quickack = false;
            useSysctl = true;
            disableOffloading = true;
            mtu = 9000;
          }
        ) rtoStepsFig23
      ) serverCountsFig3
    ))
    + "\n"
    +  "${python3}/bin/python3 ${./recreate-figure-3.py} jumbo-frames-figure-3-output_servers_rto_vs_goodput.png"
  );

  plot-figure-3-jumbo-frames = pkgs.writeShellScriptBin "plot-figure-3-no-offloading" (
    "${python3}/bin/python3 ${./recreate-figure-3.py} jumbo-frames-figure-3-output_servers_rto_vs_goodput.png"
  );

  incast-figure-9 = pkgs.writeShellScriptBin "incast-figure-9" (
    "rm -rf out-graphs && mkdir -p out-graphs"
    + "\n"
    + (builtins.concatStringsSep "\n" (
      builtins.concatMap (
        n:
        map (
          rto:
          mkCommand {
            blockSizeBytes = 1000000;
            n = n;
            linkspeed = 1000;
            quickack = true;
            rto = rto;
          }
        ) rtoStepsFig9
      ) serverCountsFig9_14
    ))
    + "\n"
    + "${python3}/bin/python3 ${./recreate-figure-9.py}"
  );

  incast-figure-9-low-bandwidth = pkgs.writeShellScriptBin "incast-figure-9-low-bandwidth" (
    "rm -rf out-graphs && mkdir -p out-graphs"
    + "\n"
    + (builtins.concatStringsSep "\n" (
      builtins.concatMap (
        n:
        map (
          rto:
          mkCommand {
            blockSizeBytes = 1000000;
            n = n;
            linkspeed = 250;
            quickack = true;
            rto = rto;
          }
        ) rtoStepsFig9
      ) serverCountsFig9_14
    ))
    + "\n"
    + "${python3}/bin/python3 ${./recreate-figure-9-low-bandwidth.py}"
  );

  plot-figure-9 = pkgs.writeShellScriptBin "plot-figure-9" (
    "${python3}/bin/python3 ${./recreate-figure-9.py}"
  );

  plot-figure-9-low-bandwidth = pkgs.writeShellScriptBin "plot-figure-9-low-bandwidth" (
    "${python3}/bin/python3 ${./recreate-figure-9-low-bandwidth.py}"
  );


  incast-figure-14 = pkgs.writeShellScriptBin "incast-figure-14" (
    "rm -rf out-graphs && mkdir -p out-graphs"
    + "\n"
    + (builtins.concatStringsSep "\n" (
      builtins.concatMap (
        n:
        map
          (quickack: ''
            ${
              pkgs.lib.getExe (
                nixnet.mkExperiment (
                  (import ../experiment.nix {
                    inherit
                      pkgs
                      incast
                      n
                      quickack
                      ;
                    rtoMinUs = 1;
                    blockSizeBytes = 1000000;
                    lib = pkgs.lib;
                  })
                  // {
                    workDir = "out-graphs/{run}/${toString n}-servers/quickack-${toString quickack}";
                  }
                )
              )
            } $@
              grep -h 'Goodput' out-graphs/*/${toString n}-servers/quickack-${toString quickack}/client/stdout.txt | sed 's/^/Server Count = ${toString n}, Quickack = ${if quickack then "1" else "0"}: /' >> out-graphs/summary.txt
          '')
          [
            false
            true
          ]
      ) serverCountsFig9_14
    ))
    + "\n"
    + "${python3}/bin/python3 ${./recreate-figure-14.py} \n"
    + "${python3}/bin/python3 ${./recreate-figure-14-relative.py}"
  );

  plot-figure-14 = pkgs.writeShellScriptBin "plot-figure-14" (
    "${python3}/bin/python3 ${./recreate-figure-14.py}"
  );

  plot-figure-14-relative = pkgs.writeShellScriptBin "plot-figure-14-relative" (
    "${python3}/bin/python3 ${./recreate-figure-14-relative.py}"
  );

  incast-figure-14-low-bandwidth = pkgs.writeShellScriptBin "incast-figure-14-low-bandwidth" (
    "rm -rf out-graphs && mkdir -p out-graphs"
    + "\n"
    + (builtins.concatStringsSep "\n" (
      builtins.concatMap (
        n:
        map
          (quickack: ''
            ${
              pkgs.lib.getExe (
                nixnet.mkExperiment (
                  (import ../experiment.nix {
                    inherit
                      pkgs
                      incast
                      n
                      quickack
                      ;
                    rtoMinUs = 1;
                    blockSizeBytes = 1000000;
                    lib = pkgs.lib;
                    linkspeed = 250;
                  })
                  // {
                    workDir = "out-graphs/{run}/${toString n}-servers/quickack-${toString quickack}";
                  }
                )
              )
            } $@
              grep -h 'Goodput' out-graphs/*/${toString n}-servers/quickack-${toString quickack}/client/stdout.txt | sed 's/^/Server Count = ${toString n}, Quickack = ${if quickack then "1" else "0"}: /' >> out-graphs/summary.txt
          '')
          [
            false
            true
          ]
      ) serverCountsFig9_14
    ))
    + "\n"
    + "${python3}/bin/python3 ${./recreate-figure-14-low-bandwidth.py} \n"
  );

  plot-figure-14-low-bandwidth = pkgs.writeShellScriptBin "plot-figure-14-low-bandwidth" (
    "${python3}/bin/python3 ${./recreate-figure-14-low-bandwidth.py}"
  );
}
