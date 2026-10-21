## Regresión ejecutable del Hotel de los Olvidados (#2488).
##
## godot4 --headless --path godot --script pruebas/pruebas_hotel_olvidados.gd
## Prueba contratos reales; no necesita partidas guardadas ni acceso a red.
extends SceneTree

const CATALOGO = preload("res://guion/hotel_olvidados/catalogo_habitaciones.gd")
const SELECTOR = preload("res://guion/hotel_olvidados/selector_habitaciones.gd")
const HUB = preload("res://guion/hotel_olvidados/hub_hotel.gd")

var pasadas := 0
var fallos := 0


class HabitacionFalsa:
	extends Node3D

	var conectada := false
	var inmovil := false

	func connect_to_hub(nodo: Node3D) -> void:
		conectada = nodo != null

	func set_static(valor: bool) -> void:
		inmovil = valor


func _init() -> void:
	var catalogo_antes: Array = CATALOGO.CATALOGO.duplicate(true)
	_catalogo()
	_selector()
	_hub()
	_comprobar("hotel no cambia el catálogo global", CATALOGO.CATALOGO, catalogo_antes)

	print("Hotel de los Olvidados: %d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _catalogo() -> void:
	var habitaciones: Array = CATALOGO.CATALOGO
	_comprobar("hay exactamente cuatro habitaciones", habitaciones.size(), 4)

	var motivos := {}
	var campos := ["motivo", "visual", "sonido", "indicio", "salida"]
	for habitacion in habitaciones:
		for campo in campos:
			_comprobar(
				"habitación %s tiene %s" % [habitacion.get("motivo", "?"), campo],
				not str(habitacion.get(campo, "")).strip_edges().is_empty(),
				true
			)
		motivos[habitacion.get("motivo", "")] = true
	_comprobar("los cuatro motivos son únicos", motivos.size(), 4)


func _selector() -> void:
	for raiz in [0, 1, 98, 2488, -25]:
		for visita in range(-1, 7):
			var primera: Array = SELECTOR.seleccionar(raiz, visita)
			var segunda: Array = SELECTOR.seleccionar(raiz, visita)
			var indices: Array = SELECTOR.indices_seleccionados(raiz, visita)
			var motivos := []
			for habitacion in primera:
				motivos.append(habitacion.get("motivo", ""))
			_comprobar("selección de dos (%d,%d)" % [raiz, visita], primera.size(), 2)
			_comprobar("sin repetición (%d,%d)" % [raiz, visita], motivos[0] != motivos[1], true)
			_comprobar("repetible (%d,%d)" % [raiz, visita], primera, segunda)
			_comprobar(
				"dos índices distintos (%d,%d)" % [raiz, visita],
				indices.size() == 2 and indices[0] != indices[1],
				true
			)

	var visita_cero: Array = SELECTOR.indices_seleccionados(73, 0)
	var visita_uno: Array = SELECTOR.indices_seleccionados(73, 1)
	_comprobar("visitas contiguas rotan la pareja", visita_cero != visita_uno, true)
	_comprobar("cantidad cero no selecciona", SELECTOR.seleccionar(73, 0, 0), [])
	_comprobar("cantidad excesiva se limita al catálogo", SELECTOR.seleccionar(73, 0, 99).size(), 4)

	var copia: Array = SELECTOR.seleccionar(73, 0)
	var motivo_real: String = SELECTOR.seleccionar(73, 0)[0]["motivo"]
	copia[0]["motivo"] = "modificado durante la visita"
	_comprobar(
		"selector devuelve copias independientes",
		SELECTOR.seleccionar(73, 0)[0]["motivo"],
		motivo_real
	)


func _hub() -> void:
	var hotel := HUB.new()
	hotel.name = "HotelDePrueba"
	var habitacion := HabitacionFalsa.new()
	habitacion.name = "SalaDePrueba"
	hotel.add_child(habitacion)
	hotel.rooms = [NodePath("SalaDePrueba")]

	# Entrar en el árbol ejecuta _ready y construye colisión y geometría reales.
	root.add_child(hotel)
	_comprobar("la habitación queda conectada", habitacion.conectada, true)
	_comprobar("la habitación queda inmóvil", habitacion.inmovil, true)
	_comprobar("el corredor mantiene su modo estático", hotel.corridor_stable, true)

	for nombre in ["Suelo", "Muro_-1_-1", "Muro_-1_1", "Muro_1_-1", "Muro_1_1", "Fondo"]:
		var tramo := hotel.get_node_or_null(nombre)
		_comprobar("%s es sólido estático" % nombre, tramo is StaticBody3D, true)
		if tramo is StaticBody3D:
			_comprobar("%s tiene colisión" % nombre, tramo.get_child(0) is CollisionShape3D, true)
			_comprobar("%s tiene malla" % nombre, tramo.get_child(1) is MeshInstance3D, true)

	var sin_combate := true
	for nodo in hotel.get_children():
		if nodo is Area3D or nodo is RigidBody3D or nodo is CharacterBody3D:
			sin_combate = false
	_comprobar("el hub no incorpora entidades de combate", sin_combate, true)

	var salidas := [0]
	hotel.hotel_exited.connect(func(): salidas[0] += 1)
	var cancelar := InputEventAction.new()
	cancelar.action = "ui_cancel"
	cancelar.pressed = true
	hotel._unhandled_input(cancelar)
	_comprobar("cancelar abandona el hotel", salidas[0], 1)
	hotel.exit_hotel()
	_comprobar("salir dos veces no duplica la transición", salidas[0], 1)
	hotel.free()


func _comprobar(nombre: String, obtenido: Variant, esperado: Variant) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s: esperado=%s obtenido=%s" % [nombre, esperado, obtenido])
