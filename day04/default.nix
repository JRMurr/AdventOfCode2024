{ pkgs ? import ../locked.nix }:
let

  lib = pkgs.lib;

  parseToList = text:
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

  # a % b
  modulo = a: b: a - b * builtins.floor (a / b);


  # A ray is an attrset with
  # {
  #  offsets =  <offset idxs>;
  #  allowed = idx => boolean. Returns true if the full ray can be cast starting at that idx;
  # };

  getRays = { width, height }:
    let
      getCol = idx: modulo idx width;
      getRow = idx: idx / width;
      # TODO: probably an off by one in these checks....
      horizontal = {
        offsets = builtins.genList (i: i) 4;
        allowed = idx: (getCol idx) <= width - 4;
      };
      vertical = {
        offsets = builtins.genList (i: i * width) 4;
        allowed = idx: (getRow idx) <= height - 4;
      };
      diagSE = {
        offsets = builtins.genList (i: i * (width + 1)) 4;
        allowed = idx: ((getRow idx) <= height - 4) && (getCol idx) <= width - 4;
      };
      diagSW = {
        offsets = builtins.genList (i: i * (width - 1)) 4;
        allowed = idx: ((getRow idx) <= height - 4) && (getCol idx) >= 3;
      };
    in
    {
      inherit horizontal vertical diagSE diagSW;
      all = [ horizontal vertical diagSE diagSW ];
    };


  # given a ray get the list of char it matches (returns list<string> not string)
  # if the ray can not be cast from this point return empty list
  evalRay = { lst, ray, startIdx }:
    let
      inherit (ray) offsets allowed;
    in
    if allowed startIdx then
      builtins.map (x: builtins.elemAt lst (x + startIdx)) offsets
    else [ ];


  validStrings = [ [ "X" "M" "A" "S" ] [ "S" "A" "M" "X" ] ];

  rayIsMatch = { lst, ray, startIdx }@args:
    let
      rayChars = evalRay args;
    in
    builtins.length rayChars > 0 && builtins.any (x: x == rayChars) validStrings;


  part0 = { text, filePath }:
    let
      parsed = parseToList text;
      inherit (parsed) width lst height;
      rays = getRays { inherit width height; };


      numHitsAtIdx = lib.imap0
        (i: v: if v != "X" && v != "S" then 0 else
        (
          lib.lists.count (ray: rayIsMatch { inherit ray lst; startIdx = i; }) rays.all
        ))
        lst;

      # checkIdx = idx: value:
      #   let

      #   in false;

      # numMatches = lib.lists.ifilter0 checkIdx lst;

      numMatches = lib.lists.foldl' builtins.add 0 numHitsAtIdx;
    in
    numMatches;
  # lib.debug.traceSeq { tmp = rays.diagSW; } numMatches;

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
