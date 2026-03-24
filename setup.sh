#!/bin/bash
set -euo pipefail

echo ""
echo "  Refraction Setup"
echo "  ================"
echo ""

pip3 install -r requirements.txt
python3 run_all.py
echo ""
echo "Setup complete. Open RefractionApp/ in Xcode."
