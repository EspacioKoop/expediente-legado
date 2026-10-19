## Timeline aislada para scrub y reproducción de los planos del editor.
extends HBoxContainer

signal muestra_cambiada(indice: int, avance: float)

var _planos: Array = []
var _duracion_total := 0.0
var _tiempo_actual := 0.0
var _reproduciendo := false
var _refrescando := false
var _permite_edicion := false
var _boton: Button
var _scrub: HSlider
var _etiqueta: Label


func _ready() -> void:
	_montar()


func _process(delta: float) -> void:
	if not _reproduciendo:
		return
	var siguiente := _tiempo_actual + delta
	if siguiente >= _duracion_total:
		_establecer_tiempo(_duracion_total)
		_reproduciendo = false
		_actualizar_interfaz()
		return
	_establecer_tiempo(siguiente)


func _montar() -> void:
	_boton = Button.new()
	_boton.text = "▶ Reproducir"
	_boton.pressed.connect(alternar_reproduccion)
	add_child(_boton)
	_scrub = HSlider.new()
	_scrub.min_value = 0.0
	_scrub.max_value = 0.1
	_scrub.step = 0.01
	_scrub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scrub.value_changed.connect(_al_mover_scrub)
	add_child(_scrub)
	_etiqueta = Label.new()
	_etiqueta.text = "0.00 / 0.00 s"
	_etiqueta.custom_minimum_size.x = 180
	add_child(_etiqueta)


func configurar(planos: Array, permite_edicion: bool) -> void:
	_reproduciendo = false
	_planos = planos
	_permite_edicion = permite_edicion
	_duracion_total = 0.0
	if _permite_edicion:
		for plano in _planos:
			if plano is Dictionary:
				_duracion_total += maxf(float(plano.get("segundos", 0.0)), 0.0)
	_tiempo_actual = clampf(_tiempo_actual, 0.0, _duracion_total)
	_refrescando = true
	_scrub.editable = _duracion_total > 0.0
	_scrub.max_value = maxf(_duracion_total, 0.1)
	_scrub.value = _tiempo_actual
	_refrescando = false
	_actualizar_interfaz()
	_emitir_muestra()


func seleccionar_plano(indice: int) -> void:
	if indice < 0 or indice >= _planos.size():
		return
	_establecer_tiempo(_inicio_plano(indice))


func muestra_actual() -> Dictionary:
	return muestra_en(_tiempo_actual)


func muestra_en(tiempo: float) -> Dictionary:
	var acumulado := 0.0
	for indice in _planos.size():
		var plano: Variant = _planos[indice]
		if not plano is Dictionary:
			continue
		var duracion := maxf(float(plano.get("segundos", 0.0)), 0.0)
		if duracion <= 0.0:
			continue
		var final_plano := acumulado + duracion
		if (
			tiempo < final_plano
			or indice == _planos.size() - 1
			or (tiempo >= _duracion_total and final_plano >= _duracion_total)
		):
			return {"indice": indice, "avance": clampf((tiempo - acumulado) / duracion, 0.0, 1.0)}
		acumulado = final_plano
	return {"indice": -1, "avance": 0.0}


func duracion_total() -> float:
	return _duracion_total


func tiempo_actual() -> float:
	return _tiempo_actual


func alternar_reproduccion() -> void:
	if _reproduciendo:
		_reproduciendo = false
	elif _duracion_total > 0.0:
		if _tiempo_actual >= _duracion_total:
			_establecer_tiempo(0.0)
		_reproduciendo = true
	_actualizar_interfaz()


func pausar() -> void:
	_reproduciendo = false
	_actualizar_interfaz()


func _al_mover_scrub(valor: float) -> void:
	if _refrescando:
		return
	_tiempo_actual = clampf(valor, 0.0, _duracion_total)
	_actualizar_interfaz()
	_emitir_muestra()


func _establecer_tiempo(valor: float) -> void:
	_tiempo_actual = clampf(valor, 0.0, _duracion_total)
	_refrescando = true
	_scrub.value = _tiempo_actual
	_refrescando = false
	_actualizar_interfaz()
	_emitir_muestra()


func _emitir_muestra() -> void:
	var muestra := muestra_actual()
	muestra_cambiada.emit(int(muestra["indice"]), float(muestra["avance"]))


func _actualizar_interfaz() -> void:
	_boton.text = "⏸ Pausar" if _reproduciendo else "▶ Reproducir"
	_boton.disabled = _duracion_total <= 0.0
	var muestra := muestra_actual()
	var texto := "%.2f / %.2f s" % [_tiempo_actual, _duracion_total]
	if int(muestra["indice"]) >= 0:
		var plano: Dictionary = _planos[int(muestra["indice"])]
		texto += " · Plano %d" % (int(muestra["indice"]) + 1)
		if String(plano.get("tipo", "3d")) != "3d":
			texto += " · plano 2D sin vista previa"
	_etiqueta.text = texto


func _inicio_plano(indice_buscado: int) -> float:
	var acumulado := 0.0
	for indice in mini(indice_buscado, _planos.size()):
		var plano: Variant = _planos[indice]
		if plano is Dictionary:
			acumulado += maxf(float(plano.get("segundos", 0.0)), 0.0)
	return acumulado
