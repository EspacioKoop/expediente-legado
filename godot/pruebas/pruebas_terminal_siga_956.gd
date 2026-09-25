## Regresión standalone del núcleo de terminal SIGA (#956).
extends SceneTree

const Terminal := preload("res://guion/terminal_siga.gd")

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

	for comando in ["del README.TXT", "rm README.TXT", "copy README.TXT X.TXT", "edit README.TXT"]:
		_comprobar(not bool(terminal.ejecutar(comando)["ok"]), comando + " queda bloqueado")

	_comprobar(not bool(terminal.ejecutar("comando_inventado")["ok"]), "comando desconocido falla")
	_comprobar(
		not Terminal.ARCHIVOS.has("/etc/passwd"),
		"el namespace del terminal no contiene rutas del host",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(valor: bool, nombre: String) -> void:
	if valor:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO terminal SIGA #956: %s" % nombre)
