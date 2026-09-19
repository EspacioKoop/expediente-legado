# Evidencia de props utilizables · #680

Este gate fija una revisión reproducible de los dos props del primer vertical de
#680 dentro del recorrido real de `dia.tscn`. No crea una escena de showcase:
usa la casa, el inventario y las consecuencias domésticas que ya consume el
juego.

El workflow **Evidencia props 680** genera cinco capturas sin HUD:

1. `pickups_casa.png`: palanca + linterna junto a `AlmacenamientoCasa`;
2. `persiana_atascada.png`: consecuencia real `casa_persiana_atascada`;
3. `persiana_reparada.png`: mismo encuadre después de usar `palanca_kkryy`;
4. `luz_reducida_sin_linterna.png`: bombilla fundida sin herramienta carried;
5. `luz_reducida_con_linterna.png`: mismo estado con `linterna_kkryy` en carried.

Las PNG se acompañan de `manifest.json`, con hashes y coste incremental de la
representación de los props.

## Estado provisional y estado final

Mientras no estén materializados `Crowbar.glb` y `Flashlight.glb`, las
capturas de pickup muestran los proxies procedurales fusionados en #1067/#1069.
Eso sirve para revisar ubicación, escala jugable, legibilidad de interacción y
antes/después de los usos reales, pero **es provisional** y no sustituye la
aceptación visual de las mallas Kkryy.

El workflow escucha cambios bajo
`godot/assets/modelos/street_furniture/**` y `godot/assets/procedencia.json`.
Cuando los GLB entren mediante el materializador de #1064 y **Git LFS** real, la
misma evidencia se volverá a generar sin cambiar cámaras, estado de partida ni
criterios.

## Presupuesto de coste

El gate mide únicamente el coste añadido por los dos props, no toda la casa:

- máximo **2.000 triángulos combinados**;
- máximo 12 `MeshInstance3D`;
- máximo 16 superficies de malla;
- máximo una luz dinámica de #680;
- la luz portátil no puede proyectar sombras.

El límite geométrico está deliberadamente por encima de una pareja comparable ya
auditada dentro del propio proyecto: el `crowbar` + `flashlight` de Chill
Vibes Art Jam 4 suman **972 triángulos** (240 + 732). También queda por debajo
del presupuesto de 3.000 triángulos que la regresión de mobiliario urbano usa
para un lote de cinco piezas. Es una barrera de regresión razonable, no una
afirmación de equivalencia entre packs ni una excusa para sustituir los modelos
Kkryy.

El presupuesto **no certifica FPS** en hardware objetivo. Sirve para impedir que
la sustitución de dos props pequeños por sus GLB reales multiplique
silenciosamente geometría, superficies o luces. Benchmark CC0 y el playtest
siguen siendo las fuentes de evidencia para coste global.

## Qué debe revisar una persona

Las capturas hacen comparables los estados, pero **no sustituyen la revisión humana** final. Al entrar los GLB reales hay que comprobar:

- que palanca y linterna se reconocen desde la cámara normal sin dominar la casa;
- que la escala sigue siendo creíble junto al almacenamiento;
- que la persiana reparada se entiende como un cambio del entorno;
- que el haz de la linterna mejora lectura durante `casa_luz_reducida` sin lavar
  toda la escena;
- que materiales SIGA-98 no destruyen textura, silueta o lectura del asset;
- que el `manifest.json` permanece dentro del presupuesto.

Hasta que existan los binarios Kkryy con procedencia/hash y las capturas se
regeneren sobre ellos, este gate cierra la **evidencia funcional/provisional**,
no el cierre material final de #680.
