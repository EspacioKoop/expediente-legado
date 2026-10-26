## Vertical jugable de la catedral invertida (#2431).
##
## El jugador recorre dos sellos físicos en lados opuestos de una nave,
## reorienta la arquitectura existente y abre una salida real. El suelo de
## seguridad NO gira: no cambiamos ni gravedad ni cámara ni locomoción global.
## No concede pistas, objetos ni estado de campaña; el selector nocturno puede
## escuchar recorrido_completado cuando decida integrar este vertical.
class_name CatedralInvertidaRecorrido3D
extends Node3D

signal recorrido_completado

const CAMINANTE_ESCENA := preload("res://escenas/caminante.tscn")
const PUNTOS := [
	Vector3(-3.0, 1.0, -1.8),
	Vector3(3.0, 1.0, -1.8),
	Vector3(0.0, 1.0, -2.8),
]
const ETIQUETAS := ["el sello de la izquierda", "el sello de la derecha", "el umbral de salida"]
const ALCANCE := 2.35
const COLOR_APAGADO := Color(0.22, 0.24, 0.29)
const COLOR_ACTIVO := Color(0.76, 0.56, 0.27)
const COLOR_FINAL := Color(0.41, 0.82, 0.69)

@export var demo_autonoma := false
@export var reduccion_movimiento := false

var _catedral: CatedralInvertida3D
var _actor: Node3D
var _sellos: Array[Interactuable3D] = []
var _paso := 0
var _montado := false
var _hud: HUDLayer
var _estado_texto: Label


func _ready() -> void:
	if demo_autonoma:
		var caminante := CAMINANTE_ESCENA.instantiate() as CharacterBody3D
		add_child(caminante)
		caminante.position = Vector3(0.0, 0.95, 2.5)
		montar_para(caminante)


## Entrada reusable: el propietario de la jornada aporta su caminante existente.
## En el .tscn autónomo se crea uno idéntico al de la partida para poder jugar.
func montar_para(actor: Node3D) -> bool:
	if _montado or actor == null or not is_instance_valid(actor):
		return false
	_actor = actor
	_montado = true
	_catedral = CatedralInvertida3D.new()
	_catedral.name = "NaveRotatoria"
	_catedral.reduccion_movimiento = reduccion_movimiento
	add_child(_catedral)
	_catedral.preparar()
	_montar_suelo_estable()
	_montar_limites_estables()
	_montar_luz()
	for indice in PUNTOS.size():
		_crear_sello(indice)
	_montar_hud()
	_actualizar_sellos()
	return true


func paso_actual() -> int:
	return _paso


func completado() -> bool:
	return _paso == PUNTOS.size()


func sello(indice: int) -> Interactuable3D:
	if indice < 0 or indice >= _sellos.size():
		return null
	return _sellos[indice]


func nave() -> CatedralInvertida3D:
	return _catedral


func suelo_seguro() -> StaticBody3D:
	return get_node_or_null("SueloSeguro") as StaticBody3D


func _montar_suelo_estable() -> void:
	# Este collider se queda en el mundo, fuera del contenedor que rota.
	var base := StaticBody3D.new()
	base.name = "SueloSeguro"
	base.position = Vector3(0.0, -0.12, 0.0)
	add_child(base)
	var forma := BoxShape3D.new()
	forma.size = Vector3(11.0, 0.24, 7.4)
	var colision := CollisionShape3D.new()
	colision.shape = forma
	base.add_child(colision)
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = forma.size
	malla.mesh = caja
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.13, 0.15, 0.18)
	material.roughness = 0.93
	malla.material_override = material
	base.add_child(malla)


func _montar_limites_estables() -> void:
	# Las paredes visuales rotan; cuatro colliders fijos evitan que el actor
	# abandone el área segura durante cualquiera de las dos orientaciones.
	var bordes := [
		{"nombre": "LimiteOeste", "pos": Vector3(-5.46, 1.6, 0.0), "tam": Vector3(0.24, 3.2, 7.1)},
		{"nombre": "LimiteEste", "pos": Vector3(5.46, 1.6, 0.0), "tam": Vector3(0.24, 3.2, 7.1)},
		{"nombre": "LimiteNorte", "pos": Vector3(0.0, 1.6, -3.46), "tam": Vector3(11.1, 3.2, 0.24)},
		{"nombre": "LimiteSur", "pos": Vector3(0.0, 1.6, 3.46), "tam": Vector3(11.1, 3.2, 0.24)},
	]
	for borde in bordes:
		var pared := StaticBody3D.new()
		pared.name = String(borde["nombre"])
		pared.position = borde["pos"]
		add_child(pared)
		var colision := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = borde["tam"]
		colision.shape = forma
		pared.add_child(colision)


