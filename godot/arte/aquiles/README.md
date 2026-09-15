# Aquiles — arte propio (#438)

Láminas de referencia y assets vectoriales creados para el sueño de Aquiles y su lectura espacial de la vulnerabilidad.

## Contenido

- `aquiles_atlas_referencia.jpg`: referencia compacta de silueta, estados, pistas, props, iconografía y FX.
- `aquiles_entorno_referencia.jpg`: referencia compacta de modelado, ruinas, espejos, plataforma, agua y atmósfera.
- `icono_observar.svg`: icono neutro de observación; no debe revelar por sí mismo la solución.
- `icono_reflejo.svg`: icono para interacción con espejo/reflejo.
- `icono_talon.svg`: símbolo de talón para debug, documentación o estados posteriores al descubrimiento; **no** debe mostrarse antes de deducir la vulnerabilidad.
- `impacto_inefectivo.svg`: FX 2D para reforzar invulnerabilidad sin introducir combate como sistema global.
- `onda_reflejo.svg`: onda reutilizable en charcos/espejos de agua.
- `marca_talon.svg`: marca visual del punto vulnerable una vez revelado mediante luz/reflejo/sombra.
- `estandarte_aquiles.svg`: decoración modular para ruinas oníricas.

## Integración

Las dos láminas raster son **referencias visuales**, no spritesheets runtime ni modelos 3D terminados. Sirven para bloquear silueta, materiales, props y jerarquía visual sin obligar a cortar automáticamente elementos que no comparten una cuadrícula fiable.

Los SVG sí están preparados para importarse directamente desde Godot mediante `res://arte/aquiles/` y pueden usarse en prototipos, UI diegética, decals o planos 2D dentro de la escena 3D.

Reglas de uso ligadas a #438:

1. La marca del talón permanece oculta hasta que la lectura espacial (luz, reflejo, sombra o equivalente) la revele.
2. `impacto_inefectivo.svg` comunica que la figura no responde a intentos directos, pero no implica añadir un botón global de ataque.
3. La solución debe poder leerse rodeando/observando la figura, no probando cada superficie.
4. Con `reduccion_movimiento`, usar fundidos, cambios progresivos de escala y estados estáticos equivalentes; evitar flashes o sacudidas obligatorias.
5. La resolución puede transformar la figura en papel, sal, fichas o sellos, pero estos assets no introducen hechos nuevos de expedientes.

## Origen y licencia

Obra original creada específicamente para este repositorio el 15-09-2026 a partir de la dirección visual del issue #438. Las dos láminas de referencia proceden de generación visual de OpenAI aprobada en la conversación de trabajo del issue; se almacenan aquí en versión raster optimizada para revisión. Los SVG son reinterpretaciones vectoriales propias realizadas para integración directa en Godot.

No se han incorporado deliberadamente logotipos, personajes ni assets de terceros. La iconografía y la ornamentación son ficticias y no reproducen una adaptación moderna concreta de Aquiles.

Se distribuyen bajo la misma licencia del repositorio (GPL-2.0).
