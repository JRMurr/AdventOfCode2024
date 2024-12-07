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


  # rulesToLst = ruleLines:
  #   let
  #     rules = builtins.map parseRule ruleLines;

  #     # attr set where key is a number, the values are the numbers its less than
  #     ruleMap = lib.lists.groupBy' (lst: x: lst ++ [ x.greater ]) [ ] (x: x.less) rules;

  #     getMapping = x: myLib.getOrDefault { key = x; attrs = ruleMap; default = [ ]; };

  #     compare = a: b:
  #       let
  #         aLessThans = getMapping a;
  #         bLessThans = getMapping b;
  #       in
  #       # a is less than b
  #       if (builtins.elem b aLessThans) then true else
  #         # b is less than a
  #       if (builtins.elem a bLessThans) then false else
  #         # we don't know the ordering
  #       null
  #     ;

  #     # since lib.misc.uniqList is n^2 build up an attr set whose keys are the numbers
  #     allNums = lib.trivial.pipe rules [
  #       (builtins.concatMap (x: [
  #         {
  #           name = x.less;
  #           value = 0;
  #         }
  #         {
  #           name = x.greater;
  #           value = 0;
  #         }
  #       ]))
  #       builtins.listToAttrs
  #       builtins.attrNames
  #     ];

  #     # this seems to get sad on the real input with cycles...
  #     # TODO: instead of doing this work to sort all the numbers from the jump
  #     # we can just do it on the update list and see if the update list is sorted
  #     sorted = lib.toposort compare allNums;

  #   in
  #   lib.traceSeq { inherit allNums ruleMap; } sorted;



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
    in
    sorted == updateLst;

  getMiddle = lst:
    let
      midIdx = builtins.length lst / 2;
    in
    builtins.elemAt lst midIdx;

  part0 = { text, filePath }:
    let
      inherit (parseInput text) updates compareFn;

      validUpdates = builtins.filter (updateLst: isValidUpdate { inherit updateLst compareFn; }) updates;

      middleNums = builtins.map (lst: lib.strings.toIntBase10 (getMiddle lst)) validUpdates;

      sum = myLib.sumList middleNums;
    in
    sum;

  part1 = { text, filePath }: "TODO P2";

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
