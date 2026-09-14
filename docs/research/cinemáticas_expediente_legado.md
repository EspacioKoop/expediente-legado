# Técnicas cinematográficas para Expediente Legado

Seguimiento de #463. Este documento concreta cuatro referencias —*Neon Genesis Evangelion*, *Serial Experiments Lain*, *Kingdom Hearts* y *Persona*— en reglas y experimentos transferibles al standalone de **Expediente Legado**.

No se incorporan imágenes, audio, tipografías, logos, nombres, diálogos, personajes ni otros assets de esas obras. Las referencias se usan únicamente como estudio de técnicas generales de puesta en escena, ritmo, sonido e interfaz.

Este documento complementa [`docs/investigacion-cinematografica.md`](../investigacion-cinematografica.md); no abre un sistema narrativo paralelo ni sustituye los issues propietarios de cinemáticas, sueño o accesibilidad.

## Matriz de evaluación

| Recurso | URL de referencia | Licencia / situación | Qué se estudia | Integración propuesta | Riesgo legal |
| --- | --- | --- | --- | --- | --- |
| *Neon Genesis Evangelion* | <https://en.wikipedia.org/wiki/Neon_Genesis_Evangelion> | Obra protegida por copyright | planos estáticos, silencios largos, espacio negativo, encuadres que separan al sujeto del entorno y edición que dilata o comprime la percepción del tiempo | aplicar duración, encuadre y diseño sonoro propios a transiciones rutinarias, sin reproducir planos concretos | Bajo si se limita a técnicas abstractas; alto si se replica composición, música, personajes o iconografía reconocible |
| *Serial Experiments Lain* | <https://en.wikipedia.org/wiki/Serial_Experiments_Lain> | Obra protegida por copyright | repetición con pequeñas alteraciones, interferencia entre interfaz y narración, elipsis y ambigüedad controlada | deformar únicamente información ya conocida por el jugador mediante orden, ruido, escala o superposición | Bajo si la implementación usa contenido propio; evitar reconstruir interfaces, textos, audio o escenas identificables |
| *Kingdom Hearts* | <https://en.wikipedia.org/wiki/Kingdom_Hearts> | Obra protegida por copyright | cambio claro de estado/mundo mediante umbrales visuales, continuidad musical y objetos simbólicos | usar puertas, ascensores, pasillos u otros umbrales propios de SIGA-98 para marcar oficina ↔ trayecto ↔ casa ↔ sueño | Bajo si el lenguaje visual y musical es original; evitar iconografía, partículas, música o diseños de puertas reconocibles de la saga |
| *Persona* (énfasis en *Persona 5*) | <https://en.wikipedia.org/wiki/Persona_5> | Obra protegida por copyright | interfaz con fuerte dirección visual, transiciones rápidas y relación entre UI, ritmo y estado psicológico | hacer que la UI propia de SIGA-98 participe en transiciones sin copiar paleta, tipografía, composiciones ni animaciones concretas | Bajo si se usa como principio de diseño; riesgo medio si la UI se aproxima demasiado a la identidad visual de *Persona 5* |

## Principios transferibles

### 1. Evangelion: pausa con intención

La técnica útil no es “hacer una escena larga”, sino sostener un encuadre cuando el silencio añade información emocional o espacial.

Reglas para SIGA-98:

- toda pausa debe contener al menos un microevento perceptible: fluorescente, impresora, tráfico, pasos, reloj, ventilación o un cambio mínimo de foco/luz;
- una transición rutinaria no debería superar los **8 s** sin permitir salto/acortado;
- la información necesaria no puede depender del audio;
- con `reduce_motion`, el efecto debe conservarse mediante encuadre estable y fundido/corte simple.

### 2. Lain: fragmentar la presentación, no los hechos

La ambigüedad debe surgir de cómo se presenta información conocida, nunca de inventar pistas.

Reglas para SIGA-98:

- solo pueden aparecer nombres, conceptos, folios, llamadas o elementos que existan en el estado persistido;
- las alteraciones admitidas son orden, repetición, recorte, escala, ruido, mezcla de capas y elipsis;
- ninguna deformación puede cambiar el contenido semántico de una pista;
- toda selección procedural debe ser reproducible con una semilla o estado determinista.

### 3. Kingdom Hearts: transición como umbral

El cambio de bloque debe leerse antes de que el jugador consulte un HUD.

Reglas para SIGA-98:

- cada bloque principal debe tener al menos dos señales propias entre luz, sonido, composición, material, cámara y ritmo;
- se priorizan umbrales ya coherentes con el mundo: puerta de oficina, ascensor, portal, pasillo, transporte, dormitorio;
- no se requiere un sistema de “mundos” ni una pantalla intermedia nueva;
- la música puede ayudar, pero la transición debe funcionar también silenciada.

### 4. Persona: la interfaz participa, no decora

La UI puede reforzar el tono si cada aparición tiene una función clara.

Reglas para SIGA-98:

