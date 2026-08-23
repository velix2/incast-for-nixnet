{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/2989ce0cac7eef85d1a792067b689c1825371126";
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
    buildInputs = [ pkgs.gcc41 pkgs.gnumake ];

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