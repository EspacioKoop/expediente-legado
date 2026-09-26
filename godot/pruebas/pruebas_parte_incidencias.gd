extends SceneTree

const Parte = preload("res://guion/parte_incidencias.gd")

var pasadas := 0
var fallos := 0


func _init() -> void:
	comprobar("categorías previstas", Parte.CATEGORIAS.size(), 6)
	comprobar(
		"URL HTTPS admitida",
		Parte.url_configurada({"feedback_url": "https://example.test/report"}),
		"https://example.test/report",
	)
	comprobar(
		"esquema no web rechazado",
		Parte.url_configurada({"feedback_url": "file:///tmp/form"}),
		"",
	)
	comprobar(
		"fallback GitHub admitido",
		Parte.url_issue_fallback(
			{"fallback_issue_url": "https://github.com/EspacioKoop/expediente-legado/issues/new"}
		),
		"https://github.com/EspacioKoop/expediente-legado/issues/new",
	)
	comprobar(
		"fallback ajeno rechazado",
		Parte.url_issue_fallback({"fallback_issue_url": "https://example.test/issues/new"}),
		"",
	)
	comprobar("escena res se reduce a nombre", Parte.escena_segura("res://escenas/dia.tscn"), "dia")
	comprobar(
		"ruta privada no entra en diagnóstico",
		Parte.escena_segura("/home/alguien/proyecto/dia.tscn"),
		"desconocida",
	)
	comprobar("Windows se normaliza", Parte.plataforma_generica("Windows"), "windows")
	comprobar("macOS se normaliza", Parte.plataforma_generica("macOS"), "macos")

	var candidato := {
		"build": "alpha-1",
		"godot": "4.7",
		"plataforma": "linux",
		"escena": "dia",
		"renderer": "gl_compatibility",
		"reduccion_movimiento": true,
		"home": "/home/tester",
		"usuario": "tester",
		"ip": "127.0.0.1",
		"token": "secreto",
		"partida": {"dinero": 999},
	}
	var filtrado := Parte.filtrar_diagnostico(candidato)
	comprobar("lista blanca conserva seis campos", filtrado.size(), 6)
	comprobar("home descartado", filtrado.has("home"), false)
	comprobar("usuario descartado", filtrado.has("usuario"), false)
	comprobar("ip descartada", filtrado.has("ip"), false)
	comprobar("token descartado", filtrado.has("token"), false)
	comprobar("partida descartada", filtrado.has("partida"), false)

	var campos := {
		"categoria": "bug",
		"titulo": "Botón sin respuesta",
		"descripcion": "Al pulsar no cambia la pantalla.",
		"pasos": "1. Abrir\n2. Pulsar",
		"esperado": "Cambiar de pantalla",
		"observado": "No cambia",
	}
	var sin_diagnostico := Parte.compilar(campos)
	comprobar(
		"sin consentimiento no aparece diagnóstico",
		sin_diagnostico.contains("DIAGNÓSTICO TÉCNICO"),
		false,
	)
	comprobar("bug conserva pasos", sin_diagnostico.contains("1. Abrir"), true)
	var con_diagnostico := Parte.compilar(campos, filtrado)
	comprobar(
		"adjunto consentido queda rotulado",
		con_diagnostico.contains("DIAGNÓSTICO TÉCNICO (consentido)"),
		true,
	)
	comprobar("secreto no reaparece", con_diagnostico.contains("secreto"), false)

	var payload := Parte.crear_payload(campos, filtrado)
	comprobar("payload declara origen F9", payload.get("source"), "siga98-f9")
	comprobar("payload conserva categoría", payload.get("category"), "bug")
	comprobar("payload conserva título", payload.get("title"), "Botón sin respuesta")
	comprobar(
		"payload contiene cuerpo formateado",
		String(payload.get("body", "")).contains("PARTE DE INCIDENCIAS"),
		true,
	)
	comprobar(
		"fallback pre-rellena título",
		(
			Parte
			. url_issue_preparado(
				payload,
				{
					"fallback_issue_url":
					"https://github.com/EspacioKoop/expediente-legado/issues/new"
				},
			)
			. contains("title=")
		),
		true,
	)
	comprobar(
		"fallback pre-rellena cuerpo",
		(
			Parte
			. url_issue_preparado(
				payload,
				{
					"fallback_issue_url":
					"https://github.com/EspacioKoop/expediente-legado/issues/new"
				},
			)
			. contains("body=")
		),
		true,
	)

	var ruta_build := "user://build-info-prueba.txt"
	var archivo := FileAccess.open(ruta_build, FileAccess.WRITE)
	archivo.store_string("SIGA-98 alpha playtest\nbuild_sha=0123456789abcdef\n")
	archivo.close()
	comprobar(
		"BUILD-INFO aporta SHA exacto",
		Parte.build_actual(ruta_build),
		"0123456789abcdef",
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_build))

	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func comprobar(nombre: String, obtenido, esperado) -> void:
	if obtenido == esperado:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s\n  esperado: %s\n  obtenido: %s" % [nombre, esperado, obtenido])
