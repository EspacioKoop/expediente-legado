## Primer corte de escenografía CC0 visible tras el segundo playtest (#400).
##
## Es un controller hijo de `dia.tscn`: no sustituye la raíz histórica
## `dia_clima_app.gd` ni altera la cadena de jornada. Observa cuándo cambia el
## mundo montado por el día y añade únicamente dressing visual/interactivo.
##
## No descarga assets en runtime. Reutiliza modelos CC0 ya versionados y una
## adaptación procedural CC0 documentada, sin introducir nuevos binarios/LFS.
extends Node

var _mundo_vestido_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_vestido_id:
		return

	_mundo_vestido_id = mundo_id
	match String(dia.jornada.get("fase", "")):
		"archivo":
			_vestir_archivo_cc0(mundo)
		"trayecto":
			_vestir_calle_cc0(mundo)
		"casa":
			_vestir_casa_cc0(mundo)


func _vestir_archivo_cc0(mundo: Node3D) -> void:
	# Los dos puestos del lado derecho ya tenían escritorio, pero seguían leyendo
	# como mesas vacías. Añadir CRT reales cambia su silueta sin duplicar SIGA.
	_mueble_cc0(
		mundo,
		"MonitorPuestoC",
		"computerScreen",
		Vector3(1.05, 0.98, -2.08),
		Vector3(0.48, 0.42, 0.38),
		Color(0.56, 0.55, 0.50),
		"monitor CRT",
		"monitor"
	)
	_mueble_cc0(
		mundo,
		"MonitorPuestoD",
		"computerScreen",
		Vector3(1.05, 0.98, 1.08),
		Vector3(0.48, 0.42, 0.38),
		Color(0.54, 0.53, 0.49),
		"monitor CRT",
		"monitor"
	)
	_mueble_cc0(
		mundo,
		"PapeleraPuestoC",
		"trashcan",
		Vector3(2.05, 0.22, -1.82),
		Vector3(0.34, 0.45, 0.34),
		Color(0.34, 0.34, 0.32),
		"papelera"
	)
	_archivador_vintage_cc0(mundo)


func _archivador_vintage_cc0(mundo: Node3D) -> void:
	# Cierra el extremo libre de la batería de archivadores existente con una
	# silueta distinta y legible. El frente mira hacia el pasillo central.
	var tam := VintageWoodenDrawer.TAMANO
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "ArchivadorVintageCC0"
	cuerpo.position = Vector3(5.50, tam.y * 0.5, 4.42)
	cuerpo.rotation_degrees.y = 90.0
	mundo.add_child(cuerpo)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	cuerpo.add_child(colision)
	cuerpo.add_child(VintageWoodenDrawer.crear())
	_montar_examinable(cuerpo, tam, "archivador vintage", "archivador")


func _vestir_calle_cc0(mundo: Node3D) -> void:
	# Objetos pequeños rompen la lectura de «dos paredes y tres farolas» sin
	# estrechar la calzada. Se colocan en las aceras, fuera del eje de avance.
	_mueble_cc0(
		mundo,
		"PapeleraCalleSur",
		"trashcan",
		Vector3(4.75, 0.22, -10.0),
		Vector3(0.34, 0.45, 0.34),
		Color(0.25, 0.27, 0.27),
		"papelera de calle"
	)
	_mueble_cc0(
		mundo,
		"PapeleraCalleNorte",
		"trashcan",
		Vector3(-4.72, 0.22, 8.6),
		Vector3(0.34, 0.45, 0.34),
		Color(0.24, 0.26, 0.25),
		"papelera de calle"
	)
	_mueble_cc0(
		mundo,
		"CajaRepartoEscaparate",
		"cardboardBoxClosed",
		Vector3(-4.92, 0.20, -4.55),
		Vector3(0.50, 0.40, 0.70),
		Color(0.55, 0.46, 0.33),
		"caja de reparto"
	)
	_mueble_cc0(
		mundo,
		"CajaRepartoPortal",
		"cardboardBoxClosed",
		Vector3(4.92, 0.20, 12.5),
		Vector3(0.50, 0.40, 0.70),
		Color(0.50, 0.43, 0.32),
		"caja de reparto"
	)
	_zona_servicio_industrial_cc0(mundo)


