## Persiana urbana reactiva para el trayecto exterior (#400).
##
## Añade una microinteracción física a una ventana ya existente: abrir/cerrar
## desplaza la hoja metálica sin persistencia, economía, lore ni efectos de
## jornada. El gesto es instantáneo para respetar reducción de movimiento.
class_name PersianaCalleInteractiva3D
extends "res://guion/interactuable_3d.gd"

const POS_CERRADA := Vector3.ZERO
const POS_ABIERTA := Vector3(0, 1.25, 0)
const TAM_INTERACCION := Vector3(0.42, 1.35, 1.65)

var _abierta := false
var _hoja: Node3D


func configurar() -> void:
	verbo = Verbo.ABRIR
	nombre_objeto = "persiana"

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = TAM_INTERACCION
	colision.shape = forma
	add_child(colision)

	_montar_guia()
	_montar_hoja()
	activado.connect(_alternar)


func esta_abierta() -> bool:
	return _abierta


func posicion_hoja() -> Vector3:
	return _hoja.position


func _alternar(_actor: Node) -> void:
	_abierta = not _abierta
	verbo = Verbo.CERRAR if _abierta else Verbo.ABRIR
	_hoja.position = POS_ABIERTA if _abierta else POS_CERRADA


func _montar_guia() -> void:
	var metal_oscuro := Color(0.17, 0.18, 0.19)
	_agregar_caja(self, Vector3(0, 0.62, -0.79), Vector3(0.12, 1.28, 0.08), metal_oscuro)
	_agregar_caja(self, Vector3(0, 0.62, 0.79), Vector3(0.12, 1.28, 0.08), metal_oscuro)
	_agregar_caja(self, Vector3(0, 1.27, 0), Vector3(0.14, 0.14, 1.66), metal_oscuro)


func _montar_hoja() -> void:
	_hoja = Node3D.new()
	_hoja.name = "HojaPersianaCalle"
	_hoja.position = POS_CERRADA
	add_child(_hoja)

	var metal := Color(0.33, 0.35, 0.36)
	var metal_sombra := Color(0.23, 0.24, 0.25)
	for indice in range(8):
		var y := 0.12 + float(indice) * 0.145
		_agregar_caja(_hoja, Vector3(0, y, 0), Vector3(0.10, 0.12, 1.48), metal)
		_agregar_caja(
			_hoja, Vector3(-0.055, y - 0.055, 0), Vector3(0.025, 0.025, 1.48), metal_sombra
		)
	_agregar_caja(_hoja, Vector3(-0.02, 0.04, 0), Vector3(0.16, 0.08, 1.54), metal_sombra)


static func _agregar_caja(raiz: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	malla.material_override = material
	raiz.add_child(malla)
