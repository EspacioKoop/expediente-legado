## Adaptador del puesto de trabajo al shell de escritorio (#539).
##
## `Dia` sigue siendo dueño de entrar/salir del puesto y de persistir la partida.
## Este controller detecta únicamente la pantalla que contiene el visor histórico,
## lo adopta como una aplicación del shell y deja intactos duelos/cinemáticas.
extends Node

var _pantalla_envuelta_id := 0
var _siga_app: EscritorioSigaApp
var _explorador_app: EscritorioSigaApp
var _navegador_app: EscritorioSigaApp
var _software_app: EscritorioSigaApp
var _correo_app: EscritorioSigaApp
var _bloc_notas_app: EscritorioSigaApp
var _calculadora_app: EscritorioSigaApp
var _catalogo_anomalias_app: EscritorioSigaApp
var _evaluaciones_app: EscritorioSigaApp
var _auditorias_app: EscritorioSigaApp
var _explorador_vista: ExploradorSiga
var _navegador_vista: NavegadorSiga
var _menu_global: Node
var _boton_salida_menu_global: Button

## Todas las apps registradas en este puesto, para persistencia declarada
## (#535): quien guarde/cargue partida no necesita conocerlas una a una.
var _apps: Array[EscritorioSigaApp] = []


func _ready() -> void:
	call_deferred("_integrar_salida_menu_global")
	call_deferred("_integrar_climax_hastur")


## #1103: el escritorio solo compone el owner. Las reglas del clímax viven
## fuera de OS98 y consumen exclusivamente la señal pública del handoff.
func _integrar_climax_hastur() -> void:
	var dia := get_parent()
	if dia == null or dia.get_node_or_null("ClimaxHasturOwnerController") != null:
		return
	var controlador := load("res://guion/dia_climax_hastur_app.gd").new() as Node
	if controlador == null:
		return
	controlador.name = "ClimaxHasturOwnerController"
	dia.add_child(controlador)


func _exit_tree() -> void:
	if is_instance_valid(_boton_salida_menu_global):
		_boton_salida_menu_global.queue_free()
	_boton_salida_menu_global = null
	_menu_global = null


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		_actualizar_salida_menu_global(false)
		return
	var pantalla: Variant = dia._pantalla
	var puesto_activo := (
		pantalla != null
		and is_instance_valid(pantalla)
		and (pantalla as Node).get_node_or_null("EscritorioSiga") != null
	)
	_actualizar_salida_menu_global(puesto_activo)
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


## Salida de rescate de #793. Vive en el menú global, no dentro de OS98:
## Escape/Start reconstruyen allí un foco propio y liberan el ratón aunque el
## escritorio haya perdido ambos. El botón entra en el VBox normal del menú,
## así que ratón, teclado y mando comparten exactamente la misma ruta de salida.
func _integrar_salida_menu_global() -> void:
	if is_instance_valid(_boton_salida_menu_global):
		return
	var menu := get_node_or_null("/root/MenuGlobal")
	if menu == null:
		call_deferred("_integrar_salida_menu_global")
		return
	var salir := menu.get("_salir") as Button
	if salir == null or salir.get_parent() == null:
		call_deferred("_integrar_salida_menu_global")
		return
	var caja := salir.get_parent() as VBoxContainer
	if caja == null:
		return

	_menu_global = menu
	_boton_salida_menu_global = Button.new()
	_boton_salida_menu_global.name = "SalirPuestoSiga"
	_boton_salida_menu_global.text = tr("PUESTO_LEVANTARSE")
	_boton_salida_menu_global.tooltip_text = _boton_salida_menu_global.text
	_boton_salida_menu_global.accessibility_name = _boton_salida_menu_global.text
	_boton_salida_menu_global.visible = false
	_boton_salida_menu_global.pressed.connect(_salir_desde_menu_global)
	caja.add_child(_boton_salida_menu_global)
	caja.move_child(_boton_salida_menu_global, salir.get_index())


func _actualizar_salida_menu_global(activa: bool) -> void:
	if is_instance_valid(_boton_salida_menu_global):
		_boton_salida_menu_global.visible = activa


