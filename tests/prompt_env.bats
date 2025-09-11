#!/usr/bin/env bats

load 'test_helper.bash'

setup() {
    # Source the script to test internal prompt functions
    source "$PWD/bin/fastpull"
}

@test "_prompt uses env var override when set" {
    export GDR_TESTVAR="from-env"
    local out
    _prompt "msg" out "default" "GDR_TESTVAR"
    [ "$out" = "from-env" ]
}

@test "_prompt_masked uses env var override when set" {
    export GDR_SECRET="s3cr3t"
    local secret
    _prompt_masked "secret" secret "GDR_SECRET"
    [ "$secret" = "s3cr3t" ]
}

