---
description: Levantar contenedores Docker
---

# /docker

> **Propósito**: Levantar los servicios que tu app necesita (base de datos, etc.) en contenedores aislados.

---

## 📚 GLOSARIO - ¿Qué significa cada cosa?

| Término | Qué es (en simple) | Analogía |
|---------|-------------------|----------|
| **Docker** | Programa que crea "mini computadoras" aisladas | Máquinas virtuales pero más livianas |
| **Container** | Una "mini computadora" corriendo | Una app en su propia burbuja |
| **Image** | Plantilla para crear contenedores | El molde para hacer galletas |
| **Dockerfile** | Receta para crear una imagen | Instrucciones paso a paso |
| **docker-compose** | Herramienta para manejar varios contenedores | Director de orquesta de contenedores |
| **docker-compose.yml** | Archivo que define qué contenedores levantar | La partitura de la orquesta |
| **Volume** | Carpeta compartida entre tu PC y el contenedor | USB conectado al contenedor |
| **Port** | Puerto de red (ej: 5432 para PostgreSQL) | Puerta de entrada al contenedor |
| **up -d** | Levantar contenedores en segundo plano | Encender y dejar corriendo |
| **down** | Apagar y eliminar contenedores | Apagar todo |
| **logs** | Ver qué está pasando dentro del contenedor | Leer el diario del contenedor |
| **exec** | Ejecutar un comando dentro del contenedor | Entrar a la burbuja y hacer algo |

### Archivos docker-compose en este proyecto

| Archivo | Para qué sirve |
|---------|---------------|
| `docker-compose.dev.yml` | Desarrollo local (solo PostgreSQL) |
| `docker-compose.vps.yml` | Producción en el servidor VPS |
| `docker-compose.prod.yml` | Producción completa |

---

## 🎯 QUÉ VAMOS A HACER

1. **Ver qué archivos hay** → Listar docker-compose disponibles
2. **Levantar servicios** → `docker-compose up -d` inicia contenedores
3. **Verificar estado** → `docker ps` muestra qué está corriendo
4. **Esperar PostgreSQL** → Confirmar que la DB está lista

---

## PASOS

1. Leer los archivos docker-compose del proyecto:
// turbo
```powershell
Get-ChildItem -Filter "docker-compose*.yml" | Select-Object Name
```

2. Levantar contenedores de desarrollo:
```powershell
docker-compose -f docker-compose.dev.yml up -d
```

3. Verificar que los contenedores están corriendo:
// turbo
```powershell
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

4. Esperar a que PostgreSQL esté listo:
// turbo
```powershell
docker-compose -f docker-compose.dev.yml exec -T postgres pg_isready -U postgres
```

5. Si hay errores, mostrar logs:
```powershell
docker-compose -f docker-compose.dev.yml logs --tail=50
```
