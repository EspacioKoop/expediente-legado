# SUEÑO 98 · ROM literaria de #1179

SUEÑO 98 es la primera ROM propia de la vertical literaria. Su función es demostrar el
contrato completo de #1179 sin duplicar la Portátil Color 98 ni convertir el minijuego en
una fuente de conocimiento documental.

## 1. Obra fuente

La obra asociada es *La vida es sueño*, de Pedro Calderón de la Barca (1635), ya
declarada por `godot/datos/literatura_obras.json`.

La implementación **no incorpora texto de la obra**, versos, diálogos, escaneos,
ilustraciones de ediciones ni una reconstrucción de escenas. La procedencia documental
de la lectura pertenece al catálogo literario y a la interacción que genera el evento de
conocimiento.

## 2. Adaptación

La adaptación parte de motivos generales que ya estaban declarados en el vertical:
apariencia/vigilia, doble y umbral. SUEÑO 98 los expresa como tres paneles de luz/sombra
que deben componerse de forma distinta en tres rondas.

Soluciones:

1. luz · sombra · luz;
2. sombra · luz · luz;
3. luz · luz · sombra.

La relación con la obra es temática y abstracta. Resolver esas composiciones **no
equivale a leer ni comprender el texto fuente**.

## 3. Invención propia de SIGA-98

Son invención del proyecto:

- el nombre SUEÑO 98;
- la interfaz de tres paneles;
- las tres máscaras y su orden;
- los tiles y la presentación visual;
- las reglas de cursor, alternancia y confirmación;
- el handshake técnico de finalización.

No se añaden assets gráficos o sonoros de terceros.

## 4. Contrato de desbloqueo

`LiteraturaRoms.desbloqueadas()` recorre el catálogo y exige simultáneamente:

- `rom.estado == "jugable"`;
- `rom.desbloqueo == "conocimiento"`;
- `LiteraturaEventos.obra_conocida(registro, obra_id)`.

Por tanto:

- poseer un ejemplar no desbloquea la ROM;
- un insight aislado no desbloquea la ROM;
- abrir la portátil no desbloquea la ROM;
- completar una lectura significativa sí puede desbloquearla, porque esa interacción es
  la que produce el evento de conocimiento.

La Portátil Color 98 recibe únicamente el id `sueno_98` mediante
`desbloquear_rom()`. La consola y el emulador no importan clases literarias ni conocen
la razón del desbloqueo.

## 5. Objetivo y handshake

La ROM compila desde `gbc/minijuegos/sueno_98` con el cartucho estándar del proyecto.

WRAM `$C100`:

| Estado | Valor |
|---|---:|
| arranque | `0x00` |
| error | `0x00` |
| ronda 1 completa | `0x00` |
| ronda 2 completa | `0x00` |
| ronda 3 completa | `0xA5` |
| reinicio desde victoria | `0x00` |

La ROM no contiene referencias a Godot, `LiteraturaEventos`, `GestorLiteratura` ni
`Partida`.

## 6. Observer externo

`Sueno98Vigilia` reutiliza `LiteraturaRomVigilia`. El observer:

1. exige que la ROM activa tenga cabecera `SUENO98`;
2. lee `$C100` mediante la API genérica de la consola;
3. espera `0xA5`;
4. crea el evento estable
   `insight:rom:sueno_98:objetivo_completado`;
5. pide al autoload que lo registre como `CANAL_INSIGHT`.

`GestorLiteratura.registrar_evento_externo()` rechaza explícitamente
`CANAL_CONOCIMIENTO`. Así, ningún observer o minijuego puede usar este puente para
simular que la obra fue leída.

El id del evento no incluye jornada ni vuelta: el registro es **idempotente** y rejugar
o reabrir la ROM no duplica el hecho literario.

## 7. Regresión

La cobertura de #1179 comprueba:

- posesión e insight sin conocimiento no desbloquean;
- conocimiento sí desbloquea `sueno_98`;
- el evento del handshake pertenece a `insight`, no a `conocimiento`;
- el gestor rechaza conocimiento desde observers externos;
- la ROM publica `0xA5` solo tras las tres soluciones;
- la cabecera es dual CGB y reproducible;
- selector 2D/3D y catálogo siguen usando la Portátil Color 98 existente.

Refs #1175 #1176 #932 #1179.
