# Paridad de religión: legado pre-Godot → sistema transversal

## Estado posterior al corte — 2026-09-22

La conclusión histórica de esta auditoría no cambia: no había un subsistema religioso jugable pre-Godot que “portar”. Lo que sí ha avanzado es la expansión nueva: JALI 98 (#1158/#1163), VITRAL 98 (#1168) y SARNATH 98 (#1170) prueban el canal cultural/ROM; #934 dispone de un primer corte de práctica y cultura material (#1147); y #936 tiene ya un primer contrato contextual de conflicto (#1117).

Mantener la separación central de #916: **exposición, práctica, convicción y vínculo no son equivalentes**, y religión no debe absorber Tarot ni mitologías.

Seguimiento de #930 y base documental de #916 / #931–#937.

## Corte temporal y método

Esta auditoría usa como frontera el primer corte del port a Godot:

- `fcff395024bd3a1cbd6abbcf50867c555fead5e8` — 2026-09-10, «primer corte del port a Godot — contenido como datos y lógica pura (#54)».

Por tanto, **legado pre-Godot** significa aquí el material versionado anterior a ese commit. Los sistemas Godot posteriores se consultan solo para identificar equivalentes actuales y evitar reclasificaciones retrospectivas.

Fuentes revisadas:

- `backend/src/main/resources/static/js/prometeo-ui.js`;
- `backend/src/main/resources/static/js/prometeo-logic.js`;
- `backend/src/test/js/prometeo-logic.test.js`;
- `backend/src/main/java/com/legado/expediente/service/CartaOcultaService.java`;
- `backend/src/main/java/com/legado/expediente/config/DataSeeder.java`;
- historial desde el commit inicial `6d16dbc6582a9d3314de3cfb8be0300c183c0afb` hasta el corte de Godot;
- issues históricas #21, #44, #45 y #46;
- #1029 como comprobación posterior de paridad del Tarot;
- equivalentes actuales `godot/guion/prometeo.gd`, `historias.gd`, `cartas_ocultas.gd` y `godot/datos/prometeo.json`;
- `docs/paridad-ideologias.md` y `docs/design/gramatica-simbolica-siga98.md` para fijar fronteras entre dominios.

La búsqueda no se limitó a `religion`: se revisaron también iglesia, capilla, culto, misa, rezar, biblia, sacerdote, virgen, sagrado, fe, creencia, ritual, Tarot/Arcanos, Prometeo, Carcosa, Hastur, finales, logros, combate y contenido oculto en documentos.

## Resultado ejecutivo

**No se ha encontrado en el corpus pre-Godot versionado un sistema de religión vivida, una institución religiosa, una práctica religiosa, una convicción declarada, una comunidad religiosa, un calendario religioso ni una ROM religiosa.**

Sí existe una capa amplia de **Tarot/Prometeo** y simbolismo esotérico. Algunos nombres —Sacerdotisa, Hierofante, Diablo, Juicio— tienen vocabulario que puede parecer religioso fuera de contexto, pero en el juego son Arcanos de Tarot con reglas burocráticas: descubrir pistas, emitir un veredicto, perder vidas, gastar cartas o completar el archivo. No son prueba de afiliación, práctica ni institución religiosa.

También existen motivos de horror literario como **Carcosa**, el **Comité Ad Honorem** y la credencial `hastur-local-13`. El material legado no establece un culto, rito ni religión asociados: convertir esas pistas en una institución religiosa sería añadir canon que la fuente no contiene.

La consecuencia para #916 es importante: **la épica religiosa es principalmente una expansión nueva apoyada en infraestructura existente, no la migración de un subsistema religioso oculto**. Lo recuperable del legado son patrones técnicos y narrativos —eventos significativos, idempotencia, memoria por vuelta, exposición mediante documentos—, no una identidad religiosa que deba inferirse o conservarse.

## Separación de dominios

| Dominio exigido por #930 | Resultado en el legado pre-Godot | Decisión |
| --- | --- | --- |
| Religión vivida / practicada | No se encontró evidencia versionada | Contenido nuevo bajo #931/#933/#934; no fabricar paridad |
| Institución religiosa | No se encontró evidencia versionada | El Comité Ad Honorem es una institución burocrática ficticia, no religiosa |
| Cultura / material religioso | No se encontró evidencia versionada | #934 es expansión nueva |
| Mito / folclore | El nombre Prometeo funciona como referencia nominal; no había sistema mitológico transversal | Mantener separado de religión; las familias #435/#650 son posteriores |
| Tarot / esoterismo | Sistema amplio de 22 Arcanos, cartas ocultas, combate, canje y memoria | Pertenece a Tarot; #1029 y #888 son referencias principales |
| Simbolismo onírico | No se encontró una capa religiosa onírica pre-Godot | #935 es expansión; no atribuir al legado los sueños mitológicos posteriores |
| Postura personal de NPC | No se encontró una postura religiosa explícita de NPC | #933 es expansión nueva |
| Hechos históricos/culturales religiosos | No se encontró un corpus religioso factual | Cualquier tradición viva futura necesita fuentes nuevas conforme a #916 |

## Matriz canónica

| Concepto | Fuente legado | Equivalente actual | Estado | Decisión | Issue destino | Prueba / evidencia |
| --- | --- | --- | --- | --- | --- | --- |
| Catálogo de 22 Arcanos | `prometeo-ui.js` / `tarotActual`; #21, #44, #46 | `prometeo.json` + `Prometeo` | **Portado / paridad aún parcial en triggers** | Tarot/esoterismo, **no religión vivida** | #1029; #888 | #1029 enumera los triggers heredados aún sujetos a paridad |
| Sacerdotisa, Hierofante, Diablo y Juicio | entradas de `tarotActual` | mismas cartas en Godot | **Portado** | Los nombres son Arcanos. Sus requisitos son progreso burocrático; no crear práctica, credo ni institución a partir del nombre | #1029; #888; #935 solo como consumidor simbólico | Hierofante: primer veredicto; Diablo: verificación falsa; Juicio: carta oculta documental |
| Cartas ocultas dentro de documentos | `CartaOcultaService` | `CartasOcultas` + `Marcas` | **Portado** | El contenido sigue siendo Tarot. El **patrón** «interacción documental significativa → exposición registrada» sí es reutilizable para religión sin reetiquetar cartas antiguas | #931, #932, #933, #934 | `CartasOcultas` declara explícitamente que porta `CartaOcultaService` |
| Desbloqueos de Tarot por progreso | `sincronizarConEstadoReal()` y eventos en `prometeo-ui.js` | funciones de `Prometeo` / #1029 | **Portado parcialmente** | Reutilizable como patrón de evento estable e idempotente; **no** reutilizar el estado Tarot como estado religioso | #1029; lección arquitectónica para #931 | #1029: Mago, Emperador, Hierofante, Enamorados, Fuerza, Templanza, Estrella y Mundo |
| Canje de carta, Templanza y memoria fantasma | #44, #46 y lógica Prometeo | estado Tarot de Godot | **Portado / ampliándose** | Esoterismo y metaprogresión. La distinción «conocido alguna vez» vs «poseído esta vuelta» sirve como precedente de separar conocimiento de participación, pero con claves religiosas independientes | #1029; #931 como precedente conceptual | #46 define Tarot per-run + memoria fantasma |
| Combate de cartas de Tarot | #21 y Prometeo legado | `Combate`, Juicio y capas posteriores | **Replanteado / expandido** | No convertir mecánicas de carta en bonus por credo | #1029; #779/#888 para Tarot simbólico; #936 para religión contextual | #21 pide explícitamente combate de cartas de Tarot |
| Ocho historias vinculadas a cartas | `HISTORIAS_CARTAS` | `Historias` + `prometeo.json` | **Portado** | Su contenido funcional es político. Lo posee #915/#919, no #916 | #915, #919, #925 | `docs/paridad-ideologias.md` ya fija su paridad |
| Final político y logros políticos | `LINEAS_FINAL_POLITICO`, `finalPoliticoShown` | cierre político actual | **Portado / generalizado** | No son final religioso ni indicador de creencia | #925 | `docs/paridad-ideologias.md` |
| Nombre «Prometeo» | UI y lógica Prometeo | clase `Prometeo` y superficies actuales | **Portado** | Referencia mitológica/branding; no demuestra religiosidad del jugador ni religión griega practicada | #888 si se reutiliza simbólicamente | Historial pre-Godot muestra Prometeo desde el inicio |
| Carcosa Servicios Escénicos / sello amarillo | `DataSeeder`, documentos y historia de La Luna | datos de casos actuales | **Portado** | Horror/literatura y expediente. No inferir culto ni institución religiosa | #888/#935 solo si reaparece como memoria conocida | El legado describe compañía teatral, contrato y sello; no culto |
| Comité Ad Honorem / `hastur-local-13` | `DataSeeder` y credencial especial | capa OS98/Hastur posterior | **Portado y expandido después** | Institución burocrática ficticia + horror. No reclasificarla como religión sin nueva evidencia | #888/#935 para simbolismo; no #933/#934 como institución religiosa | Credencial y acta describen administración perpetua, no credo/rito |
| Capilla del castillo, Duat y «rituales» Tarot+mitología | **No existían antes del corte Godot** | sueños y `JuicioSimbolico` actuales | **Fuera del legado auditado** | Mantener en mitología/Tarot/sueño. #935 debe declarar el canal cuando los consuma | #435, #650, #779, #888, #935 | aparecen en código/documentación posterior al 2026-09-10 |
| ROM religiosa/cultural | Sin evidencia pre-Godot | aún por desarrollar en épica religiosa | **No existía** | #932 es expansión nueva, no port | #932 | inventario negativo |
| Práctica/participación religiosa | Sin evidencia pre-Godot | contrato nuevo de religión | **No existía** | Registrar solo actos futuros explícitos/contextuales | #931, #934 | inventario negativo |
| Convicción religiosa declarada | Sin evidencia pre-Godot | contrato nuevo de religión | **No existía** | Nunca derivarla de Tarot, lectura, mito o visita | #931, #933 | inventario negativo |
| Vínculo religioso social/institucional | Sin evidencia pre-Godot | contrato nuevo de religión | **No existía** | Introducirlo mediante personas/comunidades nuevas y hechos observables | #931, #933 | inventario negativo |
| Trayectoria / epílogo religioso | Sin evidencia pre-Godot | previsto por #937 | **No existía** | #937 debe resumir hechos nuevos, no reinterpretar el final político o Tarot | #937 | inventario negativo |

## Inventario negativo

La ausencia también es un resultado de la auditoría y evita que una expansión futura se presente erróneamente como «recuperación».

- En backend/web legado no se localizó una superficie funcional de iglesia, misa, oración, Biblia, sacerdocio, Virgen, comunidad de fe o declaración de creencia.
- En el historial anterior al primer commit Godot sí aparecen repetidamente **Tarot** y **Prometeo** entre el 5 y el 10 de julio de 2026, mientras que las búsquedas de religión/mitología/sueño no revelan una capa religiosa equivalente.
- `capilla` aparece en la arquitectura onírica del castillo **posterior** al corte Godot, no como institución religiosa del juego anterior.
- El término `ritual` que hoy aparece en Juicio describe combinaciones Tarot+mitología añadidas posteriormente; no prueba una práctica religiosa heredada.
- Carcosa/Hastur no autoriza a inventar retrospectivamente un culto: el material pre-Godot revisado solo acredita horror literario, compañía teatral, burocracia y credenciales.

Este inventario describe el **corpus versionado revisado**. No pretende afirmar qué ideas no versionadas pudo considerar alguna persona fuera del repositorio.

## Qué se recupera para #916

### Se recupera como patrón

1. **Evento significativo antes de registrar estado.** El Tarot ya distinguía progreso real de abrir una pantalla. #931/#932 deben conservar esa disciplina: insertar o arrancar una ROM no equivale a exposición significativa.
2. **Idempotencia y procedencia.** Los desbloqueos heredados muestran que una misma fuente no debe duplicar progreso. Los eventos religiosos necesitan IDs/fuentes estables.
3. **Conocimiento separado de posesión.** La memoria fantasma de #46 demuestra que «haber conocido» y «tener ahora» pueden ser estados distintos. Religión necesita una separación aún más estricta: exposición, práctica, convicción y vínculo.
4. **Contenido dentro del mundo, no formulario abstracto.** `CartaOcultaService` usa documentos reales del expediente. Libros, conversaciones, ROMs o visitas religiosas futuras deben registrar la experiencia desde su interacción real.
5. **No inferir más de lo observado.** Si encontrar el Hierofante nunca significó «el jugador cree en X», leer un texto religioso tampoco puede significarlo.

### No se arrastra

- ninguna variable Tarot como sustituto de religión;
- una barra global de fe;
- una religión deducida por cartas recogidas;
- una práctica deducida de leer o jugar contenido cultural;
- una conversión deducida de visitar un espacio;
- un culto a Hastur/Carcosa inventado a partir de horror burocrático;
- una tradición viva tratada como bioma mitológico;
- bonus/debilidades permanentes por credo.

## Ruta de los sub-issues de #916

| Issue | Relación con el legado auditado |
| --- | --- |
| #931 — contrato transversal | **Nuevo contrato**. Puede reutilizar idempotencia/procedencia como patrón, nunca el estado Tarot |
| #932 — ROMs religiosas/culturales | **Expansión nueva**. No había ROM religiosa pre-Godot |
| #933 — diálogos, familia, comunidades | **Expansión nueva**. No se halló postura religiosa heredada de NPC |
| #934 — espacios, prácticas, calendario, material | **Expansión nueva**. No se halló institución/espacio/material religioso heredado |
| #935 — sueño y simbolismo | **Consumidor nuevo**. Puede cruzar recuerdos de Tarot/mitología solo declarando su dominio y canal |
| #936 — conflicto y ritual | **Expansión nueva**. Los compromisos religiosos no proceden del combate Tarot legado |
| #937 — trayectoria y epílogo | **Expansión nueva**. No debe reinterpretar final político, logros o colección Tarot como identidad religiosa |

## Criterio de cierre de #930

- [x] se revisa legado web/backend y el historial hasta una frontera temporal explícita;
- [x] cada concepto aparentemente religioso detectado termina con dominio y decisión;
- [x] se identifican los **patrones recuperables** para documentos, diálogo/mundo, ROMs, sueño, conflicto y trayectoria, dejando explícito dónde no existía contenido religioso heredado;
- [x] se documentan los límites entre religión, mitología, Tarot, horror y simbolismo onírico;
- [x] el inventario negativo impide que la ausencia se convierta en omisión silenciosa;
- [x] #931–#937 quedan enlazados como destinos y se distingue qué es port y qué es expansión.

La conclusión canónica es deliberadamente conservadora: **no había una religión jugable que rescatar; había sistemas vecinos que deben seguir siendo vecinos**.
