---
description: Iniciar entorno de desarrollo completo
---

# /desarrollo

> **Propósito**: Preparar todo lo necesario para empezar a programar - base de datos, servidor, etc.

---

## 📚 GLOSARIO - ¿Qué significa cada cosa?

| Término | Qué es (en simple) | Analogía |
|---------|-------------------|----------|
| **Entorno de desarrollo** | Tu PC configurada para programar | Tu taller de trabajo |
| **Dev server** | Servidor local que muestra tu app | Preview en vivo de tu trabajo |
| **Hot reload** | Cambias código y se actualiza solo | Ver cambios al instante |
| **PostgreSQL** | Base de datos donde se guardan los datos | El almacén de información |
| **localhost** | Tu propia computadora como servidor | Tu PC haciéndose pasar por servidor |
| **Puerto (port)** | Número que identifica un servicio | Puerta de entrada (3000, 5432, etc.) |
| **npm run dev** | Comando que inicia el servidor de desarrollo | "Encender" tu app |
| **pg_isready** | Comando que verifica si PostgreSQL está listo | Tocar la puerta de la DB |

### Puertos en este proyecto

| Puerto | Servicio | URL |
|--------|----------|-----|
| 3000 | Tu app React | http://localhost:3000 |
| 5432 | PostgreSQL | (solo interno) |
| 5555 | Prisma Studio | http://localhost:5555 |

---

## 🎯 QUÉ VAMOS A HACER

1. **Verificar Docker** → ¿Está corriendo?
2. **Levantar PostgreSQL** → La base de datos
3. **Esperar conexión** → Confirmar que la DB responde
4. **Generar Prisma** → Preparar el cliente de DB
5. **Iniciar servidor** → ¡A programar!

---

## PASOS

1. Verificar si Docker está corriendo:
// turbo
```powershell
docker ps --format "table {{.Names}}\t{{.Status}}"
```

2. Levantar base de datos si no está corriendo:
```powershell
docker-compose -f docker-compose.dev.yml up -d
```

3. Esperar a que PostgreSQL esté listo:
// turbo
```powershell
docker-compose -f docker-compose.dev.yml exec -T postgres pg_isready -U postgres
```

4. Generar cliente Prisma si hay cambios:
// turbo
```powershell
npx prisma generate
```

5. Iniciar servidor de desarrollo:
```powershell
npm run dev
```
