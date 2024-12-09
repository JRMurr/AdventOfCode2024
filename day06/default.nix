{
  pkgs ? import ../locked.nix,
}:
let

  lib = pkgs.lib;

  myLib = import ../myLib { inherit pkgs; };

  gridLib = myLib.grid;

  directions = gridLib.directions;

  obstruction = "#";

  minBy =
    minFn: lst:
    let
      reduceFn =
        acc: x:
        if acc == null then
          x
        else if (minFn x) < (minFn acc) then
          x
        else
          acc;
    in
    builtins.foldl' reduceFn null lst;

  findNextObstruction =
    {
      grid, # grid<T>
      guardLoc, # {x,y}
      obstructionLocations, # list<{x,y}>
      dir, # gridLib.direction
    }:
    let
      obstructionSelector =
        if dir == directions.east then
          {
            filter = coord: coord.y == guardLoc.y && coord.x > guardLoc.x;
            newDir = directions.south;
            minimizer = coord: coord.x;
            distToEdge = grid.width - guardLoc.x;
            guardEnd = obsCoord: gridLib.movementFuncs.west obsCoord;
            cellsCovered =
              numCells:
              builtins.genList (i: {
                x = guardLoc.x + i;
                y = guardLoc.y;
              }) numCells;
          }
        else if dir == directions.west then
          {
            filter = coord: coord.y == guardLoc.y && coord.x < guardLoc.x;
            newDir = directions.north;
            distToEdge = guardLoc.x;
            minimizer = coord: -1 * coord.x;
            guardEnd = obsCoord: gridLib.movementFuncs.east obsCoord;
            cellsCovered =
              numCells:
              builtins.genList (i: {
                x = guardLoc.x - i;
                y = guardLoc.y;
              }) numCells;
          }
        else if dir == directions.north then
          {
            filter = coord: coord.x == guardLoc.x && coord.y < guardLoc.y;
            newDir = directions.east;
            distToEdge = guardLoc.y;
            minimizer = coord: -1 * coord.y;
            guardEnd = obsCoord: gridLib.movementFuncs.south obsCoord;
            cellsCovered =
              numCells:
              builtins.genList (i: {
                x = guardLoc.x;
                y = guardLoc.y - i;
              }) numCells;
          }
        else if dir == directions.south then
          {
            filter = coord: coord.x == guardLoc.x && coord.y > guardLoc.y;
            newDir = directions.west;
            distToEdge = grid.height - guardLoc.y;
            minimizer = coord: coord.y;
            guardEnd = obsCoord: gridLib.movementFuncs.north obsCoord;
            cellsCovered =
              numCells:
              builtins.genList (i: {
                x = guardLoc.x;
                y = guardLoc.y + i;
              }) numCells;
          }
        else
          throw "unhandled dir ${toString dir}";

      validObstructions = builtins.filter obstructionSelector.filter obstructionLocations;
      obstructionHit = minBy obstructionSelector.minimizer validObstructions;

      isOverEdge = obstructionHit == null;

      # these assume obstructionHit is not null
      guardEndCoord = if isOverEdge then null else obstructionSelector.guardEnd obstructionHit;
      hitDistance = gridLib.coordDist guardLoc obstructionHit;

      dist = if isOverEdge then obstructionSelector.distToEdge else hitDistance;

      cellsTouched = obstructionSelector.cellsCovered dist;

    in
    {
      inherit guardEndCoord cellsTouched;
      newDir = obstructionSelector.newDir;
    };

  coveredCells =
    {
      grid,
      guardLoc,
      obstructionLocations,
      dir,
    }@args:
    let
      obstructionInfo = findNextObstruction args;
    in
    obstructionInfo.cellsTouched
    ++ (
      if obstructionInfo.guardEndCoord == null then
        [ ]
      else
        coveredCells {
          inherit grid obstructionLocations;
          guardLoc = obstructionInfo.guardEndCoord;
          dir = obstructionInfo.newDir;
        }
    );

  part0 =
    { text, filePath }:
    let
      grid = gridLib.parse2dGrid (lib.strings.trim text);

      cellsWithCoord = gridLib.asList grid;
      # group by cell type to get all obstructions
      cellTypes = lib.lists.groupBy' (
        lst: elem:
        lst
        ++ [
          {
            x = elem.x;
            y = elem.y;
          }
        ]
      ) [ ] (elem: elem.value) cellsWithCoord;

      obstructionLocations = builtins.getAttr obstruction cellTypes;
      guardStart = builtins.head (builtins.getAttr "^" cellTypes);

      cellsSeen = coveredCells {
        inherit grid;
        guardLoc = guardStart;
        obstructionLocations = obstructionLocations;
        dir = directions.north;
      };

      numSeen = builtins.length (lib.lists.unique cellsSeen);

    in
    numSeen;

  part1 = { text, filePath }: "TODO P2";

  solve =
    filePath:
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
