#!/bin/sh
#  shellcheck disable=SC2086
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 21:31:10 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Mac OSX - HomeBrew install packages in a forgiving way

set -eu #o pipefail  # undefined in /bin/sh
[ -n "${DEBUG:-}" ] && set -x

echo "Installing Mac HomeBrew Packages"

packages=""
for arg; do
    if [ -f "$arg" ]; then
        echo "adding packages from file:  $arg"
        packages="$packages $(sed 's/#.*//;/^[[:space:]]*$$/d' "$arg")"
        echo
    else
        packages="$packages $arg"
    fi
    # uniq
    packages="$(echo "$packages" | tr ' ' ' \n' | sort -u | tr '\n' ' ')"
done

# Sudo is not required as running Homebrew as root is extremely dangerous and no longer supported as
# Homebrew does not drop privileges on installation you would be giving all build scripts full access to your system

brew_update_opts=""
if [ -n "${TRAVIS:-}" ]; then
    brew_update_opts="-v"
fi
if [ -z "${NO_UPDATE:-}" ]; then
    if [ -n "${NO_FAIL:-}" ]; then
        set +e #o pipefail  # undefined in /bin/sh
    fi
    echo "Updating Homebrew"
    brew update $brew_update_opts &
    while jobs | grep -Eq '[[:space:]]+Running[[:space:]]+brew[[:space:]]+update'; do
        # /bin/sh doesn't support -e
        #echo -n .
        printf .
        sleep 5
    done
    set -e #o pipefail  # undefined in /bin/sh
fi

cask=""
if [ -n "${CASK:-}" ]; then
    cask=cask
fi

# Fails if any of the packages are already installed, so you'll probably want to ignore and continue and detect missing
# package later in build system if it's a problem eg. resulting in missing headers later in build
if [ -n "${NO_FAIL:-}" ]; then
    for package in $packages; do
        brew $cask install "$package" || :
    done
else
    # want splitting
    # shellcheck disable=SC2086
    brew $cask install $packages
fi
