const { google } = require('googleapis');
const shell = require('shelljs');
const inquirer = require('inquirer');
const chalk = require('chalk');
const fs = require('fs');
const path = require('path');

const PACKAGE_NAME = 'com.promuslink.app';
const TRACK = 'internal';
const PUBSPEC_PATH = path.join(__dirname, '../pubspec.yaml');

// ============================================================================
// FUNCIONES DE VERSIONADO
// ============================================================================

/**
 * Lee y parsea la versión actual del pubspec.yaml
 * @returns {{ versionName: string, buildNumber: number, fullVersion: string }}
 */
function getCurrentVersion() {
  const pubspec = fs.readFileSync(PUBSPEC_PATH, 'utf8');
  const versionMatch = pubspec.match(/^version:\s*(.+)$/m);
  
  if (!versionMatch) {
    throw new Error('No se encontró la línea "version:" en pubspec.yaml');
  }
  
  const fullVersion = versionMatch[1].trim();
  const [versionName, buildNumberStr] = fullVersion.split('+');
  const buildNumber = parseInt(buildNumberStr || '0', 10);
  
  return { versionName, buildNumber, fullVersion };
}

/**
 * Incrementa el build number en pubspec.yaml
 * @returns {{ oldVersion: string, newVersion: string, newBuildNumber: number }}
 */
function incrementBuildNumber() {
  const { versionName, buildNumber, fullVersion } = getCurrentVersion();
  const newBuildNumber = buildNumber + 1;
  const newVersion = `${versionName}+${newBuildNumber}`;
  
  let pubspec = fs.readFileSync(PUBSPEC_PATH, 'utf8');
  pubspec = pubspec.replace(
    /^version:\s*.+$/m,
    `version: ${newVersion}`
  );
  fs.writeFileSync(PUBSPEC_PATH, pubspec, 'utf8');
  
  return { oldVersion: fullVersion, newVersion, newBuildNumber };
}

// ============================================================================
// FUNCIONES DE VERIFICACIÓN
// ============================================================================

/**
 * Consulta y muestra el estado actual del track en Google Play
 * @param {any} androidPublisher Instancia autenticada de la API
 */
async function printTrackStatus(androidPublisher) {
  console.log(chalk.blue('\n🔍 Verificando estado real en Google Play...'));
  try {
    // Necesitamos una nueva sesión de edición para leer el estado actual post-commit
    const edit = await androidPublisher.edits.insert({ packageName: PACKAGE_NAME });
    const editId = edit.data.id;
    
    const trackInfo = await androidPublisher.edits.tracks.get({
      editId: editId,
      packageName: PACKAGE_NAME,
      track: TRACK
    });

    console.log(chalk.cyan(`   Track: ${TRACK}`));
    if (trackInfo.data.releases && trackInfo.data.releases.length > 0) {
      trackInfo.data.releases.forEach(release => {
        const statusColor = release.status === 'draft' ? chalk.yellow : chalk.green;
        console.log(`   - Versión: ${chalk.bold(release.name || '(sin nombre)')}`);
        console.log(`     Códigos: [${release.versionCodes?.join(', ')}]`);
        console.log(`     Estado: ${statusColor(release.status)}`);
      });
    } else {
      console.log(chalk.dim('   (Sin releases activos)'));
    }

    // Limpiamos la sesión de lectura
    try {
      await androidPublisher.edits.delete({ editId, packageName: PACKAGE_NAME });
    } catch (e) { /* ignorar error de limpieza */ }

  } catch (error) {
    console.log(chalk.yellow('   ⚠️ No se pudo verificar el estado automáticamente (pero la subida fue exitosa).'));
    // No fallamos el proceso por esto, es solo informativo
  }
}

// ============================================================================
// FUNCIÓN PRINCIPAL
// ============================================================================

