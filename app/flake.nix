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
  {
    packages.${system}.default = pkgs.stdenv.mkDerivation {
        inherit system;
        name = "incast";
        src = ./src;
        buildInputs = [ pkgs.gcc41 pkgs.gnumake ];
        buildPhase = "make";

        installPhase = ''
          mkdir -p $out/bin
          cp client/a.out $out/bin/client
          cp server/a.out $out/bin/server
          '';
    };
  };
}