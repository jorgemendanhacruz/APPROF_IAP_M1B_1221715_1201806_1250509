#!/usr/bin/env bash

VENV_DIR="$(dirname "$0")/.venv"
REQUIREMENTS="$(dirname "$0")/requirements.txt"

# Activate venv
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "ERROR: venv not found at $VENV_DIR"
    exit 1
fi

source "$VENV_DIR/bin/activate"
echo "Activated venv: $VIRTUAL_ENV"
echo "Python: $(python --version)"
echo ""

# Check each package in requirements.txt
PASS=0
FAIL=0

while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" == \#* ]] && continue

    # Extract package name (strip version specifier)
    pkg_name=$(echo "$line" | sed 's/[>=<!].*//' | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    display_name=$(echo "$line" | sed 's/[>=<!].*//')
    expected_version=$(echo "$line" | grep -o '[0-9][0-9.]*' | head -1)

    # Get installed version
    installed=$(python -c "
import importlib.metadata, sys
try:
    v = importlib.metadata.version('${display_name}')
    print(v)
except importlib.metadata.PackageNotFoundError:
    print('NOT_FOUND')
" 2>/dev/null)

    if [ "$installed" = "NOT_FOUND" ]; then
        printf "  FAIL  %-30s not installed\n" "$display_name"
        ((FAIL++))
    elif [ "$installed" = "$expected_version" ]; then
        printf "  OK    %-30s %s\n" "$display_name" "$installed"
        ((PASS++))
    else
        printf "  WARN  %-30s installed=%s expected=%s\n" "$display_name" "$installed" "$expected_version"
        ((PASS++))
    fi

done < "$REQUIREMENTS"

echo ""
echo "Result: $PASS OK / $FAIL failed"

if [ $FAIL -gt 0 ]; then
    echo "Run: pip install -r requirements.txt"
    exit 1
fi
