# Paridad de expedientes: legado web → Godot

## Estado posterior al corte — 2026-09-22

Esta auditoría conserva su valor como mapa **legado → Godot**, pero el runtime ha seguido avanzando. Desde su corte se han integrado, entre otros, correcciones de oficina/SIGA observadas a 1920×1080 (#1141) y un gate visual reproducible para exigir evidencia documental (#1101). Los issues #431/#513/#286 siguen siendo la autoridad para decidir si la profundidad de investigación ya pasa un playtest humano.

No interpretar una fila histórica “pendiente” como permiso para duplicar sistemas que ya estén en `main`: comprobar primero el issue dueño y el código actual.

Estado operativo del issue #286. Esta tabla existe para evitar que una mecánica del legado desaparezca por omisión durante el port.

## Convención

- **Portada**: existe en Godot y conserva la función esencial.
- **Sustituida**: la función existe mediante una mecánica nueva documentada.
- **Pendiente**: existe en el legado o en los datos, pero falta una superficie jugable equivalente.
- **Descartada**: decisión explícita de no portar; debe enlazar la decisión.

No se considera "portada" una mecánica solo porque exista un módulo o un campo de datos: debe haber un flujo jugable o una sustitución explícita.

## Tabla de paridad

| Área | Legado web | Godot actual | Estado | Evidencia / cortes | Siguiente hueco real |
| --- | --- | --- | --- | --- | --- |
| Lectura de múltiples folios | `InvestigacionCasoService.preparar()` reúne los registros del caso y su contenido | visor de expediente con navegación de folios y coste solo en primera lectura | **Portada** | visor actual; lectura persistente reforzada por #289 | validar legibilidad en playtest, no reescribir |
| Pistas de un solo documento | `HotspotService` inserta el disparador de `fraseGatillo` y `descubrir()` persiste la pista | `Marcas` + visor registran pistas catalogadas | **Portada** | flujo base del visor | validar feedback audiovisual; no duplicar descubrimiento |
| Conclusiones por combinación de dos documentos | `buscarCombinacion()` consulta la pareja de registros; el catálogo legado expone conclusiones | selección manual A+B, simétrica, sobre conclusiones ya catalogadas | **Portada** | #289; feedback de pareja en #320 | playtest de gesto fijar→abrir→relacionar |
| Lecturas que sobreviven al cambio de día | persistencia de descubrimientos/estado de usuario | `leidos_total` separado de `leido_hoy` | **Portada** | #289 | mantener compatibilidad de guardado |
| Marcadores personales | no era una capa equivalente del legado | marcar/desmarcar folios ya leídos sin crear pistas | **Sustituida / nueva** | #309 | validar utilidad; no convertir en checklist obligatoria |
| Metadatos documentales | el modelo de registro conserva folio/tipo/fecha | capa de visor muestra folio · tipo · fecha ya existentes | **Portada ampliada** | #318 | comparar cronologías solo si #155 lo requiere; no inferir hechos automáticamente |
| Anexos documentales | contenido adicional podía formar parte del registro/página | contrato de anexos opcionales + primer anexo examinable | **Portada parcial** | #321, #323 | ampliar solo con anexos explícitamente sustentados por el catálogo y procedencia válida |
| Cartas ocultas | `CartaOcultaService.aplicar()` inserta la carta en el documento correspondiente | descubrimiento de carta y apertura de historia política | **Portada** | flujo de cartas/historias existente; #176 | no abrir otra implementación paralela |
| Historias políticas derivadas de cartas | superficie web posterior al descubrimiento | historia en Godot con decisión persistente | **Portada** | #176 y derivados | #287 puede ajustar ritmo/posposición sin cambiar paridad |
| Relación investigación → firma | progreso del caso se deriva de pistas descubiertas | firma/acusación usa evidencia descubierta y detecta precipitación | **Portada** | `Acusacion` / `Progreso` actuales | revisar opacidad en playtest; no automatizar culpable |
| Careo posterior a firma | flujo posterior del caso | careo encadenado desde la decisión del expediente | **Portada** | flujo de careo integrado | más contexto puede venir de #286, sin cambiar resultado automáticamente |
| Feedback al descubrir una relación | la web presenta conclusiones descubiertas dentro de la vista de investigación | mensaje explícito `FOLIO A ↔ FOLIO B` + conclusión catalogada | **Portada** | #320 | validar que se entiende sin explicar la solución antes de tiempo |
| Conteo de conclusiones/pistas | `InvestigacionVista` expone totales y encontradas | el port conserva progreso interno pero evita convertir SIGA en checklist visible | **Sustituida** | decisión de diseño de #286 | mantener el conteo fuera de HUD salvo necesidad de accesibilidad/feedback |
| Logros / registro / colecciones del legado | persistencia y superficies separadas del flujo de investigación | existen sistemas Prometeo/tarot y módulos relacionados, pero la equivalencia completa no está auditada | **Pendiente de auditoría** | #286 | revisar uno por uno: función, desbloqueo, persistencia y si aporta progresión real |
| Reconstrucción temporal / contradicciones | no hay una única mecánica canónica equivalente en `InvestigacionCasoService` | propuesta específica en #155 | **Nueva, fuera de paridad estricta** | #155 | no duplicarla dentro de #286; usarla si el siguiente playtest pide más comparación cronológica |
| Contenido opcional que cambia contexto posterior | la web combina descubrimientos y progresión del usuario | combinaciones, marcadores, metadatos y anexos ya dan contexto; puzzles oníricos pueden reusar pistas catalogadas | **Parcial** | #289, #309, #318, #323, #332 | definir qué contexto llega al careo sin introducir una respuesta correcta automática |

## Hallazgos vigentes

1. La principal carencia funcional original —las conclusiones de dos documentos presentes en datos pero sin interacción jugable— quedó cubierta por #289. No debe volver a figurar como pendiente.
2. #309, #318, #320 y #323 añadieron profundidad sin inventar hechos: memoria personal, metadatos, feedback y anexos explícitos.
3. #513 amplía el caso `caso@1` con contexto interno en factura, memorándum, ficha y acta: el peritaje de tinta y el alcance de la revisión quedan consultables sin convertirlos en una conclusión automática.
4. La auditoría de **logros/registro/colecciones** sigue incompleta. Es el hueco de paridad más claro que queda antes de afirmar cobertura total del legado.
5. #155 posee la reconstrucción cronológica/contradicciones. #286 no debe crear un segundo sistema incompatible.
6. Cualquier nueva capa debe seguir la regla central de #286: premiar leer, relacionar y recordar; no hacer clic en todo ni producir una respuesta correcta automática.

## Próximos cortes recomendados

### A. Auditar logros/registro/colecciones

Comparar superficies y condiciones del backend/web con los módulos actuales de Godot. Para cada elemento, clasificarlo como portada, sustituida, descartada explícitamente o pendiente. Si una colección solo era presentación sin efecto jugable, no elevarla artificialmente a P0.

### B. Contexto de investigación hacia el careo

Seleccionar una sola señal ya existente —por ejemplo una conclusión relacional descubierta— y comprobar si puede reflejarse en la presentación/contexto del careo sin alterar automáticamente el veredicto, las cargas ni el resultado del combate.

### C. Playtest de profundidad

Repetir un expediente completo y medir cualitativamente si el jugador usa al menos dos de estas acciones por decisión propia: releer, fijar/relacionar, marcar, consultar metadatos, abrir anexo. Si no las usa, el problema será de presentación/ritmo antes que de añadir más sistemas.

## Fuentes de referencia dentro del repositorio

- Legado: `backend/src/main/java/com/legado/expediente/service/InvestigacionCasoService.java`.
- Catálogo compartido: `godot/datos/casos.json`.
- Flujo actual: capas `godot/guion/visor_*` y módulos `Marcas`, `Progreso`, `Acusacion`.
- Verticales ya integrados: #289, #309, #318, #320, #321 y #323.
- Trabajo relacionado pero no duplicable: #155 (reconstrucción/contradicciones), #287 (ritmo de decisión política), #89/#332 (pistas oníricas catalogadas).

Última revisión: 2026-09-13.
