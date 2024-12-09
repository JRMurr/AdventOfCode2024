{
  pkgs ? import ../locked.nix,
}:
let

  lib = pkgs.lib;

  myLib = (import ./default.nix { inherit pkgs; });

  /**
    type Grid<T> = {
      lst: List<T>
      width: number
      height: number
    }
  */
  parse2dGrid =
    text:
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

  # returns a list of `{x,y, value}` to get all values of the grid with their coordinates
  asList =
    grid: # grid<T>
    lib.imap0 (
      i: v:
      (
        {
          value = v;
        }
        // (idxToCoord {
          idx = i;
          width = grid.width;
        })
      )
    ) grid.lst;

  mapGrid =
    fn: # T -> U
    grid: # grid<T>
    let
      newLst = builtins.map fn grid.lst;
    in
    grid // { lst = newLst; };

  coordToIndex =
    {
      x,
      y,
      width,
    }:
    x + (y * width);

  getCol = { idx, width }: myLib.modulo idx width;
  getRow = { idx, width }: idx / width;

  idxToCoord =
    { idx, width }:
    let
      x = getCol { inherit idx width; };
      y = getRow { inherit idx width; };
    in
    {
      inherit x y;
    };

  isValidCoord =
    {
      grid, # Grid<T>
      x,
      y,
    }:
    let
      xValid = x >= 0 && x < grid.width;
      yValid = y >= 0 && y < grid.height;
    in
    xValid && yValid;

  getCoordSafe =
    {
      grid,
      x,
      y,
    }:
    let
      validcoord = isValidCoord {
        inherit
          grid
          x
          y
          ;
      };
      idx = coordToIndex {
        inherit x y;
        width = grid.width;
      };
    in
    if validcoord then
      { result = builtins.elemAt grid.lst idx; }
    else
      {
        error = "invalid coord";
      };

  getCoord =
    {
      grid, # Grid<T>
      x,
      y,
    }:
    let
      res = getCoordSafe {
        inherit
          grid
          x
          y
          ;
      };
    in
    if builtins.hasAttr "result" res then res.result else throw res.error;

  # functions of coord -> coord for a particular direction
  movementFuncs = {
    north =
      { x, y }:
      {
        inherit x;
        y = y - 1;
      };

    south =
      { x, y }:
      {
        inherit x;
        y = y + 1;
      };

    east =
      { x, y }:
      {
        inherit y;
        x = x + 1;
      };

    west =
      { x, y }:
      {
        inherit y;
        x = x - 1;
      };

    NorthEast =
      { x, y }:
      {
        y = y - 1;
        x = x + 1;
      };

    NorthWest =
      { x, y }:
      {
        y = y - 1;
        x = x - 1;
      };

    SouthEast =
      { x, y }:
      {
        y = y + 1;
        x = x + 1;
      };

    SouthWest =
      { x, y }:
      {
        y = y + 1;
        x = x - 1;
      };
  };

  # enum to track direction
  directions = {
    north = 0;
    south = 1;
    east = 2;
    west = 3;
    northEast = 4;
    northWest = 5;
    southEast = 6;
    southWest = 7;
  };

  # manhattan distance between two coords
  coordDist =
    c1: c2:
    let
      xDiff = myLib.abs (c1.x - c2.x);
      yDiff = myLib.abs (c1.y - c2.y);
    in
    xDiff + yDiff;

in
{
  inherit
    parse2dGrid
    asList
    mapGrid
    coordToIndex
    getCoordSafe
    getCoord
    getCol
    getRow
    idxToCoord
    isValidCoord
    movementFuncs
    directions
    coordDist
    ;
}