func _salir_desde_menu_global() -> void:
	if is_instance_valid(_boton_salida_menu_global):
		_boton_salida_menu_global.visible = false
	if is_instance_valid(_menu_global):
		_menu_global.call("_cerrar")
	_solicitar_salida()


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
	# SIGA concentra índice, documento, pronóstico y estado. El tamaño de serie
	# (760×540) hacía que el índice de folios se colapsara y obligaba a jugar
	# dentro de una ventana menor que el propio contenido. En 1080p abre grande
	# pero deja escritorio visible alrededor, y sigue siendo redimensionable.
	_siga_app.tamano_minimo = Vector2(900, 620)
	_siga_app.tamano_preferido = Vector2(1180, 800)
	_siga_app.redimensionable = true
	_siga_app.registrar_en(escritorio)
	_apps.append(_siga_app)

	# El Explorador consume el mismo contrato que SIGA, pero su contenido se crea
	# bajo demanda. Desde #539 persiste únicamente la progresión local del OS por
	# partida/vuelta; no duplica jornada, expedientes ni contenido de campaña.
	_explorador_app = EscritorioSigaApp.new(
		"explorador", "Explorador", Callable(self, "_crear_explorador"), "explorador"
	)
	_explorador_app.tamano_minimo = Vector2(480, 330)
	_explorador_app.tamano_preferido = Vector2(720, 520)
	_explorador_app.redimensionable = true
	_explorador_app.persistir_estado = true
	_explorador_app.registrar_en(escritorio)
	_apps.append(_explorador_app)

	# Navegador Web98 consume el índice declarativo ya existente (#667). Historial
	# y favoritos son estado local persistible; el conocimiento de #539 se deriva
	# del mismo estado OS98 que recibe Explorador.
	_navegador_app = EscritorioSigaApp.new(
		"navegador-web98", "Navegador Web98", Callable(self, "_crear_navegador"), "web98"
	)
	_navegador_app.tamano_minimo = Vector2(640, 430)
	_navegador_app.tamano_preferido = Vector2(820, 560)
	_navegador_app.redimensionable = true
	_navegador_app.persistir_estado = true
	_navegador_app.registrar_en(escritorio)
	_apps.append(_navegador_app)

	# #663 se aloja como una aplicación normal del shell. Su estado local solo
	# contiene instalaciones y ejecuciones ficticias; nunca toca campaña ni host.
	_software_app = EscritorioSigaApp.new(
		"software-98", "Archivo de programas", Callable(self, "_crear_software"), "software"
	)
	_software_app.tamano_minimo = Vector2(600, 390)
	_software_app.tamano_preferido = Vector2(760, 520)
	_software_app.redimensionable = true
	_software_app.persistir_estado = true
	_software_app.registrar_en(escritorio)
	_apps.append(_software_app)

	# Correo es otra app del contrato común: su contenido se resuelve contra la
	# jornada viva y la plantilla real de esta vuelta. Solo persiste qué mensajes
	# se leyeron y qué respuestas eligió el jugador; no guarda una copia de la
	# campaña ni concede progreso.
	_correo_app = EscritorioSigaApp.new(
		"correo", CorreoSiga.texto("titulo_app"), Callable(self, "_crear_correo"), "correo"
	)
	_correo_app.tamano_minimo = Vector2(620, 400)
	_correo_app.tamano_preferido = Vector2(790, 540)
	_correo_app.redimensionable = true
	_correo_app.persistir_estado = true
	_correo_app.registrar_en(escritorio)
	_apps.append(_correo_app)

	# Primeras utilidades funcionales de #538. El bloc persiste solo texto local,
	# separado por raíz de partida; la calculadora no conserva estado y limita su
	# evaluación a aritmética, sin acceso a rutas, procesos ni APIs del host.
	_bloc_notas_app = EscritorioSigaApp.new(
		"bloc-notas", "Bloc de notas", Callable(self, "_crear_bloc_notas"), "bloc-notas"
	)
	_bloc_notas_app.tamano_minimo = Vector2(440, 300)
	_bloc_notas_app.tamano_preferido = Vector2(620, 440)
	_bloc_notas_app.redimensionable = true
	_bloc_notas_app.persistir_estado = true
	_bloc_notas_app.registrar_en(escritorio)
	_apps.append(_bloc_notas_app)

	_calculadora_app = EscritorioSigaApp.new(
		"calculadora", "Calculadora", Callable(self, "_crear_calculadora"), "calculadora"
	)
	_calculadora_app.tamano_minimo = Vector2(360, 220)
	_calculadora_app.tamano_preferido = Vector2(430, 300)
	_calculadora_app.registrar_en(escritorio)
	_apps.append(_calculadora_app)

	# El catálogo de #149 es una vista de la memoria de Partida: no guarda estado
	# paralelo ni interpreta el sueño. Las entradas bloqueadas tampoco exponen
	# metadata del catálogo declarativo.
	_catalogo_anomalias_app = (
		EscritorioSigaApp
		. new(
			"catalogo-anomalias",
			CatalogoAnomaliasSiga.texto("titulo_app"),
			Callable(self, "_crear_catalogo_anomalias"),
			"catalogo-anomalias",
		)
	)
	_catalogo_anomalias_app.tamano_minimo = Vector2(560, 360)
	_catalogo_anomalias_app.tamano_preferido = Vector2(760, 500)
	_catalogo_anomalias_app.redimensionable = true
	_catalogo_anomalias_app.registrar_en(escritorio)
	_apps.append(_catalogo_anomalias_app)

	# #150: el informe ya sellado se consulta como otra aplicación del terminal.
	# La vista recibe Partida en directo pero es estrictamente de solo lectura:
	# no duplica historial en EstadoAplicacionesSiga ni recalcula vidas cerradas.
	_evaluaciones_app = (
		EscritorioSigaApp
		. new(
			"evaluaciones-desempeno",
			tr("EVALUACION_APP_TITULO"),
			Callable(self, "_crear_evaluaciones"),
			"siga",
		)
	)
	_evaluaciones_app.tamano_minimo = Vector2(560, 360)
	_evaluaciones_app.tamano_preferido = Vector2(780, 500)
	_evaluaciones_app.redimensionable = true
	_evaluaciones_app.registrar_en(escritorio)
	_apps.append(_evaluaciones_app)

	# #152: consulta del reto elegido para esta vida. Comparte el estado canónico
	# de Partida y no ofrece edición desde el escritorio: aceptar una condición
	# sigue siendo una decisión previa a empezar la vida laboral.
	_auditorias_app = (
		EscritorioSigaApp
		. new(
			"auditorias",
			tr("AUDITORIAS_APP_TITULO"),
			Callable(self, "_crear_auditorias"),
			"siga",
		)
	)
	_auditorias_app.tamano_minimo = Vector2(520, 300)
	_auditorias_app.tamano_preferido = Vector2(700, 430)
	_auditorias_app.redimensionable = true
	_auditorias_app.registrar_en(escritorio)
	_apps.append(_auditorias_app)

	# Reponer el estado declarado ANTES de adoptar/abrir nada: así una app que
	# lea su estado local al construir su contenido (como hacen Correo y #539) ya
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
	_explorador_vista = explorador
	var dia := get_parent()
	if dia != null:
		explorador.configurar_contexto(_contexto_os98(dia))
	explorador.documento_abierto.connect(_registrar_documento_os98)
	explorador.ruta_abierta.connect(_registrar_ruta_os98)
	return explorador


