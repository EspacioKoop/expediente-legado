## Adaptador del puesto de trabajo al shell de escritorio (#534, #535, #536, #538).
##
## `Dia` sigue siendo dueño de entrar/salir del puesto y de persistir la partida.
## Este controller detecta únicamente la pantalla que contiene el visor histórico,
## lo adopta como una aplicación del shell y deja intactos duelos/cinemáticas.
extends Node

var _pantalla_envuelta_id := 0
var _siga_app: EscritorioSigaApp
var _explorador_app: EscritorioSigaApp
var _correo_app: EscritorioSigaApp

## Todas las apps registradas en este puesto, para persistencia declarada
## (#535): quien guarde/cargue partida no necesita conocerlas una a una.
var _apps: Array[EscritorioSigaApp] = []


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var pantalla: Variant = dia._pantalla
	if pantalla == null or not is_instance_valid(pantalla):
		_pantalla_envuelta_id = 0
		return
	var id := (pantalla as Node).get_instance_id()
	if id == _pantalla_envuelta_id:
		return
	var visor := (pantalla as Node).get_node_or_null("Visor")
	if visor == null or not visor is Control:
		return
	_pantalla_envuelta_id = id
	_envolver_puesto(dia, pantalla as CanvasLayer, visor as Control)


func _envolver_puesto(dia: Node, pantalla: CanvasLayer, visor: Control) -> void:
	var escritorio := EscritorioSigaVisual.new()
	escritorio.name = "EscritorioSiga"
	var preferencias := PreferenciasSiga.cargar()
	# configurar_escala_ui() construye la interfaz al entrar en el árbol, así
	# que tiene que fijarse antes de add_child; el resto de "configurar_*" da igual.
	escritorio.configurar_escala_ui(float(preferencias.get("escala_ui", 1.0)))
	pantalla.add_child(escritorio)

	escritorio.configurar_reduccion_movimiento(
		bool(preferencias.get("reduccion_movimiento", false))
	)
	escritorio.establecer_reloj_narrativo(tr("ESCRITORIO_RELOJ") % int(dia.jornada.get("dia", 1)))

	var creador_visor := Callable(self, "_crear_visor")
	var titulo_siga := tr("ESCRITORIO_SIGA_TITULO")
	_siga_app = EscritorioSigaApp.new("siga-98", titulo_siga, creador_visor, "siga")
	_siga_app.registrar_en(escritorio)
	_apps.append(_siga_app)

	# El Explorador consume el mismo contrato que SIGA, pero su contenido se crea
	# bajo demanda y recibe solo el contexto de campaña que necesita para resolver
	# reglas declarativas. No conserva ni modifica jornada/expedientes por su cuenta.
	_explorador_app = EscritorioSigaApp.new(
		"explorador", "Explorador", Callable(self, "_crear_explorador"), "equipo"
	)
	_explorador_app.tamano_minimo = Vector2(480, 330)
	_explorador_app.tamano_preferido = Vector2(720, 520)
	_explorador_app.redimensionable = true
	_explorador_app.registrar_en(escritorio)
	_apps.append(_explorador_app)

	# Correo es otra app del contrato común: su contenido se resuelve contra la
	# jornada viva y la plantilla real de esta vuelta. Solo persiste qué mensajes
	# se leyeron; no guarda una copia de la campaña ni concede progreso.
	_correo_app = EscritorioSigaApp.new(
		"correo", "Correo interno", Callable(self, "_crear_correo"), "correo"
	)
	_correo_app.tamano_minimo = Vector2(620, 400)
	_correo_app.tamano_preferido = Vector2(790, 540)
	_correo_app.redimensionable = true
	_correo_app.persistir_estado = true
	_correo_app.registrar_en(escritorio)
	_apps.append(_correo_app)

	# Reponer el estado declarado ANTES de adoptar/abrir nada: así una app que
	# lea su estado local al construir su contenido (como hace Correo) ya
	# lo ve actualizado desde el primer fotograma.
	EstadoAplicacionesSiga.cargar(_apps)

	# Ayuda sigue siendo utilidad propia del shell; las aplicaciones de juego usan
	# EscritorioSigaApp y no conocen la tabla de ventanas interna.
	escritorio.registrar_identidad_visual("ayuda-sistema", "ayuda")
	escritorio.activar_ayuda_sistema()
	_siga_app.adoptar_en(escritorio, visor)
	escritorio.salir_solicitado.connect(_solicitar_salida)

	# `_abrir_expediente()` conserva temporalmente el botón histórico para que
	# la propiedad de salir siga en Dia. El shell ofrece esa acción en su menú,
	# así que se oculta la representación antigua sin desconectar su callback.
	for hijo in pantalla.get_children():
		if hijo is Button:
			(hijo as Button).visible = false


## Vuelca el estado local de las apps que lo declaren (#535). Se llama desde
## el mismo punto donde `Dia` guarda `Partida`, pero escribe en un fichero
## aparte: la campaña y el estado de aplicaciones nunca comparten sección.
func guardar_estado_aplicaciones() -> void:
	if not _apps.is_empty():
		EstadoAplicacionesSiga.guardar(_apps)


func _crear_visor() -> Control:
	return load("res://escenas/visor.tscn").instantiate() as Control


func _crear_explorador() -> Control:
	var explorador := ExploradorSiga.new()
	var dia := get_parent()
	var jornada_actual := 1
	if dia != null:
		jornada_actual = int(dia.jornada.get("dia", 1))
	(
		explorador
		. configurar_contexto(
			{
				"jornada": jornada_actual,
				# Reservas explícitas para #28: por defecto no revelan ni desbloquean nada.
				"habilitar_enlace13": false,
				"credenciales": [],
			}
		)
	)
	return explorador


func _crear_correo() -> Control:
	var correo := CorreoSiga.new()
	var dia := get_parent()
	if dia == null:
		return correo

	var presentes: Array[String] = []
	var semilla_plantilla := int(dia.jornada.get("plantilla", 0))
	for valor in Companeros.plantilla(semilla_plantilla):
		if valor is Dictionary:
			var id := String((valor as Dictionary).get("id", ""))
			if not id.is_empty():
				presentes.append(id)
	correo.configurar_contexto(dia.jornada, presentes)

	if _correo_app != null:
		var guardados: Variant = _correo_app.obtener_estado_local("leidos", [])
		if guardados is Array:
			correo.configurar_leidos(guardados as Array)
	correo.mensaje_leido.connect(_registrar_correo_leido)
	return correo


func _registrar_correo_leido(id: String) -> void:
	if _correo_app == null or id.is_empty():
		return
	var leidos: Array = []
	var guardados: Variant = _correo_app.obtener_estado_local("leidos", [])
	if guardados is Array:
		leidos = (guardados as Array).duplicate()
	if not leidos.has(id):
		leidos.append(id)
	_correo_app.establecer_estado_local("leidos", leidos)


func _solicitar_salida() -> void:
	var dia := get_parent()
	if dia != null and dia._pantalla != null:
		dia._cerrar_expediente()
