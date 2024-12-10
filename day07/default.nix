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
      res = builtins.foldl' (acc: op: op acc) (builtins.head vals) partialApplied;

    in
    res;

  checkEq =
    validOps:
    { left, right }:
    let
      numOps = (builtins.length right) - 1;
      opsToTry = myLib.permutations validOps numOps;
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
      checkFn = checkEq [
        builtins.add
        builtins.mul
      ];
      validEqs = builtins.filter checkFn eqs;
      res = myLib.sumList (builtins.map (eq: eq.left) validEqs);
    in
    res;

  concatDigits =
    a: b:
    let
      concatStrs = lib.strings.concatMapStrings (x: toString x) [
        # flipping order since we apply on the right in the eval fn
        b
        a
      ];
    in
    lib.strings.toIntBase10 concatStrs;

  part1 =
    { text, filePath }:
    let
      eqs = myLib.parseLines parseEquation text;
      checkFn = checkEq [
        builtins.add
        builtins.mul
        concatDigits
      ];
      validEqs = builtins.filter checkFn eqs;
      res = myLib.sumList (builtins.map (eq: eq.left) validEqs);
    in
    # lib.debug.traceSeq validEqs
    res; # took 2ish min on real input

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
