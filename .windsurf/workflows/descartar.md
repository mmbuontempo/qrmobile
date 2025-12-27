---
description: Descartar cambios y volver al último commit
---

# /descartar

> **Propósito**: Borrar todos los cambios que hiciste y volver al último punto guardado (commit).

---

## 📚 GLOSARIO - ¿Qué significa cada cosa?

| Término | Qué es (en simple) | Analogía |
|---------|-------------------|----------|
| **Working directory** | Los archivos como están ahora en tu PC | Tu escritorio actual |
| **Staged changes** | Cambios marcados para el próximo commit | Cosas en la caja lista para guardar |
| **Unstaged changes** | Cambios que aún no marcaste | Cosas sueltas en el escritorio |
| **HEAD** | El último commit (punto de guardado) | Tu último save |
| **git reset --hard** | Borrar TODO y volver a HEAD | Cargar el último save |
| **git stash** | Guardar cambios temporalmente (sin commit) | Guardar en un cajón temporal |
| **git clean** | Borrar archivos nuevos no trackeados | Tirar a la basura archivos nuevos |
| **Untracked files** | Archivos nuevos que Git no conoce | Archivos que nunca guardaste |

### ⚠️ NIVELES DE PELIGRO

| Comando | Qué borra | ¿Recuperable? |
|---------|-----------|---------------|
| `git stash` | Nada (guarda temporal) | ✅ Sí, con `git stash pop` |
| `git reset --hard` | Cambios en archivos existentes | ❌ No |
| `git clean -fd` | Archivos nuevos | ❌ No |

---

## 🎯 QUÉ VAMOS A HACER

1. **Ver cambios** → Qué vas a perder
2. **Decidir** → ¿Guardar temporal o borrar definitivo?
3. **Ejecutar** → Stash (seguro) o Reset (peligroso)
4. **Verificar** → Confirmar estado limpio

---

⚠️ **ADVERTENCIA**: Este workflow puede borrar cambios PERMANENTEMENTE.

## PASOS

1. Mostrar qué cambios se van a perder:
// turbo
```powershell
git status
git diff --stat
```

2. Confirmar con el usuario antes de proceder

3. **Opción A** - Guardar cambios temporalmente (recomendado):
```powershell
git stash push -m "backup antes de reset"
```

4. **Opción B** - Descartar cambios permanentemente:
```powershell
git reset --hard HEAD
git clean -fd
```

5. Verificar estado limpio:
// turbo
```powershell
git status
```

6. Para recuperar cambios guardados con stash:
```powershell
git stash list
git stash pop
```
