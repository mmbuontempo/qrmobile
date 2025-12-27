---
description: Optimize UI - Mobile-first, modern SaaS, persistence, micro-interactions
---

# /optimizar-ui

> **Purpose**: Create professional SaaS-level UI/UX with mobile-first approach.

---

## 📚 GLOSSARY - Industry Terms

| Term | What it is | Analogy |
|------|-----------|---------|
| **Mobile-first** | Design for mobile first, then adapt to desktop | Build small house, then expand |
| **Breakpoint** | Point where design changes (sm, md, lg, xl) | Clothing sizes (S, M, L, XL) |
| **Touch target** | Minimum tappable area (44x44px recommended) | Button big enough for finger |
| **Viewport** | The visible area of the screen | The window you look through |
| **Skeleton** | Animated placeholder while loading | Gray silhouette that "pulses" |
| **Haptic feedback** | Vibration when tapping (on mobile) | The "click" you feel |
| **Gesture** | Touch interaction (swipe, pinch, long-press) | Finger movements |
| **Bottom sheet** | Panel that slides up from bottom | Drawer that slides up |
| **FAB** | Floating Action Button | Main button always visible |
| **Micro-interaction** | Small feedback animation | Button that "bounces" on tap |
| **Optimistic Update** | UI changes before server confirms | Instant change, rollback if fails |
| **Progressive Disclosure** | Show little, expand on demand | Menu that unfolds |
| **Persistence** | State that survives refresh | Your saved preference |
| **Design Token** | Reusable design value | `gap-4`, `rounded-xl` |

---

## 🎯 WHAT WE'LL DO

### Step 1: MOBILE-FIRST
**Problem**: UI designed for desktop, uncomfortable on mobile.
**Solution**: Design for small screen first, then scale up.
**Rule**: Write base classes for mobile, add `sm:`, `lg:` for desktop.

### Step 2: TOUCH-FRIENDLY
**Problem**: Buttons too small, hard to tap.
**Solution**: Touch targets 44px minimum, generous spacing.
**Rule**: If you can't tap it with your thumb, it's too small.

### Step 3: INSTANT FEEDBACK
**Problem**: User taps and doesn't know if it worked.
**Solution**: Micro-interactions, loading states, optimistic updates.
**Rule**: Every action must have visual feedback in <100ms.

### Step 4: SMART PERSISTENCE
**Problem**: User loses configuration on refresh.
**Solution**: Save UI state in localStorage, filters in URL.
**Rule**: User should never repeat a configuration.

### Step 5: CLEAR HIERARCHY
**Problem**: Everything looks equally important.
**Solution**: Clear visual scale, consistent spacing.
**Rule**: The eye should know where to look first.

---

## 1. MOBILE-FIRST DESIGN

### Tailwind Breakpoints (memorize)

| Prefix | Min width | Typical device |
|--------|-----------|----------------|
| (base) | 0px | Mobile portrait |
| `sm:` | 640px | Mobile landscape |
| `md:` | 768px | Tablet |
| `lg:` | 1024px | Laptop |
| `xl:` | 1280px | Desktop |
| `2xl:` | 1536px | Large monitor |

### ❌ Desktop-first (WRONG)

```tsx
// Designed for desktop, then "fixed" for mobile
<div className="grid grid-cols-4 md:grid-cols-2 sm:grid-cols-1">
```

### ✅ Mobile-first (CORRECT)

```tsx
// Designed for mobile, then enhanced for desktop
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
```

### Common mobile-first patterns

```tsx
// Text: small on mobile, larger on desktop
className="text-xs sm:text-sm lg:text-base"

// Padding: compact on mobile, spacious on desktop
className="p-3 sm:p-4 lg:p-6"

// Hide on mobile, show on desktop
className="hidden lg:block"

// Show on mobile, hide on desktop
className="block lg:hidden"

// Vertical stack on mobile, horizontal on desktop
className="flex flex-col lg:flex-row"
```

---

## 2. TOUCH-FRIENDLY

### Minimum sizes (Apple Human Interface Guidelines)

| Element | Min size | Tailwind |
|---------|----------|----------|
| Touch button | 44x44px | `min-h-11 min-w-11` |
| Tappable icon | 44x44px | `p-2.5` around 24px icon |
| Input | 44px height | `h-11` or `py-3` |
| Checkbox/Radio | 44x44px area | `p-2` around |

### ❌ Too small to tap

```tsx
<button className="p-1 text-xs">
  <X className="w-3 h-3" />
</button>
```

### ✅ Touch-friendly

```tsx
<button className="p-2.5 -m-2.5 touch-manipulation">
  <X className="w-5 h-5" />
</button>
// -m-2.5 compensates extra padding visually
// touch-manipulation improves touch response
```

### Spacing between tappable elements

```tsx
// Minimum 8px between buttons to avoid accidental taps
className="flex gap-2"  // 8px
className="flex gap-3"  // 12px (recommended)
```

---

## 3. FEEDBACK & MICRO-INTERACTIONS

### Button states (all required)