func _crear_navegador() -> Control:
	var navegador := NavegadorSiga.new()
	_navegador_vista = navegador
	var dia := get_parent()
	if dia != null:
		navegador.configurar_contexto(_contexto_os98(dia))
	if _navegador_app != null:
		navegador.configurar_estado(_navegador_app.obtener_estado_local("estado", {}))
	navegador.estado_cambiado.connect(_registrar_estado_navegador)
	return navegador


func _crear_software() -> Control:
	var software := SoftwareSiga.new()
	if _software_app != null:
		software.configurar_estado(_software_app.obtener_estado_local("estado", {}))
	software.estado_cambiado.connect(_registrar_estado_software)
	return software


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
		var clave := _clave_partida(dia)
		var por_partida: Variant = _correo_app.obtener_estado_local("leidos_por_partida", {})
		if por_partida is Dictionary:
			var guardados: Variant = (por_partida as Dictionary).get(clave, [])
			if guardados is Array:
				correo.configurar_leidos(guardados as Array)
		var respuestas_por_partida: Variant = _correo_app.obtener_estado_local(
			"respuestas_por_partida", {}
		)
		if respuestas_por_partida is Dictionary:
			var respuestas: Variant = (respuestas_por_partida as Dictionary).get(clave, {})
			if respuestas is Dictionary:
				correo.configurar_respuestas_enviadas(respuestas as Dictionary)
	correo.mensaje_leido.connect(_registrar_correo_leido)
	correo.respuesta_enviada.connect(_registrar_respuesta_correo)
	return correo


