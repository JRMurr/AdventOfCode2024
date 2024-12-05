{ pkgs ? import ../locked.nix }:
let

  lib = pkgs.lib;

  callRg = filePath:
    let
      rgPath = "${pkgs.ripgrep}/bin/rg";
    in
    pkgs.runCommandLocal "call-rg" { } ''
      ${rgPath} --only-matching --no-line-number "mul\((\d{1,3}),(\d{1,3})\)" ${filePath} > $out 
    '';


  doMul = mulStr:
    lib.trivial.pipe mulStr [
      # clean the string to remove the non-digit chars
      (lib.strings.removePrefix "mul(")
      (lib.strings.removeSuffix ")")
      # split the numbers
      (lib.strings.splitString ",")
      # convert to an actual number
      (builtins.map lib.strings.toIntBase10)

      # do the multiplication (fold with acc as 1 to make it easy)
      (lib.lists.foldl' (x: y: x * y) 1)
    ];

  part0 = { text, filePath }:
    let
      matches = builtins.readFile (callRg filePath);
      matchLines = (lib.strings.splitString "\n" (lib.strings.trim matches));
      muls = builtins.map doMul matchLines;
    in
    (lib.lists.foldl' builtins.add 0 muls);


  callRgP2 = filePath:
    let
      rgPath = "${pkgs.ripgrep}/bin/rg";
    in
    pkgs.runCommandLocal "call-rg" { } ''
      ${rgPath} --only-matching --no-line-number "(mul\((\d{1,3}),(\d{1,3})\))|(do\(\))|(don't\(\))" ${filePath} > $out 
    '';

  part1 = { text, filePath }:
    let
      matches = builtins.readFile (callRgP2 filePath);
      matchLines = (lib.strings.splitString "\n" (lib.strings.trim matches));

      trimFn = { lst, addAllowed }: x:
        let
          command = builtins.head (lib.strings.splitString "(" x);
          addAllowed' = if command == "do" then true else if command == "don't" then false else addAllowed;
          lst' = if command == "mul" && addAllowed then (lst ++ [ x ]) else lst;
        in
        { lst = lst'; addAllowed = addAllowed'; };

      trimmedMuls = (lib.lists.foldl' trimFn { lst = [ ]; addAllowed = true; } matchLines).lst;

      muls = builtins.map doMul trimmedMuls;
    in
    (lib.lists.foldl' builtins.add 0 muls);

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
