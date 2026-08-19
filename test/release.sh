#!/bin/sh
set -eu

usage() {
    printf 'Usage: %s PACKAGE ARCH [--run-installed FIXTURE]\n' "$0" >&2
    exit 2
}

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    usage
fi

package_path=$1
expected_arch=$2
case "$expected_arch" in
    amd64|arm64)
        ;;
    *)
        printf 'release check: unsupported architecture: %s\n' "$expected_arch" >&2
        exit 2
        ;;
esac

if [ ! -f "$package_path" ]; then
    printf 'release check: package does not exist: %s\n' "$package_path" >&2
    exit 1
fi

package_name=$(dpkg-deb --field "$package_path" Package)
package_version=$(dpkg-deb --field "$package_path" Version)
package_arch=$(dpkg-deb --field "$package_path" Architecture)
package_depends=$(dpkg-deb --field "$package_path" Depends)

[ "$package_name" = journql ]
[ "$package_version" = 0.1.0+duckdb1.4.5 ]
[ "$package_arch" = "$expected_arch" ]
[ "$package_depends" = 'systemd, libc6' ]

extract_root=$(mktemp -d)
control_root=$(mktemp -d)
cleanup() {
    rm -rf "$extract_root" "$control_root"
}
trap cleanup EXIT HUP INT TERM

dpkg-deb --extract "$package_path" "$extract_root"
dpkg-deb --control "$package_path" "$control_root"

for path in \
    usr/bin/journql \
    usr/lib/journql/duckdb \
    usr/share/lintian/overrides/journql \
    usr/share/man/man1/journql.1.gz \
    usr/share/doc/journql/copyright \
    usr/share/doc/journql/changelog.gz \
    usr/share/doc/journql/LICENSE \
    usr/share/doc/journql/NOTICE \
    usr/share/doc/journql/README.md
do
    [ -f "$extract_root/$path" ]
done

manual_page="$extract_root/usr/share/man/man1/journql.1.gz"
gzip -t "$manual_page"
manual_text=$(gzip -dc "$manual_page")
printf '%s\n' "$manual_text" | \
    grep -F "journql [OPTIONS] \\-\\- [JOURNAL SELECTION] \\-\\- 'JOURNAL QUERY'" >/dev/null
manual_sections=$(printf '%s\n' "$manual_text" | sed -n \
    -e 's/^\.SH "\(.*\)"$/\1/p' \
    -e 's/^\.SH \([^"].*\)$/\1/p')
for section in \
    NAME SYNOPSIS DESCRIPTION OPTIONS 'JOURNAL SELECTION' 'JOURNAL QUERY' \
    'RESULT FORMATS' 'JOURNAL RELATION' ENVIRONMENT FILES 'EXIT STATUS' \
    LIMITS EXAMPLES 'SEE ALSO'
do
    printf '%s\n' "$manual_sections" | grep -Fx "$section" >/dev/null
done

for path in postinst postrm md5sums; do
    [ -f "$control_root/$path" ]
done

# shellcheck disable=SC2016  # Match the literal command shown to operators.
grep -F 'sudo usermod -aG systemd-journal' "$control_root/postinst" >/dev/null
test -x "$extract_root/usr/bin/journql"
test -x "$extract_root/usr/lib/journql/duckdb"
grep -F 'DuckDB 1.4.5' "$extract_root/usr/bin/journql" >/dev/null
grep -F 'Copyright: 2018-2025 Stichting DuckDB Foundation' \
    "$extract_root/usr/share/doc/journql/copyright" >/dev/null

duckdb_description=$(file "$extract_root/usr/lib/journql/duckdb")
case "$expected_arch:$duckdb_description" in
    amd64:*'x86-64'*)
        ;;
    arm64:*'ARM aarch64'*)
        ;;
    *)
        printf 'release check: DuckDB architecture does not match %s: %s\n' \
            "$expected_arch" "$duckdb_description" >&2
        exit 1
        ;;
esac

if [ "$#" -eq 2 ]; then
    printf 'verified %s (%s)\n' "$package_path" "$expected_arch"
    exit 0
fi

if [ "$3" != --run-installed ] || [ "$#" -ne 4 ]; then
    usage
fi

fixture_path=$4
if [ ! -f "$fixture_path" ]; then
    printf 'release check: fixture does not exist: %s\n' "$fixture_path" >&2
    exit 1
fi

host_arch=$(dpkg --print-architecture)
if [ "$host_arch" != "$expected_arch" ]; then
    printf 'release check: cannot run %s on host architecture %s\n' \
        "$expected_arch" "$host_arch" >&2
    exit 2
fi

fake_bin=$(mktemp -d)
cat >"$fake_bin/journalctl" <<EOF
#!/bin/sh
cat '$fixture_path'
EOF
chmod 755 "$fake_bin/journalctl"
trap 'rm -rf "$fake_bin"; cleanup' EXIT HUP INT TERM

dpkg --install "$package_path"
PATH="$fake_bin:$PATH" journql --help >/dev/null
version_output=$(PATH="$fake_bin:$PATH" journql --version)
printf '%s\n' "$version_output" | grep -F 'journql 0.1.0' >/dev/null
printf '%s\n' "$version_output" | grep -F 'DuckDB 1.4.5' >/dev/null
query_result=$(PATH="$fake_bin:$PATH" journql --format csv -- -- \
    'SELECT count(*) AS count FROM journal;')
printf '%s\n' "$query_result" | grep -Fx 'count' >/dev/null
printf '%s\n' "$query_result" | grep -Fx '1' >/dev/null

printf 'verified and ran %s (%s)\n' "$package_path" "$expected_arch"
