## Vertical independiente del Estuario del Maestro — aprender investigando (#2589).
## Escena 3D autónoma con tres minirretos de método de investigación:
## 1. Contrastar una afirmación con evidencia.
## 2. Refutar una falsa dicotomía.
## 3. Revisar una hipótesis.
## El mentor (Maestro del Estuario) responde diferente según el progreso,
## ofrece ayuda tras fallos y admite ser cuestionado.
## Salida disponible en ambos enfoques (completitud metódica o cuestionamiento).
class_name CronicasEstuarioMaestro3D
extends Node3D

signal completado

const ESCENA_CAMINANTE := preload("res://escenas/caminante.tscn")

const COLOR_AGUA := Color(0.08, 0.16, 0.24)
const COLOR_PIEDRA := Color(0.25, 0.27, 0.30)
const COLOR_PIEDRA_CLARA := Color(0.38, 0.39, 0.42)
const COLOR_MADERA := Color(0.40, 0.26, 0.15)
const COLOR_INSCRIPCION := Color(0.85, 0.74, 0.48)
const COLOR_MENTOR := Color(0.32, 0.48, 0.62)

var _reto1_resuelto := false
var _reto2_resuelto := false
var _reto3_resuelto := false

var _fallos_reto1 := 0
var _fallos_reto2 := 0
var _fallos_reto3 := 0

var _mentor_cuestionado := false
var _ayuda_recibida := false
var _completado := false
var _enfoque_salida := ""

var _caminante: CharacterBody3D
var _hud: HUDLayer
var _label_objetivo: Label
var _panel_dialogo: PanelContainer
var _label_dialogo: Label
var _contenedor_opciones: VBoxContainer

var _interactuable_reto1: Interactuable3D
var _interactuable_reto2: Interactuable3D
var _interactuable_reto3: Interactuable3D
var _interactuable_mentor: Interactuable3D
var _interactuable_salida: Interactuable3D


func _ready() -> void:
	_montar_entorno()
	_montar_interactuables()
	_montar_hud()
	_instanciar_caminante()


## Devuelve la consulta de progreso local determinista de esta escena.
func estado_local() -> Dictionary:
	return {
		"reto1_resuelto": _reto1_resuelto,
		"reto2_resuelto": _reto2_resuelto,
		"reto3_resuelto": _reto3_resuelto,
		"retos_resueltos": _cantidad_retos_resueltos(),
		"fallos_totales": _fallos_reto1 + _fallos_reto2 + _fallos_reto3,
		"mentor_cuestionado": _mentor_cuestionado,
		"ayuda_recibida": _ayuda_recibida,
		"completado": _completado,
		"enfoque_salida": _enfoque_salida,
	}


func puede_salir() -> bool:
	if _completado:
		return false
	return (_cantidad_retos_resueltos() == 3) or _mentor_cuestionado


func solicitar_salida() -> bool:
	if _completado:
		return false
	if not puede_salir():
		_mostrar_mensaje_hud(
			(
				"El umbral del estuario permanece cerrado. "
				+ "Resuelve los tres retos o cuestiona al Maestro."
			)
		)
		return false

	_completado = true
	if _cantidad_retos_resueltos() == 3 and _mentor_cuestionado:
		_enfoque_salida = "integral"
	elif _cantidad_retos_resueltos() == 3:
		_enfoque_salida = "metodico"
	else:
		_enfoque_salida = "cuestionamiento"

	_actualizar_interacciones()
	_mostrar_mensaje_hud(
		(
			"Estuario del Maestro superado (%s). " % _enfoque_salida
			+ "Has demostrado capacidad analítica."
		)
	)
	completado.emit()
	return true


func _cantidad_retos_resueltos() -> int:
	var total := 0
	if _reto1_resuelto:
		total += 1
	if _reto2_resuelto:
		total += 1
	if _reto3_resuelto:
		total += 1
	return total


func _instanciar_caminante() -> void:
	_caminante = ESCENA_CAMINANTE.instantiate() as CharacterBody3D
	_caminante.name = "Caminante"
	_caminante.position = Vector3(0.0, 1.0, 8.0)
	add_child(_caminante)
	_caminante.call("conectar_hud", _hud)


