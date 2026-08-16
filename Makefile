SHELL = /bin/bash

NAME       := journql
VERSION    := $(shell cat VERSION)
ARCH       ?= amd64
DUCKDB_VER := 1.4.5
DUCKDB_ASSET_ARCH := $(ARCH)
ifeq ($(ARCH), arm64)
	DUCKDB_ASSET_ARCH := aarch64
endif
DUCKDB_URL := https://github.com/duckdb/duckdb/releases/download/v$(DUCKDB_VER)/duckdb_cli-linux-$(DUCKDB_ASSET_ARCH).zip

ifeq ($(ARCH), amd64)
	DUCKDB_SHA256 := ff4ef9ec59fe3e1a1f3dd1004c6218d1fd59c0533c185c968c4403fd0240d02b
else ifeq ($(ARCH), arm64)
	DUCKDB_SHA256 := c6d1c19631bb4d7a2a5dcf30586d888e167ce6fb22396060110c7a32e2bfc298
endif

BUILD_DIR  := build/$(NAME)_$(VERSION)_$(ARCH)
DEB_FILE   := build/$(NAME)_$(VERSION)_$(ARCH).deb

.PHONY: all clean deb fetch-duckdb stage lint pre-commit

all: deb

fetch-duckdb:
	$(call check_defined, DUCKDB_SHA256, Set DUCKDB_SHA256 for ARCH=$(ARCH) in the Makefile)
	mkdir -p build/cache
	if [ ! -f build/cache/duckdb-$(DUCKDB_VER)-$(ARCH).zip ]; then \
		curl -L --retry 3 -o build/cache/duckdb-$(DUCKDB_VER)-$(ARCH).zip $(DUCKDB_URL); \
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
	install -m 644 LICENSE $(BUILD_DIR)/usr/share/doc/$(NAME)/LICENSE
	install -m 644 NOTICE $(BUILD_DIR)/usr/share/doc/$(NAME)/NOTICE

	# DuckDB binary
	unzip -o build/cache/duckdb-$(DUCKDB_VER)-$(ARCH).zip -d $(BUILD_DIR)/usr/lib/$(NAME)/
	chmod 755 $(BUILD_DIR)/usr/lib/$(NAME)/duckdb

	# Control files, with version/arch substituted
	sed -e 's/__VERSION__/$(VERSION)+duckdb$(DUCKDB_VER)/' \
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

lint: deb
	lintian $(BUILD_DIR).deb

clean:
	rm -rf build

# check that given variables are set and non-empty; die with an error otherwise.
check_defined = $(strip $(foreach 1,$1, $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = $(if $(value $1),, $(error Undefined $1$(if $2, ($2))))