```tsx
<button className="
  bg-purple-600 text-white
  hover:bg-purple-700           // Desktop: mouse hover
  active:bg-purple-800          // Click/tap active
  active:scale-95               // Micro-interaction: shrinks
  disabled:opacity-50           // Disabled state
  disabled:cursor-not-allowed
  transition-all duration-150   // Smooth changes
">
```

### Skeleton while loading

```tsx
// Reusable skeleton component
function Skeleton({ className }) {
  return (
    <div className={`
      animate-pulse 
      bg-gradient-to-r from-slate-200 via-slate-100 to-slate-200
      bg-[length:200%_100%]
      rounded
      ${className}
    `} />
  );
}

// Usage
<Skeleton className="h-4 w-32" />  // Text
<Skeleton className="h-10 w-full" /> // Input
<Skeleton className="h-24 w-24 rounded-xl" /> // Image
```

### Action states with feedback

```tsx
type ActionState = "idle" | "loading" | "success" | "error";

function SaveButton({ state, onClick }) {
  return (
    <button 
      onClick={onClick}
      disabled={state === "loading"}
      className="relative min-w-[100px] h-11 px-4 rounded-lg bg-purple-600 text-white
        active:scale-95 transition-all disabled:opacity-70"
    >
      {state === "idle" && "Save"}
      {state === "loading" && <Loader2 className="w-5 h-5 animate-spin mx-auto" />}
      {state === "success" && <Check className="w-5 h-5 mx-auto text-green-300" />}
      {state === "error" && "Retry"}
    </button>
  );
}
```

### Toast notifications (global feedback)

```tsx
// Use library like sonner or react-hot-toast
import { toast } from "sonner";

// Success
toast.success("Product saved");

// Error
toast.error("Could not save");

// With action
toast("Product deleted", {
  action: { label: "Undo", onClick: () => undoDelete() }
});
```

---

## 4. SMART PERSISTENCE

### What to persist and where

| Type | Where | Why |
|------|-------|-----|
| Expand/collapse | `localStorage` | Survives refresh |
| View (grid/list) | `localStorage` | Personal preference |
| Active filters | `URL params` | Shareable, back button |
| Search | `URL params` | Shareable |
| Scroll position | `sessionStorage` | This session only |
| Form draft | `sessionStorage` | Don't lose work |

### Hook for persistence

```typescript
// app/hooks/usePersistentExpand.ts (already exists)
const { isExpanded, toggle } = usePersistentExpand("admin:card:location");
```

### Key convention

```
{area}:{component}:{property}

admin:products:view-mode     → "grid" | "list"
admin:dashboard:expanded     → ["location", "hours"]
admin:orders:sort            → "date-desc"
```

---

## 5. VISUAL HIERARCHY (Mobile-first)

### Typography scale

| Element | Mobile | Desktop | Tailwind |
|---------|--------|---------|----------|
| Page title | 20px | 24px | `text-xl lg:text-2xl font-bold` |
| Section title | 16px | 18px | `text-base lg:text-lg font-semibold` |
| Card title | 12px | 14px | `text-xs lg:text-sm font-medium` |
| Body | 12px | 14px | `text-xs lg:text-sm` |
| Label | 10px | 12px | `text-[10px] lg:text-xs text-slate-500` |
| Caption | 10px | 10px | `text-[10px] text-slate-400` |

### Spacing (Mobile-first)

```
Mobile → Desktop

p-3 lg:p-4    → Card padding
gap-3 lg:gap-4 → Between elements
gap-4 lg:gap-6 → Between sections
mb-1 lg:mb-2  → Between label and input
```

### Containers

```tsx
// Page container
<div className="px-4 py-4 lg:px-6 lg:py-6 max-w-7xl mx-auto">

// Section (large card)
<div className="bg-white/70 backdrop-blur-md rounded-2xl p-3 lg:p-4 shadow-sm border border-slate-200">

// Card (inside section)
<div className="bg-white/50 rounded-xl p-2 lg:p-3 border border-slate-100">

// Field group
<div className="bg-white/30 rounded-lg p-2">
```

---

## 6. MODERN SAAS PATTERNS

### Bottom Sheet (mobile)

Instead of centered modals, use sheets that slide up from bottom:

```tsx
// More natural on mobile, thumb is at bottom
<div className={`
  fixed inset-x-0 bottom-0 z-50
  bg-white rounded-t-2xl shadow-2xl
  transform transition-transform duration-300
  ${isOpen ? 'translate-y-0' : 'translate-y-full'}
  max-h-[85vh] overflow-y-auto
  pb-safe  // Safe area for iPhone
`}>
  {/* Drag handle */}
  <div className="flex justify-center py-3">
    <div className="w-10 h-1 bg-slate-300 rounded-full" />
  </div>
  {children}
</div>
```

### Swipe to action (lists)

```tsx
// Swipe left to delete, right to edit
<SwipeableItem
  onSwipeLeft={() => handleDelete(item.id)}
  onSwipeRight={() => handleEdit(item.id)}
  leftAction={<Trash className="text-red-500" />}
  rightAction={<Edit className="text-blue-500" />}
>
  <ItemContent />
</SwipeableItem>
```

