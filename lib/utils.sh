#!/usr/bin/env bash
#  shellcheck disable=SC2128,SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2015-05-25 01:38:24 +0100 (Mon, 25 May 2015)
#
#  https://github.com/harisekhon/devops-python-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu
[ -n "${DEBUG:-}" ] && set -x
srcdir_bash_tools_utils="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${bash_tools_utils_imported:-0}" = 1 ]; then
    return 0
fi
bash_tools_utils_imported=1

# shellcheck disable=SC1090
. "$srcdir_bash_tools_utils/docker.sh"

# shellcheck disable=SC1090
. "$srcdir_bash_tools_utils/perl.sh"

# consider adding ERR as set -e handler, not inherited by shell funcs / cmd substitutions / subshells without set -E
export TRAP_SIGNALS="INT QUIT TRAP ABRT TERM EXIT"

if [ -z "${run_count:-}" ]; then
    run_count=0
fi
if [ -z "${total_run_count:-}" ]; then
    total_run_count=0
fi

wrong_port=1111

die(){
    echo "$@"
    exit 1
}

hr(){
    echo "================================================================================"
}

hr2(){
    echo "=================================================="
}

hr3(){
    echo "========================================"
}

section(){
    name="$*"
    hr
    "$srcdir_bash_tools_utils/../center.sh" "$@"
    hr
    if [ -n "${PROJECT:-}" ]; then
        echo "PROJECT: $PROJECT"
    fi
    if is_inside_docker; then
        echo "(running inside docker)"
    fi
    echo
}

section2(){
    hr2
    hr2echo "$@"
    hr2
    echo
}

section3(){
    hr3
    hr3echo "$@"
    hr3
    echo
}

hr2echo(){
    "$srcdir_bash_tools_utils/../center.sh" "$@" 50
}

hr3echo(){
    "$srcdir_bash_tools_utils/../center.sh" "$@" 40
}

#set +o pipefail
#spark_home="$(ls -d tests/spark-*-bin-hadoop* 2>/dev/null | head -n 1)"
#set -o pipefail
#if [ -n "$spark_home" ]; then
#    export SPARK_HOME="$spark_home"
#fi

# shellcheck disable=SC1090
type isExcluded &>/dev/null || . "$srcdir_bash_tools_utils/excluded.sh"


check_bin(){
    local bin="${1:-}"
    if ! which "$bin" &>/dev/null; then
        echo "command '$bin' not found in \$PATH ($PATH)"
        exit 1
    fi
}


check_output(){
    local expected="$1"
    local cmd="${*:2}"
    # do not 2>&1 it will cause indeterministic output even with python -u so even tail -n1 won't work
    echo "check_output:  $cmd"
    echo "expecting:     $expected"
    local output
    output="$($cmd)"
    # intentionally not quoting so that we can use things like google* glob matches for google.com and google.co.uk
    # shellcheck disable=SC2053
    if [[ "$output" = $expected ]]; then
        echo "SUCCESS:       $output"
    else
        die "FAILED:        $output"
    fi
    echo
}

check_exit_code(){
    local exit_code=$?
    local expected_exit_codes
    expected_exit_codes="$*"
    local failed
    failed=1
    for e in $expected_exit_codes; do
        if [ "$exit_code" = "$e" ]; then
            echo "got expected exit code: $e"
            failed=0
        fi
    done
    if [ "$failed" != 0 ]; then
        echo "WRONG EXIT CODE RETURNED! Expected: '$expected_exit_codes', got: '$exit_code'"
        return 1
    fi
}

cpu_count(){
    if is_mac; then
        cpu_count="$(sysctl -n hw.ncpu)"
    else
        #cpu_count="$(awk '/^processor/ {++n} END {print n+1}' /proc/cpuinfo)"
        cpu_count="$(grep -c '^processor[[:space:]]*:' /proc/cpuinfo)"
    fi
    echo "$cpu_count"
}

is_linux(){
    if [ "$(uname -s)" = "Linux" ]; then
        return 0
    fi
    return 1
}

is_mac(){
    if [ "$(uname -s)" = "Darwin" ]; then
        return 0
    fi
    return 1
}

is_jenkins(){
    if [ -n "${JENKINS_URL:-}" ] &&
       [ -n "${BUILD_NUMBER:-}" ] &&
       [ -n "${BUILD_URL:-}" ]
       ; then
        return 0
    fi
    return 1
}

is_travis(){
    if [ -n "${TRAVIS:-}" ]; then
        return 0
    fi
    return 1
}

