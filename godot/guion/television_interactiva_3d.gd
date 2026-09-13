## Capa de interacción para el televisor real ya declarado en la casa (#283).
##
## No crea otro televisor: CasaUtileria coloca este Area3D en el bulto
## `televisionVintage` del catálogo y conserva ese modelo como representación.
## El encendido es feedback local; no persiste ni altera Jornada o Partida.
class_name TelevisionInteractiva3D
extends Interactuable3D

var _encendida := false
var _brillo: OmniLight3D


func configurar(tam: Vector3) -> void:
	verbo = Verbo.ENCENDER
	nombre_objeto = "televisor"

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam + Vector3(0.12, 0.12, 0.12)
	colision.shape = forma
	add_child(colision)

	_brillo = OmniLight3D.new()
	_brillo.name = "BrilloTelevisor"
	_brillo.position = Vector3(0.0, tam.y * 0.08, -tam.z * 0.42)
	_brillo.omni_range = 2.6
	_brillo.light_energy = 0.75
	_brillo.light_color = Color(0.58, 0.70, 0.82)
	_brillo.visible = false
	add_child(_brillo)

	activado.connect(_alternar)


func esta_encendida() -> bool:
	return _encendida


func texto_accion() -> String:
	if _encendida:
		return "Apagar televisor"
	return super.texto_accion()


func _alternar(_actor: Node) -> void:
	_encendida = not _encendida
	_brillo.visible = _encendida
