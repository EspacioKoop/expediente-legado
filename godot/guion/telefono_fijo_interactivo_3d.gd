## Teléfono fijo doméstico con visual original de 1998 para #671.
##
## Es una superficie 3D real, no un icono de HUD. La lógica de llamadas vive en
## TelefonoFijo; este nodo solo presenta el aparato, expone la interacción común
## y refleja timbre/mensajes mediante dos pilotos físicos.
class_name TelefonoFijoInteractivo3D
extends Interactuable3D

signal telefono_usado(actor: Node)

const COLOR_CARCASA := Color(0.34, 0.31, 0.26)
const COLOR_AURICULAR := Color(0.22, 0.20, 0.18)
const COLOR_TECLA := Color(0.63, 0.59, 0.50)
const COLOR_APAGADO := Color(0.10, 0.08, 0.07)
const COLOR_MENSAJE := Color(0.78, 0.16, 0.10)
const COLOR_TIMBRE := Color(0.92, 0.58, 0.12)

var jornada: Dictionary = {}
var _piloto_mensaje: MeshInstance3D
var _piloto_timbre: MeshInstance3D
var _auricular: Node3D


func _ready() -> void:
	verbo = Verbo.USAR
	nombre_objeto = "teléfono fijo"
	sonido = SIN_SONIDO
	_montar_geometria()
	_asegurar_volumen_interaccion()
	actualizar_estado()


func configurar(estado_jornada: Dictionary) -> void:
	jornada = estado_jornada
	actualizar_estado()


func interactuar(actor: Node) -> bool:
	if jornada.is_empty():
		return false
	if not super.interactuar(actor):
		return false
	telefono_usado.emit(actor)
	return true


func actualizar_estado() -> void:
	if jornada.is_empty() or not is_inside_tree():
		return
	var activo := not TelefonoFijo.llamada_activa(jornada).is_empty()
	var nuevos := TelefonoFijo.mensajes_nuevos(jornada) > 0
	var descolgado := bool(TelefonoFijo.estado(jornada).get(TelefonoFijo.DESCOLGADO, false))
	_pintar_piloto(_piloto_timbre, COLOR_TIMBRE if activo else COLOR_APAGADO, activo)
	_pintar_piloto(_piloto_mensaje, COLOR_MENSAJE if nuevos else COLOR_APAGADO, nuevos)
	if is_instance_valid(_auricular):
		_auricular.position.y = 0.27 if descolgado else 0.19
		_auricular.rotation_degrees.z = -8.0 if descolgado else 0.0


func _montar_geometria() -> void:
	if get_node_or_null("Carcasa") != null:
		return
	var carcasa := MeshInstance3D.new()
	carcasa.name = "Carcasa"
	carcasa.mesh = (load("res://arte/props_originales_98/telefono_fijo_base_98.obj") as Mesh)
	add_child(carcasa)

	_auricular = Node3D.new()
	_auricular.name = "Auricular"
	_auricular.position = Vector3(0, 0.19, -0.16)
	add_child(_auricular)
	var visual_auricular := MeshInstance3D.new()
	visual_auricular.name = "VisualAuricularOriginal98"
	visual_auricular.mesh = (
		load("res://arte/props_originales_98/telefono_auricular_98.obj") as Mesh
	)
	_auricular.add_child(visual_auricular)

	# Conserva el nodo semántico; las teclas forman parte de la malla importada.
	var teclado := Node3D.new()
	teclado.name = "Teclado"
	add_child(teclado)

	_piloto_timbre = _crear_caja(
		"PilotoTimbre", Vector3(0.055, 0.025, 0.035), Vector3(-0.22, 0.215, 0.18), COLOR_APAGADO
	)
	_piloto_mensaje = _crear_caja(
		"PilotoMensajes", Vector3(0.055, 0.025, 0.035), Vector3(0.22, 0.215, 0.18), COLOR_APAGADO
	)


func _crear_caja(nombre: String, tam: Vector3, posicion: Vector3, color: Color) -> MeshInstance3D:
	return _crear_caja_en(self, nombre, tam, posicion, color)


func _crear_caja_en(
	padre: Node3D, nombre: String, tam: Vector3, posicion: Vector3, color: Color
) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = posicion
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	malla.material_override = material
	padre.add_child(malla)
	return malla


func _pintar_piloto(nodo: MeshInstance3D, color: Color, encendido: bool) -> void:
	if not is_instance_valid(nodo):
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.45
	material.emission_enabled = encendido
	material.emission = color if encendido else Color.BLACK
	material.emission_energy_multiplier = 1.35 if encendido else 0.0
	nodo.material_override = material


func _asegurar_volumen_interaccion() -> void:
	if get_node_or_null("VolumenInteraccion") != null:
		return
	var colision := CollisionShape3D.new()
	colision.name = "VolumenInteraccion"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.86, 0.62, 0.76)
	colision.shape = forma
	colision.position = Vector3(0, 0.20, 0)
	add_child(colision)