func _crear_bloc_notas() -> Control:
	var bloc := BlocNotasSiga.new()
	var dia := get_parent()
	if dia != null and _bloc_notas_app != null:
		var guardado: Variant = _bloc_notas_app.obtener_estado_local("texto_por_partida", {})
		if guardado is Dictionary:
			bloc.configurar_texto(String((guardado as Dictionary).get(_clave_partida(dia), "")))
	bloc.contenido_cambiado.connect(_registrar_texto_bloc)
	return bloc


func _crear_calculadora() -> Control:
	return CalculadoraSiga.new()


func _crear_catalogo_anomalias() -> Control:
	var catalogo := CatalogoAnomaliasSiga.new()
	var dia := get_parent()
	if dia == null:
		return catalogo
	var partida_actual: Variant = dia.get("partida")
	if partida_actual is Partida:
		catalogo.configurar_estado(partida_actual.estado)
	return catalogo


func _crear_evaluaciones() -> Control:
	var evaluaciones := EvaluacionDesempenoSiga.new()
	var dia := get_parent()
	if dia == null:
		return evaluaciones
	var partida_actual: Variant = dia.get("partida")
	if partida_actual is Partida:
		evaluaciones.configurar_estado(partida_actual.estado)
	return evaluaciones


func _crear_auditorias() -> Control:
	var auditorias := AuditoriasSiga.new()
	var dia := get_parent()
	if dia == null:
		return auditorias
	var partida_actual: Variant = dia.get("partida")
	if partida_actual is Partida:
		auditorias.configurar_estado(partida_actual.estado, false)
	return auditorias


func _registrar_documento_os98(documento_id: String) -> void:
	var dia := get_parent()
	if dia == null or _explorador_app == null:
		return
	var partida_actual: Variant = dia.get("partida")
	if not partida_actual is Partida:
		return
	var estado := _estado_os98(dia)
	if ContaminacionOs98.registrar_documento(
		(partida_actual as Partida).estado, estado, documento_id
	):
		_persistir_estado_os98(dia, estado)
		_sincronizar_contexto_os98(dia)


func _registrar_ruta_os98(ruta: String) -> void:
	var dia := get_parent()
	if dia == null or _explorador_app == null:
		return
	var partida_actual: Variant = dia.get("partida")
	if not partida_actual is Partida:
		return
	var estado := _estado_os98(dia)
	if not ContaminacionOs98.registrar_ruta(estado, ruta):
		return
	_al_acceso_administrativo(dia, partida_actual as Partida, estado)


func _sincronizar_contexto_os98(dia: Node) -> void:
	var contexto := _contexto_os98(dia)
	if _explorador_vista != null and is_instance_valid(_explorador_vista):
		_explorador_vista.configurar_contexto(contexto)
	if _navegador_vista != null and is_instance_valid(_navegador_vista):
		_navegador_vista.configurar_contexto(contexto)


func _contexto_os98(dia: Node) -> Dictionary:
	var partida_actual: Variant = dia.get("partida")
	if not partida_actual is Partida:
		return {
			"jornada": int(dia.jornada.get("dia", 1)),
			"dia": int(dia.jornada.get("dia", 1)),
			"credenciales": [],
			"conocimiento": [],
			"urls_caidas": [],
		}
	return (
		ContaminacionOs98
		. contexto(
			(partida_actual as Partida).estado,
			_estado_os98(dia),
			int(dia.jornada.get("dia", 1)),
		)
	)


func _estado_os98(dia: Node) -> Dictionary:
	var estado := ContaminacionOs98.nuevo()
	if _explorador_app == null:
		return estado
	var por_vuelta: Variant = _explorador_app.obtener_estado_local("contaminacion_por_vuelta", {})
	if por_vuelta is Dictionary:
		var guardado: Variant = (por_vuelta as Dictionary).get(_clave_vuelta(dia), {})
		if guardado is Dictionary:
			estado = (guardado as Dictionary).duplicate(true)
	return ContaminacionOs98.completar(estado)


func _persistir_estado_os98(dia: Node, estado: Dictionary) -> void:
	if _explorador_app == null:
		return
	var por_vuelta: Dictionary = {}
	var guardado: Variant = _explorador_app.obtener_estado_local("contaminacion_por_vuelta", {})
	if guardado is Dictionary:
		por_vuelta = (guardado as Dictionary).duplicate(true)
	por_vuelta[_clave_vuelta(dia)] = ContaminacionOs98.completar(estado).duplicate(true)
	_explorador_app.establecer_estado_local("contaminacion_por_vuelta", por_vuelta)


