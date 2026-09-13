## Primer corte de escenografía CC0 visible tras el segundo playtest (#400).
##
## No introduce reglas de jornada ni descarga assets en runtime. Reutiliza únicamente
## modelos CC0 ya versionados y registrados en `assets/procedencia.json`, de modo que
## oficina, calle y casa ganen densidad reconocible sin abrir otra vía de assets.
##
## Los puntos examinables usan el contrato semántico de #283: el detector sigue siendo
## quien decide qué está bajo la mirada y la acción sigue siendo `interactuar`.
extends "res://guion/dia_clima_app.gd"


func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	match fase:
		"archivo":
			_vestir_archivo_cc0()
		"trayecto":
			_vestir_calle_cc0()
		"casa":
			_vestir_casa_cc0()


func _vestir_archivo_cc0() -> void:
	# Los dos puestos del lado derecho ya tenían escritorio, pero seguían leyendo
	# como mesas vacías. Añadir CRT reales cambia su silueta sin duplicar SIGA.
	_mueble_cc0(
		"MonitorPuestoC",
		"computerScreen",
		Vector3(1.05, 0.98, -2.08),
		Vector3(0.48, 0.42, 0.38),
		Color(0.56, 0.55, 0.50),
		"monitor CRT"
	)
	_mueble_cc0(
		"MonitorPuestoD",
		"computerScreen",
		Vector3(1.05, 0.98, 1.08),
		Vector3(0.48, 0.42, 0.38),
		Color(0.54, 0.53, 0.49),
		"monitor CRT"
	)
	_mueble_cc0(
		"PapeleraPuestoC",
		"trashcan",
		Vector3(2.05, 0.22, -1.82),
		Vector3(0.34, 0.45, 0.34),
		Color(0.34, 0.34, 0.32),
		"papelera"
	)


func _vestir_calle_cc0() -> void:
	# Objetos pequeños rompen la lectura de «dos paredes y tres farolas» sin
	# estrechar la calzada. Se colocan en las aceras, fuera del eje de avance.
	_mueble_cc0(
		"PapeleraCalleSur",
		"trashcan",
		Vector3(4.75, 0.22, -10.0),
		Vector3(0.34, 0.45, 0.34),
		Color(0.25, 0.27, 0.27),
		"papelera de calle"
	)
	_mueble_cc0(
		"PapeleraCalleNorte",
		"trashcan",
		Vector3(-4.72, 0.22, 8.6),
		Vector3(0.34, 0.45, 0.34),
		Color(0.24, 0.26, 0.25),
		"papelera de calle"
	)
	_mueble_cc0(
		"CajaRepartoEscaparate",
		"cardboardBoxClosed",
		Vector3(-4.92, 0.20, -4.55),
		Vector3(0.50, 0.40, 0.70),
		Color(0.55, 0.46, 0.33),
		"caja de reparto"
	)
	_mueble_cc0(
		"CajaRepartoPortal",
		"cardboardBoxClosed",
		Vector3(4.92, 0.20, 12.5),
		Vector3(0.50, 0.40, 0.70),
		Color(0.50, 0.43, 0.32),
		"caja de reparto"
	)


func _vestir_casa_cc0() -> void:
	# La vivienda necesita objetos con uso doméstico reconocible, no otra capa de
	# cubos. Esta primera pasada deja almacenamiento, asiento y cajas reales.
	_mueble_cc0(
		"EstanteriaCasaCC0",
		"bookcaseClosed",
		Vector3(3.42, 0.90, -0.15),
		Vector3(0.80, 1.80, 0.48),
		Color(0.34, 0.28, 0.23),
		"estantería"
	)
	_mueble_cc0(
		"SillaCasaCC0",
		"chairDesk",
		Vector3(1.55, 0.45, 0.25),
		Vector3(0.62, 0.95, 0.62),
		Color(0.30, 0.31, 0.30),
		"silla"
	)
	_mueble_cc0(
		"CajaCasaBaja",
		"cardboardBoxClosed",
		Vector3(-3.30, 0.20, -0.25),
		Vector3(0.50, 0.40, 0.70),
		Color(0.56, 0.48, 0.35),
		"caja doméstica"
	)
	_mueble_cc0(
		"CajaCasaAlta",
		"cardboardBoxClosed",
		Vector3(-3.30, 0.61, -0.25),
		Vector3(0.50, 0.40, 0.70),
		Color(0.52, 0.45, 0.34),
		"caja doméstica"
	)


func _mueble_cc0(
	nombre_nodo: String,
	modelo: String,
	posicion: Vector3,
	tam: Vector3,
	color: Color,
	nombre_examinable: String = ""
) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre_nodo
	cuerpo.position = posicion
	_mundo.add_child(cuerpo)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	cuerpo.add_child(colision)

	if not Modelos.mueble(cuerpo, modelo, tam, color):
		cuerpo.queue_free()
		return

	if not nombre_examinable.is_empty():
		_montar_examinable(cuerpo, tam, nombre_examinable)


func _montar_examinable(cuerpo: Node3D, tam: Vector3, nombre_objeto: String) -> void:
	var examinable := Interactuable3D.new()
	examinable.name = "Examinar%s" % cuerpo.name
	examinable.verbo = Interactuable3D.Verbo.EXAMINAR
	examinable.nombre_objeto = nombre_objeto
	cuerpo.add_child(examinable)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam + Vector3(0.12, 0.12, 0.12)
	colision.shape = forma
	examinable.add_child(colision)

	# El feedback cabe en el mismo prompt contextual: tras examinar, el objeto
	# queda marcado localmente como observado. No abre modal, no persiste y no
	# compite con diálogos ni instrucciones.
	examinable.activado.connect(_marcar_observado.bind(examinable))


func _marcar_observado(_actor: Node, examinable: Interactuable3D) -> void:
	if examinable.get_meta("observado", false):
		return
	examinable.set_meta("observado", true)
	examinable.nombre_objeto = "%s · observado" % examinable.nombre_objeto