func _montar_entorno() -> void:
	var ambiente_nodo := WorldEnvironment.new()
	ambiente_nodo.name = "AmbienteEstuario"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.04, 0.07, 0.11)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.50, 0.58, 0.68)
	entorno.ambient_light_energy = 0.65
	ambiente_nodo.environment = entorno
	add_child(ambiente_nodo)

	var luz_sol := DirectionalLight3D.new()
	luz_sol.name = "LuzEstuario"
	luz_sol.rotation_degrees = Vector3(-48, -30, 0)
	luz_sol.light_color = Color(0.65, 0.75, 0.88)
	luz_sol.light_energy = 0.85
	luz_sol.shadow_enabled = true
	add_child(luz_sol)

	_crear_bloque("SueloCanal", Vector3(0, -0.5, 0), Vector3(20, 1.0, 24), COLOR_PIEDRA)
	_crear_bloque(
		"AguaEstuarioIzquierda", Vector3(-9.5, -0.4, 0), Vector3(3, 0.8, 24), COLOR_AGUA, false
	)
	_crear_bloque(
		"AguaEstuarioDerecha", Vector3(9.5, -0.4, 0), Vector3(3, 0.8, 24), COLOR_AGUA, false
	)

	_crear_bloque("MuroNorte", Vector3(0, 2.5, -11.5), Vector3(20, 5.0, 1.0), COLOR_PIEDRA)
	_crear_bloque("MuroSur", Vector3(0, 2.5, 11.5), Vector3(20, 5.0, 1.0), COLOR_PIEDRA)
	_crear_bloque("MuroOeste", Vector3(-11.0, 2.5, 0), Vector3(1.0, 5.0, 24), COLOR_PIEDRA)
	_crear_bloque("MuroEste", Vector3(11.0, 2.5, 0), Vector3(1.0, 5.0, 24), COLOR_PIEDRA)

	_crear_bloque("AtrilReto1", Vector3(-5.0, 0.75, 2.0), Vector3(1.6, 1.5, 1.2), COLOR_MADERA)
	_crear_bloque("AtrilReto2", Vector3(0.0, 0.75, -2.0), Vector3(1.6, 1.5, 1.2), COLOR_MADERA)
	_crear_bloque("AtrilReto3", Vector3(5.0, 0.75, 2.0), Vector3(1.6, 1.5, 1.2), COLOR_MADERA)

	_crear_bloque("EstatuaMaestro", Vector3(0.0, 1.5, -7.5), Vector3(1.8, 3.0, 1.8), COLOR_MENTOR)
	_crear_bloque(
		"MarcoUmbral", Vector3(0.0, 2.5, -10.8), Vector3(4.0, 5.0, 0.5), COLOR_PIEDRA_CLARA
	)

	_crear_rotulo("Reto I: Evidencia", Vector3(-5.0, 2.0, 2.0))
	_crear_rotulo("Reto II: Dicotomia", Vector3(0.0, 2.0, -2.0))
	_crear_rotulo("Reto III: Hipotesis", Vector3(5.0, 2.0, 2.0))
	_crear_rotulo("Maestro del Estuario", Vector3(0.0, 3.2, -7.5))
	_crear_rotulo("Umbral de Salida", Vector3(0.0, 4.2, -10.5))


func _crear_bloque(
	nombre: String, posicion: Vector3, tamano: Vector3, color: Color, con_colision := true
) -> void:
	var nodo_raiz: Node3D
	if con_colision:
		var cuerpo := StaticBody3D.new()
		var colision := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = tamano
		colision.shape = caja
		cuerpo.add_child(colision)
		nodo_raiz = cuerpo
	else:
		nodo_raiz = Node3D.new()

	nodo_raiz.name = nombre
	nodo_raiz.position = posicion

	var malla_inst := MeshInstance3D.new()
	var cubo := BoxMesh.new()
	cubo.size = tamano
	malla_inst.mesh = cubo

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	malla_inst.material_override = mat

	nodo_raiz.add_child(malla_inst)
	add_child(nodo_raiz)


func _crear_rotulo(texto: String, posicion: Vector3) -> void:
	var label := Label3D.new()
	label.name = "Rotulo_" + texto.replace(" ", "_").replace(":", "")
	label.text = texto
	label.position = posicion
	label.pixel_size = 0.005
	label.font_size = 32
	label.modulate = COLOR_INSCRIPCION
	add_child(label)


