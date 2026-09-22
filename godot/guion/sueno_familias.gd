## Familias espaciales no ortogonales para el sueño (#279).
##
## Este catálogo no decide qué noche sale cada familia ni qué contenido contiene.
## Solo fija tres siluetas reutilizables que pueden recibir después figuras,
## frases, objetos y objetivos sin volver a caer en cajas/pasillos ortogonales.
class_name SuenoFamilias
extends RefCounted

const CONVERGENTE := "convergente"
const ANULAR := "anular"
const FRAGMENTADA := "fragmentada"

## Los PackedVector2Array se construyen en tiempo de carga y Godot 4.7 no los
## acepta dentro de una expresión `const`. El catálogo sigue siendo de solo
## lectura por API; se expone siempre mediante copia profunda en `de()`.
static var _familias := {
	CONVERGENTE:
	{
		"contorno":
		PackedVector2Array(
			[
				Vector2(-15, -18),
				Vector2(15, -18),
				Vector2(8, -3),
				Vector2(11, 16),
				Vector2(-11, 16),
				Vector2(-8, -3),
			]
		),
		"altura": 3.2,
		"entrada": Vector3(0, 0, -14),
		"anclas": [Vector3(0, 0, 10), Vector3(-6, 0, 2), Vector3(6, 0, 2)],
	},
	ANULAR:
	# Anillo abierto en C y deliberadamente irregular. Sigue cabiendo dentro
	# de la envolvente histórica de `patio`: la planta de celdas conserva
	# timing/mapa y esta silueta sustituye solo la arquitectura visible/física.
	# El recorte central queda fuera de suelo, techo y colisión; la abertura
	{
		# lateral permite recorrerlo andando sin salto ni navegación especial.
		"contorno":
		PackedVector2Array(
			[
				Vector2(-18, -12),
				Vector2(-14, -18),
				Vector2(12, -18),
				Vector2(12, -10),
				Vector2(2, -10),
				Vector2(0, -8),
				Vector2(-8, -8),
				Vector2(-8, 8),
				Vector2(0, 8),
				Vector2(2, 10),
				Vector2(12, 10),
				Vector2(12, 18),
				Vector2(-14, 18),
				Vector2(-18, 12),
				Vector2(-18, 4),
				Vector2(-18, -4),
			]
		),
		"altura": 3.4,
		"entrada": Vector3(-17, 0, 0),
		"anclas":
		[
			Vector3(-15, 0, -14),
			Vector3(8, 0, -14),
			Vector3(8, 0, 14),
			Vector3(-15, 0, 14),
		],
	},
	FRAGMENTADA:
	# Sala irregular atravesada por planos parciales: no encierra al jugador ni
	# exige saltar, pero rompe la lectura de "una caja rara" con diagonales y
	# alturas distintas. Los extremos de cada tabique quedan siempre abiertos.
	{
		"contorno":
		PackedVector2Array(
			[
				Vector2(-16, -15),
				Vector2(4, -17),
				Vector2(13, -9),
				Vector2(10, 3),
				Vector2(16, 12),
				Vector2(1, 17),
				Vector2(-13, 12),
				Vector2(-9, 1),
			]
		),
		"tabiques":
		[
			{
				"desde": Vector2(-7, -3),
				"hasta": Vector2(-2, -5),
				"altura_desde": 1.1,
				"altura_hasta": 2.3,
			},
			{
				"desde": Vector2(2, 1),
				"hasta": Vector2(7, 3),
				"altura_desde": 2.4,
				"altura_hasta": 1.2,
			},
			{
				"desde": Vector2(0, 11),
				"hasta": Vector2(5, 13),
				"altura_desde": 1.5,
				"altura_hasta": 2.6,
			},
		],
		"altura": 3.0,
		"entrada": Vector3(-10, 0, -10),
		"anclas": [Vector3(6, 0, -8), Vector3(-3, 0, 7), Vector3(9, 0, 8)],
	},
}


static func ids() -> Array:
	var resultado := _familias.keys()
	resultado.sort()
	return resultado


static func de(id: String) -> Dictionary:
	return _familias.get(id, {}).duplicate(true)


static func malla(id: String) -> ArrayMesh:
	var familia := de(id)
	if familia.is_empty():
		return ArrayMesh.new()
	return SuenoGeometria.malla_sala(
		familia["contorno"], float(familia.get("altura", 3.2)), familia.get("tabiques", [])
	)


## Materializa una familia como arquitectura estática completa.
##
## El catálogo sigue sin decidir cuándo aparece: simplemente entrega al runtime
## una malla y una colisión que comparten exactamente el mismo contorno. Esto
## permite integrar una familia en una noche real sin volver a una colisión de
## cajas distinta de lo que ve el jugador.
static func cuerpo(id: String) -> StaticBody3D:
	var familia := de(id)
	if familia.is_empty():
		return StaticBody3D.new()
	return SuenoGeometria.cuerpo_sala(
		familia["contorno"], float(familia.get("altura", 3.2)), familia.get("tabiques", [])
	)


static func valida(id: String) -> bool:
	var familia := de(id)
	if familia.is_empty():
		return false
	var contorno: PackedVector2Array = familia.get("contorno", PackedVector2Array())
	var tabiques: Array = familia.get("tabiques", [])
	return (
		SuenoGeometria.contorno_valido(contorno)
		and SuenoGeometria.tiene_arista_diagonal(contorno)
		and (id != FRAGMENTADA or not tabiques.is_empty())
	)
