## Vertical jugable de huellas ambientales persistentes (#959).
##
## Observa únicamente Interactuable3D que optan explícitamente al sistema con
## metadatos. Registrar una acción no añade HUD ni cambia progresión: solo deja
## una marca visual pequeña en el suelo junto al objeto y guarda su intensidad.
extends Node

const META_ID := "huella_ambiental_id"
const META_TIPO := "huella_ambiental_tipo"
const META_OFFSET := "huella_ambiental_offset"
const NOMBRE_RAIZ := "HuellasAmbientales959"

var _mundo_id := 0
var _conectados := {}


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id != _mundo_id:
		_mundo_id = mundo_id
		_conectados.clear()
		_asegurar_raiz(mundo)
	_conectar_marcables(dia, mundo, mundo)


func _conectar_marcables(dia: Node, mundo: Node3D, nodo: Node) -> void:
	if nodo is Interactuable3D and nodo.has_meta(META_ID):
		var marcable := nodo as Interactuable3D
		var instancia := marcable.get_instance_id()
		if not _conectados.has(instancia):
			_conectados[instancia] = true
			var id := String(marcable.get_meta(META_ID, "")).strip_edges()
			var tipo := String(marcable.get_meta(META_TIPO, "uso"))
			if not id.is_empty():
				marcable.activado.connect(_al_activar.bind(marcable, id, tipo))
				if HuellasAmbientales.intensidad_de(dia.partida.estado, id) > 0.0:
					_montar_o_actualizar_marca(dia, mundo, marcable, id, tipo)
	for hijo in nodo.get_children():
		_conectar_marcables(dia, mundo, hijo)


func _al_activar(
	_actor: Node,
	marcable: Interactuable3D,
	id: String,
	tipo: String,
) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null or not is_instance_valid(marcable):
		return
	var fase := String(dia.jornada.get("fase", ""))
	if not Jornada.FASES.has(fase):
		return
	var huella := HuellasAmbientales.registrar(dia.partida.estado, id, tipo, fase)
	if huella.is_empty():
		return
	_montar_o_actualizar_marca(dia, dia._mundo, marcable, id, tipo)
	if dia.has_method("_guardar_o_avisar"):
		dia.call("_guardar_o_avisar", "")


func _asegurar_raiz(mundo: Node3D) -> Node3D:
	var existente := mundo.get_node_or_null(NOMBRE_RAIZ) as Node3D
	if existente != null:
		return existente
	var raiz := Node3D.new()
	raiz.name = NOMBRE_RAIZ
	mundo.add_child(raiz)
	return raiz


func _montar_o_actualizar_marca(
	dia: Node,
	mundo: Node3D,
	marcable: Interactuable3D,
	id: String,
	tipo: String,
) -> void:
	var raiz := _asegurar_raiz(mundo)
	var nombre := _nombre_marca(id)
	var marca := raiz.get_node_or_null(nombre) as MeshInstance3D
	if marca == null:
		marca = MeshInstance3D.new()
		marca.name = nombre
		marca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raiz.add_child(marca)

	var offset = marcable.get_meta(META_OFFSET, Vector3.ZERO)
	var punto_global := marcable.global_position
	if typeof(offset) == TYPE_VECTOR3:
		punto_global = marcable.to_global(offset)
	var local := mundo.to_local(punto_global)
	local.y = 0.012
	marca.position = local
	marca.rotation.y = deg_to_rad(float(abs(id.hash()) % 35) - 17.0)

	var plano := PlaneMesh.new()
	plano.size = _tamano_de(tipo)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 1.0
	var intensidad := HuellasAmbientales.intensidad_de(dia.partida.estado, id)
	var alpha := 0.07 + intensidad * 0.28
	material.albedo_color = Color(0.11, 0.085, 0.065, alpha)
	plano.material = material
	marca.mesh = plano


func _tamano_de(tipo: String) -> Vector2:
	match tipo:
		"apertura":
			return Vector2(0.44, 0.19)
		"paso":
			return Vector2(0.50, 0.17)
		"roce":
			return Vector2(0.28, 0.24)
		"lectura":
			return Vector2(0.24, 0.20)
		_:
			return Vector2(0.34, 0.23)


func _nombre_marca(id: String) -> String:
	return "Huella_" + id.replace(":", "_").replace("/", "_").replace(" ", "_")
