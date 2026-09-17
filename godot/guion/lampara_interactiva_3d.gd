## Lámpara doméstica interactiva reutilizando el contrato común de #283.
##
## El estado es deliberadamente local a la escena: encenderla o apagarla no
## guarda progreso, no consume acciones y no modifica estado persistente.
class_name LamparaInteractiva3D
extends Interactuable3D

const ENERGIA_ENCENDIDA := 1.1

var _encendida := false
var _luz: OmniLight3D


func configurar() -> void:
	verbo = Verbo.ENCENDER
	nombre_objeto = "lámpara"

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.7, 1.95, 0.7)
	colision.position = Vector3(0, 0.95, 0)
	colision.shape = forma
	add_child(colision)

	_luz = OmniLight3D.new()
	_luz.name = "LuzLampara"
	_luz.position = Vector3(0, 1.62, 0)
	_luz.omni_range = 4.2
	_luz.light_energy = 0.0
	_luz.shadow_enabled = true
	_luz.visible = false
	add_child(_luz)

	activado.connect(_alternar)


func esta_encendida() -> bool:
	return _encendida


func texto_accion() -> String:
	if _encendida:
		return "Apagar lámpara"
	return super.texto_accion()


func _alternar(_actor: Node) -> void:
	_encendida = not _encendida
	_luz.light_energy = ENERGIA_ENCENDIDA if _encendida else 0.0
	_luz.visible = _encendida
