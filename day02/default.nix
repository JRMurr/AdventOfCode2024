{
  pkgs ? import ../locked.nix,
}:
let

  lib = pkgs.lib;

  parseLine =
    lineStr:
    let
      nums = lib.strings.splitString " " lineStr;
    in
    builtins.map lib.strings.toIntBase10 nums;

  abs = x: if x < 0 then x * -1 else x;

  getAdjPairs =
    lst:
    let
      tailLst = lib.lists.drop 1 lst;
    in
    lib.lists.zipListsWith (a: b: [
      a
      b
    ]) lst tailLst;

  diffPair = pair: builtins.head pair - lib.lists.last pair;

  isPos = num: num > 0;

  isSafe =
    nums:
    let
      diffs = builtins.map diffPair (getAdjPairs nums);
      # true if the first diff is positive
      firstDiffDir = isPos (builtins.head diffs);

      checkDiff =
        diff:
        let
          absDiff = abs diff;
        in
        if (absDiff > 3 || absDiff < 1) then
          false
        else
          (
            # make sure direction is same as first diff
            firstDiffDir == isPos diff
          );

      res = builtins.all checkDiff diffs;
    in
    res;

  part0 =
    text:
    let
      lines = builtins.map parseLine (lib.strings.splitString "\n" (lib.strings.trim text));
    in
    lib.lists.count isSafe lines;

  removeAtIndex =
    index: list:
    if index < 0 || index >= builtins.length list then
      list
    else
      lib.lists.concatLists [
        (lib.lists.sublist 0 index list)
        (lib.lists.sublist (index + 1) (builtins.length list - index - 1) list)
      ];

  isSafeP2 =
    nums:
    let
      diffs = builtins.map diffPair (getAdjPairs nums);
      # true if the first diff is positive
      firstDiffDir = isPos (builtins.head diffs);

      checkDiff =
        diff:
        let
          absDiff = abs diff;
        in
        if (absDiff > 3 || absDiff < 1) then
          false
        else
          (
            # make sure direction is same as first diff
            firstDiffDir == isPos diff
          );

      resWithIdx = lib.lists.imap0 (idx: diff: {
        inherit idx diff;
        safe = checkDiff diff;
      }) diffs;

      failures = builtins.filter (x: !x.safe) resWithIdx;

      numFailures = builtins.length failures;

      isNoFailure = numFailures == 0;

      idxsToRemove =
        if (numFailures == 1) then
          (
            let
              failureIdx = (builtins.head failures).idx;

            in
            [
              failureIdx
              (failureIdx + 1)
            ]
          )
        else if (numFailures == 2) then
          (
            let
              firstFailureIdx = (builtins.head failures).idx;
              secondFailureIdx = (lib.lists.last failures).idx;
            in
            if firstFailureIdx + 1 == secondFailureIdx then
              [
                secondFailureIdx
              ]
            else
              [ ]
          )
        else if (numFailures >= (builtins.length diffs - 2)) then
          [
            0
            1
          ]
        else
          [ ];

      checkWithRemoved =
        removeIdx:
        let
          removedLst = removeAtIndex removeIdx nums;
        in
        isSafe removedLst;

      couldRemove = lib.lists.any checkWithRemoved idxsToRemove;

      res = isNoFailure || couldRemove;
    in
    res;

  part1 =
    text:
    let
      lines = builtins.map parseLine (lib.strings.splitString "\n" (lib.strings.trim text));
    in
    lib.lists.count isSafeP2 lines;

  solve = text: {
    "0" = part0 text;
    "1" = part1 text;
  };
in
{
  example = solve (builtins.readFile ./in.example);
  real = solve (builtins.readFile ./in);
}
