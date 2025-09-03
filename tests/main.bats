#!/usr/bin/env bats

load 'test_helper.bash'

setup() {
    # Make the script available in PATH for testing
    export PATH="$PWD/bin:$PATH"
}

@test "shows help message" {
    run fastpull help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "USAGE" ]]
}

@test "shows version" {
    run fastpull version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "fastpull version" ]]
}

@test "handles unknown command" {
    run fastpull foobar
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown command: foobar" ]]
}
