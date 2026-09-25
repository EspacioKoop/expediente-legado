## Regresión standalone del núcleo de terminal SIGA (#956).
extends SceneTree

const Terminal := preload("res://guion/terminal_siga.gd")
const TerminalApp := preload("res://guion/terminal_siga_app.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var terminal = Terminal.new()

	_comprobar(terminal.cwd() == "/", "empieza en la raíz simulada")
	var ayuda: Dictionary = terminal.ejecutar("help")
	_comprobar(bool(ayuda["ok"]), "HELP responde")
	_comprobar(String(ayuda["salida"]).contains("DIR/LS"), "HELP enumera comandos")
	_comprobar(String(ayuda["salida"]).contains("COPY/CP"), "HELP anuncia comandos temporales")

	var raiz: Dictionary = terminal.ejecutar("dir")
	_comprobar(bool(raiz["ok"]), "DIR lista la raíz")
	_comprobar(String(raiz["salida"]).contains("[DIR] SIGA"), "la raíz expone SIGA")
	_comprobar(String(raiz["salida"]).contains("README.TXT"), "la raíz expone README")

	_comprobar(bool(terminal.ejecutar("cd siga/memos")["ok"]), "CD acepta ruta relativa")
	_comprobar(terminal.cwd() == "/SIGA/MEMOS", "CD normaliza mayúsculas")
	var memo: Dictionary = terminal.ejecutar("type ayuda.txt")
	_comprobar(bool(memo["ok"]), "TYPE lee un archivo simulado")
	_comprobar(String(memo["salida"]).contains("solo expone utilidades"), "el memo tiene contenido")

	_comprobar(bool(terminal.ejecutar("cd ..")["ok"]), "CD .. sube un nivel")
	_comprobar(terminal.cwd() == "/SIGA", "CD .. queda dentro del árbol simulado")
	terminal.ejecutar("cd ../../../../")
	_comprobar(terminal.cwd() == "/", "no se puede escapar por encima de la raíz")
	var absoluto: Dictionary = terminal.ejecutar("cat /red/hosts.txt")
	_comprobar(bool(absoluto["ok"]), "CAT acepta ruta absoluta")
	_comprobar(
		String(absoluto["salida"]).contains("ARCHIVO.LOCAL"), "hosts son ficticios y estables"
	)

	_comprobar(terminal.ejecutar("whoami")["salida"] == "auditor", "WHOAMI es determinista")
	var entorno: String = terminal.ejecutar("set")["salida"]
	_comprobar(entorno.contains("SISTEMA=SIGA-98"), "SET enseña entorno simulado")
	_comprobar(
		terminal.ejecutar("echo %USER% @ %SISTEMA%")["salida"] == "auditor @ SIGA-98",
		"ECHO expande variables ficticias",
	)

	var ping: Dictionary = terminal.ejecutar("ping archivo.local")
	_comprobar(bool(ping["ok"]), "PING conocido responde")
	_comprobar(String(ping["salida"]).contains("18 ms"), "PING no depende de red real")
	_comprobar(not bool(terminal.ejecutar("ping example.com")["ok"]), "PING no alcanza Internet")
	_comprobar(
		String(terminal.ejecutar("netstat")["salida"]).contains("ARCHIVO.LOCAL"),
		"NETSTAT muestra conexiones simuladas",
	)

	var copia: Dictionary = terminal.ejecutar("copy README.TXT /SIGA/MEMOS/COPIA.TXT")
	_comprobar(bool(copia["ok"]), "COPY crea una copia temporal")
	_comprobar(
		(
			terminal.ejecutar("type /SIGA/MEMOS/COPIA.TXT")["salida"]
			== terminal.ejecutar("type /README.TXT")["salida"]
		),
		"COPY conserva el contenido dentro del filesystem simulado",
	)
	var editado: Dictionary = terminal.ejecutar("edit /SIGA/MEMOS/NOTAS.TXT pista temporal")
	_comprobar(bool(editado["ok"]), "EDIT crea o reemplaza un archivo temporal")
	_comprobar(
		terminal.ejecutar("cat /SIGA/MEMOS/NOTAS.TXT")["salida"] == "pista temporal",
		"EDIT conserva texto con espacios",
	)
	_comprobar(
		String(terminal.ejecutar("users")["salida"]).contains("auditor"),
		"USERS enumera usuarios ficticios",
	)
	_comprobar(bool(terminal.ejecutar("del /SIGA/MEMOS/COPIA.TXT")["ok"]), "DEL borra la copia")
	_comprobar(
		not bool(terminal.ejecutar("type /SIGA/MEMOS/COPIA.TXT")["ok"]),
		"el archivo eliminado desaparece durante la sesión",
	)
	var nueva_sesion = Terminal.new()
	_comprobar(
		not bool(nueva_sesion.ejecutar("type /SIGA/MEMOS/NOTAS.TXT")["ok"]),
		"los cambios temporales se reinician al crear otra sesión",
	)
	_comprobar(
		bool(nueva_sesion.ejecutar("type /README.TXT")["ok"]),
		"una sesión nueva recupera los archivos base",
	)
	_comprobar(
		not bool(terminal.ejecutar("copy /etc/passwd /SIGA/MEMOS/X.TXT")["ok"]),
		"COPY no puede leer rutas fuera del namespace simulado",
	)

	_comprobar(not bool(terminal.ejecutar("comando_inventado")["ok"]), "comando desconocido falla")
	_comprobar(
		not Terminal.ARCHIVOS.has("/etc/passwd"),
		"el namespace del terminal no contiene rutas del host",
	)

	var app = TerminalApp.new()
	root.add_child(app)
	await process_frame
	_comprobar(app._linea != null and app._linea.has_focus(), "la entrada recibe foco al abrir")
	_comprobar(app._registro != null, "la pantalla monta historial de terminal")
	_comprobar(app._abrir_siga != null, "la pantalla ofrece acceso explícito al visor SIGA")
	_comprobar(
		app._abrir_siga.text == TranslationServer.translate("TERMINAL_SIGA_ABRIR"),
		"la UI resuelve sus textos desde el catálogo de traducciones",
	)
	var ui_help: Dictionary = app.ejecutar("help")
	_comprobar(bool(ui_help["ok"]), "la UI delega HELP al núcleo")
	_comprobar(
		app._registro.get_parsed_text().contains("DIR/LS"),
		"la salida del núcleo aparece en el historial visible",
	)
	_comprobar(
		app._linea.focus_neighbor_bottom == app._linea.get_path_to(app._abrir_siga),
		"mando/teclado pueden bajar desde la línea al botón SIGA",
	)
	app.queue_free()
	await process_frame

	var capa := FileAccess.get_file_as_string("res://guion/dia_clima_app.gd")
	_comprobar(capa.contains("TerminalSigaApp.new()"), "el terminal físico abre la nueva UI")
	_comprobar(
		capa.contains("terminal.abrir_siga_solicitado.connect(_abrir_siga_desde_terminal)"),
		"la UI reutiliza la apertura real del visor SIGA",
	)
	_comprobar(
		not capa.contains('_sonar("documento")\n\t_abrir_expediente()'),
		"usar el terminal ya no salta directamente al visor",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(valor: bool, nombre: String) -> void:
	if valor:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO terminal SIGA #956: %s" % nombre)
