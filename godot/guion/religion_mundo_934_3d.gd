## Superficies físicas y práctica presencial del primer corte de #934.
##
## No usa iconografía de una tradición viva ni assets externos. La geometría es
## procedural y el mismo gesto registra exactamente el mismo hecho con o sin
## reducción de movimiento.
class_name ReligionMundo9343D
extends Node3D

signal practica_registrada(id_practica: String)

const Mundo = preload("res://guion/religion_mundo_934.gd")

var _registro: Dictionary = {}
var _dia := 0
var _reduccion_movimiento := false


func configurar(registro: Dictionary, dia: int, reduccion_movimiento: bool = false) -> void:
	_registro = registro
	_dia = dia
	_reduccion_movimiento = reduccion_movimiento
	if get_node_or_null("CulturaMaterial") == null:
		_montar_superficies()
	var practica := practica_interactuable()
	if practica != null:
		practica.habilitado = Mundo.actividad_disponible(Mundo.ID_ACTO_MEMORIA, _dia)


func tablon_interactuable() -> Interactuable3D:
	return get_node_or_null("CulturaMaterial/TablonCalendario/Interactuar") as Interactuable3D


func practica_interactuable() -> Interactuable3D:
	return get_node_or_null("CulturaMaterial/MesaRecuerdo/Practica") as Interactuable3D


func reduccion_movimiento_activa() -> bool:
	return _reduccion_movimiento


func _montar_superficies() -> void:
	var raiz := Node3D.new()
	raiz.name = "CulturaMaterial"
	add_child(raiz)
	_montar_tablon(raiz)
	_montar_mesa(raiz)


func _montar_tablon(padre: Node3D) -> void:
	var tablon := Node3D.new()
	tablon.name = "TablonCalendario"
	padre.add_child(tablon)
	_caja(
		tablon,
		"Corcho",
		Vector3(-1.65, 1.55, 0.0),
		Vector3(1.5, 1.05, 0.10),
		Color(0.42, 0.24, 0.11)
	)
	for indice in 4:
		_caja(
			tablon,
			"Papel%d" % indice,
			Vector3(-2.05 + indice * 0.27, 1.55 + (indice % 2) * 0.18, -0.06),
			Vector3(0.22, 0.30, 0.015),
			Color(0.80, 0.77, 0.66)
		)
	var zona := _zona_interactiva(
		tablon,
		"Interactuar",
		Vector3(-1.65, 1.50, -0.32),
		Vector3(1.6, 1.2, 0.55),
		Interactuable3D.Verbo.EXAMINAR
	)
	zona.activado.connect(_on_tablon_activado)


func _montar_mesa(padre: Node3D) -> void:
	var mesa := Node3D.new()
	mesa.name = "MesaRecuerdo"
	padre.add_child(mesa)
	_caja(
		mesa, "Tablero", Vector3(1.55, 0.82, 0.0), Vector3(1.4, 0.10, 0.75), Color(0.28, 0.18, 0.10)
	)
	_caja(
		mesa, "PataA", Vector3(1.05, 0.40, 0.0), Vector3(0.10, 0.80, 0.55), Color(0.24, 0.15, 0.08)
	)
	_caja(
		mesa, "PataB", Vector3(2.05, 0.40, 0.0), Vector3(0.10, 0.80, 0.55), Color(0.24, 0.15, 0.08)
	)
	_caja(
		mesa,
		"LibroMemoria",
		Vector3(1.55, 0.91, -0.02),
		Vector3(0.52, 0.05, 0.38),
		Color(0.72, 0.69, 0.57)
	)
	var zona := _zona_interactiva(
		mesa,
		"Practica",
		Vector3(1.55, 1.05, -0.35),
		Vector3(1.5, 1.2, 0.70),
		Interactuable3D.Verbo.USAR
	)
	zona.activado.connect(_on_practica_activada)


func _on_tablon_activado(_actor: Node) -> void:
	Mundo.registrar_exposicion(_registro, "tablon_calendario", _dia)


func _on_practica_activada(_actor: Node) -> void:
	if Mundo.registrar_practica(_registro, "silencio_memoria", _dia):
		practica_registrada.emit("silencio_memoria")


static func _zona_interactiva(
	padre: Node3D, nombre: String, posicion: Vector3, tamano: Vector3, verbo: int
) -> Interactuable3D:
	var zona := Interactuable3D.new()
	zona.name = nombre
	zona.verbo = verbo
	zona.nombre_objeto = ""
	zona.sonido = Interactuable3D.SIN_SONIDO
	zona.position = posicion
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamano
	colision.shape = forma
	zona.add_child(colision)
	padre.add_child(zona)
	return zona


static func _caja(
	padre: Node3D, nombre: String, posicion: Vector3, tamano: Vector3, color: Color
) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.name = nombre
	var caja := BoxMesh.new()
	caja.size = tamano
	malla.mesh = caja
	malla.position = posicion
	malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	malla.material_override = material
	padre.add_child(malla)
	return malla