func _registrar_estado_navegador(estado: Dictionary) -> void:
	if _navegador_app != null:
		_navegador_app.establecer_estado_local("estado", estado)


func _registrar_estado_software(estado: Dictionary) -> void:
	if _software_app != null:
		_software_app.establecer_estado_local("estado", estado)


func _registrar_correo_leido(id: String) -> void:
	if _correo_app == null or id.is_empty():
		return
	var dia := get_parent()
	if dia == null:
		return
	var por_partida: Dictionary = {}
	var guardado: Variant = _correo_app.obtener_estado_local("leidos_por_partida", {})
	if guardado is Dictionary:
		por_partida = (guardado as Dictionary).duplicate(true)
	var clave := _clave_partida(dia)
	var leidos: Array = []
	var anteriores: Variant = por_partida.get(clave, [])
	if anteriores is Array:
		leidos = (anteriores as Array).duplicate()
	if not leidos.has(id):
		leidos.append(id)
	por_partida[clave] = leidos
	_correo_app.establecer_estado_local("leidos_por_partida", por_partida)


## #1029: solo se llama tras el primer acceso REAL a la ruta restringida.
## El memorándum revela credenciales y la UI puede mostrar la ruta, pero ninguno
## de esos dos hechos basta para adquirir Tarot.
func _al_acceso_administrativo(dia: Node, partida_actual: Partida, estado: Dictionary) -> void:
	_persistir_estado_os98(dia, estado)
	var partida_estado := partida_actual.estado
	Prometeo.desbloquear_carta_en_estado(partida_estado, "el-emperador")

	# Si Emperador era la última carta válida pendiente de una partida perfecta,
	# El Mundo se evalúa en este mismo evento y nunca al cargar el escritorio.
	var contenido := Contenido.new()
	if contenido.cargar():
		Prometeo.sincronizar_tarot_mundo(partida_estado, contenido.principales())

	# Dia escribe primero Partida y después el estado local de las apps OS98.
	# La rama de fallback solo protege este adaptador si se monta fuera de Dia.
	if dia.has_method("_guardar_o_avisar"):
		dia.call("_guardar_o_avisar", "")
	else:
		partida_actual.guardar()


func _registrar_respuesta_correo(
	mensaje_id: String, opcion_id: String, dia_envio: int, acciones_envio: int
) -> void:
	if _correo_app == null or mensaje_id.is_empty() or opcion_id.is_empty():
		return
	var dia := get_parent()
	if dia == null:
		return
	var por_partida: Dictionary = {}
	var guardado: Variant = _correo_app.obtener_estado_local("respuestas_por_partida", {})
	if guardado is Dictionary:
		por_partida = (guardado as Dictionary).duplicate(true)
	var clave := _clave_partida(dia)
	var respuestas: Dictionary = {}
	var anteriores: Variant = por_partida.get(clave, {})
	if anteriores is Dictionary:
		respuestas = (anteriores as Dictionary).duplicate(true)
	if respuestas.has(mensaje_id):
		return
	respuestas[mensaje_id] = {
		"opcion_id": opcion_id,
		"dia": dia_envio,
		"acciones": acciones_envio,
	}
	por_partida[clave] = respuestas
	_correo_app.establecer_estado_local("respuestas_por_partida", por_partida)


func _registrar_texto_bloc(texto: String) -> void:
	if _bloc_notas_app == null:
		return
	var dia := get_parent()
	if dia == null:
		return
	var por_partida: Dictionary = {}
	var guardado: Variant = _bloc_notas_app.obtener_estado_local("texto_por_partida", {})
	if guardado is Dictionary:
		por_partida = (guardado as Dictionary).duplicate(true)
	por_partida[_clave_partida(dia)] = texto
	_bloc_notas_app.establecer_estado_local("texto_por_partida", por_partida)


func _clave_partida(dia: Node) -> String:
	return str(int(dia.jornada.get("raiz", 0)))


func _clave_vuelta(dia: Node) -> String:
	return "%s:%d" % [_clave_partida(dia), int(dia.jornada.get("vuelta", 1))]


func _solicitar_salida() -> void:
	var dia := get_parent()
	if dia != null and dia._pantalla != null:
		dia._cerrar_expediente()
