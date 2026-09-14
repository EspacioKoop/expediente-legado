extends Control

signal finalizada(resultado: Dictionary)

const PARTICIPANTES := ["jugador", "distancia", "papelera", "cunado"]
const MODALIDADES := ["distancia", "precision", "zona"]
const MODELOS := ["estable", "rapido", "impredecible"]
const PISTA := Rect2(70.0, 50.0, 560.0, 580.0)

var estado: Dictionary = {}

@onready var avion: Label = %Avion
@onready var modalidad: OptionButton = %Modalidad
@onready var modelo: OptionButton = %Modelo
@onready var direccion: HSlider = %Direccion
@onready var altura: HSlider = %Altura
@onready var potencia: HSlider = %Potencia
@onready var estado_label: Label = %Estado
@onready var marcador: Label = %Marcador
@onready var lanzar: Button = %Lanzar
@onready var abandonar: Button = %Abandonar


func _ready() -> void:
	for nombre in ["Distancia", "Precisión", "Zona"]:
		modalidad.add_item(nombre)
	for nombre in ["Estable", "Rápido", "Impredecible"]:
		modelo.add_item(nombre)
	modalidad.item_selected.connect(_al_cambiar_modalidad)
	lanzar.pressed.connect(_al_lanzar)
	abandonar.pressed.connect(_al_abandonar)
	_nueva_ronda()
	modelo.grab_focus()
	queue_redraw()


func _draw() -> void:
	draw_rect(PISTA, Color("c8c0ad"))
	draw_line(PISTA.position, PISTA.end, Color("797264"), 3.0)
	draw_line(
		Vector2(PISTA.end.x, PISTA.position.y),
		Vector2(PISTA.position.x, PISTA.end.y),
		Color("797264"),
		3.0
	)
	for indice in range(4):
		var y := PISTA.position.y + 90.0 + float(indice) * 120.0
		draw_rect(Rect2(PISTA.position.x + 14.0, y, 48.0, 26.0), Color("6d5f50"))
		draw_rect(Rect2(PISTA.end.x - 62.0, y, 48.0, 26.0), Color("5b6570"))
	var papelera := _proyectar(
		Vector3(
			AvionesPapel.OBJETIVO_PAPELERA.x,
			0.0,
			AvionesPapel.OBJETIVO_PAPELERA.y,
		)
	)
	draw_circle(papelera, 10.0, Color("40484d"))
	var objetivo := _proyectar(Vector3(AvionesPapel.OBJETIVO.x, 0.0, AvionesPapel.OBJETIVO.y))
	draw_circle(objetivo, 22.0, Color("76896b"), false, 3.0)


func _nueva_ronda() -> void:
	estado = AvionesPapel.nueva(PARTICIPANTES, MODALIDADES[modalidad.selected])
	modalidad.disabled = false
	modelo.disabled = false
	direccion.editable = true
	altura.editable = true
	potencia.editable = true
	abandonar.disabled = false
	lanzar.disabled = false
	lanzar.text = "Lanzar"
	avion.position = _origen_avion()
	estado_label.text = "Tu turno · lanzamiento 1/3"
	_actualizar_marcador()


func _al_cambiar_modalidad(indice: int) -> void:
	if _hay_lanzamientos():
		return
	estado = AvionesPapel.nueva(PARTICIPANTES, MODALIDADES[indice])
	_actualizar_marcador()


func _al_lanzar() -> void:
	if estado.get("terminada", false) or estado.get("abandonada", false):
		_nueva_ronda()
		return
	if int(estado.get("turno", 0)) != 0:
		return

	modalidad.disabled = true
	estado = AvionesPapel.lanzar(
		estado,
		MODELOS[modelo.selected],
		float(direccion.value),
		float(altura.value),
		float(potencia.value)
	)
	var vuelos: Array = estado["resultados"]["jugador"]
	var vuelo: Dictionary = vuelos.back()
	_animar_vuelo(vuelo)
	_actualizar_marcador()

	if int(estado.get("turno", 0)) > 0:
		_resolver_companeros()
	else:
		estado_label.text = "Tu turno · lanzamiento %d/3" % (int(estado["lanzamiento"]) + 1)


func _resolver_companeros() -> void:
	while not estado.get("terminada", false):
		var indice := int(estado.get("turno", 0))
		var participantes: Array = estado.get("participantes", [])
		if indice < 0 or indice >= participantes.size():
			break
		var participante := String(participantes[indice])
		estado = AvionesPapel.lanzar_companero(estado, participante)
	_terminar_ronda()


func _terminar_ronda() -> void:
	var resultado := AvionesPapel.resultado(estado)
	var ganador := String(resultado.get("ganador", "empate"))
	estado_label.text = "Ronda terminada · ganador: %s" % ganador
	lanzar.text = "Nueva ronda"
	modelo.disabled = true
	direccion.editable = false
	altura.editable = false
	potencia.editable = false
	abandonar.disabled = true
	_actualizar_marcador()
	finalizada.emit(resultado)


func _al_abandonar() -> void:
	if estado.get("terminada", false) or estado.get("abandonada", false):
		return
	var resultado := AvionesPapel.abandonar(estado)
	estado_label.text = "Ronda abandonada · el ciclo diario no cambia"
	lanzar.text = "Nueva ronda"
	modelo.disabled = true
	direccion.editable = false
	altura.editable = false
	potencia.editable = false
	abandonar.disabled = true
	finalizada.emit(resultado)


func _animar_vuelo(vuelo: Dictionary) -> void:
	var posicion: Vector3 = vuelo.get("posicion", Vector3.ZERO)
	var destino := _proyectar(posicion) - avion.size * 0.5
	avion.position = _origen_avion()
	var duracion := clampf(float(vuelo.get("tiempo", 0.0)) * 0.18, 0.25, 1.1)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(avion, "position", destino, duracion)
	estado_label.text = "%.1f m · %.0f precisión · %s" % [
		float(vuelo.get("distancia", 0.0)),
		float(vuelo.get("precision", 0.0)),
		String(vuelo.get("motivo", "aterrizaje")),
	]


func _actualizar_marcador() -> void:
	var resultado := AvionesPapel.resultado(estado)
	var puntuaciones: Dictionary = resultado.get("puntuaciones", {})
	marcador.text = "Marcador\nTú: %.1f\nDistancia: %.1f\nPapelera: %.1f\nCuñado: %.1f" % [
		float(puntuaciones.get("jugador", 0.0)),
		float(puntuaciones.get("distancia", 0.0)),
		float(puntuaciones.get("papelera", 0.0)),
		float(puntuaciones.get("cunado", 0.0)),
	]


func _hay_lanzamientos() -> bool:
	for vuelos in estado.get("resultados", {}).values():
		if not vuelos.is_empty():
			return true
	return false


func _origen_avion() -> Vector2:
	return Vector2(PISTA.get_center().x - avion.size.x * 0.5, PISTA.end.y - 36.0)


func _proyectar(posicion: Vector3) -> Vector2:
	var x := remap(
		posicion.x,
		-AvionesPapel.LIMITE_LATERAL,
		AvionesPapel.LIMITE_LATERAL,
		PISTA.position.x + 40.0,
		PISTA.end.x - 40.0
	)
	var y := remap(
		clampf(posicion.z, 0.0, AvionesPapel.LIMITE_FONDO),
		0.0,
		AvionesPapel.LIMITE_FONDO,
		PISTA.end.y - 40.0,
		PISTA.position.y + 40.0
	)
	return Vector2(x, y)
