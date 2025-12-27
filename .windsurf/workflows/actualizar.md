---
description: Actualizar todas las dependencias a últimas versiones (npm, Docker, VPS)
---

# /actualizar

> **Propósito**: Mantener todo el stack actualizado para seguridad y rendimiento.

---

## 📚 GLOSARIO

| Término | Qué significa |
|---------|--------------|
| **npm outdated** | Muestra paquetes desactualizados |
| **npm audit** | Escanea vulnerabilidades de seguridad |
| **ncu** | npm-check-updates, actualiza a últimas versiones major |
| **docker pull** | Descarga última versión de imagen |

---

## 🎯 QUÉ VAMOS A HACER

1. **Auditar seguridad** → npm audit
2. **Ver qué está desactualizado** → npm outdated
3. **Actualizar dependencias** → npm update o ncu
4. **Actualizar Docker images** → docker-compose pull
5. **Actualizar VPS** → apt upgrade + docker pull

---

## PASOS

### Parte 1: Auditoría de Seguridad Local

1. Verificar vulnerabilidades conocidas:
// turbo
```powershell
npm audit
```

2. Intentar arreglar automáticamente:
```powershell
npm audit fix
```

3. Ver paquetes desactualizados:
// turbo
```powershell
npm outdated
```

### Parte 2: Actualizar Dependencias NPM

4. Actualizar dentro de rangos semver (seguro):
```powershell
npm update
```

5. Para actualizar a últimas versiones major (puede romper cosas):
```powershell
npx npm-check-updates -u
npm install
```

6. Verificar que todo funciona:
// turbo
```powershell
npm run typecheck
```

7. Probar la app:
```powershell
npm run dev
```

### Parte 3: Actualizar Docker Images Locales

8. Actualizar imágenes Docker:
```powershell
docker-compose pull
```

9. Recrear contenedores con nuevas imágenes:
```powershell
docker-compose up -d --force-recreate
```

10. Verificar versiones:
// turbo
```powershell
docker-compose exec db postgres --version
docker-compose exec redis redis-server --version
```

### Parte 4: Actualizar VPS (Requiere SSH)

11. Conectar al VPS:
```powershell
ssh -i $env:USERPROFILE\.ssh\id_ed25519 -p 2222 root@217.196.62.140
```

12. Una vez conectado, ejecutar en el VPS:
```bash
# Actualizar sistema operativo
apt update && apt upgrade -y

# Actualizar Docker images
cd /opt/promuslink
docker-compose pull

# Reiniciar con nuevas imágenes
docker-compose up -d --force-recreate

# Limpiar imágenes viejas
docker image prune -f

# Verificar versiones
docker --version
docker-compose exec db postgres --version
docker-compose exec redis redis-server --version

# Verificar que la app responde
curl -s http://localhost:3030/health
```

13. Salir del VPS:
```bash
exit
```

### Parte 5: Commit de Cambios

14. Si hubo cambios en package.json:
```powershell
git add package.json package-lock.json
git commit -m "chore: update dependencies to latest versions"
git push
```

---

## 🔄 SCRIPT ONE-CLICK (Solo Local)

Para actualizar todo lo local de una vez:

```powershell
# Auditoría
npm audit fix

# Actualizar dependencias
npm update

# Actualizar Docker
docker-compose pull
docker-compose up -d --force-recreate

# Verificar
npm run typecheck
docker ps
```

---

## ⚠️ NOTAS IMPORTANTES

- **Antes de actualizar major versions**: Lee el changelog
- **Después de actualizar**: Siempre corre `npm run typecheck` y prueba la app
- **En producción**: Actualiza primero en local, prueba, luego deploy
- **Rollback**: Si algo falla, `git checkout package.json && npm install`

---

## 📅 FRECUENCIA RECOMENDADA

| Tipo | Frecuencia |
|------|------------|
| `npm audit` | Semanal |
| `npm update` | Quincenal |
| Major updates | Mensual (evaluar) |
| VPS system | Mensual |
| Docker images | Con cada deploy |
