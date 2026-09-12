# Which CLIPS:
#
#   make                        the 6.4.2 release tarball (the default)
#   make CLIPS_VERSION=svn-6x   branches/64x of the CLIPS Subversion repository
#   make CLIPS_VERSION=svn-7x   branches/70x
#
# "make help" lists the targets and what each variable accepts.

.DEFAULT_GOAL := all

CLIPS_VERSION  ?= 6.4.2
CLIPS_VERSIONS := 6.4.2 svn-6x svn-7x

ARCHIVE     := clips_core_source_642.tar.gz
ARCHIVE_URL ?= https://sourceforge.net/projects/clipsrules/files/CLIPS/6.4.2/$(ARCHIVE)

CLIPS_SVN_ROOT   ?= https://svn.code.sf.net/p/clipsrules/code
CLIPS_SVN_6X_REV ?= 967
CLIPS_SVN_7X_REV ?= 978

CLIPS_SHA256_6.4.2 := 608a1eb2fc6e9caff30d63d684095f0bca7108f2294d21ee6f5617427c10455a
CLIPS_SHA256 ?= $(CLIPS_SHA256_$(CLIPS_VERSION))
export CLIPS_SHA256

ifeq ($(CLIPS_VERSION),6.4.2)
  CLIPS_TAG    := 6.4.2
  CLIPS_FETCH   = tarball "$(ARCHIVE_URL)" "$(ARCHIVE)"
  CLIPS_ORIGIN := the 6.4.2 release tarball from SourceForge
else ifeq ($(CLIPS_VERSION),svn-6x)
  CLIPS_SVN_URL ?= $(CLIPS_SVN_ROOT)/branches/64x/core
  CLIPS_SVN_REV ?= $(CLIPS_SVN_6X_REV)
  CLIPS_TAG     := svn-6x-r$(CLIPS_SVN_REV)
  CLIPS_FETCH    = svn "$(CLIPS_SVN_URL)" "$(CLIPS_SVN_REV)"
  CLIPS_ORIGIN  := branches/64x at r$(CLIPS_SVN_REV)
else ifeq ($(CLIPS_VERSION),svn-7x)
  CLIPS_SVN_URL ?= $(CLIPS_SVN_ROOT)/branches/70x/core
  CLIPS_SVN_REV ?= $(CLIPS_SVN_7X_REV)
  CLIPS_TAG     := svn-7x-r$(CLIPS_SVN_REV)
  CLIPS_FETCH    = svn "$(CLIPS_SVN_URL)" "$(CLIPS_SVN_REV)"
  CLIPS_ORIGIN  := branches/70x at r$(CLIPS_SVN_REV)
else
  $(error CLIPS_VERSION is '$(CLIPS_VERSION)': expected one of $(CLIPS_VERSIONS))
endif

CLIPS_SRC_DIR := vendor/clips-source/$(CLIPS_TAG)
BUILD_DIR     := vendor/clips-build/$(CLIPS_TAG)
TARGET        := $(BUILD_DIR)/clips

CLIPS_SRC_STAMP := $(CLIPS_SRC_DIR)/.clips-source
BUILD_STAMP     := $(BUILD_DIR)/.clips-source

CLIPS_LINK := vendor/clips

# Which binary the tests run. Empty means the one this build produces.
CLIPS   ?=
CLIPS_BIN = $(if $(strip $(CLIPS)),$(CLIPS),$(TARGET))

LDLIBS := -lm -lncurses

.PHONY: all clips clips-source clean distclean \
        test test-all test-suite test-examples \
        print-clips print-clips-versions help

all: clips

clips: $(TARGET)
	@:

$(CLIPS_SRC_STAMP): | scripts/fetch-clips.sh
	./scripts/fetch-clips.sh $(CLIPS_FETCH) "$(CLIPS_SRC_DIR)"

$(BUILD_STAMP): $(CLIPS_SRC_STAMP)
	mkdir -p "$(BUILD_DIR)"
	cp -R "$(CLIPS_SRC_DIR)/." "$(BUILD_DIR)/"
	touch "$@"

