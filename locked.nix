let

  lockFile = builtins.fromJSON (builtins.readFile ./flake.lock);

  pkgsInfo = lockFile.nodes.nixpkgs;

  nixTar = builtins.fetchTarball {
    name = pkgsInfo.original.ref;
    url = "https://github.com/nixos/nixpkgs/archive/${pkgsInfo.locked.rev}.tar.gz";
    sha256 = pkgsInfo.locked.narHash;
  };

in
(import nixTar) { }