func _montar_interactuables() -> void:
	_interactuable_reto1 = _crear_interactuable(
		"InteractuableReto1",
		Vector3(-5.0, 1.2, 2.0),
		Vector3(2.0, 2.0, 2.0),
		Interactuable3D.Verbo.EXAMINAR,
		"Afirmacion vs Evidencia",
	)
	_interactuable_reto1.activado.connect(func(_actor: Node): _iniciar_reto1())

	_interactuable_reto2 = _crear_interactuable(
		"InteractuableReto2",
		Vector3(0.0, 1.2, -2.0),
		Vector3(2.0, 2.0, 2.0),
		Interactuable3D.Verbo.EXAMINAR,
		"Refutar Falsa Dicotomia",
	)
	_interactuable_reto2.activado.connect(func(_actor: Node): _iniciar_reto2())

	_interactuable_reto3 = _crear_interactuable(
		"InteractuableReto3",
		Vector3(5.0, 1.2, 2.0),
		Vector3(2.0, 2.0, 2.0),
		Interactuable3D.Verbo.EXAMINAR,
		"Revisar Hipotesis",
	)
	_interactuable_reto3.activado.connect(func(_actor: Node): _iniciar_reto3())

	_interactuable_mentor = _crear_interactuable(
		"InteractuableMentor",
		Vector3(0.0, 1.5, -6.5),
		Vector3(2.5, 3.0, 2.5),
		Interactuable3D.Verbo.LLAMAR,
		"al Maestro del Estuario",
	)
	_interactuable_mentor.activado.connect(func(_actor: Node): _interactuar_mentor())

	_interactuable_salida = _crear_interactuable(
		"InteractuableSalida",
		Vector3(0.0, 1.5, -10.0),
		Vector3(3.0, 3.0, 1.5),
		Interactuable3D.Verbo.USAR,
		"umbral de salida",
	)
	_interactuable_salida.activado.connect(func(_actor: Node): solicitar_salida())

	_actualizar_interacciones()


func _crear_interactuable(
	nombre: String,
	posicion: Vector3,
	tamano: Vector3,
	verbo: int,
	titulo: String,
) -> Interactuable3D:
	var obj := Interactuable3D.new()
	obj.name = nombre
	obj.position = posicion
	obj.verbo = verbo
	obj.nombre_objeto = titulo
	obj.sonido = Interactuable3D.SIN_SONIDO

	var colision := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = tamano
	colision.shape = caja
	obj.add_child(colision)

	add_child(obj)
	return obj


func _actualizar_interacciones() -> void:
	if is_instance_valid(_interactuable_salida):
		_interactuable_salida.habilitado = not _completado


func _montar_hud() -> void:
	_hud = HUDLayer.new()
	_hud.name = "HUD_Estuario"
	_hud.layer = 8
	add_child(_hud)

	var margin_top := MarginContainer.new()
	margin_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin_top.add_theme_constant_override("margin_left", 24)
	margin_top.add_theme_constant_override("margin_right", 24)
	margin_top.add_theme_constant_override("margin_top", 18)
	_hud.add_child(margin_top)

	_label_objetivo = Label.new()
	_label_objetivo.name = "LabelObjetivo"
	_label_objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_objetivo.custom_minimum_size = Vector2(0, 70)
	margin_top.add_child(_label_objetivo)

	_mostrar_mensaje_hud(
		(
			"Estuario del Maestro — Examina los tres atriles de investigación "
			+ "o dialoga con el Maestro."
		)
	)

	_panel_dialogo = PanelContainer.new()
	_panel_dialogo.name = "PanelDialogoEstuario"
	_panel_dialogo.visible = false
	_panel_dialogo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel_dialogo.custom_minimum_size = Vector2(0, 220)
	_hud.add_child(_panel_dialogo)

	var margin_panel := MarginContainer.new()
	margin_panel.add_theme_constant_override("margin_left", 20)
	margin_panel.add_theme_constant_override("margin_right", 20)
	margin_panel.add_theme_constant_override("margin_top", 12)
	margin_panel.add_theme_constant_override("margin_bottom", 12)
	_panel_dialogo.add_child(margin_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin_panel.add_child(vbox)

	_label_dialogo = Label.new()
	_label_dialogo.name = "LabelDialogo"
	_label_dialogo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_label_dialogo)

	_contenedor_opciones = VBoxContainer.new()
	_contenedor_opciones.name = "ContenedorOpciones"
	_contenedor_opciones.add_theme_constant_override("separation", 6)
	vbox.add_child(_contenedor_opciones)


func _mostrar_mensaje_hud(texto: String) -> void:
	if is_instance_valid(_label_objetivo):
		_label_objetivo.text = texto


func _abrir_panel_dialogo(texto_pregunta: String, opciones: Array) -> void:
	if is_instance_valid(_caminante):
		_caminante.process_mode = Node.PROCESS_MODE_DISABLED

	_label_dialogo.text = texto_pregunta
	for hijo in _contenedor_opciones.get_children():
		hijo.queue_free()

	var primer_boton: Button = null

	for i in range(opciones.size()):
		var datos_opcion: Dictionary = opciones[i]
		var boton := Button.new()
		boton.text = datos_opcion.get("texto", "")
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var cb: Callable = datos_opcion.get("callback", Callable())
		boton.pressed.connect(
			func():
				_cerrar_panel_dialogo()
				if cb.is_valid():
					cb.call()
		)
		_contenedor_opciones.add_child(boton)
		if primer_boton == null:
			primer_boton = boton

	_panel_dialogo.visible = true
	if primer_boton != null:
		primer_boton.grab_focus()


