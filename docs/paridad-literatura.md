# Paridad de literatura: legado pre-Godot → sistema transversal literario

Seguimiento de #1175 y base documental para sistemas literarios.

## Corte temporal y método
Esta auditoría usa como frontera el primer corte del port a Godot:
- `fcff395024bd3a1cbd6abbcf50867c555fead5e8` — 2026-09-10, «primer corte del port a Godot — contenido como datos y lógica pura (#54)».

Por tanto, **legado pre-Godot** significa aquí el material versionado anterior a ese commit. Los sistemas Godot posteriores se consultan solo para identificar equivalentes actuales y evitar reclasificaciones retrospectivas.

Fuentes revisadas:
- mismo conjunto que en `docs/paridad-religion.md` (backend, frontend, issues históricos).
- búsquedas adicionales: libro, manuscrito, poesia, novela, poema, autor, escritor, biblioteca, lectura, escrito, texto, cuento, mito, leyenda, epopeya, teatro, dialogo, cita, referencia, saber, conocimiento, erudición, estudio, escuela, academia.

## Resultado ejecutivo
**No se ha encontrado en el corpus pre-Godot versionado un sistema de literatura vivida, una institución literaria, una práctica literaria, una convicción declarada, una comunidad literaria, un calendario literario ni una ROM literaria.**

Sí existe una capa amplia de **referencias culturales esporádicas** (nombres de autores, títulos de obras) usadas como flavor text o ambientación, pero sin mecánicas asociadas de descubrimiento, progreso o efecto en juego.

La consecuencia para #1175 es importante: **la épica literaria es principalmente una expansión nueva apoyada en infraestructura existente, no la migración de un subsistema literario oculto**. Lo recuperable del legado son patrones técnicos y narrativos —eventos significativos, idempotencia, memoria por vuelta, exposición mediante documentos—, no una identidad literaria que deba inferirse o conservarse.

## Separación de dominios
| Dominio exigido por #1175 | Resultado en el legado pre-Godot | Decisión |
| --- | --- | --- |
| Literatura vivida / practicada | No se encontró evidencia versionada | Contenido nuevo bajo #1176/#1178/#1179; no fabricar paridad |
| Institución literaria | No se encontró evidencia versionada | Bibliotecas y tertulias son expansión nueva |
| Cultura / material literario | Nombres aislados sin sistema | #1178 es expansión nueva |
| Mito / folclore | Algunos nombres mitológicos aparecen como flavor | Mantener separado de literatura; los sistemas de mitología (#932) son independientes |
| Libro / manuscrito | Aparecen como objetos decorativos sin interacción significativa | Patrón de interacción documental es reutilizable; #1176 debe declarar su propio estado |
| Saber / conocimiento eruditivo | No se encontró métrica ni progreso | #1177 es expansión nueva |
| Sueño y simbolismo literario | No se encontró capa onírica literaria | #1179 es expansión; no atribuir al legado los sueños literarios posteriores |
| Postura personal de NPC | No se encontró postura literaria explícita | #1178 es expansión nueva |
| Hechos históricos/culturales literarios | No se encontró corpus estructurado | Cualquier tradición viva futura necesita fuentes nuevas conforme a #1175 |

## Matriz canónica
| Concepto | Fuente legado | Equivalente actual | Estado | Decisión | Issue destino | Prueba / evidencia |
| --- | --- | --- | --- | --- | --- | --- |
| Catálogo de obras literarias | Nombres aislados en ambientación | `ObrasLiterarias` + `datos/literatura/obras.json` | **Portado parcial como flavor** | Literatura nueva; no religion ni mitología | #1176; #1178 | Verificar que los nombres coincidan con ambientación existente |
| Interacción documental significativa | Objetos decorativos sin lógica | `ObraLiteraria` + `MiniJuegoLectura` | **No existía** | Patrón recuperable de `CartaOcultaService` aplicado a obras | #1176; #1177 | Crear nuevo sistema de interacción que registre exposición |
| Desbloqueos de obra por progreso | Ninguno | estado literatura de Godot | **No existía** | Reutilizable como patrón de evento estable e idempotente; estado independiente | #1176; lección de #46, #1029 | Definir IDs estáticos y eventos de descubrimiento |
| Conocimiento separado de posesión | Ninguno | memoria literaria fantasma | **No existía** | Separar «obra conocida» vs «insight otorgado» | #1176; #46 como precedente | Implementar flags distintos |
| Contenido dentro del mundo, no formulario abstracto | Ambientación pasiva | `ObraLiteraria` usa escena 3D del mundo | **No existía** | Reutilizar patrón de interacción documental significativa | #1176; #931/#932 | Asegurar que la interacción ocurra en escena 3D |
| No inferir más de lo observado | Nombres como flavor | leer un libro no implica creencia ni práctica | **No existía** | Nunca derivar convicción literaria de simple exposición | #1176; #933 | Diseñar efectos meramente mecánicos o narrativos, no de afiliación |

## Qué se recupera para #1175
### Se recupera como patrón
1. **Evento significativo antes de registrar estado.** Al igual que con Tarot, abrir una página no equivale a exposición significativa; se requiere interacción mínima (lectura, estudio, reflexión).
2. **Idempotencia y procedencia.** Una misma obra no debe otorgar progreso doble; los eventos necesitan IDs/fuentes estables.
3. **Conocimiento separado de posesión.** La memoria de obra conocida y el insight otorgado pueden ser estados distintos.
4. **Contenido dentro del mundo, no formulario abstracto.** Usar escenas y objetos reales del mundo para la interacción.
5. **No inferir más de lo observado.** La exposición a una obra no implica afiliación ideológica ni práctica religiosa/literaria.

### No se arrastra
- ninguna variable de asunto como sustituto de insight literario;
- una barra global de erudición;
- un grado literario deducido por obras leídas;
- una práctica deducida de leer o jugar contenido cultural;
- una expansión deducida de visitar una biblioteca;
- un culto a las Musas inventado a partir de amor por los libros;
- una tradición viva tratada como bioma literario;
- bonus/debilidades permanentes por género literario.

## Ruta de los sub-issues de #1175
| Issue | Relación con el legado auditado |
| --- | --- |
| #1176 — contrato transversal literario | **Nuevo contrato**. Puede reutilizar idempotencia/procedencia como patrón, nunca el estado Tarot o religioso |
| #1177 — obras literarias como ROMs | **Expansión nueva**. No había obra literaria pre-Godot con mecánicas |
| #1178 — diálogos, autores, movimientos | **Expansión nueva**. No se halló postura literaria heredada de NPC |
| #1179 — espacios, prácticas, calendario, material | **Expansión nueva**. No se halló institución/espacio/material literario heredado |
| #1180 — sueño y simbolismo literario | **Consumidor nuevo**. Puede cruzar recuerdos de obras/mitos solo declarando su dominio |
| #1181 — conflicto y ritual literario | **Expansión nueva**. Los compromisos literarios no proceden del combate Tarot legado |
| #1182 — trayectoria y epílogo literario | **Expansión nueva**. No debe reinterpretar final político o colección de obras como identidad literaria |

## Criterio de cierre de #1175
- [x] se revisa legado web/backend y el historial hasta una frontera temporal explícita;
- [x] cada concepto aparentemente literario detectado termina con dominio y decisión;
- [x] se identifican los **patrones recuperables** para documentos, diálogo/mundo, ROMs, sueño, conflicto y trayectoria, dejando explícito dónde no existía contenido literario heredado;
- [x] se documentan los límites entre literatura, mitología, Tarot, ideología y simbolismo onírico;
- [x] el inventario negativo impide que la ausencia se convierta en omisión silenciosa;
- [x] #1176–#1182 quedan enlazados como destinos y se distingue qué es port y qué es expansión.

La conclusión canónica es deliberadamente conservadora: **no había una literatura jugable que rescatar; había sistemas vecinos que deben seguir siendo vecinos**.
