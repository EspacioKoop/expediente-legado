## Capa física de la ronda de cierre opcional (#156).
##
## Reutiliza Interactuable3D: el detector común de primera persona y su prompt
## de entrada son los únicos que deciden cómo se activa un punto. Esta capa no
## concede recompensas ni mueve el reloj; traduce gestos físicos al contrato
## persistido de RondaCierre.
class_name RondaCierre3D
extends Node3D

signal punto_completado(punto: String)

const NOMBRE_RAIZ := "RondaCierreFisica"
const ALTURA_CONVERSABLE := 0.9
const POS_CUNADO := Vector3(-1.9, 0.0, 0.4)
const POS_LUZ_OBJETIVO := Vector3(-4.0, 2.65, 2.0)

var _estado: Dictionary = {}
var _puntos := {}
var _mundo: Node3D


func configurar(estado: Dictionary) -> void:
	_estado = estado
	_mundo = get_parent() as Node3D
	name = NOMBRE_RAIZ
	_montar_puntos()
	refrescar()


func punto(id_punto: String) -> Interactuable3D:
	return _puntos.get(id_punto) as Interactuable3D


func refrescar() -> void:
	if _estado.is_empty():
		return
	var bloqueada := (
		bool(_estado.get("abandonada", false)) or bool(_estado.get("finalizada", false))
	)
	var completados: Array = _estado.get("completados", [])
	for id_punto in _puntos:
		var interactuable := _puntos[id_punto] as Interactuable3D
		if interactuable == null:
			continue
		var hecho := completados.has(id_punto)
		if hecho:
			_aplicar_estado_completado(String(id_punto), interactuable)
		if bloqueada or hecho:
			_deshabilitar(interactuable, String(id_punto) != RondaCierre.PUNTO_CUNADO)


func _montar_puntos() -> void:
	var ruta: Array = _estado.get("ruta", [])
	for valor in ruta:
		var id_punto := String(valor)
		if id_punto == RondaCierre.PUNTO_CUNADO:
			_conectar_cunado()
			continue
		var interactuable := _crear_interactuable(id_punto)
		if interactuable == null:
			continue
		_puntos[id_punto] = interactuable


func _crear_interactuable(id_punto: String) -> Interactuable3D:
	var posicion := _posicion(id_punto)
	if posicion == Vector3.INF:
		return null

	var punto := Interactuable3D.new()
	punto.name = "RondaCierre_%s" % id_punto
	punto.position = posicion
	punto.verbo = _verbo(id_punto)
	punto.nombre_objeto = _nombre(id_punto)
	punto.set_meta("ronda_cierre_punto", id_punto)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = _tam_interaccion(id_punto)
	colision.shape = forma
	punto.add_child(colision)

	_agregar_visual_si_toca(punto, id_punto)
	if id_punto == "cerrar_puerta":
		punto.rotation.y = deg_to_rad(14.0)

	punto.activado.connect(_al_activar.bind(id_punto, punto))
	add_child(punto)
	return punto


func _conectar_cunado() -> void:
	if _mundo == null:
		return
	for hijo in _mundo.get_children():
		if not hijo is CompaneroInteractivo3D:
			continue
		var companero := hijo as CompaneroInteractivo3D
		var pies := companero.position - Vector3.UP * ALTURA_CONVERSABLE
		if pies.distance_to(POS_CUNADO) > 0.2:
			continue
		_puntos[RondaCierre.PUNTO_CUNADO] = companero
		var callback := _al_activar.bind(RondaCierre.PUNTO_CUNADO, companero)
		if not companero.activado.is_connected(callback):
			companero.activado.connect(callback)
		return


func _al_activar(_actor: Node, id_punto: String, interactuable: Interactuable3D) -> void:
	var completados: Array = _estado.get("completados", [])
	if completados.has(id_punto):
		return
	if not RondaCierre.completar_punto(_estado, id_punto):
		return
	_aplicar_estado_completado(id_punto, interactuable)
	_deshabilitar(interactuable, id_punto != RondaCierre.PUNTO_CUNADO)
	punto_completado.emit(id_punto)


