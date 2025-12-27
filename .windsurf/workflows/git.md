---
description: Guardar cambios y subir a GitHub con mensaje automático en español
---

# /git

> **Propósito**: Guardar tu trabajo y subirlo a GitHub para que no se pierda y otros puedan verlo.

---

## 📚 GLOSARIO - ¿Qué significa cada cosa?

| Término | Qué es (en simple) | Analogía |
|---------|-------------------|----------|
| **Git** | Sistema que guarda el historial de cambios de tu código | Como "Ctrl+Z" pero para todo el proyecto, infinito |
| **Repository (Repo)** | Carpeta de proyecto con historial Git | Tu proyecto + toda su historia |
| **Commit** | Una "foto" de tu código en un momento | Punto de guardado en un videojuego |
| **Stage (add)** | Seleccionar qué archivos incluir en el commit | Elegir qué poner en la caja antes de cerrarla |
| **Push** | Subir tus commits a GitHub (la nube) | Subir tu save a la nube |
| **Pull** | Bajar cambios de GitHub a tu PC | Descargar el save de la nube |
| **Branch** | Versión paralela del código | Línea temporal alternativa |
| **Main** | La rama principal (antes se llamaba "master") | La línea temporal "oficial" |
| **Remote** | El servidor donde está tu repo (GitHub) | La nube donde guardas backups |
| **Origin** | Nombre por defecto del remote | Apodo de GitHub en tu proyecto |

### Conventional Commits (mensajes estándar)

| Prefijo | Cuándo usarlo | Ejemplo |
|---------|--------------|---------|
| `feat:` | Nueva funcionalidad | `feat: agregar carrito de compras` |
| `fix:` | Arreglar un bug | `fix: corregir precio negativo` |
| `refactor:` | Mejorar código sin cambiar función | `refactor: simplificar validación` |
| `chore:` | Tareas de mantenimiento | `chore: actualizar dependencias` |
| `docs:` | Documentación | `docs: agregar README` |
| `test:` | Tests | `test: agregar tests de login` |

---

## 🎯 QUÉ VAMOS A HACER

1. **Ver qué cambió** → `git status` muestra archivos modificados
2. **Agregar cambios** → `git add` los prepara para guardar
3. **Crear commit** → `git commit` guarda la "foto" con un mensaje
4. **Subir a GitHub** → `git push` sube todo a la nube

---

## PASOS

1. Verificar estado y conflictos:
// turbo
```powershell
git status --porcelain
```

2. Ver qué cambió:
// turbo
```powershell
git diff --stat
```

3. Agregar todo:
// turbo
```powershell
git add -A
```

4. Commit con mensaje Conventional Commits en español (feat/fix/refactor/chore/docs/test):
// turbo
```powershell
git commit -m "[tipo]: [mensaje breve en español]"
```

5. Subir a GitHub:
// turbo
```powershell
git push origin main
```
