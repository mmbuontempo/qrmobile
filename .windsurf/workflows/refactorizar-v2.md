---
description: Extraer componentes, organizar jerarquía y crear bloques reutilizables
---

# /refactorizar

> **Purpose**: Extract components, organize directory hierarchy, and create reusable blocks following best practices.

---

## 📚 GLOSSARY

| Term | Meaning | When to apply |
|------|---------|---------------|
| **Extract** | Move code to its own file/function | Component >100 lines, logic >15 lines |
| **Colocation** | Keep related files together | Feature-specific components near their route |
| **Barrel export** | `index.ts` with public API | Every module folder |
| **Atomic component** | Single responsibility, no side effects | UI primitives in `components/ui/` |
| **Feature module** | Self-contained business logic | `modules/{feature}/` |
| **LLM-friendly** | Comments that help AI understand context | Every exported function/component |

---

## 🏗️ DIRECTORY HIERARCHY

```
app/
├── components/           # Shared UI components
│   ├── ui/              # Atomic primitives (Button, Input, Modal)
│   │   └── index.ts     # Barrel: export * from './Button'
│   ├── layout/          # Layout components (Header, Footer, Sidebar)
│   └── forms/           # Form components (FormField, FormSection)
│
├── modules/             # Feature modules (business logic)
│   ├── {feature}/       # e.g., storage/, catalog/, auth/
│   │   ├── components/  # Feature-specific components
│   │   ├── hooks/       # Feature-specific hooks
│   │   ├── utils/       # Feature-specific utilities
│   │   ├── types.ts     # Feature types
│   │   └── index.ts     # Public API (barrel export)
│   └── shared/          # Cross-module utilities
│
├── routes/              # Page components (loaders/actions only)
│   └── {route}.tsx      # Thin: imports from modules/, renders components
│
├── hooks/               # Global custom hooks
├── lib/                 # Core utilities (prisma, auth, etc.)
└── plantillas/          # Microsite templates
    └── {type}/          # gastronomy/, store/, service/
        ├── components/  # Template-specific components
        └── index.ts     # Template entry point
```

### Hierarchy Rules

1. **Routes are thin** - Only loader/action + component composition
2. **Modules are self-contained** - Import via `index.ts`, never internals
3. **Components are dumb** - No business logic, only props → UI
4. **Hooks encapsulate logic** - State + effects in one place

---

## 🧱 EXTRACTION THRESHOLDS

| Situation | Action | Target location |
|-----------|--------|-----------------|
| Component >100 lines | Split into subcomponents | Same folder or `components/` |
| JSX block >30 lines | Extract to component | Same folder |
| Logic >15 lines | Extract to hook | `hooks/` or `modules/{feature}/hooks/` |
| Utility >10 lines | Extract to function | `lib/` or `modules/{feature}/utils/` |
| Repeated code (2+ places) | Extract to shared | `modules/shared/` or `components/ui/` |
| Route >150 lines | Split loader/action to `.server.ts` | Same folder |

---

## 🤖 LLM-FRIENDLY COMMENTS

Add structured comments to help LLMs understand context:

### Component Header
```tsx
/**
 * @component ProductCard
 * @description Displays a single product with image, name, price
 * @location app/components/products/ProductCard.tsx
 * 
 * @props
 * - product: Product - The product data to display
 * - onEdit?: () => void - Optional edit callback
 * - variant?: 'grid' | 'list' - Display variant
 * 
 * @usage
 * <ProductCard product={product} onEdit={handleEdit} />
 * 
 * @dependencies
 * - OptimizedImage (ui/OptimizedImage)
 * - formatPrice (lib/format)
 */
```

### Hook Header
```tsx
/**
 * @hook useProductActions
 * @description Handles CRUD operations for products
 * @location app/hooks/useProductActions.ts
 * 
 * @returns
 * - handleCreate: (data) => Promise<void>
 * - handleUpdate: (id, data) => Promise<void>
 * - handleDelete: (id) => Promise<void>
 * - isLoading: boolean
 * 
 * @sideEffects
 * - Calls API endpoints via fetcher
 * - Triggers revalidation on success
 */
```

