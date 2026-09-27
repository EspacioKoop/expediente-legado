## Regla local jugable para los modificadores ideológicos del sueño (#923).
##
## Traduce una relación semántica ya resuelta a una interacción espacial pequeña.
## No conoce ejes políticos, no persiste estado, no desbloquea progreso y no
## modifica hechos del expediente. Los CollisionShape3D pertenecen a Area3D:
## sirven para el raycast de interacción y nunca bloquean navegación.
class_name SuenoReglaIdeologica923
extends Node3D

const REGLAS := ["distribuir", "capas", "equilibrar", "desplazar"]
const COLOR_INDICADOR := Color(0.52, 0.48, 0.62)
const COLOR_ACTIVO := Color(0.72, 0.67, 0.82)

var regla := ""
var reduccion_movimiento := false
var _estado: Dictionary = {}
var _controles: Array[Interactuable3D] = []


func configurar(nueva_regla: String, reducir_movimiento: bool = false) -> void:
	if not regla.is_empty() or not _controles.is_empty():
		return
	regla = nueva_regla if REGLAS.has(nueva_regla) else ""
	reduccion_movimiento = reducir_movimiento
	_estado = _estado_inicial(regla)
	if regla.is_empty():
		return
	_montar_controles()
	_refrescar_visual()


func estado_jugable() -> Dictionary:
	return _estado.duplicate(true)


func plan_presentacion() -> Dictionary:
	return {
		"regla": regla,
		"reduccion_movimiento": reduccion_movimiento,
		"modo": "estatico",
		"duracion": 0.0,
		"mover_camara": false,
	}


func aplicar_accion(indice: int) -> Dictionary:
	if regla.is_empty() or indice < 0 or indice >= _cantidad_controles():
		return {
			"ok": false,
			"regla": regla,
			"estado": estado_jugable(),
			"presentacion": plan_presentacion(),
		}

	match regla:
		"distribuir":
			_aplicar_distribucion(indice)
		"capas":
			_aplicar_capas(indice)
		"equilibrar":
			_aplicar_equilibrio(indice)
		"desplazar":
			_aplicar_desplazamiento(indice)

	_refrescar_visual()
	return {
		"ok": true,
		"regla": regla,
		"estado": estado_jugable(),
		"presentacion": plan_presentacion(),
	}


func _estado_inicial(regla_id: String) -> Dictionary:
	match regla_id:
		"distribuir":
			return {"cargas": [3, 0, 0], "total": 3}
		"capas":
			return {"visitadas": [false, false, false], "esperada": 0, "completa": false}
		"equilibrar":
			return {"pesos": [2, 0], "equilibrado": false}
		"desplazar":
			return {"posicion": 0, "desplazamientos": 0}
	return {}


func _cantidad_controles() -> int:
	return 2 if regla == "equilibrar" else 3


func _montar_controles() -> void:
	var posiciones := _posiciones()
	for indice in _cantidad_controles():
		var control := Interactuable3D.new()
		control.name = "Accion%02d" % (indice + 1)
		control.position = posiciones[indice]
		control.verbo = Interactuable3D.Verbo.USAR
		control.nombre_objeto = _nombre_control(indice)
		control.sonido = Interactuable3D.SIN_SONIDO
		control.collision_mask = 0
		control.activado.connect(_al_activar.bind(indice))
		add_child(control)
		_controles.append(control)

		var colision := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(0.62, 0.72, 0.62)
		colision.shape = forma
		control.add_child(colision)

		var indicador := MeshInstance3D.new()
		indicador.name = "Indicador"
		var caja := BoxMesh.new()
		caja.size = Vector3(0.34, 0.34, 0.34)
		indicador.mesh = caja
		indicador.material_override = _material(COLOR_INDICADOR)
		control.add_child(indicador)


