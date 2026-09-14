## Cómoda doméstica con un cajón utilizable para la casa (#400/#97).
##
## Reutiliza el contrato semántico de Interactuable3D para abrir/cerrar y el
## contrato puro de Inventario para mover objetos entre carried/home_storage.
## La cómoda no posee ni persiste estado: recibe el diccionario de inventario
## explícitamente y solo permite guardar/sacar mientras el cajón está abierto.
class_name AlmacenamientoCasaInteractivo3D
extends "res://guion/interactuable_3d.gd"

const POS_CERRADO := Vector3.ZERO
const POS_ABIERTO := Vector3(0, 0, -0.36)

var _abierto := false
var _cajon: Node3D


func configurar() -> void:
	verbo = Verbo.ABRIR
	nombre_objeto = "cajón"

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.25, 0.95, 0.70)
	colision.position = Vector3(0, 0.47, 0)
	colision.shape = forma
	add_child(colision)

	_montar_carcasa()
	_montar_cajon()
	activado.connect(_alternar)


func esta_abierto() -> bool:
	return _abierto


func posicion_cajon() -> Vector3:
	return _cajon.position


func guardar_objeto(estado_inventario: Dictionary, objeto_id: String) -> bool:
	if not _abierto or objeto_id.strip_edges().is_empty():
		return false
	return Inventario.guardar_en_casa(estado_inventario, objeto_id)


func sacar_objeto(estado_inventario: Dictionary, objeto_id: String) -> bool:
	if not _abierto or objeto_id.strip_edges().is_empty():
		return false
	return Inventario.sacar_de_casa(estado_inventario, objeto_id)


func contenido(estado_inventario: Dictionary) -> Array:
	if not _abierto:
		return []
	Inventario.completar(estado_inventario)
	return estado_inventario[Inventario.HOME_STORAGE].duplicate(true)


func _alternar(_actor: Node) -> void:
	_abierto = not _abierto
	verbo = Verbo.CERRAR if _abierto else Verbo.ABRIR
	_cajon.position = POS_ABIERTO if _abierto else POS_CERRADO


func _montar_carcasa() -> void:
	var madera := Color(0.34, 0.24, 0.17)
	var madera_oscura := Color(0.25, 0.17, 0.12)
	_agregar_caja(self, Vector3(0, 0.07, 0), Vector3(1.20, 0.14, 0.58), madera_oscura)
	_agregar_caja(self, Vector3(0, 0.89, 0), Vector3(1.24, 0.12, 0.62), madera)
	_agregar_caja(self, Vector3(-0.56, 0.48, 0), Vector3(0.12, 0.76, 0.58), madera)
	_agregar_caja(self, Vector3(0.56, 0.48, 0), Vector3(0.12, 0.76, 0.58), madera)
	_agregar_caja(self, Vector3(0, 0.48, 0.26), Vector3(1.02, 0.76, 0.08), madera_oscura)

	# El cajón inferior queda cerrado y ayuda a que el mueble se lea como
	# almacenamiento, no como una caja genérica.
	_agregar_caja(self, Vector3(0, 0.27, -0.27), Vector3(1.02, 0.28, 0.08), madera)
	_agregar_caja(self, Vector3(0, 0.27, -0.325), Vector3(0.24, 0.05, 0.05), madera_oscura)


func _montar_cajon() -> void:
	_cajon = Node3D.new()
	_cajon.name = "CajonCasa"
	_cajon.position = POS_CERRADO
	add_child(_cajon)

	var madera := Color(0.38, 0.27, 0.19)
	var interior := Color(0.27, 0.20, 0.15)
	_agregar_caja(_cajon, Vector3(0, 0.66, -0.27), Vector3(1.02, 0.30, 0.08), madera)
	_agregar_caja(_cajon, Vector3(0, 0.53, 0.0), Vector3(0.92, 0.06, 0.50), interior)
	_agregar_caja(_cajon, Vector3(-0.44, 0.66, 0.0), Vector3(0.06, 0.26, 0.50), interior)
	_agregar_caja(_cajon, Vector3(0.44, 0.66, 0.0), Vector3(0.06, 0.26, 0.50), interior)
	_agregar_caja(_cajon, Vector3(0, 0.66, 0.22), Vector3(0.92, 0.26, 0.06), interior)
	_agregar_caja(_cajon, Vector3(0, 0.66, -0.325), Vector3(0.24, 0.05, 0.05), interior)


static func _agregar_caja(raiz: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	malla.material_override = material
	raiz.add_child(malla)