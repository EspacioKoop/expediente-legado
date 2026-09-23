# SUEÑO 98

Micro-ROM literaria original para #1179, compatible con Game Boy / Game Boy Color.

## Obra fuente

El desbloqueo se vincula a *La vida es sueño* de Pedro Calderón de la Barca
(1635), obra del Siglo de Oro. El cartucho no incorpora versos, diálogos,
ilustraciones editoriales ni una edición concreta. El catálogo de SIGA-98
conserva por separado la procedencia documental de la lectura.

## Adaptación

La adaptación toma como punto de partida motivos generales ya declarados por la
vertical literaria: **apariencia/vigilia, doble y umbral**. Los convierte en un
puzle visual abstracto de tres paneles. En cada ronda el jugador alterna qué
paneles muestran luz y confirma una composición distinta.

Las tres soluciones son deterministas:

1. luz · sombra · luz;
2. sombra · luz · luz;
3. luz · luz · sombra.

No son citas, escenas de la obra ni pretenden representar literalmente su trama.

## Invención propia del juego

Son invención de SIGA-98 el nombre SUEÑO 98, la interfaz de tres paneles, las
tres máscaras anteriores, el orden de rondas, los tiles y el contrato de
finalización. No se usa material gráfico o sonoro de terceros.

## Desbloqueo y handshake

El cartucho solo aparece como ROM propia cuando LiteraturaEventos contiene
**conocimiento** de `vida_es_sueno_1635`. Poseer un libro, tener otro insight o
arrancar el emulador no satisface esa condición.

WRAM `$C100`:

- arranque: `0x00`;
- partida parcial o confirmación errónea: `0x00`;
- rondas 1 o 2 completas: `0x00`;
- tercera composición completa: `0xA5`;
- reinicio desde victoria: `0x00`.

La ROM no conoce Godot, LiteraturaEventos ni Partida. `Sueno98Vigilia` observa
el byte desde fuera y registra un único insight idempotente de adaptación
completada. Ese evento no sustituye el conocimiento obtenido leyendo la obra.
