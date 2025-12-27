---
description: Verificar linting y formateo
---

# /lint

> **Propósito**: Verificar que tu código sigue las reglas de estilo y no tiene errores obvios.

---

## 📚 GLOSARIO - ¿Qué significa cada cosa?

| Término | Qué es (en simple) | Analogía |
|---------|-------------------|----------|
| **Linting** | Revisar código buscando errores y mal estilo | Corrector ortográfico para código |
| **ESLint** | Herramienta de linting para JavaScript/TypeScript | El corrector que usamos |
| **Formateo** | Arreglar espacios, indentación, comillas | Que el código se vea bonito |
| **Prettier** | Herramienta de formateo automático | El que pone todo bonito |
| **Warning** | Aviso de algo que podría ser problema | Luz amarilla |
| **Error** | Algo que definitivamente está mal | Luz roja |
| **--fix** | Arreglar automáticamente lo que se pueda | Auto-corrector |
| **tsc --noEmit** | Verificar tipos sin generar archivos | Revisar sin compilar |

### Tipos de problemas que detecta

| Tipo | Ejemplo | Gravedad |
|------|---------|----------|
| **Error de tipo** | `const x: number = "hola"` | 🔴 Error |
| **Variable no usada** | `const x = 5; // nunca se usa` | 🟡 Warning |
| **Import no usado** | `import { algo } from '...'` | 🟡 Warning |
| **console.log** | Dejaste un console.log | 🟡 Warning |
| **Formateo** | Indentación incorrecta | 🔵 Style |

---

## 🎯 QUÉ VAMOS A HACER

1. **ESLint** → Buscar errores de código
2. **TypeScript** → Verificar tipos correctos
3. **Fix automático** → Arreglar lo que se pueda solo

---

## PASOS

1. Ejecutar ESLint:
// turbo
```powershell
npm run lint
```

2. Verificar TypeScript:
// turbo
```powershell
npx tsc --noEmit
```

3. Corregir errores de formato automáticamente:
```powershell
npm run format
```

4. Corregir errores de lint automáticamente:
```powershell
npm run lint -- --fix
```
