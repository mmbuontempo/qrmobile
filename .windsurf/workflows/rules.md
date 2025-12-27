---
description: Crear o actualizar reglas en .windsurf/rules
---

# /rules

> **Propósito**: Crear reglas que Cascade sigue automáticamente cuando editas ciertos archivos.

---

## 📚 GLOSARIO - ¿Qué significa cada cosa?

| Término | Qué es (en simple) | Analogía |
|---------|-------------------|----------|
| **Rule** | Instrucción que Cascade sigue automáticamente | Regla de la casa |
| **Trigger** | Cuándo se activa la regla | El disparador |
| **Glob** | Patrón para matchear archivos | Filtro de búsqueda |
| **Frontmatter** | Metadatos al inicio del archivo (entre `---`) | La etiqueta del producto |
| **Prompt** | Instrucción para la IA | Lo que le dices que haga |

### Tipos de trigger

| Trigger | Cuándo se activa | Ejemplo |
|---------|-----------------|---------|
| `glob` | Al editar archivos que coinciden | `*.tsx` → archivos React |
| `always` | Siempre activo | Reglas generales |
| `manual` | Solo cuando lo pides | Tareas específicas |

### Patrones glob comunes

| Patrón | Qué matchea |
|--------|------------|
| `*.tsx` | Archivos .tsx en la raíz |
| `**/*.tsx` | Archivos .tsx en cualquier carpeta |
| `app/routes/*.tsx` | Solo rutas |
| `app/components/**/*.tsx` | Todos los componentes |

---

## 🎯 QUÉ VAMOS A HACER

1. **Crear archivo temporal** → Cascade no puede escribir directo en rules/
2. **Escribir contenido** → La regla en formato correcto
3. **Copiar con PowerShell** → Mover a la carpeta correcta

---

## Problema
Cascade no puede escribir directamente en `.windsurf/rules/` por restricciones de acceso.

## Solución
Usar archivo temporal + PowerShell para copiar.

## Pasos

1. **Crear archivo temporal** en la raíz del proyecto:
```
temp-rule.md
```

2. **Escribir el contenido** con el formato correcto:
```markdown
---
trigger: glob
globs: ["**/*.tsx", "**/*.ts"]
---

# Rule Title

## Section 1
...
```

3. **Copiar con PowerShell** y borrar temporal:
```powershell
Copy-Item -Path 'temp-rule.md' -Destination '.windsurf\rules\XX-nombre.md' -Force; Remove-Item -Path 'temp-rule.md'
```

## Formato de Rules

**IMPORTANTE: El contenido de las rules SIEMPRE debe estar en inglés.**

```markdown
---
trigger: glob
globs: ["**/path/**/*.tsx"]
---

# Title · Subtitle

## Section

### Subsection

// ✅ Correct
correct code

// ❌ Incorrect
incorrect code

**Rule:**
- Point 1
- Point 2
```

## Triggers disponibles

- `glob` - Se activa cuando se editan archivos que coinciden con globs
- `always` - Siempre activo
- `manual` - Solo cuando el usuario lo invoca

## Idioma

**Las rules SIEMPRE se escriben en inglés** porque:
- Son prompts para Cascade (modelo en inglés)
- Mejor precisión en las instrucciones
- Consistencia con el código

## Ejemplo completo

```powershell
# 1. Cascade crea temp-rule.md con el contenido EN INGLÉS
# 2. Ejecutar:
Copy-Item -Path 'temp-rule.md' -Destination '.windsurf\rules\08-new-rule.md' -Force; Remove-Item -Path 'temp-rule.md'
```
