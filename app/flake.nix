{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/139ff6d52f7f2840ce129124daeb563336ca75ac";
      flake = false;
    };
  };

  outputs = { self, nixpkgs }: 
  let
    system = "x86_64-linux";
    
    pkgs = import nixpkgs { 
      inherit system; 
    };
  in
  let baseConfig = {
    inherit system;
    name = "incast";
    src = ./src;
    buildInputs = [ pkgs.gcc42 pkgs.gnumake ];

    installPhase = ''
      mkdir -p $out/bin
      cp client/a.out $out/bin/client
      cp server/a.out $out/bin/server
      '';
  };
  in
  {
    packages.${system} = {
      default = pkgs.stdenv.mkDerivation (baseConfig // {buildPhase = "make"; });
      silent = pkgs.stdenv.mkDerivation (baseConfig // {buildPhase = "make silent"; });
    }; 
  };
}