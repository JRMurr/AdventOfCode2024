{
  pkgs ? import ../locked.nix,
}:
let

  lib = pkgs.lib;

  abs = x: if x < 0 then x * -1 else x;

  modulo = a: b: a - b * builtins.floor (a / b);

  parseLines =
    lineFn: text:
    let
      lines = lib.strings.splitString "\n" (lib.strings.trim text);
    in
    builtins.map lineFn lines;

  splitEmptyLine =
    text:
    let
      lines = (lib.strings.splitString "\n" (lib.strings.trim text));

      addIfNonEmpty = { acc, lst }: if builtins.length lst > 0 then acc ++ [ lst ] else acc;

      reducer =
        { currLst, acc }:
        line:
        if line == "" then
          {
            currLst = [ ];
            acc = addIfNonEmpty {
              inherit acc;
              lst = currLst;
            };
          }
        else
          {
            inherit acc;
            currLst = currLst ++ [ line ];
          };

      reduced = builtins.foldl' reducer {
        currLst = [ ];
        acc = [ ];
      } lines;

    in
    addIfNonEmpty {
      acc = reduced.acc;
      lst = reduced.currLst;
    };

  getOrDefault =
    {
      key,
      default,
      attrs,
    }:
    if builtins.hasAttr key attrs then builtins.getAttr key attrs else default;

  sumList = lst: lib.lists.foldl' builtins.add 0 lst;

  # ggenerates all permutations of length n from a list of values
  permutations =
    values: n:
    if n == 0 then
      [ [ ] ] # Base case: a list containing an empty list
    else
      let
        # Recursive step: prepend each value from `values` to all permutations of length n-1
        smallerPermutations = permutations values (n - 1);
      in
      builtins.concatMap (p: map (v: ([ v ] ++ p)) values) smallerPermutations;

in
{
  inherit
    abs
    splitEmptyLine
    parseLines
    getOrDefault
    sumList
    modulo
    permutations
    ;

  grid = import ./grid.nix { inherit pkgs; };
}
