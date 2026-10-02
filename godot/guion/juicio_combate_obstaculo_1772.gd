## Política pura de movimiento ante obstáculos temporales de combate (#1772).
##
## No consulta SceneTree, física ni navegación. El host le entrega un obstáculo
## explícito como {activo, centro, radio}; esta capa solo decide si ir directo,
## rodear por un lado estable o esperar cuando no existe un paso seguro.
class_name JuicioCombateObstaculo1772
extends RefCounted

const MARGEN_SEGURIDAD := 0.28
const EPSILON := 0.0001


static func planear(
	posicion_rival: Vector3,
	posicion_objetivo: Vector3,
	radio_arena: float,
	obstaculo: Dictionary,
	semilla: int = 0,
) -> Dictionary:
	var destino_directo := _limitar_a_arena(posicion_objetivo, radio_arena)
	var vector_directo := destino_directo - posicion_rival
	vector_directo.y = 0.0
	if vector_directo.length() <= EPSILON:
		return _resultado("esperar", posicion_rival, Vector3.ZERO, 0, false)

	var centro_bruto: Variant = obstaculo.get("centro", Vector3.ZERO)
	var radio := maxf(0.0, float(obstaculo.get("radio", 0.0)))
	if (
		not bool(obstaculo.get("activo", false))
		or typeof(centro_bruto) != TYPE_VECTOR3
		or radio <= EPSILON
	):
		return _resultado("directo", destino_directo, vector_directo.normalized(), 0, false)

	var centro: Vector3 = centro_bruto
	var origen_2d := Vector2(posicion_rival.x, posicion_rival.z)
	var objetivo_2d := Vector2(destino_directo.x, destino_directo.z)
	var centro_2d := Vector2(centro.x, centro.z)
	var radio_seguro := radio + MARGEN_SEGURIDAD

	if objetivo_2d.distance_to(centro_2d) <= radio_seguro + EPSILON:
		return _resultado("esperar", posicion_rival, Vector3.ZERO, 0, true)
	if not segmento_bloqueado(origen_2d, objetivo_2d, centro_2d, radio_seguro):
		return _resultado("directo", destino_directo, vector_directo.normalized(), 0, false)
	if origen_2d.distance_to(centro_2d) <= radio_seguro + EPSILON:
		return _resultado("esperar", posicion_rival, Vector3.ZERO, 0, true)

	var preferido := 1 if absi(semilla) % 2 == 0 else -1
	for lado in [preferido, -preferido]:
		var tangente := _punto_tangente(origen_2d, centro_2d, radio_seguro, int(lado))
		if not bool(tangente.get("ok", false)):
			continue
		var punto: Vector2 = tangente["punto"]
		if not _dentro_arena(punto, radio_arena):
			continue
		if segmento_bloqueado(origen_2d, punto, centro_2d, radio):
			continue
		var destino := Vector3(punto.x, posicion_rival.y, punto.y)
		var direccion := destino - posicion_rival
		direccion.y = 0.0
		if direccion.length() <= EPSILON:
			continue
		return _resultado("rodear", destino, direccion.normalized(), int(lado), true)

	return _resultado("esperar", posicion_rival, Vector3.ZERO, 0, true)


static func segmento_bloqueado(
	origen: Vector2,
	destino: Vector2,
	centro: Vector2,
	radio: float,
) -> bool:
	if radio <= 0.0:
		return false
	var tramo := destino - origen
	var largo_cuadrado := tramo.length_squared()
	if largo_cuadrado <= EPSILON:
		return origen.distance_to(centro) <= radio + EPSILON
	var progreso := clampf((centro - origen).dot(tramo) / largo_cuadrado, 0.0, 1.0)
	var cercano := origen + tramo * progreso
	return cercano.distance_to(centro) <= radio + EPSILON


static func _punto_tangente(
	origen: Vector2,
	centro: Vector2,
	radio: float,
	lado: int,
) -> Dictionary:
	var relativo := origen - centro
	var distancia := relativo.length()
	if distancia <= radio + EPSILON:
		return {"ok": false}
	var angulo_origen := atan2(relativo.y, relativo.x)
	var apertura := acos(clampf(radio / distancia, -1.0, 1.0))
	var angulo := angulo_origen + float(1 if lado >= 0 else -1) * apertura
	return {
		"ok": true,
		"punto": centro + Vector2(cos(angulo), sin(angulo)) * radio,
	}


static func _dentro_arena(punto: Vector2, radio_arena: float) -> bool:
	return punto.length() <= maxf(0.0, radio_arena) + EPSILON


static func _limitar_a_arena(posicion: Vector3, radio_arena: float) -> Vector3:
	var plano := Vector2(posicion.x, posicion.z)
	var limite := maxf(0.0, radio_arena)
	if plano.length() > limite and plano.length() > EPSILON:
		plano = plano.normalized() * limite
	return Vector3(plano.x, posicion.y, plano.y)


static func _resultado(
	intencion: String,
	destino: Vector3,
	direccion: Vector3,
	lado: int,
	bloqueado_directo: bool,
) -> Dictionary:
	return {
		"intencion": intencion,
		"destino": destino,
		"direccion": direccion,
		"lado": lado,
		"bloqueado_directo": bloqueado_directo,
	}
