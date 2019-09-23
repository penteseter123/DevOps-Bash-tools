#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-06-30 14:46:43 +0100 (Thu, 30 Jun 2016)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -eu #o pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

if [ -z "$(find "${1:-.}" -name build.sbt)" ]; then
    return 0 &>/dev/null || :
    exit 0
fi

section "S B T"

start_time="$(start_timer)"

if which sbt &>/dev/null; then
    find "${1:-.}" -name build.sbt |
    grep -v '/target/' |
    sort |
    while read -r build_sbt; do
        pushd "$(dirname "$build_sbt")" >/dev/null
        echo "Validating $build_sbt"
        echo q | sbt reload || exit $?
        popd >/dev/null
        echo
    done
else
    echo "SBT not found in \$PATH, skipping maven pom checks"
fi

time_taken "$start_time"
section2 "SBT checks passed"
echo
