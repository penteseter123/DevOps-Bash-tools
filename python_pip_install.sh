#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2019-02-15 13:56:24 +0000 (Fri, 15 Feb 2019)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# Installs to --user on Mac to avoid System Integrity Protection built in to OS X El Capitan and later
#
# Also detects and sets up OpenSSL and Kerberos library paths on Mac when using HomeBrew

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x

pip="${PIP:-pip}"
opts="${PIP_OPTS:-}"

usage(){
    echo "Installs Python PyPI modules using Pip, taking in to account library paths, virtual envs etc"
    echo
    echo "Takes a list of python module names as arguments or .txt files containing lists of modules (one per line)"
    echo
    echo "usage: ${0##*} <list_of_modules>"
    echo
    exit 3
}

pip_modules=""
for x in "$@"; do
    if [ -f "$x" ]; then
        echo "adding pip modules from file:  $x"
        pip_modules="$pip_modules $(sed 's/#.*//;/^[[:space:]]*$$/d' "$x")"
        echo
    else
        pip_modules="$pip_modules $x"
    fi
    pip_modules="$(tr ' ' ' \n' <<< "$pip_modules" | sort -u | tr '\n' ' ')"
done

for x in "$@"; do
    case "$1" in
        -*) usage
            ;;
    esac
done

if [ -z "${pip_modules// }" ]; then
    usage
fi

echo "Installing Python PyPI Modules"
echo

if [ -n "${TRAVIS:-}" ]; then
    echo "running in quiet mode"
    opts="$opts -q"
fi

sudo=""
if [ $EUID != 0 ] &&
   [ -z "${VIRTUAL_ENV:-}" ] &&
   [ -z "${CONDA_DEFAULT_ENV:-}" ]; then
    sudo=sudo
fi

user_opt(){
    if [ -n "${VIRTUAL_ENV:-}" ] ||
       [ -n "${CONDA_DEFAULT_ENV:-}" ]; then
        echo "inside virtualenv, ignoring --user switch which wouldn't work"
    else
        opts="$opts --user"
        sudo=""
    fi
}

envopts=""
export LDFLAGS=""
if [ "$(uname -s)" = "Darwin" ]; then
    if type -P brew &>/dev/null; then
        # usually /usr/local
        brew_prefix="$(brew --prefix)"

        export OPENSSL_INCLUDE="$brew_prefix/opt/openssl/include"
        export OPENSSL_LIB="$brew_prefix/opt/openssl/lib"

        export LDFLAGS="${LDFLAGS:-} -L$brew_prefix/lib"
        export CFLAGS="${CFLAGS:-} -I$brew_prefix/include"
        export CPPFLAGS="${CPPFLAGS:-} -I$brew_prefix/include"

        # for OpenSSL
        export LDFLAGS="${LDFLAGS:-} -L$OPENSSL_LIB"
        export CFLAGS="${CFLAGS:-} -I$OPENSSL_INCLUDE"
        export CPPFLAGS="${CPPFLAGS:-} -I$OPENSSL_INCLUDE"

        # for Kerberos
        export LDFLAGS="${LDFLAGS:-} -L$brew_prefix/opt/krb5/lib"
        export CFLAGS="${CFLAGS:-} -I$brew_prefix/opt/krb5/include -I $brew_prefix/opt/krb5/include/krb5"
        export CPPFLAGS="${CPPFLAGS:-} -I$brew_prefix/opt/krb5/include -I $brew_prefix/opt/krb5/include/krb5"

        export CPATH="${CPATH:-} $LDFLAGS"
        export LIBRARY_PATH="${LIBRARY_PATH:-} $LDFLAGS"

        # need to send OPENSSL_INCLUDE and OPENSSL_LIB through sudo explicitly using prefix
        envopts="OPENSSL_INCLUDE=$OPENSSL_INCLUDE OPENSSL_LIB=$OPENSSL_LIB" # LDFLAGS=$LDFLAGS CFLAGS=$CFLAGS CPPFLAGS=$CPPFLAGS"
    fi
    # avoids Mac's System Integrity Protection built in to OS X El Capitan and later
    user_opt
elif [ -n "${PYTHON_USER_INSTALL:-}" ]; then
    user_opt
fi

echo "$sudo $pip install $opts $pip_modules"
# want splitting of opts and modules
# shellcheck disable=SC2086
eval $sudo $envopts "$pip" install $opts $pip_modules
