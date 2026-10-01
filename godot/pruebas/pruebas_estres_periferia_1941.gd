extends SceneTree

var fallos := 0

func _init() -> void:
	var periferia := EstresPeriferia.new()
	root.add_child(periferia)
	periferia.sincronizar(0.0)
	_comprobar(not periferia.visible, "nivel cero oculta el efecto")
	_comprobar(is_zero_approx(periferia.intensidad()), "nivel cero tiene alpha cero")
	periferia.sincronizar(0.5)
	var media := periferia.intensidad()
	_comprobar(periferia.visible and media > 0.0, "nivel medio muestra efecto")
	periferia.sincronizar(1.0)
	_comprobar(periferia.intensidad() > media, "intensidad es monotónica")
	_comprobar(periferia.intensidad() <= EstresPeriferia.ALPHA_MAX, "intensidad queda acotada")
	periferia.sincronizar(2.0)
	_comprobar(is_equal_approx(periferia.intensidad(), EstresPeriferia.ALPHA_MAX), "nivel alto se limita")
	periferia.sincronizar(-1.0, true)
	_comprobar(not periferia.visible, "nivel negativo se limita a cero también con reducción de movimiento")
	periferia.queue_free()
	quit(fallos)

func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		return
	fallos += 1
	push_error("#1941: " + mensaje)
