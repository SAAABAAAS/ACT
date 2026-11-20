# Normativa: cómo se agrega y se verifica

> Dueña: Margeory Rodriguez (Operaciones). Revisión técnica: profesional SST aliado / mentor.

El valor de ACT depende de que **lo que decimos sobre la ley sea correcto**. Por eso el agente de IA no puede usar su "memoria": solo lee la tabla `fuentes_normativas`, y solo las filas que una persona verificó.

## Proceso de verificación (para cada artículo)

1. **Buscar la fuente oficial**: Registro Oficial, [trabajo.gob.ec](https://www.trabajo.gob.ec), [iess.gob.ec](https://www.iess.gob.ec). Blogs, consultoras o resúmenes de terceros **no cuentan** como fuente (sirven para encontrarla, no para citarla).
2. **Leer el artículo completo** y confirmar que sigue vigente (que no fue reformado ni derogado).
3. **Escribir un resumen propio** en `resumen` (no copiar párrafos completos).
4. Llenar `url_oficial`, `registro_oficial` (número y fecha), `verificado_por` y `fecha_verificacion`.
5. Si se crea un **requisito** a partir del artículo, confirmar con el profesional SST a partir de cuántos trabajadores aplica y qué evidencia lo demuestra.

**Re-verificar cada 6 meses** o cuando el MDT publique una reforma. Si una norma se deroga: `vigente = false` (no borrar la fila: queda el historial).

## Normas candidatas para empezar (PENDIENTES de verificar)

| Norma | Qué es | Estado |
|---|---|---|
| Decreto Ejecutivo 255 (R.O. 2do Supl. 554, 09-may-2024) | Reglamento de Seguridad y Salud en el Trabajo. Reemplazó al Decreto 2393 de 1986. | ⏳ Pendiente |
| Acuerdo Ministerial MDT-2024-196 | Normativa del MDT para aplicar el DE 255 (registros en la plataforma SUT). | ⏳ Pendiente |
| Norma Técnica de Seguridad e Higiene del Trabajo (MDT, Anexo 3) | Clasificación de riesgos y aspectos técnicos. | ⏳ Pendiente |
| Lista de Verificación SST del MDT (Anexo 1) | Lo que revisa el inspector: muy útil para armar `requisitos`. | ⏳ Pendiente |
| Decisión 584 de la CAN | Instrumento Andino de Seguridad y Salud en el Trabajo. | ⏳ Pendiente |
| Código del Trabajo (arts. 42, 410 y otros) | Obligaciones generales del empleador. | ⏳ Pendiente |
| Ley Orgánica de Protección de Datos Personales | Cómo debemos tratar datos de trabajadores, sobre todo los de salud. | ⏳ Pendiente |
| Ley Orgánica de Discapacidades | Obligaciones de inclusión laboral. | ⏳ Pendiente |
| Acuerdo Ministerial MDT-2025-122 | Reglamento de SST para la construcción (solo si atendemos ese sector). | ⏳ Pendiente |

Esta lista es un punto de partida, no un análisis legal. Cuando una norma pase a ✅, se carga en la base con los datos de verificación.
