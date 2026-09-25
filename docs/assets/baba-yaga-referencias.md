# Baba Yaga — referencias culturales para #652

Este corte documenta fuentes **antes de cerrar arte o iconografía**. El prototipo usa geometría, materiales y señalética procedural propia; no copia ilustraciones, diseños audiovisuales ni adaptaciones modernas.

## Alcance cultural

El issue habla de folclore eslavo, pero este primer vertical toma como base **fuentes rusas de cuento tradicional y estudios sobre Baba Yaga**. Este corte no se presenta como tradición pan-eslava uniforme ni mezcla automáticamente variantes rusas, ucranianas, bielorrusas, polacas u otras.

La mecánica de arquitectura móvil es una traducción jugable de SIGA-98. No pretende reconstruir una práctica ritual ni afirmar que exista una versión única del personaje.

## Fuentes consultadas

### Estudios y recopilaciones

- **Sibelan Forrester (ed./trad.), _Baba Yaga: The Wild Witch of the East in Russian Fairy Tales_**, University Press of Mississippi, 2013: https://www.upress.state.ms.us/Books/B/Baba-Yaga
- Registro académico del mismo volumen en **JSTOR**, que describe la selección de cuentos procedentes de Aleksandr Afanas'ev e Ivan Khudiakov y destaca el carácter ambiguo de Baba Yaga: https://www.jstor.org/stable/j.ctt24hv8d
- **Arthur Ransome, _Old Peter's Russian Tales_** (1916), versión histórica en dominio público: https://www.sacred-texts.com/neu/oprt/oprt08.htm
- **Verra Xenophontovna Kalamatiano de Blumenthal, _Folk Tales From the Russian_** (1903), colección histórica en dominio público con un cuento de Baba Yaga: https://sacred-texts.com/neu/ftr/chap06.htm

Ransome y Blumenthal se usan como testimonios históricos de recepción/traducción, no como sustituto de una edición crítica ni como autoridad para homogeneizar variantes.

## Motivos que sí usa el prototipo

1. **cabaña en el bosque** asociada a Baba Yaga;
2. **cabaña sobre patas de ave/gallina** y capacidad de orientarse o desplazarse en algunas versiones;
3. **bosque y umbral doméstico** como espacio liminal de llegada, prueba y orientación;
4. variación de función narrativa: Baba Yaga puede ser peligrosa, interrogadora o proporcionar ayuda/información según el cuento, por lo que no se reduce a boss;
5. la cabaña como lugar espacialmente extraño, que el juego exagera hasta un interior mayor que el volumen exterior.

El sistema de árbol, valla y archivador que cambian cuando salen de campo o al cruzar un umbral es **invención jugable de SIGA-98**. Las marcas persistentes con cinta/post-it también son una herramienta de orientación propia del juego.

## Qué se evita fijar como hecho

- no se adopta una apariencia moderna concreta como diseño canónico;
- no se afirma una genealogía religiosa o una identidad de "diosa" como hecho consensuado;
- no se mezclan cuentos y regiones como si formaran una biografía única;
- no se convierte el personaje en "bruja malvada genérica", comerciante o boss obligatorio;
- no se usan cráneos, canibalismo u otros motivos intensos como decoración automática: requerirían una decisión tonal específica;
- no se copian frases, ilustraciones, música, cine, videojuegos o diseños modernos;
- no se exige al jugador conocer fórmulas folclóricas para resolver el espacio.

## Traducción al vertical SIGA-98

- **bosque ↔ oficina**: tabiques pasan a ser troncos y una valla se construye con listones/archivo;
- **hitos ↔ archivadores**: un archivador conserva una cinta visible y cambia solo fuera de campo;
- **cabaña ↔ mobiliario industrial**: las patas se reinterpretan mediante soportes metálicos de oficina;
- **interior imposible**: el suelo interior supera el volumen exterior sin convertirlo en truco de combate;
- **marcas persistentes**: cintas/post-its quedan donde el jugador los colocó aunque el objeto se mueva;
- **cabaña-ancla**: puede cambiar entre posiciones declaradas al cruzar el umbral, pero nunca desaparece;
- **retorno seguro**: existe una salida estable independiente de la reconfiguración.

## Accesibilidad y seguridad espacial

- ningún cambio depende de temporizadores o RNG;
- la misma secuencia de eventos produce exactamente las mismas posiciones;
- un objeto que usa la regla "fuera de campo" no cambia mientras siga visible;
- la cabaña y el retorno permanecen siempre presentes;
- la lógica nunca desplaza al jugador ni exige giros rápidos de cámara;
- con `reduccion_movimiento`, la transición se expresa por corte/fundido y la geometría no necesita interpolarse;
- las marcas y la solución son idénticas con o sin reducción de movimiento.

## Pase de lectura espacial

El vertical incorpora ahora feedback **diegético** para que la regla pueda deducirse desde la escena y no desde HUD o texto externo:

- la cinta conserva el punto de origen y, al volver a consultarla después de un cambio, materializa un rastro corto hasta la posición actual del objeto;
- origen y destino usan geometrías distintas, de modo que la lectura no depende solo del color;
- el rastro se invalida en cuanto vuelve a cambiar la arquitectura, evitando presentar una comparación obsoleta como vigente;
- el retorno seguro mantiene su plataforma y añade una baliza con dos montantes y dintel, visible como ancla estable aunque cambie el bosque;
- la última comparación forma parte del estado reproducible y se rematerializa al restaurar una partida;
- `reduccion_movimiento` conserva exactamente esta lectura sin animar geometría ni mover la cámara.

