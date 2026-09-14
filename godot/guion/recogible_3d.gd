class_name Recogible3D
extends "res://guion/interactuable_3d.gd"

## Puente entre un prop interactivo del escenario y el inventario (#97).
##
## El nodo puede colocarse sobre cualquier prop 3D. Si la escena no aporta un
## CollisionShape3D crea un volumen de interacción sencillo para que el objeto
## no dependa de una malla concreta.
signal recogido(objeto: Dictionary, actor: Node)

@export var objeto_id := ""
@export var vendible := false
@export var precio := 0
@export var origen := "escenario"
@export var radio_interaccion := 0.55
@export var metadatos: Dictionary = {}

var estado_inventario: Dictionary = Inventario.nuevo()


func _ready() -> void:
	verbo = Verbo.COGER
	_asegurar_volumen_interaccion()


func configurar(estado: Dictionary, datos_objeto: Dictionary = {}) -> void:
	estado_inventario = estado
	Inventario.completar(estado_inventario)
	if datos_objeto.is_empty():
		return

	metadatos = datos_objeto.duplicate(true)
	objeto_id = String(datos_objeto.get("id", objeto_id))
	nombre_objeto = String(datos_objeto.get("nombre", nombre_objeto))
	vendible = bool(datos_objeto.get("vendible", vendible))
	precio = int(datos_objeto.get("precio", precio))
	origen = String(datos_objeto.get("origen", origen))


func datos_objeto() -> Dictionary:
	var objeto := metadatos.duplicate(true)
	objeto["id"] = objeto_id
	objeto["nombre"] = nombre_objeto
	objeto["vendible"] = vendible
	objeto["precio"] = precio
	objeto["origen"] = origen
	return objeto


func interactuar(actor: Node) -> bool:
	Inventario.completar(estado_inventario)
	var objeto := datos_objeto()
	var id := String(objeto.get("id", ""))

	# No emitimos `activado` si el objeto no puede recogerse: una interacción
	# fallida debe dejar el prop disponible en el mundo.
	if id.is_empty() or Inventario.contiene(estado_inventario, id):
		return false
	if not super.interactuar(actor):
		return false
	if not Inventario.recoger(estado_inventario, objeto):
		return false

	recogido.emit(objeto.duplicate(true), actor)
	queue_free()
	return true


func _asegurar_volumen_interaccion() -> void:
	if not find_children("*", "CollisionShape3D", true, false).is_empty():
		return
	var colision := CollisionShape3D.new()
	colision.name = "VolumenInteraccion"
	var forma := SphereShape3D.new()
	forma.radius = maxf(0.05, radio_interaccion)
	colision.shape = forma
	add_child(colision)