func _cerrar_panel_dialogo() -> void:
	_panel_dialogo.visible = false
	for hijo in _contenedor_opciones.get_children():
		hijo.queue_free()

	if is_instance_valid(_caminante):
		_caminante.process_mode = Node.PROCESS_MODE_INHERIT


func _iniciar_reto1() -> void:
	if _reto1_resuelto:
		_mostrar_mensaje_hud("Reto I superado: Afirmación contrastada con evidencia.")
		return

	var enunciado := (
		"RETO I — Afirmación:\n"
		+ "«El dique del canal jamás colapsó; las aguas cambiaron de curso espontáneamente».\n"
		+ "¿Cómo evalúas esta afirmación?"
	)

	var opciones := [
		{
			"texto": "A) Aceptar el texto oficial sin dudar.",
			"callback": Callable(self, "_on_reto1_opcion_a"),
		},
		{
			"texto": "B) Contrastar con las marcas de erosión y sedimentos en el dique.",
			"callback": Callable(self, "_on_reto1_opcion_b"),
		},
		{
			"texto": "C) Descartar todo el manuscrito por considerarlo ficción.",
			"callback": Callable(self, "_on_reto1_opcion_c"),
		},
	]

	_abrir_panel_dialogo(enunciado, opciones)


func _on_reto1_opcion_a() -> void:
	_evaluar_reto1(false, "Has aceptado una afirmación sin contrastar.")


func _on_reto1_opcion_b() -> void:
	_evaluar_reto1(true, "¡Correcto! La erosión física desmiente la versión oficial.")


func _on_reto1_opcion_c() -> void:
	_evaluar_reto1(false, "Descartar sin analizar ignora las pistas en las contradicciones.")


func _evaluar_reto1(exito: bool, mensaje: String) -> void:
	if exito:
		_reto1_resuelto = true
		_mostrar_mensaje_hud(mensaje)
	else:
		_fallos_reto1 += 1
		_mostrar_mensaje_hud(mensaje + " Reintenta o consulta al Maestro.")


func _iniciar_reto2() -> void:
	if _reto2_resuelto:
		_mostrar_mensaje_hud("Reto II superado: Falsa dicotomía refutada.")
		return

	var enunciado := (
		"RETO II — Dilema planteado:\n"
		+ "«O los conservadores destruyeron los pergaminos, o los reformistas los perdieron».\n"
		+ "¿Qué falla lógica detectas?"
	)

	var opciones := [
		{
			"texto": "A) Atribuir la culpa exclusivamente a los conservadores.",
			"callback": Callable(self, "_on_reto2_opcion_a"),
		},
		{
			"texto": "B) Atribuir la culpa exclusivamente a los reformistas.",
			"callback": Callable(self, "_on_reto2_opcion_b"),
		},
		{
			"texto":
			"C) Refutar dicotomía: existió una orden de traslado coordinada e interrumpida.",
			"callback": Callable(self, "_on_reto2_opcion_c"),
		},
	]

	_abrir_panel_dialogo(enunciado, opciones)


func _on_reto2_opcion_a() -> void:
	_evaluar_reto2(false, "Caes en la trampa del dilema.")


func _on_reto2_opcion_b() -> void:
	_evaluar_reto2(false, "Eliges entre solo dos opciones preconcebidas.")


func _on_reto2_opcion_c() -> void:
	_evaluar_reto2(true, "¡Correcto! La disyuntiva excluía la causa real.")


func _evaluar_reto2(exito: bool, mensaje: String) -> void:
	if exito:
		_reto2_resuelto = true
		_mostrar_mensaje_hud(mensaje)
	else:
		_fallos_reto2 += 1
		_mostrar_mensaje_hud(mensaje + " Pide ayuda al Maestro o reintenta.")