async function runDeploy() {
  console.log(chalk.blue('═══════════════════════════════════════════════════════════════'));
  console.log(chalk.blue('🚀 DESPLIEGUE AUTOMÁTICO A GOOGLE PLAY - Internal Testing'));
  console.log(chalk.blue('═══════════════════════════════════════════════════════════════\n'));

  // 1. Verificaciones Previas
  console.log(chalk.cyan('📋 Verificando requisitos previos...'));
  
  const keyPropertiesPath = path.join(__dirname, '../android/key.properties');
  const googleJsonPath = path.join(__dirname, '../android/fastlane/google-play-json-key.json');

  if (!fs.existsSync(keyPropertiesPath)) {
    console.error(chalk.red('❌ Error: No se encontró android/key.properties'));
    console.error(chalk.yellow('   → Este archivo contiene las credenciales de firma de la app.'));
    process.exit(1);
  }
  console.log(chalk.green('   ✓ key.properties encontrado'));

  if (!fs.existsSync(googleJsonPath)) {
    console.error(chalk.red('❌ Error: No se encontró android/fastlane/google-play-json-key.json'));
    console.error(chalk.yellow('   → Este archivo contiene las credenciales de la API de Google Play.'));
    process.exit(1);
  }
  console.log(chalk.green('   ✓ google-play-json-key.json encontrado'));

  if (!fs.existsSync(PUBSPEC_PATH)) {
    console.error(chalk.red('❌ Error: No se encontró pubspec.yaml'));
    process.exit(1);
  }
  console.log(chalk.green('   ✓ pubspec.yaml encontrado'));

  // 2. Mostrar versión actual e incrementar
  const currentVersion = getCurrentVersion();
  console.log(chalk.white(`\n📦 Versión actual: ${chalk.yellow(currentVersion.fullVersion)}`));
  
  let versionInfo;
  if (!process.argv.includes('--no-version-bump')) {
    versionInfo = incrementBuildNumber();
    console.log(chalk.green(`   ✓ Versión incrementada a: ${chalk.bold(versionInfo.newVersion)}`));
  } else {
    console.log(chalk.yellow('   ⏩ Saltando incremento de versión (--no-version-bump detectado)'));
    versionInfo = { newVersion: currentVersion.fullVersion, newBuildNumber: currentVersion.buildNumber };
  }

  // 3. Confirmación
  if (!process.argv.includes('-y')) {
    console.log('');
    const answers = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: `¿Desplegar versión ${versionInfo.newVersion} a Google Play Internal Testing?`,
        default: true
      }
    ]);

    if (!answers.confirm) {
      console.log(chalk.yellow('\nOperación cancelada.'));
      // Revertir el bump de versión si se cancela
      if (!process.argv.includes('--no-version-bump') && versionInfo.oldVersion) {
        let pubspec = fs.readFileSync(PUBSPEC_PATH, 'utf8');
        pubspec = pubspec.replace(
          /^version:\s*.+$/m,
          `version: ${versionInfo.oldVersion}`
        );
        fs.writeFileSync(PUBSPEC_PATH, pubspec, 'utf8');
        console.log(chalk.dim('   (Versión revertida a ' + versionInfo.oldVersion + ')'));
      }
      process.exit(0);
    }
  }

  // 4. Build Flutter
  console.log(chalk.cyan('\n🔨 Construyendo App Bundle (Release)...'));
  if (!process.argv.includes('--no-build')) {
    const buildResult = shell.exec('flutter build appbundle --release', { silent: false });
    if (buildResult.code !== 0) {
      console.error(chalk.red('\n❌ Error al construir el App Bundle'));
      console.error(chalk.yellow('   → Revisa los errores de compilación arriba.'));
      process.exit(1);
    }
    console.log(chalk.green('   ✓ App Bundle construido exitosamente'));
  } else {
    console.log(chalk.yellow('   ⏩ Saltando compilación (--no-build detectado)'));
  }

  const aabPath = path.join(__dirname, '../build/app/outputs/bundle/release/app-release.aab');
  if (!fs.existsSync(aabPath)) {
    console.error(chalk.red(`❌ Error: No se encontró el AAB en ${aabPath}`));
    console.error(chalk.yellow('   → Asegúrate de compilar primero con: flutter build appbundle --release'));
    process.exit(1);
  }
  
  const aabStats = fs.statSync(aabPath);
  console.log(chalk.green(`   ✓ AAB encontrado (${(aabStats.size / 1024 / 1024).toFixed(2)} MB)`));

  // 5. Upload to Google Play
  console.log(chalk.cyan('\n📤 Subiendo a Google Play...'));

  try {
    const auth = new google.auth.GoogleAuth({
      keyFile: googleJsonPath,
      scopes: ['https://www.googleapis.com/auth/androidpublisher']
    });

    const androidPublisher = google.androidpublisher({
      version: 'v3',
      auth: auth
    });

    // Create Edit
    console.log(chalk.white('   Creando sesión de edición...'));
    const edit = await androidPublisher.edits.insert({
      packageName: PACKAGE_NAME
    });
    const editId = edit.data.id;
    console.log(chalk.dim(`   Edit ID: ${editId}`));

    // Upload AAB
    console.log(chalk.white('   Subiendo bundle (esto puede tardar)...'));
    const bundle = await androidPublisher.edits.bundles.upload({
      editId: editId,
      packageName: PACKAGE_NAME,
      media: {
        mimeType: 'application/octet-stream',
        body: fs.createReadStream(aabPath)
      }
    });
    const versionCode = bundle.data.versionCode;
    console.log(chalk.green(`   ✓ Bundle subido. Version Code: ${versionCode}`));

    // Update Track
    console.log(chalk.white(`   Asignando a track "${TRACK}"...`));
    await androidPublisher.edits.tracks.update({
      editId: editId,
      packageName: PACKAGE_NAME,
      track: TRACK,
      requestBody: {
        releases: [{
          versionCodes: [versionCode],
          status: 'draft'
        }]
      }
    });
    console.log(chalk.green(`   ✓ Asignado a ${TRACK} (draft)`));

    // Commit Edit
    console.log(chalk.white('   Confirmando cambios...'));
    await androidPublisher.edits.commit({
      editId: editId,
      packageName: PACKAGE_NAME
    });

    // Verificar estado final
    await printTrackStatus(androidPublisher);

    // Success!
    console.log(chalk.green('\n═══════════════════════════════════════════════════════════════'));
    console.log(chalk.green('✅ ¡DESPLIEGUE COMPLETADO EXITOSAMENTE!'));
    console.log(chalk.green('═══════════════════════════════════════════════════════════════'));
    console.log(chalk.white(`\n   📱 App: ${PACKAGE_NAME}`));
    console.log(chalk.white(`   📦 Versión: ${versionInfo.newVersion} (code: ${versionCode})`));
    console.log(chalk.white(`   🎯 Track: ${TRACK}`));
    console.log(chalk.white(`   📋 Estado: draft`));
    console.log(chalk.cyan('\n   → Ve a Google Play Console para revisar y publicar el release.\n'));

  } catch (error) {
    console.error(chalk.red('\n═══════════════════════════════════════════════════════════════'));
    console.error(chalk.red('❌ ERROR EN LA API DE GOOGLE PLAY'));
    console.error(chalk.red('═══════════════════════════════════════════════════════════════\n'));
    
    const errorMessage = error.message || '';
    
    // Errores conocidos con soluciones
    if (errorMessage.includes('API has not been used') || errorMessage.includes('it is disabled')) {
      console.error(chalk.yellow('🔧 Problema: La API de Google Play Android Developer no está habilitada.'));
      console.error(chalk.white('   Solución: Habilita la API en Google Cloud Console:'));
      console.error(chalk.cyan('   https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com\n'));
    } else if (errorMessage.includes('Version code') && errorMessage.includes('already been used')) {
      console.error(chalk.yellow('🔧 Problema: El código de versión ya fue usado.'));
      console.error(chalk.white('   Solución: Incrementa el build number en pubspec.yaml'));
      console.error(chalk.white('   (Esto debería ser automático, pero algo falló)\n'));
    } else if (errorMessage.includes('Only releases with status draft')) {
      console.error(chalk.yellow('🔧 Problema: La app está en estado borrador en Play Console.'));
      console.error(chalk.white('   El script ya usa status: draft, esto no debería ocurrir.\n'));
    } else if (errorMessage.includes('Invalid grant') || errorMessage.includes('invalid_grant')) {
      console.error(chalk.yellow('🔧 Problema: Las credenciales de servicio son inválidas o expiraron.'));
      console.error(chalk.white('   Solución: Regenera la clave JSON en Google Cloud Console.\n'));
    } else if (errorMessage.includes('Permission denied') || errorMessage.includes('403')) {
      console.error(chalk.yellow('🔧 Problema: La cuenta de servicio no tiene permisos suficientes.'));
      console.error(chalk.white('   Solución: Verifica que la cuenta de servicio tenga permisos de'));
      console.error(chalk.white('   "Lanzar apps a los segmentos de pruebas" en Play Console.\n'));
    } else {
      console.error(chalk.yellow('Error desconocido:'));
      console.error(chalk.white(`   ${errorMessage}\n`));
    }
    
    if (error.response && error.response.data && error.response.data.error) {
      console.error(chalk.dim('Detalles técnicos:'));
      console.error(chalk.dim(JSON.stringify(error.response.data.error, null, 2)));
    }
    
    process.exit(1);
  }
}

// ============================================================================
// EJECUCIÓN
// ============================================================================

runDeploy().catch(err => {
  console.error(chalk.red('Error inesperado:'), err);
  process.exit(1);
});
