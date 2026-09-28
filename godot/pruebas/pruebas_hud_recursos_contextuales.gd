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
	_probar_prioridades_exhaustivas()
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
	_comprobar(modelo.get("estres_segmentos", 0) == 1, "archivo inicia con un segmento visual")
	_comprobar(ControladorHUD.segmentos_estres(0.24) == 1, "primer cuarto usa un segmento")
	_comprobar(ControladorHUD.segmentos_estres(0.25) == 2, "segundo cuarto usa dos segmentos")
	_comprobar(ControladorHUD.segmentos_estres(0.50) == 3, "tercer cuarto usa tres segmentos")
	_comprobar(ControladorHUD.segmentos_estres(0.75) == 4, "último cuarto usa cuatro segmentos")
	Estres.aplicar(estado["jornada"], "documento_sensible", 2.0)
	Estres.aplicar(estado["jornada"], "documento_sensible", 2.0)
	modelo = ControladorHUD.modelo_recursos(estado)
	_comprobar(modelo.get("estres_segmentos", 0) == 2, "HUD sigue la fuente canónica de estrés")

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


func _probar_prioridades_exhaustivas() -> void:
	var hud := HUDLayer.new()
	root.add_child(hud)
	var tipos := [
		HUDLayer.ESTADO,
		HUDLayer.RECURSOS,
		HUDLayer.INTERACCION,
		HUDLayer.TUTORIAL,
		HUDLayer.FASE,
		HUDLayer.DIALOGO,
		HUDLayer.MODAL,
	]
	var controles := {}
	for tipo in tipos:
		var control := Control.new()
		control.name = "Superficie_%s" % String(tipo)
		hud.add_child(control)
		hud.registrar(tipo, control)
		controles[tipo] = control

	var primarias := [
		HUDLayer.INTERACCION,
		HUDLayer.TUTORIAL,
		HUDLayer.FASE,
		HUDLayer.DIALOGO,
	]
	for mascara in range(1 << primarias.size()):
		hud.desactivar_todo()
		hud.activar(HUDLayer.ESTADO)
		hud.activar(HUDLayer.RECURSOS)
		var esperada := StringName()
		var prioridad_esperada := -1
		for indice in range(primarias.size()):
			if (mascara & (1 << indice)) == 0:
				continue
			var tipo: StringName = primarias[indice]
			hud.activar(tipo)
			var prioridad := int(HUDLayer.PRIORIDADES[tipo])
			if prioridad > prioridad_esperada:
				prioridad_esperada = prioridad
				esperada = tipo

		var visibles_primarias := 0
		for tipo in primarias:
			var control: Control = controles[tipo]
			if control.visible:
				visibles_primarias += 1
				_comprobar(tipo == esperada, "solo gana la primaria de mayor prioridad")
		_comprobar(
			visibles_primarias == (0 if esperada == StringName() else 1),
			"cada combinación expone como máximo una superficie primaria",
		)
		_comprobar(
			bool((controles[HUDLayer.ESTADO] as Control).visible),
			"estado secundario puede convivir sin modal",
		)
		var recursos_deberian_verse := esperada == StringName() or esperada == HUDLayer.INTERACCION
		_comprobar(
			bool((controles[HUDLayer.RECURSOS] as Control).visible) == recursos_deberian_verse,
			"recursos solo conviven con ausencia de primaria o interacción breve",
		)

	hud.activar(HUDLayer.MODAL)
	for tipo in tipos:
		var control: Control = controles[tipo]
		_comprobar(
			control.visible == (tipo == HUDLayer.MODAL),
			"modal oculta cualquier otra superficie registrada",
		)
	hud.queue_free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO HUD recursos: " + nombre)
