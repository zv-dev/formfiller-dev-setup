# FormFiller Dev Setup

Development-only monorepo configuration for FormFiller packages. This setup uses npm workspaces to link all FormFiller packages together during local development.

## Prerequisites

- Node.js >= 20.0.0
- npm >= 7.0.0 (for workspaces support)
- All FormFiller repositories cloned in `/var/www/`:
  - formfiller-types
  - formfiller-schema
  - formfiller-validator
  - formfiller-backend
  - formfiller-frontend

## Setup

1. **Deploy the workspace configuration:**

```bash
cd /var/www/formfiller-dev-setup
./deploy.sh
```

This copies `workspace-package.json` to `/var/www/package.json`.

2. **Install all dependencies:**

```bash
cd /var/www
npm install
```

This will:
- Install dependencies for all packages
- Symlink internal packages (formfiller-schema, formfiller-types, formfiller-validator) instead of downloading from GitHub
- Create a shared `node_modules` in `/var/www/`
- Automatically clean up any nested formfiller packages (via postinstall script)

3. **Build libraries (required before running apps):**

```bash
npm run build:libs
```

## Development

### Starting the Backend

```bash
npm run dev:backend
```

### Starting the Frontend

```bash
npm run dev:frontend
```

### Building Individual Packages

```bash
npm run build:types      # Build formfiller-types
npm run build:schema     # Build formfiller-schema
npm run build:validator  # Build formfiller-validator
npm run build:backend    # Build formfiller-backend
npm run build:frontend   # Build frontend
```

### Running Tests

```bash
npm run test:schema      # Test formfiller-schema
npm run test:validator   # Test formfiller-validator
npm run test:backend     # Test formfiller-backend
npm run test:frontend    # Test frontend
npm run test:libs        # Test all libraries
```

## How It Works

When you run `npm install` from `/var/www/`, npm workspaces:
1. Detects the workspace configuration in `package.json`
2. Creates symlinks for internal dependencies instead of downloading them
3. Changes in any package are immediately visible to dependent packages

### Package Dependency Order

```
formfiller-types (no internal deps)
       ↓
formfiller-schema (depends on types)
       ↓
formfiller-validator (depends on schema)
       ↓
formfiller-backend & formfiller-frontend (depend on all above)
```

## Production Deployment

This setup is **development-only**. Production deployments work unchanged:
- Each package's `package.json` still contains GitHub URLs for dependencies
- When deployed individually, packages install from GitHub as before
- No changes needed to CI/CD pipelines

## Troubleshooting

### Symlinks not working

Make sure you're running `npm install` from `/var/www/` (where the symlinked `package.json` is), not from within a specific package.

### Package changes not visible

1. Make sure the source package is built: `npm run build:schema`
2. The TypeScript compiler in dependent packages should pick up changes automatically

### Clean reinstall

```bash
cd /var/www
rm -rf node_modules
rm -rf formfiller-*/node_modules
npm install
npm run build:libs
```

## Available Scripts

| Script | Description |
|--------|-------------|
| `npm run install:all` | Install all dependencies |
| `npm run build:libs` | Build all libraries in correct order |
| `npm run build:all` | Build everything |
| `npm run dev:backend` | Start backend dev server |
| `npm run dev:frontend` | Start frontend dev server |
| `npm run test:libs` | Run tests for all libraries |
| `npm run lint:all` | Lint all packages |
