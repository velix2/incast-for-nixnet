{
  pkgs,
  nixnet,
  incast,
}:
let mkConfig = n: rtoMinUs: (import ../experiment.nix { inherit pkgs nixnet incast n rtoMinUs; lib = pkgs.lib; blockSizeBytes = 1008000; }) # 1008000 instead of 1000000 because we need to make sure that blockSizeBytes / n is a multiple of 1000
  // {workDir = "out-graphs/{run}/${toString n}-servers/rto${toString rtoMinUs}"; };
mkCommand = n: rto: ''
  ${nixnet.mkExperiment (mkConfig n rto)}/bin/testbed $@
    grep -h 'Goodput' out-graphs/*/${toString n}-servers/rto${toString rto}/client/stdout.txt | sed 's/^/Server Count = ${toString n}, RTOmin = ${toString rto}: /' >> out-graphs/summary.txt
  '';
python3 = pkgs.python3.withPackages (ps: with ps; [ matplotlib ]);
rtoSteps = [ 200 1000 5000 10000 50000 100000 200000 ];
serverCountsFig2 = [ 4 8 16 32 64 128 ];
serverCountsFig3 = [ 4 8 16 ];
in
{
  incast-figure-2 = pkgs.writeShellScriptBin "incast-figure-2" 
 ("rm -rf out-graphs && mkdir -p out-graphs" + "\n" +
 (builtins.concatStringsSep "\n" (builtins.concatMap (n: map (rto: mkCommand n rto) rtoSteps) serverCountsFig2))+ "\n" + 
  "${python3}/bin/python3 ${./recreate-figure-2.py}");

  incast-figure-3 = pkgs.writeShellScriptBin "incast-figure-3" 
 ("rm -rf out-graphs && mkdir -p out-graphs" + "\n" +
 (builtins.concatStringsSep "\n" (builtins.concatMap (n: map (rto: mkCommand n rto) rtoSteps) serverCountsFig3))+ "\n" + 
  "${python3}/bin/python3 ${./recreate-figure-3.py}");
}
