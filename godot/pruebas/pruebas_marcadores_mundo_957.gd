extends SceneTree

const RUTA := "user://prueba_marcadores_mundo_957.json"

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_limpiar()

	var partida := Partida.new()
	partida.estado = Partida.nueva()
	var jornada: Dictionary = partida.estado["jornada"]

	_comprobar(MarcadoresMundo.listar(jornada, "archivo").is_empty(), "empieza sin marcadores")

	var invalido := MarcadoresMundo.colocar(
		jornada,
		"archivo",
		"spray",
		MarcadoresMundo.COLOR_BLANCO,
		"",
		Vector3.ZERO,
		Vector3.UP,
	)
	_comprobar(not bool(invalido["ok"]), "rechaza tipos fuera del vocabulario")
	_comprobar(MarcadoresMundo.listar(jornada, "archivo").is_empty(), "un tipo inválido no muta")

	var color_invalido := MarcadoresMundo.colocar(
		jornada,
		"archivo",
		MarcadoresMundo.TIPO_NOTA,
		"neon",
		"",
		Vector3.ZERO,
		Vector3.UP,
	)
	_comprobar(not bool(color_invalido["ok"]), "rechaza colores fuera de paleta")

	var texto_largo := "012345678901234567890123456789"
	var primera := MarcadoresMundo.colocar(
		jornada,
		"archivo",
		MarcadoresMundo.TIPO_NOTA,
		MarcadoresMundo.COLOR_AMARILLO,
		texto_largo,
		Vector3(1.0, 0.8, -2.0),
		Vector3(0.0, 0.0, 2.0),
	)
	_comprobar(bool(primera["ok"]), "coloca una nota válida")
	var primera_marca: Dictionary = primera["marcador"]
	_comprobar(String(primera_marca["id"]) == "m000001", "el primer id es estable")
	_comprobar(
		String(primera_marca["texto"]).length() == MarcadoresMundo.MAX_TEXTO,
		"el texto visible queda acotado",
	)
	_comprobar(
		is_equal_approx(MarcadoresMundo.normal_de(primera_marca).length(), 1.0),
		"la normal se guarda normalizada",
	)

	var tiza := MarcadoresMundo.colocar(
		jornada,
		"archivo",
		MarcadoresMundo.TIPO_TIZA,
		MarcadoresMundo.COLOR_BLANCO,
		"esto no se pinta",
		Vector3(0.0, 0.01, 0.0),
		Vector3.UP,
	)
	_comprobar(String(tiza["marcador"]["texto"]).is_empty(), "la tiza no conserva texto ajeno")

	for indice in range(3):
		var extra := MarcadoresMundo.colocar(
			jornada,
			"archivo",
			MarcadoresMundo.TIPO_CARBON,
			MarcadoresMundo.COLOR_ROJO,
			"",
			Vector3(float(indice), 0.01, 1.0),
			Vector3.UP,
		)
		_comprobar(bool(extra["ok"]), "acepta marca hasta completar el límite %d" % indice)

	_comprobar(
		MarcadoresMundo.listar(jornada, "archivo").size() == MarcadoresMundo.LIMITE_POR_ZONA,
		"la zona llega exactamente al límite",
	)
	var sexta := MarcadoresMundo.colocar(
		jornada,
		"archivo",
		MarcadoresMundo.TIPO_OBJETO,
		MarcadoresMundo.COLOR_AZUL,
		"",
		Vector3.ZERO,
		Vector3.UP,
	)
	_comprobar(String(sexta["motivo"]) == "limite_zona", "la sexta marca se rechaza")

	var otra_zona := MarcadoresMundo.colocar(
		jornada,
		"casa",
		MarcadoresMundo.TIPO_CINTA,
		MarcadoresMundo.COLOR_VERDE,
		"nevera",
		Vector3(0.5, 1.1, 0.5),
		Vector3.FORWARD,
	)
	_comprobar(bool(otra_zona["ok"]), "el límite es independiente por zona")
	_comprobar(MarcadoresMundo.listar(jornada, "casa").size() == 1, "casa conserva su propia lista")

	var copia := MarcadoresMundo.listar(jornada, "archivo")
	copia[0]["texto"] = "mutado fuera"
	_comprobar(
		String(MarcadoresMundo.listar(jornada, "archivo")[0]["texto"]) != "mutado fuera",
		"listar no expone el estado interno",
	)

	_comprobar(
		MarcadoresMundo.eliminar(jornada, "archivo", String(primera_marca["id"])),
		"elimina por id estable",
	)
	_comprobar(
		MarcadoresMundo.listar(jornada, "archivo").size() == MarcadoresMundo.LIMITE_POR_ZONA - 1,
		"el borrado libera una plaza",
	)
	var reemplazo := MarcadoresMundo.colocar(
		jornada,
		"archivo",
		MarcadoresMundo.TIPO_OBJETO,
		MarcadoresMundo.COLOR_AZUL,
		"",
		Vector3(2.0, 0.02, 2.0),
		Vector3.UP,
	)
	_comprobar(bool(reemplazo["ok"]), "se puede reutilizar la plaza liberada")
	_comprobar(
		String(reemplazo["marcador"]["id"]) != String(primera_marca["id"]),
		"los ids no se reciclan al borrar",
	)
	_comprobar(not MarcadoresMundo.eliminar(jornada, "archivo", "m999999"), "borrar ausente es seguro")
	_comprobar(MarcadoresMundo.eliminar_zona(jornada, "casa") == 1, "puede limpiar una zona")
	_comprobar(MarcadoresMundo.listar(jornada, "casa").is_empty(), "la zona queda vacía")

	var solo_sueno := MarcadoresMundo.colocar(
		jornada,
		"sueño",
		MarcadoresMundo.TIPO_NOTA,
		MarcadoresMundo.COLOR_ROJO,
		"eco",
		Vector3.ZERO,
		Vector3.UP,
		true,
	)
	_comprobar(
		not MarcadoresMundo.visible_en(solo_sueno["marcador"], false),
		"una marca onírica no aparece en vigilia",
	)
	_comprobar(
		MarcadoresMundo.visible_en(solo_sueno["marcador"], true),
		"una marca onírica aparece durante el sueño",
	)

	var visual := MarcadorMundo3D.new()
	visual.configurar(reemplazo["marcador"], false, 0.0)
	_comprobar(
		visual.find_children("*", "MeshInstance3D", true, false).size() > 0,
		"la marca materializa geometría 3D",
	)
	_comprobar(
		visual.find_children("*", "CollisionObject3D", true, false).is_empty(),
		"la marca no crea colisiones",
	)
	visual.free()

	var visual_texto := MarcadorMundo3D.new()
	visual_texto.configurar(solo_sueno["marcador"], true, 0.0)
	_comprobar(visual_texto.get_node_or_null("Texto") != null, "nota y cinta pueden mostrar texto")
	visual_texto.free()

	var visual_oculto := MarcadorMundo3D.new()
	visual_oculto.configurar(solo_sueno["marcador"], false, 0.0)
	_comprobar(not visual_oculto.visible, "el renderer respeta solo_sueno")
	visual_oculto.free()

	var d1 := MarcadorMundo3D.desplazamiento_estres("m000123", 1.0)
	var d2 := MarcadorMundo3D.desplazamiento_estres("m000123", 1.0)
	_comprobar(d1.is_equal_approx(d2), "el estrés de una misma marca es determinista")
	_comprobar(
		d1.length() <= MarcadorMundo3D.DESPLAZAMIENTO_ESTRES_MAX + 0.0001,
		"la distorsión por estrés está acotada",
	)
	_comprobar(
		MarcadorMundo3D.desplazamiento_estres("m000123", 0.0) == Vector3.ZERO,
		"sin estrés no desplaza la marca",
	)

	_comprobar(partida.guardar(RUTA), "la Jornada con marcadores se guarda")
	var recargada := Partida.new()
	var carga := recargada.cargar(RUTA)
	_comprobar(String(carga.get("resultado", "")) == "cargada", "la partida vuelve a cargar")
	var jornada_recargada: Dictionary = recargada.estado["jornada"]
	_comprobar(
		MarcadoresMundo.listar(jornada_recargada, "archivo").size()
		== MarcadoresMundo.LIMITE_POR_ZONA,
		"guardar y cargar conserva el límite lleno",
	)
	_comprobar(
		MarcadoresMundo.listar(jornada_recargada, "sueño").size() == 1,
		"guardar y cargar conserva marcas oníricas",
	)

	_limpiar()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _limpiar() -> void:
	for ruta in [RUTA, RUTA + ".nuevo", RUTA + ".roto"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO MarcadoresMundo957: " + nombre)
