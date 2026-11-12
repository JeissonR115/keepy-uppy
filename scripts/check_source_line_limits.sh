#!/usr/bin/env bash
set -uo pipefail

readonly MAX_LINES=400
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
readonly SCAN_ROOT="$(cd -- "${1:-$PROJECT_ROOT}" && pwd)"

if [[ ! -d "$SCAN_ROOT/src" || ! -d "$SCAN_ROOT/tests" ]]; then
	printf 'Expected src/ and tests/ under scan root: %s\n' "$SCAN_ROOT" >&2
	exit 2
fi

violations=0

check_files() {
	local file line_count relative_path
	while IFS= read -r -d '' file; do
		line_count=$(wc -l < "$file")
		if (( line_count > MAX_LINES )); then
			relative_path=${file#"$SCAN_ROOT"/}
			printf '%s: %s lines (limit %s)\n' "$relative_path" "$line_count" "$MAX_LINES"
			violations=$((violations + 1))
		fi
	done < <("$@")
}

check_files find "$SCAN_ROOT/src" "$SCAN_ROOT/tests" -type f -name '*.gd' -print0
check_files find "$SCAN_ROOT" \
	\( -path "$SCAN_ROOT/.git" -o -path "$SCAN_ROOT/.godot" \) -prune \
	-o -type f -name '*.tscn' -print0

if (( violations > 0 )); then
	printf '%s first-party source file(s) exceed %s lines.\n' "$violations" "$MAX_LINES" >&2
	exit 1
fi

printf 'All checked GDScript and scene files are at or below %s lines.\n' "$MAX_LINES"
