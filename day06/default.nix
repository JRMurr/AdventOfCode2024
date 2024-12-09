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
      seen ? { },
    }:
    let
      seenKey = "${toString guardLoc.x}-${toString guardLoc.y}-${toString dir}";

      looped = builtins.hasAttr seenKey seen;

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
            distToEdge = guardLoc.x + 1;
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
            distToEdge = guardLoc.y + 1;
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
      inherit guardEndCoord cellsTouched looped;
      newDir = obstructionSelector.newDir;
      seen = seen // {
        "${seenKey}" = true;
      };
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

  rightTurn =
    dir:
    if dir == directions.east then
      directions.south
    else if dir == directions.west then
      directions.north
    else if dir == directions.north then
      directions.east
    else if dir == directions.south then
      directions.west
    else
      throw "unhandled dir ${toString dir}";

  walk =
    {
      grid, # grid<T>
      guardLoc, # {x,y}
      obstructionLocations, # list<{x,y}>
      dir, # gridLib.direction
    }:
    let
      # cellValueUnchecked = gridLib.getCoordSafe ({ inherit grid; } // guardLoc);
      # outOfBounds = builtins.hasAttr "error" cellValueUnchecked;

      # cellValue = cellValueUnchecked.result;

      outOfBounds = !(gridLib.isValidCoord ({ inherit grid; } // guardLoc));

      newGuardLoc = (gridLib.movementForDir dir) guardLoc;

      touchingObs = builtins.elem newGuardLoc obstructionLocations;
    in
    if outOfBounds then
      [ ]
    else if touchingObs then
      walk {
        inherit grid guardLoc obstructionLocations;
        dir = rightTurn dir;
      }
    else
      (
        [ guardLoc ]
        ++ (walk {
          inherit grid dir obstructionLocations;
          guardLoc = newGuardLoc;
        })
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

      # cellsSeen = walk {
      #   inherit grid;
      #   guardLoc = guardStart;
      #   obstructionLocations = obstructionLocations;
      #   dir = directions.north;
      # };

      numSeen = builtins.length (lib.lists.unique cellsSeen);

    in
    # lib.debug.traceSeq (cellsSeen)
    numSeen;

  hasLoop =
    {
      grid, # grid<T>
      guardLoc, # {x,y}
      obstructionLocations, # list<{x,y}>
      dir, # gridLib.direction
    }@args:
    let
      obstructionInfo = findNextObstruction args;
    in
    if obstructionInfo.looped then
      true
    else if obstructionInfo.guardEndCoord == null then
      false
    else
      hasLoop {
        inherit grid obstructionLocations;
        guardLoc = obstructionInfo.guardEndCoord;
        dir = obstructionInfo.newDir;
      };

  part1 =
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

      guardPath = lib.lists.unique (coveredCells {
        inherit grid;
        guardLoc = guardStart;
        obstructionLocations = obstructionLocations;
        dir = directions.north;
      });

      guardPathNoStart = builtins.filter (x: x != guardStart) guardPath;

      updatedObstructions = builtins.map (x: obstructionLocations ++ [ x ]) guardPathNoStart;

      numLooped = lib.lists.count (
        obstructions:
        hasLoop {
          inherit grid;
          guardLoc = guardStart;
          obstructionLocations = obstructions;
          dir = directions.north;
        }
      ) updatedObstructions;
    in
    numLooped;

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
