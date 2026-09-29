## Ventana floja de la oficina: tercer uso transversal de herramientas (#1773).
##
## Es una capa interactiva sobre una ventana REAL del catálogo. No reemplaza el
## cristal, no crea colisión de navegación y no conoce IDs de objetos: cualquier
## herramienta carried con uso `estabilizar` (o alias `calzar`) sirve.
class_name VentanaFlojaOficina1773
extends Interactuable3D

signal estabilizada(herramienta_id: String, herramienta_nombre: String)
signal falta_herramienta

const USO_REQUERIDO := UsosHerramienta.ESTABILIZAR
const TAM_INTERACCION := Vector3(1.75, 1.45, 0.34)
const AMPLITUD_GRADOS := 2.0
const VELOCIDAD_OSCILACION := 2.6

var _inventario: Dictionary = {}
var _estabilizada := false
var _tiempo := 0.0
var _hoja: Node3D


func _ready() -> void:
	if _hoja == null:
		_montar_visual()
	if get_node_or_null("VolumenInteraccion") == null:
		_montar_volumen()
	_actualizar_presentacion()


func configurar(inventario: Dictionary, ya_estabilizada: bool = false) -> void:
	_inventario = inventario
	_estabilizada = ya_estabilizada
	verbo = Verbo.USAR
	nombre_objeto = tr("VENTANA_FLOJA_OFICINA")
	sonido = "abrir"
	set_meta("uso_requerido", USO_REQUERIDO)
	if _hoja == null:
		_montar_visual()
	if get_node_or_null("VolumenInteraccion") == null:
		_montar_volumen()
	_actualizar_presentacion()


func esta_estabilizada() -> bool:
	return _estabilizada


func herramienta_disponible() -> Dictionary:
	if _inventario.is_empty():
		return {}
	var resultado := UsosHerramienta.resolver(_inventario, USO_REQUERIDO)
	if not bool(resultado.get("ok", false)):
		return {}
	var herramienta: Variant = resultado.get("herramienta", {})
	return (herramienta as Dictionary).duplicate(true) if herramienta is Dictionary else {}


func interactuar(actor: Node) -> bool:
	if not habilitado or _estabilizada:
		return false
	var herramienta := herramienta_disponible()
	if herramienta.is_empty():
		set_meta("ultimo_resultado", "falta_herramienta")
		falta_herramienta.emit()
		return false

	_estabilizada = true
	var herramienta_id := String(herramienta.get("id", ""))
	var herramienta_nombre := String(herramienta.get("nombre", herramienta_id))
	set_meta("ultimo_resultado", "estabilizada")
	set_meta("herramienta_usada", herramienta_id)
	_actualizar_presentacion()
	if not super.interactuar(actor):
		return false
	habilitado = false
	estabilizada.emit(herramienta_id, herramienta_nombre)
	return true


func _process(delta: float) -> void:
	if _estabilizada or _hoja == null:
		return
	_tiempo += maxf(delta, 0.0)
	_hoja.rotation_degrees.z = sin(_tiempo * VELOCIDAD_OSCILACION) * AMPLITUD_GRADOS


func _actualizar_presentacion() -> void:
	set_process(not _estabilizada)
	if _hoja != null and _estabilizada:
		_hoja.rotation_degrees.z = 0.0


func _montar_visual() -> void:
	_hoja = Node3D.new()
	_hoja.name = "HojaFloja"
	_hoja.position = Vector3(0.0, 0.0, -0.065)
	add_child(_hoja)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.34, 0.35, 0.36)
	material.metallic = 0.18
	material.roughness = 0.62
	_barra("MarcoSuperior", Vector3(1.56, 0.055, 0.055), Vector3(0.0, 0.56, 0.0), material)
	_barra("MarcoInferior", Vector3(1.56, 0.055, 0.055), Vector3(0.0, -0.56, 0.0), material)
	_barra("MarcoIzquierdo", Vector3(0.055, 1.18, 0.055), Vector3(-0.75, 0.0, 0.0), material)
	_barra("MarcoDerecho", Vector3(0.055, 1.18, 0.055), Vector3(0.75, 0.0, 0.0), material)


func _barra(nombre: String, tam: Vector3, posicion: Vector3, material: StandardMaterial3D) -> void:
	var malla := BoxMesh.new()
	malla.size = tam
	malla.material = material
	var pieza := MeshInstance3D.new()
	pieza.name = nombre
	pieza.mesh = malla
	pieza.position = posicion
	pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hoja.add_child(pieza)


func _montar_volumen() -> void:
	var colision := CollisionShape3D.new()
	colision.name = "VolumenInteraccion"
	var forma := BoxShape3D.new()
	forma.size = TAM_INTERACCION
	colision.shape = forma
	add_child(colision)
