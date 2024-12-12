{
  pkgs ? import ../locked.nix,
}:
let

  lib = pkgs.lib;

  myLib = import ../myLib { inherit pkgs; };

  gridLib = myLib.grid;

  generatePairs =
    vals:
    builtins.concatLists (
      map (
        x:
        map (y: [
          x
          y
        ]) vals
      ) vals
    );

  getAntiNodesOfPair =
    c1: c2:
    let
      diff = gridLib.coordDiff c1 c2;
      ant1 = gridLib.addCoord c1 diff;
      ant2 = gridLib.addCoord c2 (gridLib.invertRay diff);
    in
    [
      ant1
      ant2
    ];

  getAllAntiNodesForFreq =
    coords:
    let
      pairs = generatePairs coords;
      getNodes =
        pairLst:
        let
          c1 = builtins.head pairLst;
          c2 = lib.last pairLst;
        in
        getAntiNodesOfPair c1 c2;
    in
    builtins.concatMap getNodes pairs;

  inRange =
    {
      min,
      max,
      val,
    }:
    val >= min && val <= max;

  part0 =
    { text, filePath }:
    let
      grid = gridLib.parse2dGrid (lib.strings.trim text);

      cellsWithCoord = gridLib.asList grid;
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

      antiNodes = builtins.concatMap (
        { name, value }: if name == "." then [ ] else getAllAntiNodesForFreq value
      ) (lib.attrsets.attrsToList cellTypes);

      validNodes = builtins.filter (
        coord:
        inRange {
          min = 0;
          max = grid.width - 1;
          val = coord.x;
        }
        && inRange {
          min = 0;
          max = grid.height - 1;
          val = coord.y;
        }
      ) antiNodes;

      coords = lib.unique validNodes;
    in
    lib.debug.traceSeq coords builtins.length (coords);

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
