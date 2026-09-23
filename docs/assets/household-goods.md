# Low poly household goods: casa por zonas (#227)

Fuente: **Low poly household goods**, de samusaa (publicado por mastjie).
Página: https://mastjie.itch.io/low-poly-household-goods
Licencia: **CC0 1.0 Universal** (`license.txt` del ZIP).
Descarga: `household_goods.zip`, `sha256` `a14d1d686c7609bdbef2e07676c179cc89f4dc664a7d3af60e88874f467d36ef`.

## Selección

Entran 13 GLB originales del directorio `gltf/`, sin modificar, en `godot/assets/modelos/household_goods/`. Cada uno lleva su paleta embebida; Godot la extrae como `*_basic-pallete.png`, y esos PNG también tienen ficha en `procedencia.json`.

| Zona | Modelos |
|---|---|
| Estar | `2_seat_sofa_01` (visual del `SofaCasa` existente), `tv_cabinet_01`, `coffee_table_01` |
| Dormitorio | `wardrobe_01` |
| Comedor | `dine_table_01`, `chair_01` ×3 |
| Cocina | `stove_01`, `washing_machine_01`, `microwave_01`, `toaster_01`, `kettle_01` |
| Entrada | `cupboard_01`, `table_lamp_01` |

Quedan fuera por no encajar en una casa de 1998: `tv_01` (pantalla plana), `laptop_01`, `computer_01` (torre y monitor plano), `air_conditioner_01` (split) y `fridge_01` (frigorífico americano negro). También quedan fuera `bed_01`, `bookshelf_01`, `desk_01`, `ceiling_fan_01`, `pendaflour_lamp_01`, `rice_cooker_01` y `blender_01`, porque la casa ya tiene esas funciones cubiertas o no aportan lectura.

## Distribución

La casa (8 × 7 m, entrada en `(0, 0, 2.5)`) se ordena en zonas que se leen desde la puerta:

- **Dormitorio, fondo izquierda:** cama bajo la ventana (misma ancla de la salida a sueño), mesita de noche con la portátil junto al cabecero y armario en el muro izquierdo.
- **Estar, delante izquierda:** mueble de TV con el televisor y la consola de sobremesa encima, mesa baja y sofá de cara a la tele. Detrás del sofá quedan la lámpara de pie, la estantería y una silla de lectura.
- **Cocina-comedor, derecha:** encimera con fregadero, nevera, microondas, tostadora y hervidor. El horno queda al otro lado del hueco del cuenco del gato y la lavadora junto a la nevera. La mesa de comedor tiene tres sillas, y el cigarro de la jornada sigue sobre ella.
- **Entrada:** aparador con lámpara.

Cambios respecto a la versión anterior:

- desaparece el bulto-mesa suelto contra el fondo;
- la estantería CC0 del dressing ya no queda dentro de la encimera;
- las cajas domésticas salen del hueco del armario;
- la papelera se va a la esquina de la cocina;
- el televisor sube a su mueble.

`CasaHogarCC0` monta las piezas desde `CasaUtileria.montar`. Cada pieza usa `AssetCc0.sustituir`, que aplica el shader PSX común conservando la paleta del pack, y lleva una única `BoxShape3D` a la medida real si es mueble de suelo. Si falta un GLB, esa pieza no aparece y el sofá mantiene su versión procedural.

## Reutilización en el sueño

#227 no termina en vestir la vivienda. El armario `wardrobe_01` es el primer vertical que conecta el pack con #87: al examinarlo en casa, `ObjetosOniricos` conserva únicamente el ID canónico `armario_hogar` de la jornada. Si el sueño lo selecciona, `SuenoUtileria` instancia una anomalía que vuelve a cargar **el mismo GLB CC0** mediante `AssetCc0`, conserva su paleta dentro del shader PSX y deforma escala/rotación sobre esa forma reconocible.

La copia onírica no añade otro binario, no duplica procedencia, no crea inventario ni cambia objetivos. Sigue el contrato de #87: sin haber examinado el original durante el día, esa anomalía doméstica no aparece. El límite general de tres anomalías por sala permanece intacto.

## Pruebas

`godot/pruebas/pruebas_casa_hogar_cc0.gd` (desde `scripts/test_household_goods_cc0.py`) monta la casa real y comprueba:

- todas las piezas cargadas y dentro de la casa;
- shader PSX con textura;
- colisiones alineadas y apoyadas en el suelo;
- sin solapes entre muebles;
- entrada, paso a la cama y pie de la cama libres;
- cigarro sobre el tablero;
- televisor sobre su mueble;
- sofá mirando a la tele;
- horno y lavadora contra el muro de la cocina;
- presupuesto de triángulos.

Capturas: `docs/capturas/casa-hogar-227-antes.png`, `docs/capturas/casa-hogar-227-entrada.png`, `docs/capturas/casa-hogar-227-estar.png` y `docs/capturas/casa-hogar-227-cocina.png`.


## Gate visual reproducible

El workflow **Evidencia hogar 227** convierte el pendiente visual en un artifact del
mismo build: cuatro PNG sin HUD —entrada, estar, dormitorio y cocina-comedor— y
un `manifest.json` que inventaría las 15 instancias domésticas que materializan
los 13 GLB seleccionados. Para cada objeto registra en qué encuadres su centro
queda dentro del frustum de la cámara jugable.

El contrato automatizado comprueba montaje, presencia de `AssetCc0`, cobertura
de las cuatro zonas y capturas distintas. Deliberadamente **no autoaprueba**
escala, clipping ni legibilidad: esos criterios siguen siendo un pase humano
sobre el artifact. El armario deformado de #967 conserva además su validación
propia casa→sueño y debe revisarse visualmente antes de cerrar #227.

Guía del pase: `docs/evidencias/hogar-227/README.md`.
