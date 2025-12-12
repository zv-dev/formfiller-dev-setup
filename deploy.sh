#!/bin/bash

# Deploy workspace package.json to parent directory
# Usage: ./deploy.sh
# Environment variables:
#   FORCE=true    - Overwrite existing package.json without confirmation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_FILE="$SCRIPT_DIR/workspace-package.json"
TARGET_FILE="$PARENT_DIR/package.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "=========================================="
echo "  FormFiller Dev Setup - Deploy"
echo "=========================================="
echo ""

# Check if source exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo -e "${RED}Error: workspace-package.json not found${NC}"
    exit 1
fi

# Check if target exists
if [ -f "$TARGET_FILE" ]; then
    if [ "$FORCE" != "true" ]; then
        echo -e "${YELLOW}Warning: $TARGET_FILE already exists${NC}"
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
        fi
    fi
fi

# Copy the file
cp "$SOURCE_FILE" "$TARGET_FILE"
echo -e "${GREEN}✓${NC} Deployed workspace-package.json to $TARGET_FILE"

echo ""
echo "Next steps:"
echo "  1. cd $PARENT_DIR"
echo "  2. npm install"
echo "  3. npm run build:libs"
echo ""