func _posiciones() -> Array[Vector3]:
	match regla:
		"distribuir":
			return [
				Vector3(-1.10, 0.55, 0.72),
				Vector3(0.0, 0.55, 0.72),
				Vector3(1.10, 0.55, 0.72),
			]
		"capas":
			return [
				Vector3(-0.78, 0.55, 0.72),
				Vector3(0.0, 0.55, 0.72),
				Vector3(0.78, 0.55, 0.72),
			]
		"equilibrar":
			return [
				Vector3(-1.0, 0.55, 0.72),
				Vector3(1.0, 0.55, 0.72),
			]
		"desplazar":
			return [
				Vector3(-0.75, 0.55, 0.72),
				Vector3(0.0, 0.55, 0.72),
				Vector3(0.75, 0.55, 0.72),
			]
	return []


func _nombre_control(indice: int) -> String:
	match regla:
		"distribuir":
			return "ancla %d" % (indice + 1)
		"capas":
			return "capa %d" % (indice + 1)
		"equilibrar":
			return "contrapeso %s" % ("A" if indice == 0 else "B")
		"desplazar":
			return "tramo %d" % (indice + 1)
	return "estructura"


func _al_activar(_actor: Node, indice: int) -> void:
	aplicar_accion(indice)


func _aplicar_distribucion(indice: int) -> void:
	var cargas: Array = _estado.get("cargas", [3, 0, 0])
	var origen := -1
	var maximo := -1
	for candidato in cargas.size():
		if candidato == indice:
			continue
		if int(cargas[candidato]) > maximo:
			maximo = int(cargas[candidato])
			origen = candidato
	if origen >= 0 and int(cargas[origen]) > 0:
		cargas[origen] = int(cargas[origen]) - 1
		cargas[indice] = int(cargas[indice]) + 1
	_estado["cargas"] = cargas


func _aplicar_capas(indice: int) -> void:
	var esperada := int(_estado.get("esperada", 0))
	var visitadas: Array = _estado.get("visitadas", [false, false, false])
	if bool(_estado.get("completa", false)):
		visitadas = [false, false, false]
		esperada = 0
		_estado["completa"] = false
	if indice != esperada:
		visitadas = [false, false, false]
		esperada = 0
		_estado["visitadas"] = visitadas
		_estado["esperada"] = esperada
		return
	visitadas[indice] = true
	esperada += 1
	_estado["visitadas"] = visitadas
	_estado["esperada"] = esperada
	_estado["completa"] = esperada >= visitadas.size()


func _aplicar_equilibrio(indice: int) -> void:
	var pesos: Array = _estado.get("pesos", [2, 0])
	var origen := 1 - indice
	if int(pesos[origen]) > 0:
		pesos[origen] = int(pesos[origen]) - 1
		pesos[indice] = int(pesos[indice]) + 1
	_estado["pesos"] = pesos
	_estado["equilibrado"] = int(pesos[0]) == int(pesos[1])


func _aplicar_desplazamiento(indice: int) -> void:
	_estado["posicion"] = indice
	_estado["desplazamientos"] = int(_estado.get("desplazamientos", 0)) + 1


func _refrescar_visual() -> void:
	for indice in _controles.size():
		var indicador := _controles[indice].get_node_or_null("Indicador") as MeshInstance3D
		if indicador == null:
			continue
		var activo := _control_activo(indice)
		indicador.scale = Vector3.ONE * (1.28 if activo else 1.0)
		indicador.material_override = _material(COLOR_ACTIVO if activo else COLOR_INDICADOR)


func _control_activo(indice: int) -> bool:
	match regla:
		"distribuir":
			var cargas: Array = _estado.get("cargas", [])
			return indice < cargas.size() and int(cargas[indice]) > 0
		"capas":
			var visitadas: Array = _estado.get("visitadas", [])
			return indice < visitadas.size() and bool(visitadas[indice])
		"equilibrar":
			var pesos: Array = _estado.get("pesos", [])
			if bool(_estado.get("equilibrado", false)):
				return true
			return indice < pesos.size() and int(pesos[indice]) > int(pesos[1 - indice])
		"desplazar":
			return int(_estado.get("posicion", 0)) == indice
	return false


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
