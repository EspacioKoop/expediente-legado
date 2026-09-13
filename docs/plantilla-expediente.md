# Plantilla editorial de expediente SIGA-98

Esta plantilla fija el mínimo revisable para ampliar `godot/datos/casos.json` sin convertir cada caso nuevo en un cambio de código. No prescribe una trama: prescribe **qué debe poder auditarse** antes de integrar contenido.

## 1. Identidad del caso

- `id`: estable, único y con versión (`casoN@N` o convención equivalente ya existente).
- `titulo`: clave de texto/traducción coherente con el catálogo.
- `descripcion`: sinopsis factual del expediente, sin revelar automáticamente la conclusión.
- `anioSuceso`: entero explícito; nunca inferido ni `null`.
- `estado`: estado inicial válido para el flujo SIGA.
- `confidencial` y `principal`: booleanos explícitos.

## 2. Registros/documentos

Cada registro debe declarar:

- `id` único;
- `tipo` documental reconocible;
- `folio` legible y distinto dentro del caso;
- `contenido` con voz propia y suficiente contexto para investigar;
- `fecha` explícita cuando el documento la tenga.

Revisión editorial:

- el documento debe sonar a su tipo (acta, memo, oficio, ficha, etc.);
- no introducir hechos necesarios para resolver el caso solo en una pista/desenlace;
- si una pista depende de una frase literal, esa frase debe existir realmente en `contenido`;
- evitar documentos intercambiables entre casos: cada expediente debe tener al menos una voz, estructura o anomalía propia.

## 3. Pistas

Cada pista debe declarar:

- `id` único;
- `registroOrigen` existente en el mismo caso;
- `descripcion` que reformule una observación deducible, no un hecho nuevo.

Para una pista de frase:

- `fraseGatillo` debe aparecer literalmente en el `contenido` de `registroOrigen`.

Para una relación entre dos documentos:

- `registroOrigen2` debe existir en el mismo caso y ser distinto de `registroOrigen`;
- la conclusión debe surgir de comparar ambos documentos;
- A+B y B+A representan la misma relación; no duplicar la conclusión con el orden invertido.

## 4. Sospechosos y desenlaces

Cada sospechoso debe declarar:

- `id` único;
- `nombre`;
- `descripcion` basada en información disponible en el expediente;
- `desenlace` propio.

El desenlace puede ser irónico, burocrático o ambiguo, pero no debe revelar evidencia que el expediente nunca proporcionó.

## 5. Corcho, conceptos y sueño

Antes de integrar un caso nuevo, revisar además:

- referencias `[[Concepto]]`: toda referencia debe apuntar a un concepto existente en el sistema que corresponda;
- tarot, si procede: cualquier frase usada para ocultar/desbloquear una carta debe existir literalmente en el documento de origen;
- sueño: identificar **material ya leído** que pueda deformarse o recontextualizarse sin inventar hechos nuevos;
- #89: una recompensa onírica debe señalar/recontextualizar información ya presente, no resolver el caso por el jugador.

Estos elementos pueden vivir en otros catálogos; no es obligatorio añadir campos nuevos a `casos.json` para cumplir esta revisión.

## 6. Prueba editorial mínima de un caso piloto

Antes de multiplicar expedientes, el primer caso nuevo debe pasar este recorrido:

1. aparece en SIGA sin cambios de código específicos del caso;
2. todos sus registros pueden leerse;
3. sus pistas de frase se descubren desde texto real;
4. sus relaciones de dos documentos se pueden descubrir manualmente;
5. sus sospechosos/desenlaces no requieren hechos externos al catálogo;
6. el contenido leído puede alimentar sueño/corcho sin datos inventados;
7. guardar/cerrar/recargar no deja el caso en un estado imposible;
8. las guardas automáticas de catálogo quedan verdes.

## 7. Criterio de variedad

No aprobar un caso nuevo solo porque sea válido estructuralmente. Compararlo con los ya existentes y exigir al menos dos diferencias sustantivas entre:

- tipo de conflicto;
- mezcla de documentos;
- voz documental;
- forma de relación entre pruebas;
- tipo de sospechoso/responsabilidad;
- imagen o deformación onírica posible;
- tono del desenlace.

El objetivo de #91 no es alcanzar un número arbitrario de casos, sino sostener una partida larga sin que cada expediente se sienta como una reescritura del anterior.

— Odiseo (GPT-5.6 Sol)
