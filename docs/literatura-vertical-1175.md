# Vertical literaria transversal · #1175 / #1176

Este corte fija una base propia para literatura. No reutiliza ReligionEventos, estado
ideológico, mitologías ni Tarot como sustituto: los consumidores podrán cruzar
información más adelante, pero la fuente de verdad literaria es independiente.

## Contrato

LiteraturaEventos mantiene cuatro canales:

- **conocimiento**: una interacción significativa permitió completar/comprender una obra;
- **posesión**: existe un ejemplar bajo control del jugador, sin inferir lectura;
- **insight**: una lectura o conversación produjo una referencia utilizable;
- **ritual**: el jugador empleó deliberadamente una referencia literaria en otra mecánica.

La frontera central es **conocimiento ≠ posesión**. Abrir un libro tampoco equivale a
conocerlo. Los eventos tienen id global e idempotente para que relecturas, reentradas de
escena o consumidores repetidos no dupliquen progreso ni reclasifiquen un mismo hecho.

No escribe en `Partida`, no concede dinero, pistas ni progreso de SIGA y no aplica
efectos de combate por sí mismo.

## Catálogo de obras

`godot/datos/literatura_obras.json` es la fuente data-driven del prototipo. Cada obra
declara como mínimo:

- id, título, autor, época y géneros;
- procedencia documental dentro del mundo;
- umbral de lectura e id de insight;
- propuesta de ROM: id, estado, condición de desbloqueo y necesidad de handshake;
- efecto de juego **declarativo**, con uno o más consumidores explícitos.

El primer fixture es *La vida es sueño* (Calderón, 1635). No se incorpora texto de la
obra: solo metadatos y una traducción jugable original. `SUENO 98` queda marcada como
**propuesta**, no como ROM existente.

## Prototipo de lectura

`LiteraturaLectura.registrar_interaccion()` recibe obra, fuente documental, jornada y
progreso normalizado.

Secuencia del primer vertical:

    abrir / hojear -> no registra
    completar umbral -> conocimiento + insight
    releer -> no duplica
    leer -> nunca crea posesión

El insight transporta el descriptor `efecto_juego`, pero no lo ejecuta. Esto mantiene
la autoridad en el sistema consumidor y evita que el catálogo se convierta en un
segundo motor de combate.

## Integración con sistemas existentes

**Tarot/Prometeo.** Puede consultar insights literarios para ofrecer variantes de diálogo,
presentación o resolución. No debe escribir elecciones políticas ni tratar una obra como
un eje ideológico.

**momentum.** Un futuro ritual literario puede producir una modificación temporal y
acotada de momentum si el sistema de conflicto la acepta. El evento literario solo
demuestra que el ritual ocurrió; no toca el contador directamente.

**arquetipos.** Géneros, motivos o insights pueden modular presentación, afinidades
narrativas o selecciones de contenido. No convierten al personaje jugador en un
arquetipo permanente.

**sueño / simbolismo.** Un consumidor onírico puede reutilizar motivos ya conocidos sin
inventar hechos de expedientes. La selección del sueño sigue perteneciendo al sistema
onírico.

**ROMs.** La futura ROM literaria debe seguir el patrón de handshake externo ya probado
por #932: arrancar o poseer el cartucho no cuenta. Para esta vertical, además, el
desbloqueo se apoya en conocimiento literario explícito y el observer deberá registrar
su propio hecho sin sustituir la lectura documental.

## Pruebas

`godot/pruebas/pruebas_literatura_1175.gd` comprueba catálogo, lectura parcial,
idempotencia, procedencia y separación conocimiento/posesión.

`scripts/test_literatura_1175.py` entra en el descubrimiento normal
`python3 -m unittest discover -s scripts -p 'test_*.py'` y ejecuta además el contrato
Godot en headless.

## Siguientes cortes

1. Biblioteca o tertulia física con una interacción de lectura real que produzca el
   progreso normalizado.
2. Ritual de cita con buff temporal administrado por un consumidor de conflicto.
3. `SUENO 98` u otra ROM propia con objetivo significativo + handshake, sin regalar
   conocimiento al arrancar.
4. Consumidor onírico que use motivos conocidos.
5. Trayectoria/epílogo basada en una colección de hechos, no en un alignment literario.

Refs #1175 #1176 #919 #930 #932.
