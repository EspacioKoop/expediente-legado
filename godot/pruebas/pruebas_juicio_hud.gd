class_name PruebasJuicioHud
extends RefCounted


static func todo(comprobar: Callable) -> void:
	_caso(
		comprobar,
		"hud: compone ritual contra doctrina y compromiso",
		(
			JuicioCombateHud
			. texto_ritual(
				{"nombre": "Balanza"},
				2,
				"Asamblea",
				true,
				"COMPROMISO",
			)
		),
		"RITUAL · Balanza · CONTRA +2 · Asamblea · COMPROMISO",
	)

	var barra_jugador := ProgressBar.new()
	var barra_rival := ProgressBar.new()
	var etiqueta := Label.new()
	var actualizada := JuicioCombateHud.actualizar_determinacion(
		barra_jugador, barra_rival, etiqueta, 5, 3, "ESTADO"
	)
	_caso(comprobar, "hud: actualiza determinación del jugador", barra_jugador.value, 5.0)
	_caso(comprobar, "hud: actualiza determinación del rival", barra_rival.value, 3.0)
	_caso(comprobar, "hud: actualiza texto ritual", etiqueta.text, "ESTADO")
	_caso(comprobar, "hud: confirma actualización completa", actualizada, true)

	var momentum := ProgressBar.new()
	var finisher := Button.new()
	(
		JuicioCombateHud
		. actualizar_jungiano(
			momentum,
			finisher,
			{
				"momentum_max": 120.0,
				"momentum_actual": 45.0,
				"disponible": true,
				"es_super": true,
			},
			false,
			"FINISHER",
			"SUPER",
		)
	)
	_caso(comprobar, "hud: actualiza momentum máximo", momentum.max_value, 120.0)
	_caso(comprobar, "hud: actualiza momentum actual", momentum.value, 45.0)
	_caso(comprobar, "hud: habilita finisher disponible", finisher.disabled, false)
	_caso(comprobar, "hud: distingue super finisher", finisher.text, "SUPER")

	var doctrinas := HBoxContainer.new()
	JuicioCombateHud.pintar_doctrinas(
		doctrinas,
		{"comunismo": 2},
		true,
		["comunismo", "centrista"],
		{
			"comunismo": {"nombre": "ASAMBLEA", "efecto": "EFECTO"},
			"centrista": {"nombre": "MESA", "efecto": "OTRO"},
		},
		func(texto): return "T:" + String(texto),
		func(_eje): pass,
	)
	_caso(comprobar, "hud: crea solo doctrinas con carga", doctrinas.get_child_count(), 1)
	var boton := doctrinas.get_child(0) as Button
	_caso(comprobar, "hud: muestra cantidad de cargas", boton.text, "T:ASAMBLEA ×2")
	_caso(comprobar, "hud: traduce tooltip", boton.tooltip_text, "T:EFECTO")
	_caso(comprobar, "hud: respeta bloqueo", boton.disabled, true)

	barra_jugador.free()
	barra_rival.free()
	etiqueta.free()
	momentum.free()
	finisher.free()
	doctrinas.free()


static func _caso(comprobar: Callable, nombre: String, obtenido, esperado) -> void:
	comprobar.call(nombre, obtenido, esperado)
