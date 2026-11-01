## Regresión headless de la guía de lectura de SIGA-98 (#2967).
## Construye el visor real sin cargar/guardar partidas del usuario.
extends SceneTree

const Visor := preload("res://guion/visor_pronosticos_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var visor := Visor.new()
	visor.theme = EstiloSiga.tema()
	_comprobar(visor.contenido.cargar(), "abre el catálogo real")
	visor.caso = visor.contenido.casos[0]
	visor.partida.estado = Partida.nueva()
	visor.jornada = visor.partida.estado["jornada"]
	visor.descubiertas = visor.partida.estado["pistas_descubiertas"]
	visor._construir()

	_comprobar(visor._guia_lectura != null, "el visor incorpora la guía visible")
	_comprobar(
		visor._boton_siguiente_folio.pressed.is_connected(
			Callable(visor, "_abrir_siguiente_folio")
		),
		"el botón usa el handler del visor",
	)
	_comprobar(
		visor._guia_lectura.text.contains("PASO 1/3"), "primero orienta a abrir un folio"
	)
	_comprobar(
		visor._indice_folio_pendiente() == 0, "el primer folio pendiente es el primero"
	)
	_comprobar(
		not visor._boton_siguiente_folio.disabled, "la primera lectura es accesible"
	)
	_comprobar(
		visor._lista.item_count == visor.caso["registros"].size(),
		"la guía no oculta los documentos ni los altera",
	)

	var primero: Dictionary = visor.caso["registros"][0]
	var segundo: Dictionary = visor.caso["registros"][1]
	visor.jornada["leido_hoy"] = [primero["folio"]]
	visor.jornada["leidos_total"] = [primero["id"]]
	visor._refrescar_estado()
	_comprobar(
		visor._indice_folio_pendiente() == 1, "el siguiente folio se calcula desde Jornada"
	)
	_comprobar(
		visor._guia_lectura.text.contains("PASO 2/3"), "la guía pide comparar otro folio"
	)
	_comprobar(visor._reconstruir.disabled, "la guía no desbloquea reconstruir antes de tiempo")

	visor.jornada["leido_hoy"].append(segundo["folio"])
	visor.jornada["leidos_total"].append(segundo["id"])
	visor._refrescar_estado()
	_comprobar(
		visor._guia_lectura.text.contains("PASO 3/3"), "sugiere reconstruir tras dos lecturas"
	)
	_comprobar(not visor._reconstruir.disabled, "reconstruir se activa por las reglas existentes")
	_comprobar(visor.partida.estado["veredictos"].is_empty(), "la guía nunca firma una acusación")

	for registro in visor.caso["registros"]:
		if not visor.jornada["leido_hoy"].has(registro["folio"]):
			visor.jornada["leido_hoy"].append(registro["folio"])
		if not visor.jornada["leidos_total"].has(registro["id"]):
			visor.jornada["leidos_total"].append(registro["id"])
	visor._refrescar_estado()
	_comprobar(visor._indice_folio_pendiente() == -1, "no repite folios ya leídos hoy")
	_comprobar(visor._boton_siguiente_folio.disabled, "se desactiva cuando no quedan folios")

	visor.jornada["leido_hoy"] = []
	visor._refrescar_estado()
	_comprobar(
		visor._indice_folio_pendiente() == 0, "otro día permite proponer relecturas"
	)
	_comprobar(
		visor._boton_siguiente_folio.text == "Releer folio", "identifica la relectura"
	)
	_comprobar(
		visor._guia_lectura.accessibility_name == visor._guia_lectura.text,
		"la instrucción también es accesible",
	)
	visor.free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("GuiaSiga2967: " + mensaje)
