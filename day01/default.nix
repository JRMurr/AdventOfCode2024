{ pkgs ? import ../locked.nix }:
let

  lib = pkgs.lib;

  abs = x: if x < 0 then x * -1 else x;

  sortLst = lst: (lib.lists.sortOn (p: p) lst);


  parseInput = text:
    let
      pairStrs = lib.strings.splitString "\n" (lib.strings.trim text);
      splitPair = str:
        let
          split = lib.strings.splitString " " str;
        in
        {
          left = lib.strings.toIntBase10 (builtins.head split);
          right = lib.strings.toIntBase10 (lib.last split); #lib.last is more efficient than tail since tail walks the whole list
        }
      ;

      pairs = builtins.map splitPair pairStrs;
      left = builtins.map (p: p.left) pairs;
      right = builtins.map (p: p.right) pairs;
    in
    { inherit left right; };


  part0 = text:
    let
      lists = parseInput text;
      inherit (lists) left right;

      sortedLeft = sortLst left;
      sortedRight = sortLst right;

      combined = lib.zipListsWith (l: r: (abs (l - r))) sortedLeft sortedRight;
    in
    lib.lists.foldl' builtins.add 0 combined;



  part1 = text:
    let
      lists = parseInput text;
      inherit (lists) left right;
      # should probs groupb 
      # scoreElem = elem: (lib.lists.count (x: x == elem) right) * elem;

      elemScores = lib.lists.groupBy' builtins.add 0 (x: "${toString x}") right;

      getScore = x: if builtins.hasAttr "${toString x}" elemScores then builtins.getAttr "${toString x}" elemScores else 0;

      scores = builtins.map getScore left;

    in
    lib.lists.foldl' builtins.add 0 scores;


  solve = text: {
    "0" = part0 text;
    "1" = part1 text;
  };

in
{
  example = solve (builtins.readFile ./in.example);
  real = solve (builtins.readFile ./in);
}
