# Playtest #431 · profundidad de expedientes SIGA

Este gate valida el cierre pendiente de #286 sobre una build real. La implementación ya contiene relación manual de folios, marcadores, metadatos, anexos, identidad visual, presupuesto visible y contexto documental hacia el careo. El objetivo aquí no es añadir otra mecánica: es comprobar si esas capas producen investigación voluntaria y legible.

## Preparación

1. Usar una build identificable por SHA.
2. Empezar desde escenas reales, sin consola ni atajos de prueba.
3. Recorrer al menos dos expedientes.
4. Usar teclado real. El mando físico se registra cuando proceda, pero no sustituye el recorrido con teclado.
5. Guardar, cerrar y reabrir durante el pase para comprobar persistencia.

## Recorrido mínimo

En el conjunto de los dos expedientes:

- abrir varios folios antes de firmar;
- volver voluntariamente a algún documento ya leído;
- usar al menos dos capas distintas además de leer texto, sin instrucciones del desarrollador:
  - relación manual entre folios;
  - marcador personal;
  - comparación de metadatos;
  - anexo documental;
- encontrar al menos una relación válida por lectura/comparación;
- probar una pareja sin conclusión y comprobar que el feedback no afirma que jamás exista una conexión narrativa;
- entender qué dos documentos produjeron el hallazgo;
- verificar que lecturas, marcadores y relaciones sobreviven a guardar/cerrar/reabrir;
- firmar y llegar al careo;
- comprobar que el contexto investigado aparece cuando corresponde y no cambia automáticamente acusado, tiradas, vida, veredicto ni ganador.

No se exige abrir un anexo en ambos casos: algunos expedientes pueden no ofrecerlo. Tampoco se fija un tiempo mínimo artificial.

## Métricas por expediente

Registrar:

- número de folios abiertos antes de firmar;
- si hubo relectura voluntaria;
- intentos de relación antes de una válida;
- uso de marcador;
- uso de anexo cuando estuviera disponible;
- una nota breve si apareció fricción, una pista visual útil o una ambigüedad.

La impresión final debe conservar una de estas categorías del issue:

- pantalla de lectura + decisión inmediata;
- investigación ligera pero real;
- demasiada fricción;
- otra impresión, descrita en notas/incidencias.

## Registro asistido

Puede generarse un informe Markdown homogéneo con:

```bash
python3 scripts/registrar_playtest_431.py \
  --salida docs/playtests/playtest-431.md
```

El registrador resume únicamente respuestas humanas. Marca `listo para valorar cierre de #286` cuando:

- hay al menos dos expedientes con varios folios;
- se usaron espontáneamente al menos dos capas distintas además de leer;
- hubo relación válida, prueba negativa prudente y feedback entendido;
- persistieron lecturas, marcadores y relaciones;
- el contexto llegó al careo sin automatizarlo;
- no quedó un hueco de paridad relevante sin issue propio;
- la impresión final ya no fue «lectura + decisión inmediata»;
- el recorrido se hizo con teclado real.

El mando físico y las capturas se guardan como evidencia adicional, no como sustituto de esos criterios.

## Qué no valida este script

- No ejecuta Godot.
- No analiza capturas ni vídeo.
- No decide si una conclusión narrativa es correcta.
- No convierte CI/headless en aprobación humana.
- No cierra #286 ni #431 automáticamente.
- No oculta un fallo: cualquier criterio negativo deja el gate pendiente.

Si aparece una carencia concreta, abrir un issue separado con pasos reproducibles y enlazarlo desde #431. Solo reabrir alcance genérico de #286 si el fallo es transversal a la investigación.

Refs #286 #431 #619 #621 #625 #695.