define point_clips_link
	@[ ! -e "$(CLIPS_LINK)" ] || [ -L "$(CLIPS_LINK)" ] || rm -rf "$(CLIPS_LINK)"
	@ln -sfn "clips-build/$(CLIPS_TAG)" "$(CLIPS_LINK)"
	@echo "$(CLIPS_LINK) -> clips-build/$(CLIPS_TAG)  ($(CLIPS_ORIGIN))"
endef

$(TARGET): userfunctions.c $(BUILD_STAMP)
	cp userfunctions.c $(BUILD_DIR)/
	$(MAKE) -C $(BUILD_DIR) LDLIBS="$(LDLIBS)"
	$(point_clips_link)

clips-source: $(CLIPS_SRC_STAMP)
	@cat "$(CLIPS_SRC_STAMP)"

print-clips:
	@echo 'CLIPS_VERSION $(CLIPS_VERSION)'
	@echo 'origin        $(CLIPS_ORIGIN)'
	@echo 'source        $(CLIPS_SRC_DIR)'
	@echo 'build         $(BUILD_DIR)'
	@echo 'binary        $(TARGET)'
	@[ -f "$(CLIPS_SRC_STAMP)" ] && printf 'fetched       ' && cat "$(CLIPS_SRC_STAMP)" || true

print-clips-versions:
	@echo '$(CLIPS_VERSIONS)'

test: all
	CLIPS="$(CLIPS_BIN)" ./tests/run.sh

test-suite: all
	CLIPS="$(CLIPS_BIN)" ./tests/run.sh suite

test-examples: all
	CLIPS="$(CLIPS_BIN)" ./tests/run.sh examples

test-all:
	@for v in $(CLIPS_VERSIONS); do \
	    echo; \
	    echo "=== CLIPS_VERSION=$$v ==="; \
	    $(MAKE) --no-print-directory CLIPS= CLIPS_VERSION="$$v" test || exit 1; \
	done

clean:
	-rm -rf vendor/clips-build "$(CLIPS_LINK)" tests/tmp

distclean:
	rm -rf vendor tests/tmp
	rm -f "$(ARCHIVE)"

help:
	@printf 'CLIPSncurses targets:\n\n'
	@printf '  %-16s %s\n' \
	    all             'build the binary against one CLIPS (the default)' \
	    clips-source    'fetch the selected CLIPS without building it' \
	    test            'the whole suite and the examples: tests/run.sh' \
	    test-all        'build and test against all three CLIPS versions' \
	    test-suite      'only the in-process suite, tests/test.bat' \
	    test-examples   'only the examples, driven by examples/*.keys' \
	    print-clips     'say which CLIPS this build uses and where it is' \
	    clean           'remove the build trees and test scratch' \
	    distclean       'also remove the fetched CLIPS sources and tarball'
	@printf '\nCLIPS is built from one of three sources, selected with\n'
	@printf 'CLIPS_VERSION. This build uses %s: %s.\n' \
	    '$(CLIPS_VERSION)' '$(CLIPS_ORIGIN)'
	@printf '\n  CLIPS_VERSION=6.4.2   the release tarball from SourceForge\n'
	@printf '  CLIPS_VERSION=svn-6x  branches/64x, pinned at r%s\n' '$(CLIPS_SVN_6X_REV)'
	@printf '  CLIPS_VERSION=svn-7x  branches/70x, pinned at r%s\n' '$(CLIPS_SVN_7X_REV)'
	@printf '  CLIPS_SVN_REV=        build a branch at another revision,\n'
	@printf '                        or at HEAD (needs svn installed)\n'
	@printf '  CLIPS_SVN_URL=        take the branch from somewhere else\n'
	@printf '\nEach version is fetched and built under its own directory, and\n'
	@printf 'vendor/clips points at the one built last. "make print-clips"\n'
	@printf 'says which that is.\n'
	@printf '\nOther variables: CLIPS (which binary the tests run).\n'
