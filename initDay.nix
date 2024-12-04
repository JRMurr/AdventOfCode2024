{ writeShellApplication

, git
, aoc-cli
,
}:

writeShellApplication {
  name = "init-day";
  runtimeInputs = [ git aoc-cli ];
  text = ''
    REPO_ROOT=$(git rev-parse --show-toplevel)
    cd "$REPO_ROOT"

    # Check if a day argument is provided
    if [ -z "$1" ]; then
      echo "Usage: $0 <day>"
      exit 1
    fi

    # Ensure the day argument is a two-digit number
    day=$(printf "%02d" "$1")

    # Set the directory name
    day_dir="day$day"

    # Check if the directory already exists
    if [ -d "$day_dir" ]; then
      echo "Directory '$day_dir' already exists. Exiting."
      exit 1
    fi

    cp -r _template "$day_dir"

    aoc download -o --day "$day" \
        --input-file ./"$day_dir"/in \
        --year 2024 \
        --input-only
  '';
}