### Module Index Header
```tsx
/**
 * @module storage
 * @description File storage operations (R2, uploads, signed URLs)
 * @location app/modules/storage/index.ts
 * 
 * @exports
 * - uploadFile: Upload file to R2
 * - getSignedUrl: Generate signed URL for asset
 * - deleteFile: Remove file from R2
 * 
 * @internal (do not import directly)
 * - r2Client: AWS S3 client instance
 * - policies: TTL and size policies
 */
```

---

## 🔍 STEP 1: DETECT CANDIDATES

### Large components (>100 lines)
// turbo
```powershell
Get-ChildItem -Path "app/components","app/routes" -Recurse -Filter "*.tsx" | ForEach-Object { $lines = (Get-Content $_.FullName).Count; if ($lines -gt 100) { [PSCustomObject]@{Name=$_.Name;Lines=$lines;Path=$_.FullName} } } | Sort-Object Lines -Descending | Select-Object -First 15 | Format-Table -AutoSize
```

### Files in legacy folders
// turbo
```powershell
Get-ChildItem -Path "app/services","app/server" -Recurse -Filter "*.ts" -ErrorAction SilentlyContinue | Select-Object Name, FullName
```

### Components without LLM comments
// turbo
```powershell
Get-ChildItem -Path "app/components" -Recurse -Filter "*.tsx" | ForEach-Object { $content = Get-Content $_.FullName -Raw; if ($content -notmatch '@component') { $_.Name } } | Select-Object -First 10
```

### Hooks without documentation
// turbo
```powershell
Get-ChildItem -Path "app/hooks" -Filter "*.ts" | ForEach-Object { $content = Get-Content $_.FullName -Raw; if ($content -notmatch '@hook') { $_.Name } } | Select-Object -First 10
```

---

## 🔧 STEP 2: EXTRACT & ORGANIZE

For each candidate:

### A. Component Extraction

1. **Identify boundaries** - Find logical sections in JSX
2. **Create subcomponent** - New file with props interface
3. **Add LLM header** - Document purpose, props, usage
4. **Update parent** - Import and use new component
5. **Verify** - `npx tsc --noEmit`

### B. Hook Extraction

1. **Identify logic** - useState + useEffect + handlers
2. **Create hook file** - `use{Feature}.ts`
3. **Add LLM header** - Document returns, side effects
4. **Update component** - Replace inline logic with hook
5. **Verify** - `npx tsc --noEmit`

### C. Module Migration

1. **Create module folder** - `modules/{feature}/`
2. **Move related files** - services → modules
3. **Create barrel** - `index.ts` with public exports
4. **Update imports** - Find & replace across codebase
5. **Delete legacy** - Remove old files
6. **Verify** - `npx tsc --noEmit`

---

## 📦 STEP 3: CREATE REUSABLE BLOCKS

### Block Template
```tsx
/**
 * @component {BlockName}
 * @description {What it does in one line}
 * @category {ui | layout | form | feature}
 * 
 * @props
 * - {propName}: {type} - {description}
 * 
 * @variants
 * - default: {description}
 * - {variant}: {description}
 * 
 * @example
 * <{BlockName} prop={value} />
 */
interface {BlockName}Props {
  // Required props first
  requiredProp: string;
  // Optional props with defaults
  variant?: 'default' | 'compact';
  className?: string;
}

export function {BlockName}({ 
  requiredProp,
  variant = 'default',
  className = '',
}: {BlockName}Props) {
  // Implementation
}
```

### Checklist for Reusable Blocks

- [ ] Single responsibility (does ONE thing)
- [ ] Props interface documented
- [ ] Default values for optional props
- [ ] className prop for style overrides
- [ ] No hardcoded strings (use props or constants)
- [ ] No internal state unless necessary
- [ ] LLM-friendly header comment

---

## ✅ STEP 4: VERIFICATION

// turbo
```powershell
npx tsc --noEmit
```

### Post-refactor checks

1. **Imports are clean** - No `../../../` chains, use `@app/` aliases
2. **Barrels exist** - Every folder with 2+ exports has `index.ts`
3. **Comments present** - Key components have LLM headers
4. **No circular deps** - Modules don't import each other's internals

---

## 📊 STEP 5: REPORT

| Metric | Before | After |
|--------|--------|-------|
| Components >100 lines | X | Y |
| Files in services/ | X | 0 |
| Components with LLM headers | X | Y |
| Hooks documented | X | Y |
| Modules with barrel exports | X | Y |

### Files changed
- Extracted: `{list}`
- Migrated: `{list}`
- Deleted: `{list}`
