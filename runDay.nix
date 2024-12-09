{
  writeShellApplication,
  nix,
  git,
}:

let

  parseArgs = ''
    day=""
    part=0
    useExample=true

    # Function to display usage information
    usage() {
      echo "Usage: $0 --day DAY [--part PART] [--useExample true|false] [--] [additional arguments]"
      echo
      echo "Arguments:"
      echo "  --day DAY             Required. A 2-digit string representing the day."
      echo "  --part PART           Optional. Either 0 or 1. Defaults to 0."
      echo "  --useExample BOOLEAN  Optional. true or false. Defaults to true."
      echo "  --                    End of named arguments. Remaining arguments are passed to the subscript."
      exit 1
    }

    # Parse named arguments
    POSITIONAL=()
    while [[ $# -gt 0 ]]; do
      key="$1"

      case $key in
        --day)
          day="$2"
          shift # past argument
          shift # past value
          ;;
        --part)
          part="$2"
          shift
          shift
          ;;
        --useExample)
          useExample="$2"
          shift
          shift
          ;;
        --) # End of named arguments
          shift
          POSITIONAL+=("$@")
          break
          ;;
        *) # Unknown option
          echo "Unknown option: $1"
          usage
          ;;
      esac
    done

    # Validate 'day' argument
    if [[ -z "$day" ]]; then
      echo "Error: --day is required."
      usage
    fi

    if ! [[ "$day" =~ ^[0-9]{2}$ ]]; then
      echo "Error: --day must be a 2-digit string."
      usage
    fi

    # Validate 'part' argument
    if ! [[ "$part" =~ ^[01]$ ]]; then
      echo "Error: --part must be either 0 or 1."
      usage
    fi

    # Validate 'useExample' argument
    if ! [[ "$useExample" =~ ^(true|false)$ ]]; then
      echo "Error: --useExample must be 'true' or 'false'."
      usage
    fi
  '';
in
writeShellApplication {
  name = "run-day";
  runtimeInputs = [
    nix
    git
  ];
  #     nix eval --impure --expr 'let day = import ./day{{day}}/default.nix {}; in day.example."0"' "$@"

  text = ''
    ${parseArgs}
    mode="real"
    if [[ "$useExample" == "true" ]]; then
      mode="example"
    fi

    REPO_ROOT=$(git rev-parse --show-toplevel)
    cd "$REPO_ROOT"

    nix eval --impure --option max-call-depth 10000 --expr "let day = import ./day''${day}/default.nix {}; in day.''${mode}.\"''${part}\"" "''${POSITIONAL[@]}"
  '';
}
