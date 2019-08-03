#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2017-12-28 12:24:21 +0000 (Thu, 28 Dec 2017)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  http://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

section "Checking for Tabs (rather than Spaces)"

start_time="$(start_timer)"

# shellcheck disable=SC1090
. "$srcdir/lib/excluded.sh"

progress_char='-'
[ -n "${DEBUG:-}" ] && progress_char=''

files_with_tabs=0
for filename in $(find "${1:-.}" -type f | grep -Evf "$srcdir/lib/whitespace_ignore.txt" -f "$srcdir/lib/tabs_ignore.txt" | sort); do
    isExcluded "$filename" && continue
    [[ "$filename" =~ .*/check_(no_tabs|whitespace).sh$ ]] && continue
    printf "%s" "$progress_char"
    # \t aren't working inside character classes for some reason, embedding literal tabs instead
    output="$(grep -EHn '	' "$filename" || :)"
    if [ -n "$output" ]; then
        echo
        echo "$output"
        #let files_with_tabs+=1
        ((files_with_tabs + 1))
    fi
done
echo
if [ $files_with_tabs -gt 0 ]; then
    echo "$files_with_tabs files with tabs detected!"
    return 1 &>/dev/null || :
    exit 1
fi

time_taken "$start_time"
section2 "Tabs check passed"
echo