func _aplicar_estado_completado(id_punto: String, interactuable: Interactuable3D) -> void:
	match id_punto:
		"recoger_a7", "devolver_carpeta":
			var visual := interactuable.get_node_or_null("Visual") as MeshInstance3D
			if visual != null:
				visual.visible = false
		"apagar_lampara":
			_apagar_lampara()
		"cerrar_puerta":
			interactuable.rotation.y = 0.0


func _deshabilitar(interactuable: Interactuable3D, apagar_colision: bool) -> void:
	if not apagar_colision:
		return
	interactuable.habilitado = false
	interactuable.monitoring = false
	interactuable.monitorable = false
	interactuable.collision_layer = 0


func _apagar_lampara() -> void:
	if _mundo == null:
		return
	var mejor: OmniLight3D
	var distancia := INF
	for nodo in _mundo.find_children("*", "OmniLight3D", true, false):
		var luz := nodo as OmniLight3D
		if luz == null or not String(luz.name).begins_with(Espacio3D.NOMBRE_LUZ_SALA):
			continue
		var actual := luz.global_position.distance_to(_mundo.to_global(POS_LUZ_OBJETIVO))
		if actual < distancia:
			distancia = actual
			mejor = luz
	if mejor != null:
		mejor.light_energy = 0.0
		mejor.visible = false


func _agregar_visual_si_toca(punto: Interactuable3D, id_punto: String) -> void:
	var tam := Vector3.ZERO
	var color := Color(0.75, 0.72, 0.62)
	match id_punto:
		"recoger_a7":
			tam = Vector3(0.42, 0.015, 0.30)
			color = Color(0.86, 0.84, 0.76)
		"apagar_lampara":
			tam = Vector3(0.06, 0.18, 0.12)
			color = Color(0.48, 0.47, 0.42)
		"cerrar_puerta":
			tam = Vector3(0.10, 1.95, 1.05)
			color = Color(0.31, 0.32, 0.30)
		"devolver_carpeta":
			tam = Vector3(0.38, 0.07, 0.28)
			color = Color(0.54, 0.42, 0.28)
		_:
			return

	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var caja := BoxMesh.new()
	caja.size = tam
	visual.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	visual.material_override = material
	punto.add_child(visual)


func _posicion(id_punto: String) -> Vector3:
	match id_punto:
		"recoger_a7":
			return Vector3(-3.55, 0.84, 1.28)
		"apagar_lampara":
			return Vector3(-6.82, 1.15, 1.65)
		"cerrar_puerta":
			return Vector3(6.72, 1.02, 3.55)
		"revisar_bandeja":
			return Vector3(-4.62, 0.88, -2.24)
		"devolver_carpeta":
			return Vector3(3.70, 0.86, 0.06)
		"comprobar_tablon":
			return Vector3(-1.50, 1.65, -4.72)
		_:
			return Vector3.INF


func _tam_interaccion(id_punto: String) -> Vector3:
	match id_punto:
		"cerrar_puerta":
			return Vector3(0.45, 2.05, 1.20)
		"comprobar_tablon":
			return Vector3(2.25, 1.15, 0.34)
		"revisar_bandeja":
			return Vector3(0.70, 0.40, 0.60)
		_:
			return Vector3(0.70, 0.55, 0.70)


func _verbo(id_punto: String) -> int:
	match id_punto:
		"recoger_a7":
			return Interactuable3D.Verbo.COGER
		"cerrar_puerta":
			return Interactuable3D.Verbo.CERRAR
		"revisar_bandeja", "comprobar_tablon":
			return Interactuable3D.Verbo.EXAMINAR
		"devolver_carpeta":
			return Interactuable3D.Verbo.DAR
		_:
			return Interactuable3D.Verbo.USAR


func _nombre(id_punto: String) -> String:
	match id_punto:
		"recoger_a7":
			return "formulario A-7"
		"apagar_lampara":
			return "interruptor de la lámpara"
		"cerrar_puerta":
			return "puerta auxiliar"
		"revisar_bandeja":
			return "bandeja de entrada"
		"devolver_carpeta":
			return "carpeta de clasificación"
		"comprobar_tablon":
			return "tablón de anuncios"
		_:
			return "punto de cierre"
