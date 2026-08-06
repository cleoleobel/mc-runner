# GUÍA DE INSTALACIÓN Y VERIFICACIÓN DE ROLLBACK

## PROTOCOLO DE SEGURIDAD (REGLA CERO)
1. **Detección Automática:** `INSTALL_NEXUS_TO_WORLD.ps1` localiza el archivo `level.dat`.
2. **Copia de Seguridad:** Se genera una copia comprimida en `backups/BACKUP_<Mundo>_<Fecha>.zip`.
3. **Firma Digital SHA-256:** Se calcula el hash del ZIP resguardado y se registra en `nexus_installed_manifest.json`.
4. **Instalación No Destructiva:** Únicamente se añade el datapack de progresión a `<Mundo>/datapacks/nexus_progression`.
5. **Rollback Completo:** Ejecutar `UNINSTALL_NEXUS_FROM_WORLD.ps1` retira los componentes instalados sin alterar los datos originales del mundo.
