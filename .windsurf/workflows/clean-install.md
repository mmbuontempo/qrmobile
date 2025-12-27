---
description: Clean install - Reinstalar proyecto desde cero (node_modules, cache, prisma)
---

# Clean Install Workflow

Performs a complete reset of the project dependencies and cache, equivalent to cloning the repo fresh.

## Steps

### 1. Stop all Node processes

```powershell
Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
```

### 2. Remove node_modules

```powershell
Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
```

### 3. Remove package-lock.json

```powershell
Remove-Item -Force package-lock.json -ErrorAction SilentlyContinue
```

### 4. Remove Vite cache

```powershell
Remove-Item -Recurse -Force .vite -ErrorAction SilentlyContinue
```

### 5. Remove TypeScript build cache

```powershell
Remove-Item -Recurse -Force .react-router, tsconfig.tsbuildinfo -ErrorAction SilentlyContinue
```

### 6. Clear npm cache (optional, only if corruption suspected)

```powershell
npm cache clean --force
```

### 7. Fresh install

// turbo
```powershell
npm install
```

### 8. Generate Prisma client

// turbo
```powershell
npx prisma generate
```

### 9. Start development server

```powershell
npm run dev
```

## When to Use

- **504 Outdated Optimize Dep** errors in browser
- **Invalid hook call** errors (duplicate React)
- **Module not found** after package updates
- **Prisma client not initialized** errors
- After major dependency upgrades
- When something "just doesn't work" and you've tried everything

## What Gets Deleted

| Item | Purpose |
|------|---------|
| `node_modules/` | All installed packages |
| `package-lock.json` | Dependency lock file |
| `.vite/` | Vite optimization cache |
| `.react-router/` | React Router build cache |
| `tsconfig.tsbuildinfo` | TypeScript incremental build |

## What is Preserved

- Source code (`app/`, `public/`, etc.)
- Configuration files (`.env`, `vite.config.ts`, etc.)
- Database (PostgreSQL container)
- Git history

## Time Estimate

- Delete: ~10 seconds
- npm install: ~1-2 minutes
- prisma generate: ~5 seconds
- Total: ~2 minutes
