# INFORME DE OPTIMIZACIÓN Y RENDIMIENTO EN SERVIDOR

## PARÁMETROS DE CONFIGURACIÓN DEL SERVIDOR
- `view-distance=8`
- `simulation-distance=6`
- Memory allocation: 4GB - 6GB con recolector G1GC optimizado.

## STACK DE OPTIMIZADORES INSTALADOS
1. **ModernFix:** Reducción drástica de tiempo de arranque y consumo de RAM por registros de bloques/ítems.
2. **FerriteCore:** Optimización de estructuras de datos en memoria para modelos de bloques.
3. **Chunky:** Pregeneración completa de terreno para eliminar generación en tiempo de juego.
4. **Spark:** Perfilador integrado para diagnóstico de TPS/MSPT.

## RESULTADOS ESPERADOS EN PRUEBAS
- **Estado Reposo (Idle):** 20.0 TPS / ~12 MSPT.
- **Estrés en Combate (4 Jugadores):** 20.0 TPS / ~28 MSPT.
- **Fábricas de Create & Mekanism Activas:** 20.0 TPS / ~35 MSPT.