func _montar_luz() -> void:
	var luz := DirectionalLight3D.new()
	luz.name = "ClaridadDeLaNave"
	luz.rotation_degrees = Vector3(-58.0, 28.0, 0.0)
	luz.light_energy = 1.15
	luz.shadow_enabled = false
	add_child(luz)


func _crear_sello(indice: int) -> void:
	var sello_nodo := Interactuable3D.new()
	sello_nodo.name = "Sello%d" % (indice + 1) if indice < 2 else "UmbralSalida"
	sello_nodo.position = PUNTOS[indice]
	sello_nodo.verbo = Interactuable3D.Verbo.USAR if indice < 2 else Interactuable3D.Verbo.ABRIR
	sello_nodo.nombre_objeto = ETIQUETAS[indice]
	sello_nodo.sonido = Interactuable3D.SIN_SONIDO
	var choque := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.72
	choque.shape = esfera
	sello_nodo.add_child(choque)

	var marca := MeshInstance3D.new()
	marca.name = "Marca"
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.36
	cilindro.bottom_radius = 0.46
	cilindro.height = 1.35
	marca.mesh = cilindro
	sello_nodo.add_child(marca)

	var luz := OmniLight3D.new()
	luz.name = "LuzSello"
	luz.omni_range = 2.5
	luz.shadow_enabled = false
	sello_nodo.add_child(luz)
	add_child(sello_nodo)
	sello_nodo.activado.connect(_activar_sello.bind(indice))
	_sellos.append(sello_nodo)


func _activar_sello(origen: Node, indice: int) -> void:
	if _actor == null or indice != _paso or completado():
		return
	# DetectorInteraccion3D envía la cámara; no autorizar activaciones remotas
	# desde scripts, enemigos o desde otro caminante.
	if origen != _actor and origen != _actor.get_node_or_null("Camara"):
		return
	if _actor.global_position.distance_to(_sellos[indice].global_position) > ALCANCE:
		return

	_paso += 1
	if indice < 2:
		# El tween gira arquitectura, no la plataforma, el actor ni la cámara.
		_catedral.avanzar()
	_actualizar_sellos()
	if completado():
		recorrido_completado.emit()


func _actualizar_sellos() -> void:
	for indice in _sellos.size():
		var objetivo := _sellos[indice]
		var activo := indice == _paso
		objetivo.habilitado = activo
		var color := (COLOR_FINAL if indice == 2 else COLOR_ACTIVO) if activo else COLOR_APAGADO
		var marca := objetivo.get_node("Marca") as MeshInstance3D
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = activo
		material.emission = color
		material.emission_energy_multiplier = 0.75
		marca.material_override = material
		var luz := objetivo.get_node("LuzSello") as OmniLight3D
		luz.light_color = color
		luz.light_energy = 0.95 if activo else 0.12
	if _estado_texto != null:
		var mensajes := [
			"CATEDRAL INVERTIDA — Activa el primer sello (ala izquierda)",
			"PRIMER GIRO — Cruza la nave y activa el sello derecho",
			"SEGUNDO GIRO — El umbral está abierto. Busca la salida",
			"CATEDRAL SUPERADA — Has atravesado los dos giros",
		]
		_estado_texto.text = mensajes[_paso]


func _montar_hud() -> void:
	# La demo usa el mismo árbitro HUD que la jornada: el prompt de interacción
	# permanece debajo de las indicaciones, con teclado y mando remapeables.
	if not _actor.has_method("conectar_hud"):
		return
	_hud = HUDLayer.new()
	_hud.name = "HudCatedral"
	add_child(_hud)
	_estado_texto = Label.new()
	_estado_texto.name = "ObjetivoCatedral"
	_estado_texto.position = Vector2(24.0, 20.0)
	_estado_texto.add_theme_font_size_override("font_size", 24)
	_estado_texto.add_theme_color_override("font_color", Color(0.91, 0.88, 0.79))
	_hud.add_child(_estado_texto)
	_hud.registrar(HUDLayer.ESTADO, _estado_texto)
	_hud.activar(HUDLayer.ESTADO)
	_actor.call("conectar_hud", _hud)