- toda animación de UI debe comunicar jerarquía, cambio de estado o destino de la acción;
- mantener identidad visual propia de SIGA-98: burocrática, tardonoventera y legible;
- evitar reproducir rojo/negro/blanco como firma, recortes de cómic, tipografías o movimientos asociados directamente a *Persona 5*;
- las animaciones deben tener una variante instantánea o simplificada con `reduce_motion`.

## Experimentos propuestos

### Experimento E1 — oficina → trayecto

**Referencia:** Evangelion.

**Hipótesis:** una pausa breve con sonido ambiente y espacio negativo hace que salir de la oficina se perciba como cierre de bloque sin diálogo adicional.

**Prototipo:**

1. al finalizar la acción que cierra oficina, resolver y guardar el estado;
2. mantener 4–6 s un plano fijo del espacio de salida;
3. introducir un único microevento propio del entorno;
4. cortar al trayecto con cambio claro de ambiente;
5. permitir salto inmediato y variante `reduce_motion`.

**Éxito medible:** 4/5 testers identifican que “ha terminado la jornada/bloque de oficina” sin texto explicativo y ninguno interpreta la pausa como bloqueo del juego.

### Experimento L1 — casa → sueño con información conocida

**Referencia:** Lain.

**Hipótesis:** repetir elementos ya vistos con pequeñas alteraciones genera extrañeza sin introducir falsas pistas.

**Prototipo:**

1. seleccionar de forma determinista 1–3 elementos ya conocidos;
2. repetir el encuadre de casa o dormitorio;
3. deformar orden, escala, ruido o superposición;
4. cortar bruscamente a sueño;
5. registrar en debug qué elementos persistidos originaron la escena.

**Éxito medible:** ningún tester reporta una pista “nueva” que en realidad no exista; el log permite reconstruir exactamente la variante mostrada.

### Experimento K1 — umbral oficina ↔ casa

**Referencia:** Kingdom Hearts.

**Hipótesis:** un umbral físico más dos señales audiovisuales propias bastan para distinguir bloques sin pantalla de carga narrativa adicional.

**Prototipo:**

1. reutilizar un umbral del escenario existente;
2. diferenciar ambos lados mediante luz/material/ambiente;
3. usar transición sonora breve y original;
4. evitar partículas o iconografía que recuerden a la referencia externa;
5. hacer la transición saltable.

**Éxito medible:** 4/5 testers identifican el nuevo bloque antes de que aparezca texto de localización.

### Experimento P1 — menú de sueño narrativo

**Referencia:** Persona.

**Hipótesis:** una animación de UI propia que refuerce jerarquía y estado psicológico puede mejorar claridad sin adoptar la identidad visual de otra obra.

**Prototipo:**

1. conservar tipografía, paleta y geometría propias de SIGA-98;
2. animar entrada/salida siguiendo una trayectoria coherente con la jerarquía de opciones;
3. usar como máximo una capa de distorsión ligada al sueño;
4. ofrecer variante sin desplazamientos complejos bajo `reduce_motion`;
5. comprobar navegación completa con teclado/mando.

**Éxito medible:** 5/5 testers encuentran la opción principal en menos de 3 s y ningún tester describe la interfaz como una imitación directa de *Persona 5*.

## Matriz de prueba interna

| ID | Build / PR | Estado | Resultado | Evidencia |
| --- | --- | --- | --- | --- |
| E1 | pendiente | No ejecutado | — | — |
| L1 | pendiente | No ejecutado | — | — |
| K1 | pendiente | No ejecutado | — | — |
| P1 | pendiente | No ejecutado | — | — |

Los resultados reales se deben completar aquí cuando los prototipos lleguen a una build jugable. No se registran como “probados” hasta existir evidencia reproducible.

## Checklist común de aceptación

Un experimento derivado de estas referencias solo puede darse por válido si cumple todo lo siguiente:

- [ ] usa exclusivamente assets y contenido propios o con licencia compatible;
- [ ] no reproduce planos, UI, música, iconografía, diálogos o composiciones identificables de las obras de referencia;
- [ ] es saltable sin pérdida de progreso;
- [ ] el estado relevante se resuelve/guarda antes de la cinemática;
- [ ] existe variante compatible con `reduce_motion`;
- [ ] toda información esencial sigue disponible sin audio;
- [ ] ninguna deformación revela información no conocida por el jugador;
- [ ] las variantes procedurales son reproducibles en test/debug;
- [ ] la escena sigue siendo comprensible para alguien que no conozca Evangelion, Lain, Kingdom Hearts o Persona.

## Relación con el trabajo existente

- [`docs/investigacion-cinematografica.md`](../investigacion-cinematografica.md): principios generales, guardas y trazabilidad de adopción.
- #395: propietario de las cinemáticas 3D prioritarias y continuidad espacial.
- #280: validación de transiciones/cinemáticas en export.
- #87: contenido y reglas del sueño.
- #66/#67: reproductor, salto, ritmo y acortado común de cinemáticas.

#463 queda cubierto documentalmente cuando este archivo esté integrado con, como mínimo, una propuesta concreta por las cuatro referencias. La ejecución de E1/L1/K1/P1 debe entrar en el issue propietario del problema que cada experimento pretenda resolver, no como cuatro features independientes nacidas solo de la referencia externa.
