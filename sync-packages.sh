#!/bin/bash

# sync-packages.sh - Dev környezetben a library csomagok újraépítése és szinkronizálása
# 
# Usage: ./sync-packages.sh [--restart] [--schema-only]
#
# Options:
#   --restart      Automatikusan újraindítja a backend szervert
#   --schema-only  Csak a schema és függő csomagokat építi újra
#
# A script a megfelelő sorrendben építi újra a csomagokat:
# types -> schema -> validator -> embed

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
AUTO_RESTART=false
SCHEMA_ONLY=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --restart)
      AUTO_RESTART=true
      shift
      ;;
    --schema-only)
      SCHEMA_ONLY=true
      shift
      ;;
  esac
done

# Logging functions
log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_step() { echo -e "${BLUE}▶${NC} $1"; }

echo ""
echo "=========================================="
echo "  FormFiller Package Sync"
echo "=========================================="
echo ""

# Check if we're in a workspace
if [ ! -f "$PARENT_DIR/package.json" ]; then
  log_error "Workspace package.json not found in $PARENT_DIR"
  log_warn "Run 'npm run deploy' first to set up the workspace"
  exit 1
fi

cd "$PARENT_DIR"

# Step 1: Build types (if not schema-only)
if [ "$SCHEMA_ONLY" = "false" ]; then
  log_step "Step 1: Building formfiller-types..."
  if [ -d "formfiller-types" ]; then
    npm run build -w formfiller-types 2>/dev/null || log_warn "formfiller-types build skipped (no build script)"
    log_info "Types built"
  else
    log_warn "formfiller-types not found, skipping"
  fi
else
  log_warn "Skipping types (--schema-only)"
fi

# Step 2: Build schema
log_step "Step 2: Building formfiller-schema..."
if [ -d "formfiller-schema" ]; then
  npm run build -w formfiller-schema
  log_info "Schema built"
  
  # Show version
  SCHEMA_VERSION=$(node -p "require('./formfiller-schema/package.json').version")
  echo "     Schema version: ${SCHEMA_VERSION}"
else
  log_error "formfiller-schema not found!"
  exit 1
fi

# Step 3: Build validator
log_step "Step 3: Building formfiller-validator..."
if [ -d "formfiller-validator" ]; then
  npm run build -w formfiller-validator
  log_info "Validator built"
else
  log_warn "formfiller-validator not found, skipping"
fi

# Step 4: Build embed
log_step "Step 4: Building formfiller-embed..."
if [ -d "formfiller-embed" ]; then
  npm run build -w formfiller-embed
  log_info "Embed built"
else
  log_warn "formfiller-embed not found, skipping"
fi

# Step 5: Restart backend if requested
if [ "$AUTO_RESTART" = "true" ]; then
  log_step "Step 5: Restarting backend server..."
  
  # Stop running backend server (graceful)
  pkill -SIGTERM -f "ts-node-dev.*server.ts" 2>/dev/null || true
  pkill -SIGTERM -f "node.*formfiller-backend" 2>/dev/null || true
  sleep 2
  
  if [ -d "formfiller-backend" ]; then
    cd formfiller-backend
    npm run dev > ../backend.log 2>&1 &
    sleep 3
    
    if pgrep -f "ts-node-dev.*server.ts" > /dev/null; then
      log_info "Backend server restarted successfully"
    else
      log_warn "Backend server may not have started correctly. Check backend.log"
    fi
    cd "$PARENT_DIR"
  else
    log_warn "Backend not found, skipping restart"
  fi
else
  log_warn "Backend restart skipped (use --restart to auto-restart)"
fi

echo ""
echo "=========================================="
log_info "Package sync completed!"
echo "=========================================="
echo ""
echo "📋 Summary:"
echo "   - Schema v${SCHEMA_VERSION} built"
echo "   - Validator rebuilt"
echo "   - Embed rebuilt"
echo ""

if [ "$AUTO_RESTART" = "false" ]; then
  echo "💡 Tips:"
  echo "   - Backend: Changes will take effect on next restart"
  echo "   - Frontend: Vite will hot-reload automatically"
  echo ""
fi

