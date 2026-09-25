## Capa espacial puramente visual para la gramática simbólica del sueño (#888).
##
## Parte únicamente de anomalías ya legitimadas por SuenoUtileria y extiende su
## motivo al espacio cercano con mallas estáticas. No crea colisiones, prompts,
## navegación, objetivos ni persistencia: el jugador puede atravesar estas rimas
## igual que atraviesa una composición de luz.
class_name SuenoEspacioSimbolico
extends RefCounted

const COLOR_ESTRUCTURA := Color(0.30, 0.28, 0.36)
const GROSOR := 0.08


static func montar(mundo: Node3D, anomalias: Array, modificadores: Array = []) -> Array:
	var creadas := []
	var capa: Node3D
	for valor in anomalias:
		if not valor is AnomaliaSueno3D:
			continue
		var anomalia: AnomaliaSueno3D = valor
		var motivo := String(anomalia.get_meta("motivo_simbolico", ""))
		if not _motivo_soportado(motivo):
			continue

		if capa == null:
			capa = Node3D.new()
			capa.name = "EspacioSimbolico"
			mundo.add_child(capa)

		var rima := Node3D.new()
		rima.name = "RimaEspacial%d" % (creadas.size() + 1)
		rima.position = Vector3(anomalia.position.x, 0.0, anomalia.position.z)
		rima.set_meta("motivo_simbolico", motivo)
		rima.set_meta("catalogo_origen", anomalia.id_catalogo())
		capa.add_child(rima)
		_montar_motivo(rima, motivo)
		creadas.append(rima)
	_aplicar_modificadores(creadas, modificadores)
	return creadas


static func _aplicar_modificadores(rimas: Array, modificadores: Array) -> void:
	var activo := {}
	for valor in modificadores:
		if typeof(valor) != TYPE_DICTIONARY:
			continue
		var modificador: Dictionary = valor
		if String(modificador.get("canal", "")) != "eleccion":
			continue
		if String(modificador.get("regla", "")).is_empty():
			continue
		activo = modificador
		break
	if activo.is_empty():
		return

	for valor_rima in rimas:
		if not valor_rima is Node3D:
			continue
		var rima: Node3D = valor_rima
		var capa := Node3D.new()
		capa.name = "ModificadorIdeologico"
		capa.set_meta("canal_modificador", String(activo.get("canal", "")))
		capa.set_meta("familia_modificadora", String(activo.get("familia", "")))
		capa.set_meta("regla_modificadora", String(activo.get("regla", "")))
		rima.add_child(capa)
		_montar_regla(capa, String(activo.get("regla", "")))


static func _montar_regla(raiz: Node3D, regla: String) -> void:
	match regla:
		"distribuir":
			_montar_distribucion(raiz)
		"capas":
			_montar_capas(raiz)
		"equilibrar":
			_montar_equilibrio(raiz)
		"desplazar":
			_montar_desplazamiento(raiz)


static func _montar_distribucion(raiz: Node3D) -> void:
	for i in range(3):
		_caja(
			raiz,
			"Ancla%02d" % (i + 1),
			Vector3(-1.10 + 1.10 * i, 0.18, 0.0),
			Vector3(0.22, 0.36, 0.62),
		)


static func _montar_capas(raiz: Node3D) -> void:
	_marco(raiz, "CapaA", Vector3(0.0, 0.0, -0.55), 0.0)
	_marco(raiz, "CapaB", Vector3(0.0, 0.0, 0.0), 0.0)
	_marco(raiz, "CapaC", Vector3(0.0, 0.0, 0.55), 0.0)


static func _montar_equilibrio(raiz: Node3D) -> void:
	_caja(raiz, "PesoA", Vector3(-1.0, 0.18, 0.0), Vector3(0.68, 0.36, 0.68))
	_caja(raiz, "PesoB", Vector3(1.0, 0.18, 0.0), Vector3(0.68, 0.36, 0.68))
	_caja(raiz, "Vinculo", Vector3(0.0, 0.08, 0.0), Vector3(1.80, 0.08, GROSOR))


