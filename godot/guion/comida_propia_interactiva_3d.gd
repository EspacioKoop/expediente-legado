## Interacción física de comida propia para #93.
##
## No decide hambre ni economía: solo representa una cena sobre la encimera y
## expone feedback local. El controller de la casa es quien aplica la regla económica.
class_name ComidaPropiaInteractiva3D
extends Interactuable3D

const COLOR_PLATO := Color(0.66, 0.63, 0.54)
const COLOR_PAN := Color(0.58, 0.38, 0.20)
const COLOR_RELLENO := Color(0.32, 0.20, 0.14)

var _precio := 0
var _disponible := true
var _mensaje := ""
var _comida: Node3D


func configurar(precio: int) -> void:
	_precio = maxi(0, precio)
	verbo = Verbo.USAR
	nombre_objeto = "cena"
	sonido = "coger"

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.62, 0.30, 0.52)
	colision.position = Vector3(0.0, 0.12, 0.0)
	colision.shape = forma
	add_child(colision)

	var plato := MeshInstance3D.new()
	plato.name = "PlatoCena"
	var disco := CylinderMesh.new()
	disco.top_radius = 0.24
	disco.bottom_radius = 0.22
	disco.height = 0.025
	plato.mesh = disco
	plato.position = Vector3(0.0, 0.015, 0.0)
	Modelos._pintar(plato, COLOR_PLATO)
	add_child(plato)

	_comida = Node3D.new()
	_comida.name = "ComidaCena"
	_comida.position = Vector3(0.0, 0.07, 0.0)
	add_child(_comida)
	_agregar_caja(_comida, Vector3(-0.08, 0.03, 0.0), Vector3(0.20, 0.07, 0.24), COLOR_PAN)
	_agregar_caja(_comida, Vector3(0.08, 0.035, 0.0), Vector3(0.18, 0.075, 0.22), COLOR_RELLENO)


func disponible() -> bool:
	return _disponible


func consumir() -> void:
	_disponible = false
	_mensaje = "Ya has comido"
	if is_instance_valid(_comida):
		_comida.visible = false


func marcar_saciado() -> void:
	_disponible = false
	_mensaje = "No tienes hambre"


func marcar_sin_dinero() -> void:
	_mensaje = "No te alcanza para comer (%d)" % _precio


func texto_accion() -> String:
	if not _mensaje.is_empty():
		return _mensaje
	return "Comer algo (%d)" % _precio


static func _agregar_caja(raiz: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	Modelos._pintar(malla, color)
	raiz.add_child(malla)
