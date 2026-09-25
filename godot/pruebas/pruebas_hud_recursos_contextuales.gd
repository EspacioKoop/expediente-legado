extends SceneTree

const ControladorHUD := preload("res://guion/dia_hud_fases_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_archivo()
	_probar_trayecto()
	_probar_casa()
	_probar_sueno()
	_probar_prioridades()
	print("hud_recursos: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _estado(fase: String) -> Dictionary:
	var jornada := Jornada.nueva(397)
	jornada["fase"] = fase
	jornada["dia"] = 10
	jornada["dinero"] = 725
	jornada["acciones"] = 1
	jornada["hora_minutos"] = 11 * 60 + 30
	var inventario := Inventario.nuevo()
	Inventario.recoger(inventario, {"id": "llaves"})
	Inventario.recoger(inventario, {"id": "foto_guardada"})
	Inventario.guardar_en_casa(inventario, "foto_guardada")
	return {
		"jornada": jornada,
		"pistas_descubiertas": ["pista-a", "pista-b"],
		"inventario": inventario,
	}


func _probar_archivo() -> void:
	var estado := _estado("archivo")
	var modelo := ControladorHUD.modelo_recursos(estado)
	_comprobar(bool(modelo.get("visible", false)), "archivo muestra recursos")
	_comprobar(modelo.get("fase", "") == "archivo", "archivo conserva el contexto")
	_comprobar(modelo.get("acciones", -1) == 1, "archivo muestra acciones disponibles")
	_comprobar(modelo.get("dinero", -1) == 725, "archivo muestra dinero real")
	_comprobar(modelo.get("pistas", -1) == 2, "archivo cuenta pistas descubiertas")
	_comprobar(modelo.get("lecturas_gratis", -1) == 1, "archivo anuncia la lectura gratuita")

	estado["jornada"]["leido_hoy"].append("folio-a")
	modelo = ControladorHUD.modelo_recursos(estado)
	_comprobar(modelo.get("lecturas_gratis", -1) == 0, "la lectura gratuita desaparece al gastarla")


func _probar_trayecto() -> void:
	var estado := _estado("trayecto")
	var modelo := ControladorHUD.modelo_recursos(estado)
	_comprobar(bool(modelo.get("visible", false)), "trayecto muestra recursos")
	_comprobar(modelo.get("acciones", -1) == 1, "trayecto conserva la acción útil para alquiler")
	_comprobar(modelo.get("objetos", -1) == 1, "trayecto solo cuenta objetos llevados encima")
	_comprobar(bool(modelo.get("alquiler_hoy", false)), "el vencimiento de hoy se anticipa")
	_comprobar(
		modelo.get("alquiler_importe", -1) == Jornada.PRECIO_ALQUILER,
		"el HUD usa el precio canónico del alquiler"
	)

	estado["jornada"]["alquiler"]["ultimo_resuelto"] = 10
	modelo = ControladorHUD.modelo_recursos(estado)
	_comprobar(not bool(modelo.get("alquiler_hoy", true)), "alquiler resuelto deja de avisar")


func _probar_casa() -> void:
	var estado := _estado("casa")
	var modelo := ControladorHUD.modelo_recursos(estado)
	_comprobar(bool(modelo.get("visible", false)), "casa muestra recursos")
	_comprobar(modelo.get("objetos", -1) == 2, "casa suma mochila y almacenamiento doméstico")
	_comprobar(not modelo.has("acciones"), "casa no enseña acciones laborales irrelevantes")


func _probar_sueno() -> void:
	var estado := _estado("sueño")
	var modelo := ControladorHUD.modelo_recursos(estado)
	_comprobar(not bool(modelo.get("visible", true)), "sueño oculta la economía despierta")


func _probar_prioridades() -> void:
	var hud := HUDLayer.new()
	hud.activar(HUDLayer.RECURSOS)
	_comprobar(hud.debe_ser_visible(HUDLayer.RECURSOS), "recursos visibles sin mensaje primario")

	hud.activar(HUDLayer.INTERACCION)
	_comprobar(hud.debe_ser_visible(HUDLayer.RECURSOS), "recursos conviven con prompt breve")
	hud.activar(HUDLayer.TUTORIAL)
	_comprobar(not hud.debe_ser_visible(HUDLayer.RECURSOS), "tutorial despeja la banda de recursos")
	hud.desactivar(HUDLayer.TUTORIAL)
	hud.activar(HUDLayer.FASE)
	_comprobar(not hud.debe_ser_visible(HUDLayer.RECURSOS), "tarjeta de fase despeja recursos")
	hud.desactivar(HUDLayer.FASE)
	hud.activar(HUDLayer.DIALOGO)
	_comprobar(not hud.debe_ser_visible(HUDLayer.RECURSOS), "diálogo despeja recursos")
	hud.desactivar(HUDLayer.DIALOGO)
	hud.activar(HUDLayer.MODAL)
	_comprobar(not hud.debe_ser_visible(HUDLayer.RECURSOS), "modal oculta recursos")
	hud.free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO HUD recursos: " + nombre)
