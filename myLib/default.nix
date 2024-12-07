{ pkgs ? import ../locked.nix }:
let

  lib = pkgs.lib;

  splitEmptyLine = text:
    let
      lines = (lib.strings.splitString "\n" (lib.strings.trim text));

      addIfNonEmpty = { acc, lst }:
        if builtins.length lst > 0 then acc ++ [ lst ] else acc;

      reducer = { currLst, acc }: line:
        if line == "" then {
          currLst = [ ];
          acc = addIfNonEmpty { inherit acc; lst = currLst; };
        } else {
          inherit acc;
          currLst = currLst ++ [ line ];
        };

      reduced = builtins.foldl' reducer { currLst = [ ]; acc = [ ]; } lines;

    in
    addIfNonEmpty { acc = reduced.acc; lst = reduced.currLst; };


  getOrDefault = { key, default, attrs }:
    if builtins.hasAttr key attrs then builtins.getAttr key attrs else default;

in
{
  inherit splitEmptyLine getOrDefault;
}
