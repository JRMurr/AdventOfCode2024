{ pkgs ? import ../locked.nix }:
let

  lib = pkgs.lib;

  modulo = (import ./default.nix { inherit pkgs; }).modulo;

  parse2dGrid = text:
    let
      rowStrs = (lib.strings.splitString "\n" (lib.strings.trim text));
      # 2d list of charcters
      rows = builtins.map (lib.stringToCharacters) rowStrs;

      width = builtins.length (builtins.head rows);
      height = builtins.length rows;
    in
    {
      inherit width height;
      lst = lib.flatten rows;
    };


  cordToIndex = { x, y, width }:
    x + (y * width);


  getCol = { idx, width }: modulo idx width;
  getRow = { idx, width }: idx / width;

  idxToCord = { idx, width }:
    let
      x = getCol { inherit idx width; };
      y = getRow { inherit idx width; };
    in
    { inherit x y; };

  getCordSafe = { lst, width, height, x, y }:
    let
      xValid = x >= 0 && x < width;
      yValid = y >= 0 && y < height;

      idx = cordToIndex { inherit x y width; };
    in
    if xValid && yValid then { result = builtins.elemAt lst idx; } else {
      error = "invalid coord";
    };


  getCord = { lst, width, height, x, y }:
    let
      res = getCordSafe { inherit lst width height x y; };
    in
    if builtins.hasAttr "result" res then res.result else throw res.error;


in
{ inherit parse2dGrid cordToIndex getCordSafe getCord getCol getRow idxToCord; }
