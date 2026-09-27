# Religión, conflicto y ritual · criterio de representación y playtest (#936)

Este documento completa la parte verificable que faltaba en #936 sin convertir una
tradición religiosa en clase de combate, afinidad elemental o bonus pasivo.

## Estado técnico

La implementación actual ya tiene dos reglas genéricas:

- `no_iniciar_agresion`: compromiso unilateral que obliga a ceder la iniciativa;
- `tregua_mutua`: ventana bilateral temporal sin agresión, con reposicionamiento.

Ambas salen de `ReligionEventos` y solo se activan por una práctica o convicción
declarada en el contexto correcto. La tradición concreta es metadato documental:
no participa en la resolución de potencia, daño, resistencia ni targeting.

## Caso concreto documentado: Testimonio de Paz cuáquero

Como referencia para una futura escena autorada se documenta el **Testimonio de
Paz de la Sociedad Religiosa de los Amigos (cuáqueros)**.

Fuentes primarias/institucionales consultadas:

- Quakers in Britain, “Peace”:
  https://www.quaker.org.uk/resources/peace-and-engagement/peace
- *Quaker faith & practice*, capítulo 24, “Our peace testimony”:
  https://qfp.quaker.org.uk/chapter/24/

Las fuentes describen una tradición histórica de oposición a la guerra y la
violencia, pero también dejan claro que la forma práctica de vivir ese testimonio
no se reduce a una respuesta idéntica para todas las personas cuáqueras.

### Traducción de diseño permitida

Un **personaje concreto**, en una escena concreta, puede haber expresado o
practicado públicamente un compromiso de no iniciar violencia. Si ese hecho está
registrado en `ReligionEventos`, #936 puede traducirlo a
`REGLA_NO_INICIAR`.

La mecánica no afirma:

- que toda persona cuáquera actúe igual;
- que “ser cuáquero” conceda una habilidad;
- que el juego pueda deducir la convicción por un objeto, nombre o comunidad;
- que el rival conozca una práctica privada;
- que un testimonio religioso pruebe hechos del expediente.

La misma regla debe seguir funcionando con `tradicion=""` o con otro contexto
documentado: la tradición explica el **origen narrativo** del compromiso, no su
potencia mecánica.

### Forma de autorado propuesta

Ejemplo de evento, deliberadamente no global:

```gdscript
ReligionEventos.crear_evento(
    "declaracion-paz-personaje-x",
    ReligionEventos.CANAL_CONVICCION,
    "dialogo:personaje-x",
    "juicio:reclamante-y",
    0,
    "sociedad_religiosa_amigos",
    ["publico", "compromiso_personal"],
    [ReligionConflicto.REGLA_NO_INICIAR],
    true,
    ["reclamante-y"],
    {"declaracion": ReligionEventos.DECLARACION_AFIRMACION},
)
```

No se añade este fixture a contenido jugable hasta que exista la escena y el
personaje que justifiquen el hecho. El ejemplo fija el límite de representación,
no crea un NPC-portavoz.

## Playtest pendiente

La regresión automática demuestra que las reglas funcionan; no demuestra que una
persona entienda su coste o utilidad al jugar.

Usar:

```bash
python3 scripts/registrar_playtest_936.py \
  --salida docs/playtests/playtest-936.md
```

El registro exige tres pases:

1. combate base sin compromiso;
2. `no_iniciar_agresion`;
3. `tregua_mutua`.

Para los dos compromisos se registra explícitamente:

- si el HUD permitió entender **por qué** no se podía agredir;
- si el jugador percibió un **coste/limitación real**;
- si la regla cambió una **decisión táctica**;
- si la utilidad fue contextual y no un bonus permanente;
- evidencia reproducible (captura, vídeo o log).

El script no decide que una mecánica “es buena” a partir de números. Solo marca
si el registro humano está completo.

## Criterio de cierre de #936

Con la representación anterior documentada, queda pendiente únicamente ejecutar
y adjuntar el playtest humano completo. Hasta entonces #936 debe seguir abierto.
