{ pkgs ? import ../locked.nix }:
let

  lib = pkgs.lib;

  myLib = import ../myLib { inherit pkgs; };


  # leaving the numbers as strings until the end since we will be doing a lot of attr set lookups
  parseRule = ruleStr:
    let
      numStrs = lib.strings.splitString "|" ruleStr;
    in
    {
      less = builtins.head numStrs;
      greater = lib.last numStrs;
    };


  getCompareFn = ruleLines:
    let
      rules = builtins.map parseRule ruleLines;

      # attr set where key is a number, the values are the numbers its less than
      ruleMap = lib.lists.groupBy' (lst: x: lst ++ [ x.greater ]) [ ] (x: x.less) rules;

      getMapping = x: myLib.getOrDefault { key = x; attrs = ruleMap; default = [ ]; };

      compare = a: b:
        let
          aLessThans = getMapping a;
          bLessThans = getMapping b;
        in
        # a is less than b
        if (builtins.elem b aLessThans) then true else
          # b is less than a
        if (builtins.elem a bLessThans) then false else
          # we don't know the ordering
        null
      ;
    in
    compare;


  parseInput = text:
    let
      sections = myLib.splitEmptyLine text;

      rules = builtins.head sections;
      updateLines = lib.last sections;

      updates = builtins.map (lib.strings.splitString ",") updateLines;
    in
    { inherit updates; compareFn = getCompareFn rules; };


  # valid if the list in sorted order given the compareFn
  isValidUpdate = { updateLst, compareFn }:
    let
      sortRes = lib.toposort compareFn updateLst;
      sorted = if builtins.hasAttr "result" sortRes then sortRes.result else throw "invalid topo call";
      isSorted = sorted == updateLst;
    in
    { inherit isSorted sorted; };

  getMiddle = lst:
    let
      midIdx = builtins.length lst / 2;
    in
    builtins.elemAt lst midIdx;

  part0 = { text, filePath }:
    let
      inherit (parseInput text) updates compareFn;

      validUpdates = builtins.filter (updateLst: (isValidUpdate { inherit updateLst compareFn; }).isSorted) updates;

      middleNums = builtins.map (lst: lib.strings.toIntBase10 (getMiddle lst)) validUpdates;

      sum = myLib.sumList middleNums;
    in
    sum;

  part1 = { text, filePath }:
    let
      inherit (parseInput text) updates compareFn;

      sortedWithChecks = builtins.map (updateLst: (isValidUpdate { inherit updateLst compareFn; })) updates;

      invalidUpdates = builtins.filter (x: !x.isSorted) sortedWithChecks;

      sortedInvalids = builtins.map (x: x.sorted) invalidUpdates;

      middleNums = builtins.map (lst: lib.strings.toIntBase10 (getMiddle lst)) sortedInvalids;

      sum = myLib.sumList middleNums;
    in
    sum;


  solve = filePath:
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