### Pull to refresh

```tsx
// Pull down to refresh
const { isRefreshing, onRefresh } = usePullToRefresh();

<div onTouchMove={onRefresh}>
  {isRefreshing && <Loader2 className="animate-spin mx-auto" />}
  <Content />
</div>
```

### Empty states with personality

```tsx
// Not just "No data", give context and action
function EmptyProducts() {
  return (
    <div className="flex flex-col items-center py-12 px-4 text-center">
      <Package className="w-16 h-16 text-slate-300 mb-4" />
      <h3 className="text-lg font-semibold text-slate-700 mb-2">
        No products yet
      </h3>
      <p className="text-sm text-slate-500 mb-6 max-w-xs">
        Add your first product and start selling today
      </p>
      <Button onClick={openNewProduct}>
        <Plus className="w-4 h-4 mr-2" />
        Add product
      </Button>
    </div>
  );
}
```

### Smart loading states

```tsx
// Skeleton that matches real content
function ProductListSkeleton() {
  return (
    <div className="space-y-3">
      {[1, 2, 3].map(i => (
        <div key={i} className="flex gap-3 p-3 bg-white rounded-xl">
          <Skeleton className="w-16 h-16 rounded-lg" />
          <div className="flex-1 space-y-2">
            <Skeleton className="h-4 w-3/4" />
            <Skeleton className="h-3 w-1/2" />
          </div>
        </div>
      ))}
    </div>
  );
}
```

---

## 7. SUBTLE ANIMATIONS

### Recommended transitions

```tsx
// Fast for feedback (buttons, hovers)
className="transition-all duration-150"

// Medium for state changes (expand, modals)
className="transition-all duration-300"

// Slow for dramatic entrances (page transitions)
className="transition-all duration-500"
```

### Easing functions

```tsx
// ease-out: fast start, smooth end (entrances)
className="transition-transform duration-300 ease-out"

// ease-in: smooth start, fast end (exits)
className="transition-opacity duration-200 ease-in"

// ease-in-out: smooth both ends (toggles)
className="transition-all duration-300 ease-in-out"
```

### Animations with Framer Motion (optional)

```tsx
import { motion, AnimatePresence } from "framer-motion";

// Fade in/out
<AnimatePresence>
  {isVisible && (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
    >
      Content
    </motion.div>
  )}
</AnimatePresence>
```

---

## 8. VERIFICATION

### Compilation
// turbo
```powershell
npx tsc --noEmit
```

### Lint
// turbo
```powershell
npm run lint -- --max-warnings=0
```

### Lighthouse mobile (manual)
1. Open Chrome DevTools → Lighthouse
2. Select "Mobile"
3. Run audit
4. Target: Performance >90, Accessibility >90

---

## 9. TROUBLESHOOTING

### Data not updating after save (stale data on refresh)

**Symptoms:**
- Edit field, save, press F5 → old data shows
- Press F5 again → correct data shows

**Root cause:** Service Worker caching HTML with Stale-While-Revalidate strategy.

**Solution:**
1. Check `public/service-worker.js`
2. Add exclusion for admin routes:

```javascript
// NEVER cache admin routes - always fresh data
if (url.pathname.startsWith('/admin-dashboard') ||
    url.pathname.startsWith('/admin')) {
  event.respondWith(fetch(request));
  return;
}
```

3. Unregister old SW in browser console:
```javascript
navigator.serviceWorker.getRegistrations().then(r => r.forEach(x => x.unregister())).then(() => location.reload())
```

### useRevalidator not updating useLoaderData

**Known React Router bug:** `useRevalidator().revalidate()` doesn't always update `useLoaderData`.

**Workaround:** Use `navigate('.', { replace: true })` instead:

```typescript
// ❌ Bug - data may not update
const revalidator = useRevalidator();
revalidator.revalidate();

// ✅ Workaround - forces loader re-run
const navigate = useNavigate();
navigate('.', { replace: true });
```

See: https://github.com/remix-run/react-router/issues/13890

---

## 10. MODERN SAAS CHECKLIST

| Area | Item | ☐ |
|------|------|---|
| **Mobile-first** | Base classes for mobile, `sm:` `lg:` for desktop | |
| | Touch targets ≥44px | |
| | Generous spacing between tappable elements | |
| **Feedback** | Button states (hover, active, disabled) | |
| | Skeletons while loading | |
| | Toast for completed actions | |
| | Optimistic updates | |
| **Persistence** | Expand/collapse in localStorage | |
| | Filters in URL params | |
| | Preferred view (grid/list) saved | |
| **SaaS Patterns** | Bottom sheets on mobile (not centered modals) | |
| | Empty states with personality | |
| | Pull to refresh where applicable | |
| **Animations** | Smooth transitions (150-300ms) | |
| | Micro-interactions (active:scale-95) | |
| | Correct easing (ease-out for entrances) | |
| **Performance** | Lighthouse mobile >90 | |
| | No layout shifts (CLS) | |
| | Optimized images (WebP, lazy) | |
| **Caching** | Service Worker excludes admin routes | |
| | No-cache headers on dynamic loaders | | |
