## Buzón físico del portal para #672.
##
## Usa el contrato común de interacción 3D: teclado y mando llegan por la acción
## semántica `interactuar`, sin teclas nuevas. El nodo no posee reglas de correo;
## solo presenta un volumen en el mundo y delega en CorreoPostal.
class_name BuzonPostalInteractivo3D
extends Interactuable3D

signal correo_recogido(resultado: Dictionary, actor: Node)
signal buzon_vacio(actor: Node)

const COLOR_CAJA := Color(0.16, 0.14, 0.12)
const COLOR_REBORDE := Color(0.24, 0.21, 0.17)
const COLOR_PUERTA := Color(0.31, 0.27, 0.21)
const COLOR_RANURA := Color(0.055, 0.048, 0.04)
const COLOR_METAL := Color(0.36, 0.34, 0.29)
const COLOR_PLACA := Color(0.73, 0.67, 0.51)
const COLOR_PAPEL := Color(0.88, 0.84, 0.72)
const COLOR_SELLO := Color(0.43, 0.16, 0.13)
const COLOR_PAQUETE := Color(0.62, 0.49, 0.30)
const COLOR_CINTA := Color(0.82, 0.74, 0.56)

var jornada: Dictionary = {}
var inventario: Dictionary = Inventario.nuevo()
var _indicador_correo: Node3D


func _ready() -> void:
	verbo = Verbo.ABRIR
	nombre_objeto = "buzón"
	_montar_geometria()
	_asegurar_volumen_interaccion()
	_actualizar_indicador_correo()


func configurar(estado_jornada: Dictionary, estado_inventario: Dictionary) -> void:
	jornada = estado_jornada
	inventario = estado_inventario
	Inventario.completar(inventario)
	_actualizar_indicador_correo()


func pendientes() -> int:
	if jornada.is_empty():
		return 0
	return CorreoPostal.disponibles(jornada).size()


func tipo_correo_visible() -> String:
	if jornada.is_empty():
		return "vacio"
	var pieza := CorreoPostal.siguiente(jornada)
	if pieza.is_empty():
		return "vacio"
	return "paquete" if String(pieza.get("categoria", "")) == "paquete" else "sobre"


func interactuar(actor: Node) -> bool:
	if jornada.is_empty():
		return false
	if not super.interactuar(actor):
		return false

	var resultado := CorreoPostal.recoger_siguiente(jornada, inventario)
	_actualizar_indicador_correo()
	if not bool(resultado.get("ok", false)):
		buzon_vacio.emit(actor)
		return true

	correo_recogido.emit(resultado.duplicate(true), actor)
	return true


