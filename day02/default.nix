{ pkgs ? import ../locked.nix }:
let

  lib = pkgs.lib;

  parseLine = lineStr:
    let
      nums = lib.strings.splitString " " lineStr;
    in
    builtins.map lib.strings.toIntBase10 nums;


  abs = x: if x < 0 then x * -1 else x;


  getAdjPairs = lst:
    let
      tailLst = lib.lists.drop 1 lst;
    in
    lib.lists.zipListsWith (a: b: [ a b ]) lst tailLst;

  diffPair = pair: builtins.head pair - lib.lists.last pair;

  isPos = num: num > 0;

  isSafe = nums:
    let
      diffs = builtins.map diffPair (getAdjPairs nums);
      # true if the first diff is positive
      firstDiffDir = isPos (builtins.head diffs);

      checkDiff = diff:
        let
          absDiff = abs diff;
        in
        if (absDiff > 3 || absDiff < 1) then false else
        (
          # make sure direction is same as first diff
          firstDiffDir == isPos diff
        );

      res = builtins.all checkDiff diffs;
    in
    res;

  part0 = text:
    let
      lines = builtins.map parseLine (lib.strings.splitString "\n" (lib.strings.trim text));
    in
    lib.lists.count isSafe lines;

  part1 = text: "TODO P2";

  solve = text: {
    "0" = part0 text;
    "1" = part1 text;
  };
in
{
  example = solve (builtins.readFile ./in.example);
  real = solve (builtins.readFile ./in);
}