## Pase ambiental procedural

Para avanzar el acabado sin cerrar todavía una iconografía figurativa de Baba Yaga, la escena incorpora una capa propia de geometría procedural:

- un **bosque de fondo** en el que troncos y columnas de oficina comparten silueta;
- paneles de **techo de oficina invertido** sobre el bosque, con luminarias lineales suspendidas;
- un **plano administrativo plegado** convertido en volumen del paisaje, reforzando la idea de bosque como documento imposible;
- una **cocina doméstica SIGA-98** dentro del interior mayor-por-dentro de la cabaña: encimera, muebles, alacena, cocina eléctrica y mesa;
- todos estos elementos son `MeshInstance3D` visuales y no añaden `CollisionShape3D`, de modo que el pase de arte no cambia rutas, reglas ni riesgo de softlock;
- no se introduce figura, rostro, vestuario ni anatomía de Baba Yaga: esa decisión sigue detrás del gate cultural y artístico.

Este pase trabaja únicamente con la hibridación propia del juego (bosque, oficina, archivo y vivienda) y evita convertir una adaptación moderna concreta en referencia canónica.

## Escalada ambiental por fases

El acabado de fondo deja de ser una decoración fija y responde a la misma `fase_umbral` que gobierna la arquitectura principal:

- el **techo de oficina invertido** cambia de posición e inclinación entre cuatro estados declarados;
- el **plano administrativo plegado** se desplaza y rota para reforzar la lectura de paisaje-documento;
- el **bosque de fondo** cambia levemente de encuadre, manteniéndose siempre fuera de la ruta jugable;
- la fase ambiental se deriva únicamente de `fase_umbral`, sin RNG ni temporizadores;
- restaurar una partida recompone exactamente la misma transformación;
- `RetornoSeguro` no se desplaza y la capa sigue sin añadir colisiones.

Las transformaciones representan una escalada espacial propia de SIGA-98; no se presentan como motivos folclóricos documentados.

## Tránsito de horizonte de la cabaña

Al cruzar el umbral, la cabaña deja de saltar visualmente entre anclas y usa un trayecto declarado de tres puntos: **origen → horizonte elevado → destino**.

- cada fase tiene un punto de horizonte fijo y reproducible;
- el tramo de horizonte queda elevado y fuera de la zona jugable para no barrer al jugador;
- la cabaña sigue siendo geometría sin colisión, por lo que el tránsito no altera navegación ni softlocks;
- el modo normal usa dos tramos breves con `Tween.TRANS_SINE` y no mueve la cámara;
- con `reduccion_movimiento`, no hay interpolación: se aplica un corte/fundido y la cabaña aparece directamente en el nuevo ancla;
- el resultado del evento expone origen, horizonte, destino, duración y flags de seguridad, facilitando pruebas y futuras integraciones.

Este tránsito es una solución visual propia de SIGA-98 para la escalada onírica; no se presenta como motivo folclórico documentado.

## Interior variable de la cabaña

La puerta conserva un **marco estable**, pero el contenido que enmarca cambia de forma determinista con la misma fase espacial que mueve la cabaña:

- `CocinaSIGA98`: vivienda doméstica imposible, mayor por dentro que por fuera;
- `ArchivoInvertido`: archivadores y mesa invertida convierten el interior en una oficina suspendida;
- `BosqueInterior`: troncos aparecen dentro de la vivienda bajo un falso techo exterior;
- `SalaUmbral`: una sucesión de marcos repite la idea de puerta dentro de puerta sin teletransporte ni azar.

Solo un estado interior está visible a la vez. El cambio reutiliza la fase del umbral, se serializa indirectamente mediante `fase_umbral` y se reconstruye al restaurar partida. El marco, el retorno seguro y la lógica de navegación permanecen estables.

Este recurso sigue siendo una invención espacial de SIGA-98 y no se presenta como motivo folclórico documentado.

### Gate humano antes de cerrar #652

El código puede comprobar reglas, persistencia y ausencia de softlock, pero no sustituye un pase humano. Antes de cerrar el issue conviene registrar una sesión breve con estos puntos:

- [ ] una persona que no conozca la implementación identifica qué elemento cambió usando la cinta;
- [ ] distingue con claridad origen, posición actual y retorno seguro sin explicación verbal;
- [ ] entiende tras dos cruces que árbol/valla/cabaña responden al umbral y que el archivador usa otra regla;
- [ ] no confunde la cabaña con un enemigo o encuentro de combate;
- [ ] la lectura sigue siendo clara con `reduccion_movimiento`;
- [ ] revisión humana confirma que iconografía, texto y assets no convierten una variante rusa concreta en supuesto canon pan-eslavo.

## Estado del corte

La dirección artística figurativa final y el gate humano siguen pendientes. Antes de incorporar ilustraciones históricas, diseños figurativos de Baba Yaga o cualquier asset externo deberá revisarse licencia/procedencia y registrarse, cuando corresponda, en `godot/assets/procedencia.json` con URL, derechos/licencia y `sha256`.
