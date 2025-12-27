---
description: Operaciones de base de datos con Prisma
---

# /prisma

> **Propósito**: Manejar la base de datos - crear tablas, modificarlas, ver datos.

---

## 📚 GLOSARIO - ¿Qué significa cada cosa?

| Término | Qué es (en simple) | Analogía |
|---------|-------------------|----------|
| **Prisma** | Herramienta para hablar con la base de datos desde código | Traductor entre TypeScript y SQL |
| **ORM** | Object-Relational Mapping - convierte tablas en objetos | Traductor DB ↔ código |
| **Schema** | Archivo que define la estructura de tu DB | Plano del edificio |
| **Model** | Definición de una tabla en el schema | Una tabla (ej: User, Product) |
| **Migration** | Cambio guardado en la estructura de la DB | "Commit" pero para la DB |
| **Migrate** | Aplicar cambios del schema a la DB real | Construir según el plano |
| **Generate** | Crear el código TypeScript desde el schema | Crear las herramientas de trabajo |
| **Prisma Client** | Código generado para hacer queries | Tu kit de herramientas para la DB |
| **Prisma Studio** | Interfaz visual para ver/editar datos | Excel para tu base de datos |
| **Seed** | Llenar la DB con datos de prueba | Poner muebles de ejemplo en la casa |

### Flujo típico de cambios

```
1. Editar schema.prisma (agregar campo/tabla)
      ↓
2. prisma migrate dev (crear migración)
      ↓
3. prisma generate (actualizar cliente)
      ↓
4. Usar en código: prisma.user.findMany()
```

### Archivos importantes

| Archivo | Qué contiene |
|---------|-------------|
| `prisma/schema.prisma` | Definición de todas las tablas |
| `prisma/migrations/` | Historial de cambios a la DB |
| `app/lib/prisma.server.ts` | Instancia única del cliente |

---

## 🎯 QUÉ VAMOS A HACER

1. **Generate** → Crear/actualizar el cliente Prisma
2. **Migrate** → Aplicar cambios a la base de datos
3. **Studio** → Ver los datos visualmente
4. **Reset** → Borrar todo y empezar de cero (⚠️ peligroso)

---

## PASOS

1. Generar cliente Prisma después de cambios en schema:
// turbo
```powershell
npm run db:generate
```

2. Crear y aplicar migración:
```powershell
npx prisma migrate dev --name [nombre_migracion]
```

3. Aplicar migraciones pendientes (producción):
```powershell
npx prisma migrate deploy
```

4. Abrir Prisma Studio para inspeccionar datos:
```powershell
npx prisma studio
```

5. Resetear base de datos (⚠️ borra todos los datos):
```powershell
npx prisma migrate reset
```

6. Ver estado de migraciones:
// turbo
```powershell
npx prisma migrate status
```
