extends SceneTree

const Eventos = preload("res://guion/religion_eventos.gd")
const Mundo = preload("res://guion/religion_mundo_934.gd")
const Mundo3D = preload("res://guion/religion_mundo_934_3d.gd")

var pasadas := 0
var fallos := 0


func _init() -> void:
	_probar_contrato_material()
	_probar_canales()
	_probar_superficies_3d()
	_probar_reduccion_movimiento()
	print("%d pasadas, %d fallos" % [pasadas, fallos])
	quit(1 if fallos > 0 else 0)


func _probar_contrato_material() -> void:
	var superficies := Mundo.superficies()
	_comprobar(superficies.size() == 2, "hay dos superficies materiales distintas")
	_comprobar(
		String(superficies[0]["id"]) != String(superficies[1]["id"]),
		"las superficies tienen identidad propia"
	)
	_comprobar(Mundo.eventos_calendario(2).is_empty(), "el calendario no inventa eventos")
	var dia_tres := Mundo.eventos_calendario(Mundo.DIA_ACTO_MEMORIA)
	_comprobar(dia_tres.size() == 1, "el acto aparece solo en su jornada")
	_comprobar(
		String(dia_tres[0]["fuente"]) == "calendario:tablon_comunitario_98",
		"el evento conserva una fuente interna explícita"
	)


func _probar_canales() -> void:
	var registro := Eventos.nuevo()
	_comprobar(
		Mundo.registrar_exposicion(registro, "tablon_calendario", Mundo.DIA_ACTO_MEMORIA),
		"examinar el tablón registra exposición"
	)
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_EXPOSICION).size() == 1,
		"la cultura material vive en exposición"
	)
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_PRACTICA).is_empty(),
		"examinar material no se convierte en práctica"
	)
	_comprobar(
		not Mundo.registrar_practica(registro, "silencio_memoria", 2),
		"la práctica no existe fuera de su contexto de calendario"
	)
	_comprobar(
		Mundo.registrar_practica(registro, "silencio_memoria", Mundo.DIA_ACTO_MEMORIA),
		"la práctica presencial se registra en su contexto"
	)
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_PRACTICA).size() == 1,
		"la participación queda separada como práctica"
	)
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_CONVICCION).is_empty(),
		"participar no infiere convicción"
	)
	_comprobar(
		not Mundo.registrar_practica(registro, "silencio_memoria", Mundo.DIA_ACTO_MEMORIA),
		"repetir el mismo gesto no duplica trayectoria"
	)


func _probar_superficies_3d() -> void:
	var registro := Eventos.nuevo()
	var escena := Mundo3D.new()
	get_root().add_child(escena)
	escena.configurar(registro, Mundo.DIA_ACTO_MEMORIA)
	_comprobar(
		escena.get_node_or_null("CulturaMaterial/TablonCalendario/Corcho") != null,
		"el tablón existe como superficie física"
	)
	_comprobar(
		escena.get_node_or_null("CulturaMaterial/MesaRecuerdo/LibroMemoria") != null,
		"la mesa de recuerdo es una segunda superficie física"
	)
	_comprobar(escena.tablon_interactuable() != null, "el tablón se puede examinar sin menú")
	_comprobar(escena.practica_interactuable() != null, "la práctica se activa desde el mundo")
	escena.tablon_interactuable().interactuar(null)
	escena.practica_interactuable().interactuar(null)
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_EXPOSICION).size() == 1,
		"la interacción 3D registra exposición"
	)
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_PRACTICA).size() == 1,
		"la interacción 3D registra práctica"
	)
	_comprobar(
		Eventos.eventos(registro, Eventos.CANAL_CONVICCION).is_empty(),
		"el componente 3D tampoco asigna convicción"
	)
	escena.free()


func _probar_reduccion_movimiento() -> void:
	var normal := Eventos.nuevo()
	var reducido := Eventos.nuevo()
	var escena_normal := Mundo3D.new()
	var escena_reducida := Mundo3D.new()
	get_root().add_child(escena_normal)
	get_root().add_child(escena_reducida)
	escena_normal.configurar(normal, Mundo.DIA_ACTO_MEMORIA, false)
	escena_reducida.configurar(reducido, Mundo.DIA_ACTO_MEMORIA, true)
	escena_normal.practica_interactuable().interactuar(null)
	escena_reducida.practica_interactuable().interactuar(null)
	_comprobar(escena_reducida.reduccion_movimiento_activa(), "la preferencia llega al componente")
	_comprobar(
		(
			JSON.stringify(Eventos.eventos(normal, Eventos.CANAL_PRACTICA))
			== JSON.stringify(Eventos.eventos(reducido, Eventos.CANAL_PRACTICA))
		),
		"reducción de movimiento no cambia el significado de la práctica"
	)
	escena_normal.free()
	escena_reducida.free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		pasadas += 1
	else:
		fallos += 1
		printerr("FALLO %s" % nombre)
