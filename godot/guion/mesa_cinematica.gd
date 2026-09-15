## La mesa del archivo como decorado de cinemática (#395).
##
## El sello y la carta ocurren dentro del visor, que es una pantalla sin sala
## detrás. En vez de dibujar rectángulos, ruedan sobre una mesa en 3D hecha con
## los mismos muebles, texturas y paleta que el puesto de la oficina. Es DATOS
## en el formato de `Espacio3D`: cada cinemática añade encima sus piezas.
class_name MesaCinematica
extends RefCounted

## Altura del tablero: todo lo que se apoya en la mesa parte de aquí.
const TABLERO := 0.75


static func base() -> Dictionary:
	var oficina := EspaciosCatalogo.OFICINA
	return {
		"suelo": Vector2(4, 4),
		"color_suelo": oficina["color_suelo"],
		"color_muro": oficina["color_muro"],
		"color_techo": oficina["color_techo"],
		"textura_suelo": oficina["textura_suelo"],
		"textura_muro": oficina["textura_muro"],
		"textura_techo": oficina["textura_techo"],
		"bultos":
		[
			{"pos": Vector3(0, 0.37, 0), "tam": Vector3(2.0, 0.75, 1.0), "modelo": "desk"},
			{
				"pos": Vector3(-0.65, 0.98, -0.25),
				"tam": Vector3(0.5, 0.45, 0.4),
				"color": Color(0.52, 0.54, 0.50),
				"modelo": "computerScreen"
			},
			{
				"pos": Vector3(0.75, 0.83, -0.3),
				"tam": Vector3(0.32, 0.16, 0.24),
				"color": Color(0.80, 0.78, 0.70)
			},
		],
		"luces":
		[
			{"pos": Vector3(0.3, 2.2, 0.8), "color": Color(0.95, 0.92, 0.82), "energia": 1.8},
		],
	}


## Una pieza plana apoyada en el tablero (o a [param altura] sobre él).
static func pieza(
	x: float, z: float, tam: Vector3, color: Color, altura: float = 0.0
) -> Dictionary:
	return {"pos": Vector3(x, TABLERO + altura + tam.y / 2.0, z), "tam": tam, "color": color}


## La mesa con piezas encima. Copia: la base es compartida entre planos.
static func con(piezas: Array, luces: Array = []) -> Dictionary:
	var decorado := base()
	decorado["bultos"].append_array(piezas)
	decorado["luces"].append_array(luces)
	return decorado