is_CI(){
    if [ -n "${CI:-}" ] ||
       [ -n "${CI_NAME:-}" ] ||
       is_jenkins ||
       is_travis; then
        return 0
    fi
    return 1
}

is_interactive(){
    if [ -n "${PS1:-}" ]; then
        return 0
    fi
    return 1
}

if is_travis; then
    #export DOCKER_HOST="${DOCKER_HOST:-localhost}"
    export HOST="${HOST:-localhost}"
fi

if is_travis; then
    sudo=sudo
else
    sudo=""
fi
export sudo

is_latest_version(){
    # permit .* as we often replace version if latest with .* to pass regex version tests, which allows this to be called any time
    if [ "$version" = "latest" ] || [ "$version" = ".*" ]; then
        return 0
    fi
    return 1
}

# useful for cutting down on number of noisy docker tests which take a long time but more importantly
# cause the CI builds to fail with job logs > 4MB
ci_sample(){
    local versions
    versions="${*:-}"
    if [ -n "${SAMPLE:-}" ] || is_CI; then
        if [ -n "$versions" ]; then
            local a
            IFS=' ' read -r -a a <<< "$versions"
            local highest_index
            highest_index="${#a[@]}"
            local random_index
            random_index="$((RANDOM % highest_index))"
            echo "${a[$random_index]}"
            return 0
        else
            return 1
        fi
    else
        if [ -n "$versions" ]; then
            echo "$versions"
        fi
    fi
    return 0
}

untrap(){
    # shellcheck disable=SC2086
    trap - $TRAP_SIGNALS
}

plural(){
    plural="s"
    local num
    num="${1:-}"
    if [ "$num" = 1 ]; then
        plural=""
    fi
}