static func _montar_desplazamiento(raiz: Node3D) -> void:
	for i in range(3):
		_caja(
			raiz,
			"Tramo%02d" % (i + 1),
			Vector3(-0.75 + 0.75 * i, 0.14, -0.55 + 0.55 * i),
			Vector3(0.58, 0.28, 0.58),
		)


static func _motivo_soportado(motivo: String) -> bool:
	return motivo in ["umbral", "doble", "laberinto", "ciclo-centro"]


static func _montar_motivo(raiz: Node3D, motivo: String) -> void:
	match motivo:
		"umbral":
			_montar_umbral(raiz)
		"doble":
			_montar_doble(raiz)
		"laberinto":
			_montar_laberinto(raiz)
		"ciclo-centro":
			_montar_ciclo(raiz)


static func _montar_umbral(raiz: Node3D) -> void:
	_caja(raiz, "JambaIzquierda", Vector3(-1.0, 1.25, -1.55), Vector3(GROSOR, 2.5, GROSOR))
	_caja(raiz, "JambaDerecha", Vector3(1.0, 1.25, -1.55), Vector3(GROSOR, 2.5, GROSOR))
	_caja(raiz, "Dintel", Vector3(0.0, 2.48, -1.55), Vector3(2.08, GROSOR, GROSOR))


static func _montar_doble(raiz: Node3D) -> void:
	_caja(raiz, "EjeA1", Vector3(-1.05, 0.95, -0.85), Vector3(GROSOR, 1.9, GROSOR))
	_caja(raiz, "EjeA2", Vector3(-1.05, 0.95, 0.85), Vector3(GROSOR, 1.9, GROSOR))
	_caja(raiz, "EjeB1", Vector3(1.05, 0.95, -0.85), Vector3(GROSOR, 1.9, GROSOR))
	_caja(raiz, "EjeB2", Vector3(1.05, 0.95, 0.85), Vector3(GROSOR, 1.9, GROSOR))


static func _montar_laberinto(raiz: Node3D) -> void:
	_marco(raiz, "PorticoA", Vector3(0.0, 0.0, -1.35), 0.0)
	_marco(raiz, "PorticoB", Vector3(1.35, 0.0, 0.0), 90.0)
	_marco(raiz, "PorticoC", Vector3(0.0, 0.0, 1.35), 180.0)


static func _montar_ciclo(raiz: Node3D) -> void:
	for i in range(8):
		var angulo := TAU * float(i) / 8.0
		var pos := Vector3(cos(angulo) * 1.28, 0.045, sin(angulo) * 1.28)
		var marca := _caja(
			raiz,
			"Marca%02d" % (i + 1),
			pos,
			Vector3(0.34, 0.09, 0.68),
		)
		marca.rotation_degrees.y = -rad_to_deg(angulo)


static func _marco(raiz: Node3D, nombre: String, pos: Vector3, giro_y: float) -> void:
	var marco := Node3D.new()
	marco.name = nombre
	marco.position = pos
	marco.rotation_degrees.y = giro_y
	raiz.add_child(marco)
	_caja(marco, "Izquierda", Vector3(-0.78, 1.0, 0.0), Vector3(GROSOR, 2.0, GROSOR))
	_caja(marco, "Derecha", Vector3(0.78, 1.0, 0.0), Vector3(GROSOR, 2.0, GROSOR))
	_caja(marco, "Dintel", Vector3(0.0, 1.96, 0.0), Vector3(1.64, GROSOR, GROSOR))


static func _caja(raiz: Node3D, nombre: String, pos: Vector3, tam: Vector3) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	malla.position = pos
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.material_override = _material()
	raiz.add_child(malla)
	return malla


static func _material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_ESTRUCTURA
	material.roughness = 1.0
	return material