func _zona_servicio_industrial_cc0(mundo: Node3D) -> void:
	# El hueco entre las dos fachadas de la acera derecha se convierte en una
	# pequeña zona de servicio. Queda detrás del borde caminable de la acera y
	# no añade colisión ni interacción: debe leerse como infraestructura de fondo.
	var zona := IndustrialCC0.crear_zona_servicio()
	zona.name = "ZonaServicioIndustrialCC0"
	zona.position = Vector3(6.05, 0.14, -0.40)
	zona.rotation_degrees.y = -90.0
	zona.scale = Vector3.ONE * 0.90
	mundo.add_child(zona)


func _vestir_casa_cc0(mundo: Node3D) -> void:
	# La vivienda necesita objetos con uso doméstico reconocible, no otra capa de
	# cubos. Esta primera pasada deja almacenamiento, asiento y cajas reales.
	_mueble_cc0(
		mundo,
		"EstanteriaCasaCC0",
		"bookcaseClosed",
		Vector3(-2.3, 0.90, 4.22),
		Vector3(0.80, 1.80, 0.48),
		Color(0.34, 0.28, 0.23),
		"estantería"
	)
	_mueble_cc0(
		mundo,
		"SillaCasaCC0",
		"chairDesk",
		Vector3(-1.75, 0.48, 3.55),
		Vector3(0.62, 0.95, 0.62),
		Color(0.30, 0.31, 0.30),
		"silla",
		"silla"
	)
	_mueble_cc0(
		mundo,
		"CajaCasaBaja",
		"cardboardBoxClosed",
		Vector3(-3.55, 0.20, 4.1),
		Vector3(0.50, 0.40, 0.70),
		Color(0.56, 0.48, 0.35),
		"caja doméstica"
	)
	_mueble_cc0(
		mundo,
		"CajaCasaAlta",
		"cardboardBoxClosed",
		Vector3(-3.55, 0.61, 4.1),
		Vector3(0.50, 0.40, 0.70),
		Color(0.52, 0.45, 0.34),
		"caja doméstica"
	)


func _mueble_cc0(
	mundo: Node3D,
	nombre_nodo: String,
	modelo: String,
	posicion: Vector3,
	tam: Vector3,
	color: Color,
	nombre_examinable: String = "",
	objeto_onirico_id: String = ""
) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre_nodo
	cuerpo.position = posicion
	mundo.add_child(cuerpo)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	cuerpo.add_child(colision)

	if not Modelos.mueble(cuerpo, modelo, tam, color):
		cuerpo.queue_free()
		return

	if not nombre_examinable.is_empty():
		_montar_examinable(cuerpo, tam, nombre_examinable, objeto_onirico_id)


func _montar_examinable(
	cuerpo: Node3D, tam: Vector3, nombre_objeto: String, objeto_onirico_id: String = ""
) -> void:
	var examinable := Interactuable3D.new()
	examinable.name = "Examinar%s" % cuerpo.name
	examinable.verbo = Interactuable3D.Verbo.EXAMINAR
	examinable.nombre_objeto = nombre_objeto
	examinable.set_meta("objeto_onirico_id", objeto_onirico_id)
	examinable.set_meta("huella_ambiental_id", "dressing:%s" % String(cuerpo.name))
	examinable.set_meta("huella_ambiental_tipo", "roce")
	cuerpo.add_child(examinable)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam + Vector3(0.12, 0.12, 0.12)
	colision.shape = forma
	examinable.add_child(colision)

	# El feedback cabe en el mismo prompt contextual. Solo las tres familias con
	# deformación catalogada (#87/#149) dejan memoria para el sueño; el resto del
	# dressing sigue siendo examinable pero no fabrica una anomalía genérica.
	examinable.activado.connect(_marcar_observado.bind(examinable))


func _marcar_observado(_actor: Node, examinable: Interactuable3D) -> void:
	if examinable.get_meta("observado", false):
		return
	examinable.set_meta("observado", true)
	examinable.nombre_objeto = "%s · observado" % examinable.nombre_objeto

	var objeto_id := String(examinable.get_meta("objeto_onirico_id", ""))
	if objeto_id.is_empty():
		return
	var dia := get_parent()
	if dia == null:
		return
	if ObjetosOniricos.registrar(dia.jornada, objeto_id):
		# El sueño se monta después de cambios de fase y puede mediar una recarga;
		# guardar aquí evita que una interacción deliberada desaparezca entre ambas.
		dia._guardar_o_avisar("")
