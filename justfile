
# https://github.com/casey/just

default:
    @just --list

# roc dev -- {{day}} {{part}} {{useExample}}
# nix eval --show-trace --impure --expr 'let day = import ./day{{day}}/default.nix {}; in day.example."0"'

run day='01' part='0' useExample='true':
    run-day --day {{day}} --part {{part}} --useExample {{useExample}}

get day='01':
    aoc download -o --day {{day}} \
        --input-file ./D{{day}}/in \
        --year 2024