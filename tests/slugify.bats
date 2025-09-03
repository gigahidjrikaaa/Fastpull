#!/usr/bin/env bats

load 'test_helper.bash'

setup() {
    # Source the script to test internal functions
    source "$PWD/bin/fastpull"
}

@test "slugify: basic string" {
    run _slugify "My Test App"
    [ "$status" -eq 0 ]
    [ "$output" = "my-test-app" ]
}

@test "slugify: with special characters" {
    run _slugify "App @!# One"
    [ "$status" -eq 0 ]
    [ "$output" = "app-one" ]
}

@test "slugify: with leading/trailing hyphens" {
    run _slugify "--leading-and-trailing--"
    [ "$status" -eq 0 ]
    [ "$output" = "leading-and-trailing" ]
}
