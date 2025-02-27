#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-10-16 10:33:03 +0100 (Wed, 16 Oct 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(dirname "$0")"

run(){
    echo "Running $srcdir/$1"
    QUICK=1 "$srcdir/$1"
    echo
    echo
    echo "================================================================================"
}

install_scripts="
install_ansible.sh
install_diff-so-fancy.sh
install_homebrew.sh
install_minikube.sh
install_minishift.sh
install_parquet-tools.sh
install_sdkman.sh
install_sdkman_all_sdks.sh
install_terraform.sh
install_travis.sh
"

for x in $install_scripts; do
    run "$x"
done
if [[ "$USER" =~ hari|sekhon ]]; then
    run install_github_ssh_key.sh
fi
echo
"$srcdir/shell_link.sh"
