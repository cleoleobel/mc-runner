# GUÍA DE RENDIMIENTO Y BUENAS PRÁCTICAS — NEXUS

Para mantener el servidor a **20 TPS / MSPT < 40-50** y los clientes de gama baja a **30+ FPS**, se aplican las siguientes reglas técnicas obligatorias:

## 1. CREATE — AUTOMATIZACIÓN E INFRAESTRUCTURA
- **Lotes en lugar de flujo continuo:** Diseñar fábricas activadas por pulsos Redstone o contenedores llenos, evitando contrapciones mecánicas que giren permanentemente sin procesar ítems.
- **Entidades de ítem:** Evitar la acumulación de ítems sueltos en cintas transportadoras mediante Chutes y Funnels directos a inventarios (Vaults/Drawers).
- **Redes de Trenes:** Trenes acoplados de tamaño razonable (máximo 4-6 vagones por ruta).

## 2. MEKANISM — PROCESAMIENTO QUÍMICO Y MINERÍA
- **Digital Miners:** Requerir limitación estricta de radio (máx. 32 bloques) y desactivación automatizada al llenar almacenamiento.
- **Cables y Conductos:** Priorizar cables de transferencia de alta capacidad sobre redes ramificadas infinitas de tubos.
- **Reactores:** Evitar múltiples reactores simultáneos innecesarios; optimizar el aislamiento térmico y de fluidos.

## 3. DISTANT HORIZONS & CHUNKY (CONFIGURACIÓN SERVIDOR / CLIENTE)
- **Pregeneración Terrestre:** El mundo se pregenera con Chunky antes de habilitar el servidor a los jugadores para evitar picos de generación de terrenos.
- **LOD vs Simulación:** Distant Horizons muestra paisajes a 64 chunks LOD sin solicitar simulación al servidor (`simulation-distance=6`, `view-distance=8`).
- **Sin Entidades Distantes:** Las entidades lejanas no ejecutan IA ni ataques fuera del rango de simulación del servidor.

## 4. OPTIMIZACIÓN GRÁFICA CLIENTE LOW-END
- **Embeddium + Entity Culling:** Ocultamiento automático de entidades no visibles.
- **ImmediatelyFast:** Aceleración del renderizado de HUD, texto y menús de inventario.
- **Shaders:** Totalmente desactivados en perfiles gama baja.