plural_str(){
    local parts=("$@")
    plural ${#parts[@]}
}

# =================================
#
# these functions are too clever and dynamic but save a lot of duplication in nagios-plugins test_*.sh scripts
#
print_debug_env(){
    echo
    echo "Environment for Debugging:"
    echo
    if [ -n "${VERSION:-}" ]; then
        echo "VERSION: $VERSION"
        echo
    fi
    if [ -n "${version:-}" ]; then
        echo "version: $version"
        echo
    fi
    # multiple name support for MySQL + MariaDB variables
    for name in "$@"; do
        name="$(tr '[:lower:]' '[:upper:]' <<< "$name")"
        #eval echo "export ${name}_PORT=$`echo ${name}_PORT`"
        # instead of just name_PORT, find all PORTS in environment and print them
        # while read line to preserve CASSANDRA_PORTS=7199 9042
        env | grep -E -- "^$name.*_" | grep -v -e 'DEFAULT=' -e 'VERSIONS=' | sort | while read -r env_var; do
            # sed here to quote export CASSANDRA_PORTS=7199 9042 => export CASSANDRA_PORTS="7199 9042"
            eval echo "'export $env_var'" | sed 's/=/="/;s/$/"/'
        done
        echo
    done
}

trap_debug_env(){
    local name
    name="$1"
    # shellcheck disable=SC2086,SC2154
    trap 'result=$?; print_debug_env '"$*"'; untrap; exit $result' $TRAP_SIGNALS
}

run++(){
    #if [[ "$run_count" =~ ^[[:digit:]]+$ ]]; then
        ((run_count+=1))
    #fi
}

run(){
    if [ -n "${ERRCODE:-}" ]; then
        run_fail "$ERRCODE" "$@"
    else
        run++
        echo "$@"
        "$@"
        # run_fail does it's own hr
        hr
    fi
}

run_conn_refused(){
    echo "checking connection refused:"
    ERRCODE=2 run_grep "Connection refused|Can't connect|Could not connect to|ConnectionClosed" "$@" -H localhost -P "$wrong_port"
}

run_404(){
    echo "checking 404 Not Found:"
    ERRCODE=2 run_grep "404 Not Found" "$@"
}

run_timeout(){
    echo "checking timeout:"
    ERRCODE=3 run_grep "timed out" "$@"
}

run_usage(){
    echo "checking usage / parsing:"
    ERRCODE=3 run_grep "usage: " "$@"
}

run_output(){
    local expected_output
    expected_output="$1"
    shift
    run++
    echo "$@"
    set +e
    check_output "$expected_output" "$@"
    set -e
    hr
}

run_fail(){
    local expected_exit_code
    expected_exit_code="$1"
    shift
    run++
    echo "$@"
    set +e
    "$@"
    # intentionally don't quote $expected_exit_code so that we can pass multiple exit codes through first arg and have them expanded here
    # shellcheck disable=SC2086
    check_exit_code $expected_exit_code || exit 1
    set -e
    hr
}

run_grep(){
    local egrep_pattern
    egrep_pattern="$1"
    shift
    expected_exit_code="${ERRCODE:-0}"
    run++
    echo "$@"
    set +eo pipefail
    # pytools programs write to stderr, must test this for connection refused type information
    output="$("$@" 2>&1)"
    if ! check_exit_code "$expected_exit_code"; then
        echo "$output"
        exit 1
    fi
    set -e
    # this must be egrep -i because (?i) modifier does not work
    echo "> | tee /dev/stderr | grep -Eqi '$egrep_pattern'"
    echo "$output" | tee /dev/stderr | grep -Eqi -- "$egrep_pattern"
    set -o pipefail
    hr
}

run_test_versions(){
    local name
    name="$1"
    local test_func
    test_func="$(tr '[:upper:]' '[:lower:]' <<< "test_${name/ /_}")"
    local VERSIONS
    VERSIONS="$(tr '[:lower:]' '[:upper:]' <<< "${name/ /_}_VERSIONS")"
    # shellcheck disable=SC2006
    local test_versions
    # shellcheck disable=SC2046,SC2006,SC2116
    test_versions="$(eval ci_sample $`echo "$VERSIONS"`)"
    local test_versions_ordered
    test_versions_ordered="$test_versions"
    if [ -z "${NO_VERSION_REVERSE:-}" ]; then
        # tail -r works on Mac but not Travis CI Ubuntu Trusty
        # tac works on Linux but not on Mac
        test_versions_ordered="$(tr ' ' '\n' <<< "$test_versions" | perl -pe 'print reverse <>' | tr '\n' ' ')"
    fi
    local start_time
    start_time="$(start_timer "$name tests")"
    for version in $test_versions_ordered; do
        version_start_time="$(start_timer "$name test for version:  $version")"
        run_count=0
        eval "$test_func" "$version"
        if [ $run_count -eq 0 ]; then
            echo "NO TEST RUNS DETECTED!"
            exit 1
        fi
        ((total_run_count+=run_count))
        time_taken "$version_start_time" "$name version '$version' tests completed in"
        echo
    done

    if [ -n "${NOTESTS:-}" ]; then
        print_debug_env "$name"
    else
        untrap
        echo "All $name tests succeeded for versions: $test_versions"
        echo
        echo "Total Tests run: $total_run_count"
        time_taken "$start_time" "All version tests for $name completed in"
        echo
    fi
    echo
}

# =================================

timestamp(){
    printf "%s" "$(date '+%F %T')  $*" >&2
    [ $# -gt 0 ] && printf '\n' >&2
}
tstamp(){ timestamp "$@"; }

start_timer(){
    tstamp "Starting $*
"
    date '+%s'
}

time_taken(){
    echo
    local start_time
    start_time="$1"
    shift
    local time_taken
    local msg
    msg="${*:-Completed in}"
    tstamp "Finished"
    echo
    local end_time
    end_time="$(date +%s)"
    time_taken="$((end_time - start_time))"
    echo "$msg $time_taken secs"
    echo
}

# args may be passed in client code
# shellcheck disable=SC2120
startupwait(){
    startupwait="${1:-30}"
    if is_CI; then
        ((startupwait*=2))
    fi
}
# trigger to set a sensible default if we forget, as it is used
# as a fallback in when_ports_available and when_url_content below
# shellcheck disable=SC2119
startupwait

when_ports_available(){
    local max_secs="${1:-}"
    if ! [[ "$max_secs" =~ ^[[:digit:]]+$ ]]; then
        max_secs="$startupwait"
    else
        shift
    fi
    local host="${1:-}"
    local ports="${*:2}"
    local retry_interval="${RETRY_INTERVAL:-1}"
    if [ -z "$host" ]; then
        echo "$FUNCNAME: host \$2 not set"
        exit 1
    elif [ -z "$ports" ]; then
        echo "$FUNCNAME: ports \$3 not set"
        exit 1
    else
        for port in $ports; do
            if ! [[ "$port" =~ ^[[:digit:]]+$ ]]; then
                echo "$FUNCNAME: invalid non-numeric port argument '$port'"
                exit 1
            fi
        done
    fi
    if ! [[ "$retry_interval" =~ ^[[:digit:]]+$ ]]; then
        echo "$FUNCNAME: invalid non-numeric \$RETRY_INTERVAL '$retry_interval'"
        exit 1
    fi
    # Linux nc doens't have -z switch like Mac OSX version
    #local nc_cmd="nc -vw $retry_interval $host <<< ''"
    #cmd=""
    #for x in $ports; do
    #    cmd="$cmd $nc_cmd $x &>/dev/null && "
    #done
    #local cmd="${cmd% && }"
    # shellcheck disable=SC2086
    plural_str $ports
    echo "waiting for up to $max_secs secs for port$plural '$ports' to become available, retrying at $retry_interval sec intervals"
    #echo "cmd: ${cmd// \&\>\/dev\/null}"
    local found=0
    if which nc &>/dev/null; then
        try_number=0
        # special built-in that increments for script runtime, reset to zero exploit it here
        SECONDS=0
        # bash will interpolate from string for correct numeric comparison and safer to quote vars
        while [ "$SECONDS" -lt "$max_secs" ]; do
            ((try_number + 1))
            for port in $ports; do
                if ! nc -vw "$retry_interval" "$host" "$port" <<< '' &>/dev/null; then
                    timestamp "$try_number waiting for host '$host' port '$port'"
                    sleep "$retry_interval"
                    break
                fi
                found=1
            done
            if [ $found -eq 1 ]; then
                break
            fi
        done
        if [ $found -eq 1 ]; then
            timestamp "host '$host' port$plural '$ports' available after $SECONDS secs"
        else
            timestamp "host '$host' port$plural '$ports' still not available after '$max_secs' secs, giving up waiting"
            return 1
        fi
    else
        echo "WARNING: nc command not found in \$PATH, cannot check port availability, skipping port checks, tests may fail due to race conditions on service availability"
        echo "sleeping for '$max_secs' secs instead"
        sleep "$max_secs"
    fi
}

# Do not use this on docker containers
# docker mapped ports still return connection succeeded even when the process mapped to them is no longer listening inside the container!
# must be the result of docker networking
when_ports_down(){
    local max_secs="${1:-}"
    if ! [[ "$max_secs" =~ ^[[:digit:]]+$ ]]; then
        max_secs="$startupwait"
    else
        shift
    fi
    local host="${1:-}"
    local ports="${*:2}"
    local retry_interval="${RETRY_INTERVAL:-1}"
    if [ -z "$host" ]; then
        echo "$FUNCNAME: host \$2 not set"
        exit 1
    elif [ -z "$ports" ]; then
        echo "$FUNCNAME: ports \$3 not set"
        exit 1
    else
        for port in $ports; do
            if ! [[ "$port" =~ ^[[:digit:]]+$ ]]; then
                echo "$FUNCNAME: invalid non-numeric port argument '$port'"
                exit 1
            fi
        done
    fi
    if ! [[ "$retry_interval" =~ ^[[:digit:]]+$ ]]; then
        echo "$FUNCNAME: invalid non-numeric \$RETRY_INTERVAL '$retry_interval'"
        exit 1
    fi
    #local max_tries=$(($max_secs / $retry_interval))
    # Linux nc doens't have -z switch like Mac OSX version
    local nc_cmd="nc -vw $retry_interval $host <<< ''"
    cmd=""
    for x in $ports; do
        cmd="$cmd ! $nc_cmd $x &>/dev/null && "
    done
    local cmd="${cmd% && }"
    # shellcheck disable=SC2086
    plural_str $ports
    echo "waiting for up to $max_secs secs for port$plural '$ports' to go down, retrying at $retry_interval sec intervals"
    echo "cmd: ${cmd// \&\>\/dev\/null}"
    local down=0
    if which nc &>/dev/null; then
        #for((i=1; i <= $max_tries; i++)); do
        try_number=0
        # special built-in that increments for script runtime, reset to zero exploit it here
        SECONDS=0
        # bash will interpolate from string for correct numeric comparison and safer to quote vars
        while [ "$SECONDS" -lt "$max_secs" ]; do
            ((try_number + 1))
            timestamp "$try_number trying host '$host' port(s) '$ports'"
            if eval "$cmd"; then
                down=1
                break
            fi
            sleep "$retry_interval"
        done
        if [ $down -eq 1 ]; then
            timestamp "host '$host' port$plural '$ports' down after $SECONDS secs"
        else
            timestamp "host '$host' port$plural '$ports' still not down after '$max_secs' secs, giving up waiting"
            return 1
        fi
    else
        echo "WARNING: nc command not found in \$PATH, cannot check for ports down, skipping port checks, tests may fail due to race conditions on service availability"
        echo "sleeping for '$max_secs' secs instead"
        sleep "$max_secs"
    fi
}

when_url_content(){
    local max_secs="${1:-}"
    if ! [[ "$max_secs" =~ ^[[:digit:]]+$ ]]; then
        max_secs="$startupwait"
    else
        shift
    fi
    local url="${1:-}"
    local expected_regex="${2:-}"
    local args="${*:3}"
    local retry_interval="${RETRY_INTERVAL:-1}"
    if [ -z "$url" ]; then
        echo "$FUNCNAME: url \$2 not set"
        exit 1
    elif [ -z "$expected_regex" ]; then
        echo "$FUNCNAME: expected content \$3 not set"
        exit 1
    fi
    if ! [[ "$retry_interval" =~ ^[[:digit:]]+$ ]]; then
        echo "$FUNCNAME: invalid non-numeric \$RETRY_INTERVAL '$retry_interval'"
        exit 1
    fi
    #local max_tries=$(($max_secs / $retry_interval))
    echo "waiting up to $max_secs secs at $retry_interval sec intervals for HTTP interface to come up with expected regex content: '$expected_regex'"
    found=0
    #for((i=1; i <= $max_tries; i++)); do
    try_number=0
    # special built-in that increments for script runtime, reset to zero exploit it here
    SECONDS=0
    # bash will interpolate from string for correct numeric comparison and safer to quote vars
    if which curl &>/dev/null; then
        while [ "$SECONDS" -lt "$max_secs" ]; do
            ((try_number + 1))
            timestamp "$try_number trying $url"
            # shellcheck disable=SC2086
            if curl -skL --connect-timeout 1 --max-time 5 ${args:-} "$url" | grep -Eq -- "$expected_regex"; then
                echo "URL content detected '$expected_regex'"
                found=1
                break
            fi
            sleep "$retry_interval"
        done
        if [ $found -eq 1 ]; then
            timestamp "URL content found after $SECONDS secs"
        else
            timestamp "URL content still not available after '$max_secs' secs, giving up waiting"
            return 1
        fi
    else
        echo "WARNING: curl command not found in \$PATH, cannot check url content, skipping content checks, tests may fail due to race conditions on service availability"
        echo "sleeping for '$max_secs' secs instead"
        sleep "$max_secs"
    fi
}

retry(){
    local max_secs="${1:-}"
    local retry_interval="${RETRY_INTERVAL:-1}"
    shift
    if ! [[ "$max_secs" =~ ^[[:digit:]]+$ ]]; then
        echo "ERROR: non-integer '$max_secs' passed to $FUNCNAME() for \$1"
        exit 1
    fi
    if ! [[ "$retry_interval" =~ ^[[:digit:]]+$ ]]; then
        echo "$FUNCNAME: invalid non-numeric \$RETRY_INTERVAL '$retry_interval'"
        exit 1
    fi
    local negate=""
    expected_return_code="${ERRCODE:-0}"
    if [ "$1" == '!' ]; then
        negate=1
        shift
    fi
    local cmd="${*:-}"
    if [ -z "$cmd" ]; then
        echo "ERROR: no command passed to $FUNCNAME() for \$3"
        exit 1
    fi
    echo "retrying for up to $max_secs secs at $retry_interval sec intervals:"
    try_number=0
    SECONDS=0
    while true; do
        ((try_number + 1))
        echo -n "try $try_number:  "
        set +e
        $cmd
        returncode=$?
        set -e
        if [ -n "$negate" ]; then
            if [ $returncode != 0 ]; then
                timestamp "Command failed after $SECONDS secs"
                break
            fi
        elif [ "$returncode" = "$expected_return_code" ]; then
            timestamp "Command succeeded with expected exit code of $expected_return_code after $SECONDS secs"
            break
        fi
        if [ "$SECONDS" -gt "$max_secs" ]; then
            timestamp "FAILED: giving up after $max_secs secs"
            return 1
        fi
        sleep "$retry_interval"
    done
}


usage(){
    local args=""
    local switches=""
    local description=""
    if [ -n "${usage_args:-}" ]; then
        args="$usage_args"
    fi
    if [ -n "${usage_switches:-}" ]; then
        switches="$usage_switches"
    fi
    if [ -n "${usage_description:-}" ]; then
        description="$usage_description
"
    fi
    if [ -n "$*" ]; then
        echo "$@"
        echo
    fi
    cat <<EOF
$description
usage: ${0##*/} $args

$switches
EOF
    exit 3
}
