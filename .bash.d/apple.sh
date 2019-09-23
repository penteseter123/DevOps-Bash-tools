#!/usr/bin/env bash
# shellcheck disable=SC2230
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: circa 2011 (forked from .bashrc)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

# ============================================================================ #
#                           A p p l e   M a c   O S X
# ============================================================================ #

# More Mac specific stuff in adjacent *.sh files, especially network.sh

srcdir="${srcdir:-$(dirname "${BASH_SOURCE[0]}")/..}"

# shellcheck disable=SC1090
. "$srcdir/.bash.d/os_detection.sh"

[ -n "${APPLE:-}" ] || return

# Apple default in Terminal is xterm
#export TERM=xterm
# not sure why I set it to linux
#export TERM=linux
#ulimit -u 512

macsleep(){
    sudo pmset sleepnow
}

silence_startup(){
    sudo nvram SystemAudioVolume=%80
}

fixvbox(){
    sudo /Library/StartupItems/VirtualBox/VirtualBox restart
}

fixaudio(){
    sudo kextunload /System/Library/Extensions/AppleHDA.kext
    sudo kextload   /System/Library/Extensions/AppleHDA.kext
}

showhiddenfiles(){
    defaults write com.apple.finder AppleShowAllFiles YES
    # must killall Finder after this
}

alias reloadprefs='killall -u $USER cfprefsd'
alias strace="dtruss -f"
alias vlc="/Applications/VLC.app/Contents/MacOS/VLC"


# clear paste buffer
clpb(){
    paste_clipboard < /dev/null
}

macmac(){
    ifconfig |
    awk '
        /^en[[:digit:]]+:/{gsub(":", "", $1); printf "%s:\t", $1}
        /^[[:space:]]ether[[:space:]]/{print $2}
    ' |
    # filters to only the lines with prefixed interfaces from first match
    grep "\t"
}

duall(){
    # srcdir defined in .bashrc
    # shellcheck disable=SC2154
    du -ax "$srcdir" | sort -k1n | tail -n 2000
    sudo du -ax / | sort -k1n | tail -n 50
}
alias dua=duall
if which brew &>/dev/null; then
    brew_prefix="$(brew --prefix)"
    if [ -f "$brew_prefix/etc/bash_completion" ]; then
        # shellcheck disable=SC1090
        . "$brew_prefix/etc/bash_completion"
    fi
fi

brewupdate(){
    if ! brew update; then
        echo "remove the following to brew update"
        brew update 2>&1 | tee /dev/stderr | grep '^[[:space:]]*Library/Formula/' |
        while read -r formula; do
            echo rm -fv "/usr/local/$formula"
        done
        return 1
    fi
}

brewinstall(){
    brewupdate &&
    sed 's/#.*// ; /^[[:space:]]*$/d' < ~/mac-list.txt |
    while read -r pkg; do
        brew install "$pkg" #||
            #{ echo "FAILED"; break; }
    done
}

# don't export BROWSER on Mac, trigger python bug:
# AttributeError: 'MacOSXOSAScript' object has no attribute 'basename'
# from python's webbrowser library
#export BROWSER="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
#export BROWSER="/Applications/Firefox.app/Contents/MacOS/firefox"

# MacPorts - using HomeBrew instead in recent years
#if [ -e "/sw/etc/bash_completion" ]; then
#    . /sw/etc/bash_completion
#fi

# seems Mac OS X has a native pkill now
#pkill(){
#    local args=""
#    local regex=""
#    local grep_args=""
#    while [ -n "$1" ]; do
#        case "$1" in
#            -i) grep_args="$grep_args -i"
#                shift
#                ;;
#            -*) args="$args $1"
#                shift
#                ;;
#             *) regex="$1"
#                shift
#                ;;
#        esac
#    done
#    # TODO: check this a few times and then remove the echo
#    local proclist=$(ps -e | awk '{printf $1 OFS;for(i=4;i<=NF;i++)printf $i OFS;print""}' | grep $grep_args "$regex")
#    if [ -n "$proclist" ]; then
#        echo "$proclist"
#        awk '{print $1}' <<< "$proclist" | xargs echo kill $args
#        read -r -p "Kill all these processes? [y/N] " answer
#        if [ "$answer" = "y" ]; then
#            awk '{print $1}' <<< "$proclist" | xargs kill $args
#        fi
#    fi
#}
