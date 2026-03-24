#!/bin/bash
# bundle_python.sh — Create a relocatable Python venv inside the app bundle.
# The venv is self-contained with all dependencies so users don't need
# a system Python install.
#
# Usage:
#   bash scripts/bundle_python.sh [--python /path/to/python3]
#
# Options:
#   --python PATH   Use a specific Python interpreter (default: python3)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEST="$PROJECT_ROOT/RefractionApp/Refraction/Resources/python-env"
PYTHON_BIN="${1:-python3}"

# Allow --python flag
if [[ "${1:-}" == "--python" ]]; then
    PYTHON_BIN="${2:?Missing path after --python}"
fi

echo "=== Refraction: Bundle Python Environment ==="
echo "Project root: $PROJECT_ROOT"
echo "Python:       $PYTHON_BIN"
echo "Destination:  $DEST"
echo ""

# Verify Python version >= 3.12
PYTHON_VERSION=$("$PYTHON_BIN" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
MAJOR=$("$PYTHON_BIN" -c "import sys; print(sys.version_info.major)")
MINOR=$("$PYTHON_BIN" -c "import sys; print(sys.version_info.minor)")

if [[ "$MAJOR" -lt 3 ]] || { [[ "$MAJOR" -eq 3 ]] && [[ "$MINOR" -lt 12 ]]; }; then
    echo "ERROR: Python >= 3.12 required, found $PYTHON_VERSION"
    exit 1
fi
echo "Python version: $PYTHON_VERSION (OK)"

# Clean previous environment
if [[ -d "$DEST" ]]; then
    echo "Removing previous environment..."
    rm -rf "$DEST"
fi

# Create venv with --copies so the Python binary is copied (not symlinked).
# This makes the venv relocatable inside the .app bundle.
echo "Creating virtual environment (--copies for relocatability)..."
"$PYTHON_BIN" -m venv --copies "$DEST"

# Activate and install dependencies
echo "Installing dependencies from requirements.txt..."
"$DEST/bin/pip" install --no-cache-dir --upgrade pip setuptools wheel 2>&1 | tail -1
"$DEST/bin/pip" install --no-cache-dir -r "$PROJECT_ROOT/requirements.txt" 2>&1 | tail -1

# Install the refraction package itself (editable not needed for bundling)
echo "Installing refraction package..."
"$DEST/bin/pip" install --no-cache-dir "$PROJECT_ROOT" 2>&1 | tail -1

# Verify the installation works
echo ""
echo "Verifying installation..."
"$DEST/bin/python3" -c "from refraction.analysis.engine import analyze; print('  refraction.analysis OK')"
"$DEST/bin/python3" -c "from refraction.server.api import _make_app; print('  refraction.server OK')"
"$DEST/bin/python3" -c "import uvicorn; print('  uvicorn OK')"
"$DEST/bin/python3" -c "import pandas; print('  pandas OK')"
"$DEST/bin/python3" -c "import scipy; print('  scipy OK')"

# Make pyvenv.cfg paths relative for relocatability
# Replace the absolute home path with a relative marker
echo ""
echo "Making paths relative for relocatability..."
if [[ -f "$DEST/pyvenv.cfg" ]]; then
    # Store the original home for reference, then make relative
    sed -i '' "s|home = .*|home = python-env/bin|g" "$DEST/pyvenv.cfg" 2>/dev/null || true
fi

# Strip __pycache__ and .pyc to reduce size
echo "Stripping __pycache__ directories..."
find "$DEST" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$DEST" -name "*.pyc" -delete 2>/dev/null || true

# Strip test directories from installed packages to reduce size
echo "Stripping test directories from packages..."
find "$DEST/lib" -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true
find "$DEST/lib" -type d -name "test" -exec rm -rf {} + 2>/dev/null || true

SIZE=$(du -sh "$DEST" | cut -f1)
echo ""
echo "=== Python environment bundled successfully ==="
echo "Location: $DEST"
echo "Size:     $SIZE"
echo ""
echo "Test with:"
echo "  $DEST/bin/python3 -c \"from refraction.analysis.engine import analyze; print('OK')\""
