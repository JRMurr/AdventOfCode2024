{
  pkgs ? import ../locked.nix,
}:
let

  lib = pkgs.lib;

  myLib = import ../myLib { inherit pkgs; };

  parseEquation =
    line:
    let

      splitEq = lib.trivial.pipe line [
        (lib.strings.splitString ":")
        (builtins.map lib.strings.trim)
      ];

      left = lib.strings.toIntBase10 (builtins.head splitEq);

      right = lib.trivial.pipe (lib.lists.last splitEq) [
        (lib.strings.splitString " ")
        (builtins.map lib.strings.toIntBase10)
      ];

    in
    {
      inherit left right;
    };

  evalOps =
    { opLst, vals }:
    let
      partialApplied = lib.zipListsWith (val: op: op val) (builtins.tail vals) opLst;
    in
    builtins.foldl' (acc: op: op acc) (builtins.head vals) partialApplied;

  checkEq =
    { left, right }:
    let
      numOps = (builtins.length right) - 1;
      opsToTry = myLib.permutations [ builtins.add builtins.mul ] numOps;
      tryOpLst =
        opLst:
        (evalOps {
          inherit opLst;
          vals = right;
        }) == left;
    in
    builtins.any tryOpLst opsToTry;

  part0 =
    { text, filePath }:
    let
      eqs = myLib.parseLines parseEquation text;
      validEqs = builtins.filter checkEq eqs;
      res = myLib.sumList (builtins.map (eq: eq.left) validEqs);
    in
    # lib.debug.traceSeq validEqs
    res;

  part1 = { text, filePath }: "TODO P2";

  solve =
    filePath:
    let
      text = builtins.readFile filePath;
      attrs = { inherit text filePath; };
    in
    {
      "0" = part0 attrs;
      "1" = part1 attrs;
    };
in
{
  example = solve ./in.example;
  real = solve ./in;
}