func _iniciar_reto3() -> void:
	if _reto3_resuelto:
		_mostrar_mensaje_hud("Reto III superado: Hipótesis revisada ante evidencia.")
		return

	var enunciado := (
		"RETO III — Hipótesis inicial:\n"
		+ "«El archivo del estuario fue abandonado por falta de interés en sus textos».\n"
		+ "Hallas recibos de tinta hasta el día de la evacuación. ¿Qué haces?"
	)

	var opciones := [
		{
			"texto": "A) Ocultar los recibos para no modificar la hipótesis inicial.",
			"callback": Callable(self, "_on_reto3_opcion_a"),
		},
		{
			"texto":
			"B) Reformular hipótesis: la actividad siguió hasta una orden externa repentina.",
			"callback": Callable(self, "_on_reto3_opcion_b"),
		},
		{
			"texto": "C) Abandonar la investigación por contradictoria.",
			"callback": Callable(self, "_on_reto3_opcion_c"),
		},
	]

	_abrir_panel_dialogo(enunciado, opciones)


func _on_reto3_opcion_a() -> void:
	_evaluar_reto3(false, "Suprimir datos para proteger una hipótesis es un error.")


func _on_reto3_opcion_b() -> void:
	_evaluar_reto3(true, "¡Correcto! Revisar hipótesis ante nuevos datos es clave.")


func _on_reto3_opcion_c() -> void:
	_evaluar_reto3(false, "La contradicción aparente es el motor del hallazgo.")


func _evaluar_reto3(exito: bool, mensaje: String) -> void:
	if exito:
		_reto3_resuelto = true
		_mostrar_mensaje_hud(mensaje)
	else:
		_fallos_reto3 += 1
		_mostrar_mensaje_hud(mensaje + " Revisa la evidencia o habla con el Maestro.")


func _interactuar_mentor() -> void:
	var total_fallos := _fallos_reto1 + _fallos_reto2 + _fallos_reto3
	var resueltos := _cantidad_retos_resueltos()

	var saludo := ""
	if resueltos == 3:
		saludo = (
			"Maestro del Estuario:\n"
			+ "«Has analizado las tres pruebas con solidez. El umbral está abierto.»"
		)
	elif total_fallos > 0:
		_ayuda_recibida = true
		saludo = (
			"Maestro del Estuario:\n"
			+ "«Observo vacilación. Investigar es poner a prueba premisas y buscar lo excluido.»"
		)
	else:
		saludo = (
			"Maestro del Estuario:\n"
			+ "«Bienvenido al estuario. Contrastamos testimonios y ajustamos ideas a hechos.»"
		)

	var opciones := []

	if total_fallos > 0 and resueltos < 3:
		(
			opciones
			. append(
				{
					"texto": "1) Pedir orientación sobre las fallas metodológicas.",
					"callback": Callable(self, "_orientacion_mentor"),
				}
			)
		)

	(
		opciones
		. append(
			{
				"texto":
				"2) Cuestionar al Maestro («¿Acaso vuestra taxonomía no descarta otras voces?»).",
				"callback": Callable(self, "_cuestionar_mentor"),
			}
		)
	)

	(
		opciones
		. append(
			{
				"texto": "3) Agradecer la lección y continuar.",
				"callback": Callable(self, "_on_mentor_agradecer"),
			}
		)
	)

	_abrir_panel_dialogo(saludo, opciones)


func _on_mentor_agradecer() -> void:
	_mostrar_mensaje_hud("El Maestro asiente en silencio. Continúa cuando gustes.")


func _orientacion_mentor() -> void:
	var pistas: Array = []
	if not _reto1_resuelto and _fallos_reto1 > 0:
		pistas.append("Reto I: No te fíes del texto oficial si la materia física muestra fisuras.")
	if not _reto2_resuelto and _fallos_reto2 > 0:
		pistas.append("Reto II: Ante A o B, busca qué premisa oculta sostiene la trampa.")
	if not _reto3_resuelto and _fallos_reto3 > 0:
		pistas.append("Reto III: Una hipótesis debe cambiar ante nuevos datos.")

	var texto_pistas := "Consejos del Maestro:\n" + "\n".join(pistas)
	_mostrar_mensaje_hud(texto_pistas)


func _cuestionar_mentor() -> void:
	_mentor_cuestionado = true
	var respuesta := (
		"Maestro del Estuario:\n"
		+ "«Un investigador no acepta la autoridad a ciegas. Al cuestionar mi clasificación, "
		+ "demuestras criterio analítico. Tienes acceso al umbral de salida por derecho crítico.»"
	)
	_mostrar_mensaje_hud("Has cuestionado al Maestro. La salida ahora está disponible.")
	_actualizar_interacciones()

	var opciones := [
		{
			"texto": "Aceptar el reconocimiento del Maestro.",
			"callback": Callable(self, "_on_aceptar_reconocimiento"),
		}
	]
	_abrir_panel_dialogo(respuesta, opciones)


func _on_aceptar_reconocimiento() -> void:
	_mostrar_mensaje_hud("Puedes cruzar el umbral cuando lo desees.")
