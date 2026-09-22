extends SceneTree

var pasadas := 0
var fallos := 0


func _initialize() -> void:
	_probar_fallback_identico()
	_probar_consumo_de_insight()
	_probar_no_filtracion()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _base() -> Dictionary:
	return {
		"rotulo": "sala-prueba",
		"deformacion_textura": Vector3.ONE,
		"contraste_textura": 1.0,
		"ambiente_energia": 0.32,
		"figuras": [{"id": "s1", "rotulo": "dato ya conocido"}],
		"carteles": [{"texto": "frase ya descubierta"}],
		"salidas": [{"destino": "archivo"}],
	}


func _registro_con_insight() -> Dictionary:
	var registro := LiteraturaEventos.nuevo()
	var lectura := (
		LiteraturaLectura
		. registrar_interaccion(
			registro,
			"vida_es_sueno_1635",
			"documento:biblioteca:estante_03",
			2,
			1.0,
		)
	)
	_comprobar(bool(lectura.get("insight_nuevo", false)), "la lectura produce insight real")
	return registro


func _probar_fallback_identico() -> void:
	var base := _base()
	var vacio := SuenoLiteratura.aplicar(base, LiteraturaEventos.nuevo(), 0)
	_comprobar(vacio == base, "sin insight el espacio es semanticamente identico")
	_comprobar(not vacio.has("motivo_literario"), "el fallback no anade metadatos")

	var solo_conocimiento := LiteraturaEventos.nuevo()
	var evento := (
		LiteraturaEventos
		. crear_evento(
			"conocimiento:prueba",
			LiteraturaEventos.CANAL_CONOCIMIENTO,
			"vida_es_sueno_1635",
			"prueba",
		)
	)
	LiteraturaEventos.registrar(solo_conocimiento, evento)
	_comprobar(
		SuenoLiteratura.aplicar(base, solo_conocimiento, 0) == base,
		"conocer sin insight tampoco modula el sueno",
	)


func _probar_consumo_de_insight() -> void:
	var registro := _registro_con_insight()
	var motivos := SuenoLiteratura.motivos(registro)
	_comprobar(motivos.size() == 2, "un insight expone los motivos declarados")
	_comprobar(
		motivos.any(func(m): return String(m.get("motivo", "")) == "umbral"),
		"el motivo umbral procede del catalogo",
	)
	_comprobar(
		motivos.any(func(m): return String(m.get("motivo", "")) == "doble"),
		"el motivo doble procede del catalogo",
	)

	var base := _base()
	var modulado := SuenoLiteratura.aplicar(base, registro, 1)
	_comprobar(modulado.has("motivo_literario"), "el consumidor deja procedencia explicita")
	_comprobar(
		String(modulado["motivo_literario"].get("obra_id", "")) == "vida_es_sueno_1635",
		"el motivo se vincula a la obra conocida",
	)
	_comprobar(
		modulado["deformacion_textura"] != base["deformacion_textura"],
		"el insight modula textura sin cambiar contenido",
	)
	_comprobar(
		float(modulado["contraste_textura"]) > float(base["contraste_textura"]),
		"el insight puede modular contraste",
	)


func _probar_no_filtracion() -> void:
	var base := _base()
	var modulado := SuenoLiteratura.aplicar(base, _registro_con_insight(), 0)
	_comprobar(modulado["figuras"] == base["figuras"], "no inventa ni cambia sospechosos")
	_comprobar(modulado["carteles"] == base["carteles"], "no inventa ni cambia frases")
	_comprobar(modulado["salidas"] == base["salidas"], "no altera seleccion ni navegacion")
	_comprobar(not modulado.has("pistas"), "no crea un canal de pistas")
	_comprobar(not modulado.has("hechos"), "no crea un canal de hechos")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO #1182: %s" % nombre)
