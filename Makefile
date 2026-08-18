SHELL = /bin/bash

NAME       := journql
VERSION    := $(shell cat VERSION)
ARCH       ?= amd64
DUCKDB_VER := 1.4.5
DUCKDB_URL := https://github.com/duckdb/duckdb/releases/download/v$(DUCKDB_VER)/duckdb_cli-linux-$(ARCH).zip
PACKAGE_VERSION := $(VERSION)+duckdb$(DUCKDB_VER)
CHANGELOG_FILE  := debian/changelog
UBUNTU_IMAGE ?= ubuntu:24.04
DOCKER       ?= docker

ifeq ($(ARCH), amd64)
	DUCKDB_SHA256 := ff4ef9ec59fe3e1a1f3dd1004c6218d1fd59c0533c185c968c4403fd0240d02b
	STRIP := x86_64-linux-gnu-strip
else ifeq ($(ARCH), arm64)
	DUCKDB_SHA256 := c6d1c19631bb4d7a2a5dcf30586d888e167ce6fb22396060110c7a32e2bfc298
	STRIP := aarch64-linux-gnu-strip
endif

BUILD_DIR  := build/$(NAME)_$(VERSION)_$(ARCH)
DEB_FILE   := build/$(NAME)_$(VERSION)_$(ARCH).deb

.PHONY: all clean deb fetch-duckdb stage lint pre-commit changelog test verify-package verify-release verify-release-docker

all: deb

changelog:
	git-cliff --config cliff-debian.toml \
		--unreleased \
		--tag "$(PACKAGE_VERSION)" \
		--output "$(CHANGELOG_FILE)"

fetch-duckdb:
	$(call check_defined, DUCKDB_SHA256, Set DUCKDB_SHA256 for ARCH=$(ARCH) in the Makefile)
	mkdir -p build/cache
	if [ ! -f build/cache/duckdb-$(DUCKDB_VER)-$(ARCH).zip ]; then \
		curl -L --fail --retry 3 -o build/cache/duckdb-$(DUCKDB_VER)-$(ARCH).zip $(DUCKDB_URL); \
	fi
	echo "$(DUCKDB_SHA256)  build/cache/duckdb-$(DUCKDB_VER)-$(ARCH).zip" | sha256sum -c -

stage: fetch-duckdb
	rm -rf $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/DEBIAN
	mkdir -p $(BUILD_DIR)/usr/lib/$(NAME)
	mkdir -p $(BUILD_DIR)/usr/share/doc/$(NAME)

	# CLI (and any other files staged under debian/usr/)
	cp -r debian/usr $(BUILD_DIR)/
	chmod 755 $(BUILD_DIR)/usr/bin/journql
	install -m 644 debian/copyright $(BUILD_DIR)/usr/share/doc/$(NAME)/copyright
	install -m 644 $(CHANGELOG_FILE) $(BUILD_DIR)/usr/share/doc/$(NAME)/changelog
	gzip -n -9 $(BUILD_DIR)/usr/share/doc/$(NAME)/changelog
	install -m 644 LICENSE $(BUILD_DIR)/usr/share/doc/$(NAME)/LICENSE
	install -m 644 NOTICE $(BUILD_DIR)/usr/share/doc/$(NAME)/NOTICE
	install -m 644 README.md $(BUILD_DIR)/usr/share/doc/$(NAME)/README.md

	# DuckDB binary
	unzip -o build/cache/duckdb-$(DUCKDB_VER)-$(ARCH).zip -d $(BUILD_DIR)/usr/lib/$(NAME)/
	chmod 755 $(BUILD_DIR)/usr/lib/$(NAME)/duckdb
	$(STRIP) --strip-unneeded $(BUILD_DIR)/usr/lib/$(NAME)/duckdb

	# Control files, with version/arch substituted
	sed -e 's/__VERSION__/$(PACKAGE_VERSION)/' \
	    -e 's/__ARCH__/$(ARCH)/' \
	    debian/control > $(BUILD_DIR)/DEBIAN/control
	install -m 755 debian/postinst $(BUILD_DIR)/DEBIAN/postinst
	install -m 755 debian/postrm $(BUILD_DIR)/DEBIAN/postrm

	# permissions on packaging metadata
	chmod 644 $(BUILD_DIR)/DEBIAN/control
	chmod 555 $(BUILD_DIR)/DEBIAN/postinst $(BUILD_DIR)/DEBIAN/postrm

	# md5sums for every shipped file (excludes DEBIAN/ itself)
	find $(BUILD_DIR) -type f ! -path "$(BUILD_DIR)/DEBIAN/*" \
		-exec md5sum {} \; \
		| sed "s%$(BUILD_DIR)/%%" > $(BUILD_DIR)/DEBIAN/md5sums
	chmod 644 $(BUILD_DIR)/DEBIAN/md5sums

deb: stage
	dpkg-deb --build --root-owner-group -Zxz $(BUILD_DIR)
	@echo "Built $(BUILD_DIR).deb"

pre-commit:
	pre-commit run --all-files

test:
	test/bats/bin/bats test/journql.bats

verify-package: deb
	test/release.sh "$(DEB_FILE)" "$(ARCH)"

verify-release: test
	$(MAKE) verify-package ARCH=amd64
	$(MAKE) verify-package ARCH=arm64
	$(MAKE) lint ARCH=amd64
	$(MAKE) lint ARCH=arm64
	if command -v dpkg >/dev/null 2>&1; then \
		native_arch=$$(dpkg --print-architecture); \
		case "$$native_arch" in \
			amd64|arm64) \
				test/release.sh "build/$(NAME)_$(VERSION)_$${native_arch}.deb" \
					"$$native_arch" --run-installed test/fixtures/basic-journal.json; \
				;; \
		esac; \
	fi

verify-release-docker:
	$(DOCKER) run --rm -v "$(CURDIR):/repo" -w /repo "$(UBUNTU_IMAGE)" \
		bash -lc 'set -eu; \
		apt-get update -qq; \
		DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
			make unzip binutils binutils-x86-64-linux-gnu \
			binutils-aarch64-linux-gnu file ca-certificates curl lintian systemd; \
		make verify-release'

lint: deb
	lintian $(BUILD_DIR).deb

clean:
	rm -rf build

# check that given variables are set and non-empty; die with an error otherwise.
check_defined = $(strip $(foreach 1,$1, $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = $(if $(value $1),, $(error Undefined $1$(if $2, ($2))))
