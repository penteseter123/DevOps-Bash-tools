#
#  Author: Hari Sekhon
#  Date: 2016-01-17 12:56:53 +0000 (Sun, 17 Jan 2016)
#
#  vim:ts=4:sts=4:sw=4:noet
#
#  https://github.com/harisekhon/bash-tools
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

REPO := HariSekhon/DevOps-Bash-tools

CODE_FILES := $(shell find . -type f -name '*.sh' -o -name .bashrc | sort)

CONF_FILES := \
    .ansible.cfg \
    .editorconfig \
    .gitconfig \
    .tmux.conf \
    .vimrc


include Makefile.in

.PHONY: build
build: system-packages
	:

install:
	@echo "linking dot files to \$$HOME directory: $$HOME"
	@if grep -Eq "(source|\.).+$${PWD##*/}/.bashrc" ~/.bashrc 2>/dev/null; then echo "already sourced in ~/.bashrc"; else echo "source $$PWD/.bashrc" >> ~/.bashrc; fi
	@f=""; [ -n "$$FORCE" ] && f="-f"; \
	for filename in $(CONF_FILES); do \
		test -f "$$HOME/$$filename" || ln -sv $$f "$$PWD/$$filename" ~; \
	done

.PHONY: test
test:
	./all.sh

.PHONY: clean
clean:
	@echo Nothing to clean