func _montar_geometria() -> void:
	if get_node_or_null("Caja") != null:
		_indicador_correo = get_node_or_null("CorreoVisible") as Node3D
		return

	_crear_caja("Caja", Vector3(0.56, 0.72, 0.28), Vector3.ZERO, COLOR_CAJA, 0.12, 0.82)
	_crear_caja(
		"RebordePuerta",
		Vector3(0.50, 0.58, 0.035),
		Vector3(0, -0.025, -0.157),
		COLOR_REBORDE,
		0.18,
		0.72,
	)
	_crear_caja(
		"Puerta",
		Vector3(0.445, 0.515, 0.032),
		Vector3(0, -0.025, -0.18),
		COLOR_PUERTA,
		0.14,
		0.78,
	)
	_crear_caja(
		"Ranura",
		Vector3(0.31, 0.052, 0.025),
		Vector3(0, 0.205, -0.205),
		COLOR_RANURA,
		0.05,
		0.62,
	)
	_crear_caja(
		"LabioRanura",
		Vector3(0.34, 0.018, 0.035),
		Vector3(0, 0.242, -0.198),
		COLOR_METAL,
		0.42,
		0.46,
	)
	_crear_caja(
		"Tirador",
		Vector3(0.12, 0.036, 0.045),
		Vector3(0, -0.245, -0.215),
		COLOR_METAL,
		0.48,
		0.40,
	)
	_crear_caja(
		"PlacaNombre",
		Vector3(0.20, 0.065, 0.016),
		Vector3(0, 0.095, -0.209),
		COLOR_PLACA,
		0.16,
		0.58,
	)
	_crear_caja(
		"BisagraSuperior",
		Vector3(0.035, 0.10, 0.040),
		Vector3(0.235, 0.12, -0.178),
		COLOR_METAL,
		0.45,
		0.42,
	)
	_crear_caja(
		"BisagraInferior",
		Vector3(0.035, 0.10, 0.040),
		Vector3(0.235, -0.18, -0.178),
		COLOR_METAL,
		0.45,
		0.42,
	)

	for posicion in [
		Vector3(-0.205, 0.205, -0.202),
		Vector3(0.205, 0.205, -0.202),
		Vector3(-0.205, -0.25, -0.202),
		Vector3(0.205, -0.25, -0.202),
	]:
		_crear_caja(
			"Tornillo",
			Vector3(0.022, 0.022, 0.014),
			posicion,
			COLOR_METAL,
			0.55,
			0.38,
		)

	_indicador_correo = Node3D.new()
	_indicador_correo.name = "CorreoVisible"
	_indicador_correo.position = Vector3(0, 0.245, -0.225)
	add_child(_indicador_correo)


func _crear_caja(
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
	metallic := 0.0,
	roughness := 0.88,
) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = posicion
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	malla.material_override = material
	add_child(malla)
	return malla


func _crear_caja_indicador(
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
	rotacion_z := 0.0,
) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = posicion
	malla.rotation.z = rotacion_z
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	malla.material_override = material
	_indicador_correo.add_child(malla)
	return malla


func _actualizar_indicador_correo() -> void:
	if not is_instance_valid(_indicador_correo):
		return
	for hijo in _indicador_correo.get_children():
		_indicador_correo.remove_child(hijo)
		hijo.free()

	var tipo := tipo_correo_visible()
	_indicador_correo.set_meta("tipo", tipo)
	_indicador_correo.visible = tipo != "vacio"
	if tipo == "paquete":
		_montar_paquete_visible()
	elif tipo == "sobre":
		_montar_sobre_visible()


func _montar_sobre_visible() -> void:
	_crear_caja_indicador(
		"Sobre",
		Vector3(0.255, 0.115, 0.012),
		Vector3(0, -0.005, 0),
		COLOR_PAPEL,
		-0.035,
	)
	_crear_caja_indicador(
		"Solapa",
		Vector3(0.19, 0.035, 0.014),
		Vector3(-0.008, 0.025, -0.010),
		COLOR_PAPEL.darkened(0.08),
		-0.035,
	)
	_crear_caja_indicador(
		"Sello",
		Vector3(0.040, 0.030, 0.016),
		Vector3(0.086, 0.026, -0.012),
		COLOR_SELLO,
		-0.035,
	)


func _montar_paquete_visible() -> void:
	_crear_caja_indicador(
		"PaqueteAcolchado",
		Vector3(0.285, 0.145, 0.028),
		Vector3(0, -0.010, 0),
		COLOR_PAQUETE,
		0.025,
	)
	_crear_caja_indicador(
		"CintaPaquete",
		Vector3(0.050, 0.148, 0.031),
		Vector3(0.018, -0.010, -0.010),
		COLOR_CINTA,
		0.025,
	)
	_crear_caja_indicador(
		"EtiquetaPaquete",
		Vector3(0.105, 0.052, 0.033),
		Vector3(-0.055, 0.015, -0.013),
		COLOR_PAPEL,
		0.025,
	)


func _asegurar_volumen_interaccion() -> void:
	if get_node_or_null("VolumenInteraccion") != null:
		return
	var colision := CollisionShape3D.new()
	colision.name = "VolumenInteraccion"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.68, 0.86, 0.58)
	colision.shape = forma
	add_child(colision)
