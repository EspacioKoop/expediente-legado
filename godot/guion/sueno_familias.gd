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
	{
		# Anillo abierto por una hendidura lateral. Es un único polígono cóncavo,
		# no dos mallas superpuestas: el gran recorte central queda realmente fuera
		# de suelo/techo/colisión y la abertura permite entrar andando sin salto.
		# Esto mantiene la misma ruta `malla_sala()` que la familia convergente y
		# evita introducir una segunda representación física solo para el patio.
		"contorno":
		PackedVector2Array(
			[
				Vector2(-16, -12),
				Vector2(0, -18),
				Vector2(16, -12),
				Vector2(18, 0),
				Vector2(14, 14),
				Vector2(0, 18),
				Vector2(-14, 14),
				Vector2(-18, 2),
				Vector2(-7, 2),
				Vector2(-6, 6),
				Vector2(0, 8),
				Vector2(7, 4),
				Vector2(8, -3),
				Vector2(3, -8),
				Vector2(-5, -6),
				Vector2(-7, -2),
				Vector2(-18, -2),
			]
		),
		"altura": 3.4,
		"entrada": Vector3(-13, 0, 0),
		"anclas":
		[
			Vector3(0, 0, -13),
			Vector3(12, 0, 0),
			Vector3(0, 0, 13),
			Vector3(-10, 0, 8),
		],
	},
	FRAGMENTADA:
	{
		# Una sala principal irregular y dos islas caminables separadas visualmente.
		# No exige salto: la integración debe unirlas con pasos/rampas anchas.
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
		"fragmentos":
		[
			PackedVector2Array([Vector2(-7, -2), Vector2(-2, -4), Vector2(1, 1), Vector2(-4, 4)]),
			PackedVector2Array([Vector2(4, 6), Vector2(9, 4), Vector2(11, 9), Vector2(6, 12)]),
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
	return SuenoGeometria.malla_sala(familia["contorno"], float(familia.get("altura", 3.2)))


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
	return SuenoGeometria.cuerpo_sala(familia["contorno"], float(familia.get("altura", 3.2)))


static func valida(id: String) -> bool:
	var familia := de(id)
	if familia.is_empty():
		return false
	var contorno: PackedVector2Array = familia.get("contorno", PackedVector2Array())
	return (
		SuenoGeometria.contorno_valido(contorno) and SuenoGeometria.tiene_arista_diagonal(contorno)
	)
