# Baba Yaga — referencias culturales para #652

Este corte documenta fuentes **antes de cerrar arte o iconografía**. El prototipo usa geometría, materiales y señalética procedural propia; no copia ilustraciones, diseños audiovisuales ni adaptaciones modernas.

## Alcance cultural

El issue habla de folclore eslavo, pero este primer vertical toma como base **fuentes rusas de cuento tradicional y estudios sobre Baba Yaga**. No se presenta como tradición pan-eslava uniforme ni se mezclan automáticamente variantes rusas, ucranianas, bielorrusas, polacas u otras.

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

## Estado del corte

La dirección artística final queda pendiente. Antes de incorporar ilustraciones históricas, diseños figurativos de Baba Yaga o cualquier asset externo deberá revisarse licencia/procedencia y registrarse, cuando corresponda, en `godot/assets/procedencia.json` con URL, derechos/licencia y `sha256`.
