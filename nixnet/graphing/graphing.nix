{
  pkgs,
  nixnet,
  incast,
}:
let mkConfig = blockSizeBytes: n: rtoMinUs: (import ../experiment.nix { inherit pkgs nixnet incast n rtoMinUs blockSizeBytes; lib = pkgs.lib; }) 
  // {workDir = "out-graphs/{run}/${toString n}-servers/rto${toString rtoMinUs}"; };
mkCommand = blockSizeBytes: n: rto: ''
  ${nixnet.mkExperiment (mkConfig blockSizeBytes n rto)}/bin/testbed $@
    grep -h 'Goodput' out-graphs/*/${toString n}-servers/rto${toString rto}/client/stdout.txt | sed 's/^/Server Count = ${toString n}, RTOmin = ${toString rto}: /' >> out-graphs/summary.txt
  '';
python3 = pkgs.python3.withPackages (ps: with ps; [ matplotlib ]);
rtoStepsFig23 = [ 200 1000 5000 10000 50000 100000 200000 ];
serverCountsFig2 = [ 4 8 16 32 64 128 ];
serverCountsFig3 = [ 4 8 16 ];

rtoStepsFig6 = [ 1 5000 200000 ];
serverCountsFig6 = [ 1 2 4 8 16 ];
in
{
  incast-figure-2 = pkgs.writeShellScriptBin "incast-figure-2" 
 ("rm -rf out-graphs && mkdir -p out-graphs" + "\n" +
 (builtins.concatStringsSep "\n" (builtins.concatMap (n: map (rto: mkCommand 1024000 n rto) rtoStepsFig23) serverCountsFig2))+ "\n" +
  "${python3}/bin/python3 ${./recreate-figure-2.py}");

  incast-figure-3 = pkgs.writeShellScriptBin "incast-figure-3" 
 ("rm -rf out-graphs && mkdir -p out-graphs" + "\n" +
 (builtins.concatStringsSep "\n" (builtins.concatMap (n: map (rto: mkCommand 1024000 n rto) rtoStepsFig23) serverCountsFig3))+ "\n" + # 1024000 instead of 1000000 because we need to make sure that blockSizeBytes / 128 is a multiple of 1000
  "${python3}/bin/python3 ${./recreate-figure-3.py}");

  incast-figure-9 = pkgs.writeShellScriptBin "incast-figure-9"
  ("rm -rf out-graphs && mkdir -p out-graphs" + "\n" +
 (builtins.concatStringsSep "\n" (builtins.concatMap (n: map (rto: mkCommand 1008000 n rto) rtoStepsFig6) serverCountsFig6))+ "\n" + # 1008000 instead of 1000000 because we need to make sure that blockSizeBytes / 16 is a multiple of 1000
  "${python3}/bin/python3 ${./recreate-figure-9.py}");
}
