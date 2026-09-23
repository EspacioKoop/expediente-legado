## Presentación del clima diario sobre el trayecto exterior (#143).
## También integra el diálogo diegético de #276 con la jerarquía global de #397.
extends "res://guion/dia_calle_app.gd"

const FONDO_BASE := Color(0.05, 0.05, 0.06)
## El exterior necesita horizonte: el fondo interior casi negro convertía los
## huecos entre fachadas en vacío. Este azul nocturno sigue siendo oscuro, pero
## separa con claridad cielo y siluetas urbanas. La niebla conserva prioridad y
## lo sustituye cuando el clima lo exige.
const FONDO_EXTERIOR := Color(0.035, 0.055, 0.10)
const TAM_TERMINAL_INTERACTIVO := Vector3(1.0, 1.2, 0.8)
var _clima_nodo: Node3D = null
var _archivado_sesion := ArchivadoSesion3D.new()
var _hud_prioridades: HUDLayer
var _dialogo_actual: PanelContainer
var _temporizador_estres_entorno: Timer


func _montar_interfaz() -> void:
	super._montar_interfaz()
	_hud_prioridades = HUDLayer.new()
	_hud_prioridades.name = "HUDPrioridades"
	_hud_prioridades.layer = 21
	add_child(_hud_prioridades)

	var estado := _rotulo.get_parent()
	if estado is Control:
		_hud_prioridades.registrar(HUDLayer.ESTADO, estado)
		_hud_prioridades.activar(HUDLayer.ESTADO)
	_caminante.conectar_hud(_hud_prioridades)
	_montar_temporizador_estres_entorno()


## #952: un intervalo completo debe transcurrir en la misma fase antes de
## modificar estrés. Reiniciar al entrar evita farmear cruzando una puerta.
func _montar_temporizador_estres_entorno() -> void:
	if is_instance_valid(_temporizador_estres_entorno):
		return
	_temporizador_estres_entorno = Timer.new()
	_temporizador_estres_entorno.name = "TemporizadorEstresEntorno"
	_temporizador_estres_entorno.wait_time = EstresAmbiental.INTERVALO_SEGUNDOS
	_temporizador_estres_entorno.one_shot = false
	_temporizador_estres_entorno.timeout.connect(_al_intervalo_estres_entorno)
	add_child(_temporizador_estres_entorno)
	_temporizador_estres_entorno.start()


func _reiniciar_temporizador_estres_entorno() -> void:
	if is_instance_valid(_temporizador_estres_entorno):
		_temporizador_estres_entorno.start()


func _al_intervalo_estres_entorno() -> void:
	if partida.guardado_pendiente or _pantalla != null or _entrada != null:
		return
	if is_instance_valid(_dialogo_actual):
		return
	if is_instance_valid(_caminante) and not _caminante.is_physics_processing():
		return
	if _ambiente == null:
		return

	var evento := EstresAmbiental.evento(
		String(jornada.get("fase", "")),
		_ambiente.ambient_light_energy,
		Jornada.hora_decimal(jornada),
	)
	if evento.is_empty():
		return
	if is_zero_approx(Estres.aplicar(jornada, evento, EstresAmbiental.INTENSIDAD)):
		return
	_guardar_o_avisar("")


func _abrir_vuelta() -> void:
	super._abrir_vuelta()
	if _entrada != null and _hud_prioridades != null:
		_hud_prioridades.visible = false


func _cerrar_vuelta() -> void:
	super._cerrar_vuelta()
	if _hud_prioridades != null:
		_hud_prioridades.visible = true


func _montar_onboarding_archivo() -> void:
	super._montar_onboarding_archivo()
	if _hud_prioridades == null or not is_instance_valid(_pista_puesto):
		return
	# #304 nació antes del árbitro global: además de registrar la superficie,
	# la movemos al mismo CanvasLayer para que composición y z-order sean únicos.
	if _pista_puesto.get_parent() != _hud_prioridades:
		_pista_puesto.reparent(_hud_prioridades, false)
	_hud_prioridades.registrar(HUDLayer.TUTORIAL, _pista_puesto)
	_hud_prioridades.activar(HUDLayer.TUTORIAL)


func _retirar_onboarding_archivo() -> void:
	if _hud_prioridades != null:
		_hud_prioridades.desactivar(HUDLayer.TUTORIAL)
	super._retirar_onboarding_archivo()


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	# Un guardado pendiente tiene prioridad absoluta: la capa base sabe cómo
	# reintentarlo sin duplicar efectos de jornada.
	if partida.guardado_pendiente:
		super._al_pisar_salida(cuerpo, salida)
		return
	if cuerpo != _caminante or _pantalla != null:
		super._al_pisar_salida(cuerpo, salida)
		return

	var destino := String(salida.get_meta("destino", ""))
	if jornada.get("fase", "") == "archivo" and destino == "trayecto":
		# El tránsito base guarda después de fichar y cambiar de fase. Aquí solo
		# asentamos la bandeja para que esa misma escritura incluya el abandono.
		_archivado_sesion.abandonar(self, false)

	# El sello se decide con el día todavía intacto. Al dormir se limpian los
	# contadores diarios al preparar la noche, así que después ya no sería
	# posible distinguir una jornada deliberadamente improductiva. El registro
	# es idempotente y el guardado normal del tránsito casa→sueño lo persiste.
	if jornada.get("fase", "") == "casa" and destino == "sueño":
		_registrar_noche_improductiva()

	# Las frases de compañeros ya no se disparan al pisar un volumen invisible.
	# Los triggers históricos se neutralizan al montar la oficina y este guard
	# evita que uno residual vuelva a convertirse en texto sin procedencia.
	if not String(salida.get_meta("frase", "")).is_empty():
		return

	super._al_pisar_salida(cuerpo, salida)


func _registrar_noche_improductiva() -> void:
	if not jornada.get("leido_hoy", []).is_empty():
		return
	if int(jornada.get("cerrados_hoy", 0)) != 0:
		return
	Sellos.registrar_sello(partida.estado, "noche-improductiva")


func _espacio_de(fase: String) -> Dictionary:
	var espacio: Dictionary = super._espacio_de(fase)
	if fase == "trayecto":
		espacio["exterior"] = true
	return espacio


## #966 consume únicamente fuentes canónicas: Jornada es dueña de la hora
## (#963), Estres del estado emocional (#952) y Meticulosidad de la atención
## documental diaria (#961). Normalizar aquí evita puntuaciones paralelas.
func _contexto_ambiente() -> Dictionary:
	return {
		"hora": Jornada.hora_decimal(jornada),
		"estres": Estres.nivel(jornada),
		"meticulosidad": float(Meticulosidad.puntos(jornada)) / float(Meticulosidad.PUNTOS_MAX),
	}


func _entrar_en(fase: String) -> void:
	_cerrar_dialogo_actual()
	_retirar_clima()
	super._entrar_en(fase)
	_reiniciar_temporizador_estres_entorno()
	Jornada.sincronizar_reloj_fase(jornada, fase)
	Ambiente.reproducir(self, fase, -24.0, _contexto_ambiente())
	if fase == "archivo":
		_montar_companeros_conversables()
		_montar_terminal_interactivo()
		_montar_archivadores_interactivos(_espacio_de(fase))
		_archivado_sesion.refrescar(self)
	elif fase == "casa":
		CasaUtileria.montar(_mundo)
		_montar_gilgamesh_vigilia()
		_montar_ryu_flow_vigilia()
	# La niebla cambia el fondo global del Environment. Cada entrada restaura el
	# valor base antes de decidir si este espacio recibe tiempo exterior.
	_ambiente.background_color = FONDO_BASE
	var espacio := _espacio_de(fase)
	if not bool(espacio.get("exterior", false)):
		return
	# Un cielo exterior legible no necesita otro WorldEnvironment: basta cambiar
	# el fondo del ya existente antes de aplicar clima. Niebla puede sobrescribirlo.
	_ambiente.background_color = FONDO_EXTERIOR
	# La consola de pruebas (#770) puede fijar un clima; sin ella manda el día.
	var forzado := String(jornada.get("clima_forzado", ""))
	_aplicar_clima(forzado if not forzado.is_empty() else Clima.estado(int(jornada.get("dia", 1))))


## Sustituye los volúmenes automáticos de frase por objetos a los que hay que
## mirar y activar. El cuerpo y su nombre siguen viniendo de Espacio3D; esta
## capa solo añade intención y conserva una fuente inequívoca del diálogo.
func _montar_companeros_conversables() -> void:
	_desactivar_frases_proximidad(_mundo)
	var espacio := EspaciosCatalogo.de_fase("archivo").duplicate(true)
	espacio["figuras"] = _plantilla_en(espacio)
	var indice := 0
	for figura in espacio.get("figuras", []):
		var clave := String(figura.get("frase", ""))
		if clave.is_empty():
			continue
		indice += 1
		var companero := CompaneroInteractivo3D.new()
		companero.name = "CompaneroConversable%d" % indice
		companero.position = figura["pos"] + Vector3(0.0, 0.9, 0.0)
		companero.nombre_visible = String(figura.get("rotulo", ""))
		companero.clave_dialogo = clave
		companero.conversacion_solicitada.connect(_iniciar_conversacion)
		_mundo.add_child(companero)


func _desactivar_frases_proximidad(nodo: Node) -> void:
	for hijo in nodo.get_children():
		if hijo is Area3D and not String(hijo.get_meta("frase", "")).is_empty():
			hijo.monitoring = false
			hijo.monitorable = false
			hijo.collision_layer = 0
		_desactivar_frases_proximidad(hijo)


func _iniciar_conversacion(
	companero: CompaneroInteractivo3D,
	_actor: Node,
	clave_dialogo: String,
) -> void:
	if _pantalla != null or clave_dialogo.is_empty():
		return
	if is_instance_valid(_dialogo_actual):
		return
	clave_dialogo = _clave_conversacion_contextual(companero, clave_dialogo)
	_dialogo_actual = DialogoDiegetico.mostrar(
		_hud_prioridades, _caminante, companero, tr(clave_dialogo)
	)
	_caminante.enfocar_conversacion(companero)
	_dialogo_actual.tree_exited.connect(_al_cerrar_dialogo)


func _clave_conversacion_contextual(
	companero: CompaneroInteractivo3D,
	clave_dialogo: String,
) -> String:
	if companero.nombre_visible != tr("COMPA_CUNADO"):
		return clave_dialogo

	var variante := (
		DialogoIdeologico
		. resolver(
			DialogoIdeologico.SUPERFICIE_OFICINA_CUNADO,
			partida.estado,
		)
	)
	var clave_reaccion := String(variante.get("clave", ""))
	if clave_reaccion.is_empty():
		return clave_dialogo

	if DialogoIdeologico.registrar_respuesta(partida.estado, variante):
		_guardar_o_avisar("")
	return clave_reaccion


func _al_cerrar_dialogo() -> void:
	_caminante.terminar_enfoque_conversacion()
	_dialogo_actual = null
	if _hud_prioridades != null:
		_hud_prioridades.desactivar(HUDLayer.DIALOGO)


func _cerrar_dialogo_actual() -> void:
	_caminante.terminar_enfoque_conversacion()
	if is_instance_valid(_dialogo_actual):
		_dialogo_actual.queue_free()
	_dialogo_actual = null
	if _hud_prioridades != null:
		_hud_prioridades.desactivar(HUDLayer.DIALOGO)


func _abrir_expediente() -> void:
	_cerrar_dialogo_actual()
	if _hud_prioridades != null:
		_hud_prioridades.activar(HUDLayer.MODAL)
	super._abrir_expediente()
	if _pantalla == null and _hud_prioridades != null:
		_hud_prioridades.desactivar(HUDLayer.MODAL)


func _cerrar_expediente() -> void:
	super._cerrar_expediente()
	if _hud_prioridades != null:
		_hud_prioridades.desactivar(HUDLayer.MODAL)
	if jornada.get("fase", "") == "archivo" and _pantalla == null:
		_archivado_sesion.refrescar(self)
		# El visor puede haber consumido una acción y avanzado #963. Al volver a
		# la oficina se cruza a la cama acústica de la nueva franja, si cambió.
		Ambiente.reproducir(self, "archivo", -24.0, _contexto_ambiente())


func _abrir_duelo(quien: Dictionary, zona: Area3D) -> void:
	_cerrar_dialogo_actual()
	if _hud_prioridades != null:
		_hud_prioridades.activar(HUDLayer.MODAL)
	super._abrir_duelo(quien, zona)


func _cerrar_duelo(gano: bool, quien: Dictionary, zona: Area3D) -> void:
	super._cerrar_duelo(gano, quien, zona)
	if _hud_prioridades != null:
		_hud_prioridades.desactivar(HUDLayer.MODAL)


## Sustituye únicamente el volumen que antes abría el expediente al pisarlo.
## Wiring de #436: el libro de arqueología pasó de standalone (#503) a
## alcanzable desde el recorrido real de casa. Se remonta en cada entrada
## porque `_mundo` es siempre nuevo (ver `_entrar_en` en `dia_app.gd`); la
## semilla en sí ya vive en `jornada`, así que perder el progreso de páginas
## de una visita a otra el mismo día no descarta nada ya registrado.
func _montar_gilgamesh_vigilia() -> void:
	var libro := GilgameshVigilia.new()
	libro.name = "GilgameshVigiliaCasa"
	libro.position = Vector3(1.5, 0.0, 0.2)
	_mundo.add_child(libro)
	libro.configurar(jornada)


## RYU FLOW vive en la consola física ya montada por CasaUtileria. El observer
## se mantiene fuera de la consola y del emulador: solo esta capa de jornada
## traduce el handshake de finalización a una semilla cultural.
func _montar_ryu_flow_vigilia() -> void:
	var consola := _mundo.get_node_or_null("ConsolaPortatil98") as ConsolaPortatil98
	if consola == null:
		return
	var observador := RyuFlowVigilia.new()
	observador.name = "RyuFlowVigiliaCasa"
	_mundo.add_child(observador)
	observador.configurar(jornada, consola)


## La lógica de apertura sigue siendo `_abrir_expediente()`: aquí solo cambia
## cómo expresa el jugador la intención, de caminar dentro a mirar y pulsar la
## acción semántica `interactuar`.
func _montar_terminal_interactivo() -> void:
	var zona := _buscar_zona_destino(_mundo, "expediente")
	if zona == null:
		return

	# El trigger antiguo no puede seguir abriendo al caminar ni interceptar el
	# raycast del detector de interacción.
	zona.monitoring = false
	zona.monitorable = false
	zona.collision_layer = 0

	var terminal := Interactuable3D.new()
	terminal.name = "TerminalSIGAInteractuable"
	terminal.position = zona.position
	terminal.verbo = Interactuable3D.Verbo.USAR
	terminal.nombre_objeto = tr(String(zona.get_meta("rotulo", "SALIDA_PUESTO")))
	terminal.set_meta("huella_ambiental_id", "archivo:terminal_siga")
	terminal.set_meta("huella_ambiental_tipo", "uso")
	terminal.set_meta("huella_ambiental_offset", Vector3(0.0, 0.0, -0.38))
	terminal.activado.connect(_activar_terminal_siga)
	_mundo.add_child(terminal)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = TAM_TERMINAL_INTERACTIVO
	colision.shape = forma
	terminal.add_child(colision)


## Añade intención a los archivadores ya declarados y modelados. No crea un
## inventario ni documentos: el catálogo sigue siendo dueño de qué muebles hay.
func _montar_archivadores_interactivos(espacio: Dictionary) -> void:
	var indice := 0
	for bulto in espacio.get("bultos", []):
		if String(bulto.get("modelo", "")) != "bookcaseClosed":
			continue
		indice += 1
		var archivador := ArchivadorInteractivo3D.new()
		archivador.name = "ArchivadorInteractuable%d" % indice
		archivador.position = bulto["pos"]
		archivador.set_meta("huella_ambiental_id", "archivo:archivador_%d" % indice)
		archivador.set_meta("huella_ambiental_tipo", "apertura")
		archivador.set_meta("huella_ambiental_offset", Vector3(-0.42, 0.0, 0.0))
		_mundo.add_child(archivador)
		archivador.configurar(bulto["tam"])


func _activar_terminal_siga(_actor: Node) -> void:
	if _pantalla != null:
		return
	_sonar("documento")
	_abrir_expediente()


func _buscar_zona_destino(nodo: Node, destino: String) -> Area3D:
	for hijo in nodo.get_children():
		if hijo is Area3D and String(hijo.get_meta("destino", "")) == destino:
			return hijo
		var encontrada := _buscar_zona_destino(hijo, destino)
		if encontrada != null:
			return encontrada
	return null


func _retirar_clima() -> void:
	if is_instance_valid(_clima_nodo):
		_clima_nodo.queue_free()
	_clima_nodo = null


func _aplicar_clima(estado_clima: String) -> void:
	match estado_clima:
		Clima.NUBLADO:
			_ambiente.ambient_light_energy *= 0.72
			_sol.light_energy *= 0.55
		Clima.LLUVIA:
			_ambiente.ambient_light_energy *= 0.68
			_sol.light_energy *= 0.42
			_montar_precipitacion(false)
		Clima.NIEBLA:
			# La niebla levanta el negro pero mata contraste y alcance visual.
			_ambiente.ambient_light_energy = maxf(_ambiente.ambient_light_energy, 0.62)
			_sol.light_energy *= 0.28
			_ambiente.background_color = Color(0.34, 0.35, 0.38)
		Clima.NIEVE:
			_ambiente.ambient_light_energy *= 0.82
			_sol.light_energy *= 0.65
			_montar_precipitacion(true)
		_:
			pass


func _montar_precipitacion(nieve: bool) -> void:
	_clima_nodo = Node3D.new()
	_clima_nodo.name = "ClimaPrecipitacion"
	_mundo.add_child(_clima_nodo)

	var particulas := GPUParticles3D.new()
	particulas.name = "Nieve" if nieve else "Lluvia"
	particulas.amount = 520 if nieve else 760
	particulas.lifetime = 2.8 if nieve else 1.5
	particulas.preprocess = particulas.lifetime
	particulas.visibility_aabb = AABB(Vector3(-9, -1, -18), Vector3(18, 10, 36))
	particulas.position = Vector3(0, 6.0, 0)
	_clima_nodo.add_child(particulas)

	var proceso := ParticleProcessMaterial.new()
	proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proceso.emission_box_extents = Vector3(7.5, 0.5, 17.0)
	proceso.direction = Vector3(0, -1, 0)
	proceso.spread = 8.0 if nieve else 2.0
	proceso.initial_velocity_min = 1.2 if nieve else 7.0
	proceso.initial_velocity_max = 2.2 if nieve else 10.0
	proceso.gravity = Vector3(0, -0.45 if nieve else -2.2, 0)
	particulas.process_material = proceso

	var malla := QuadMesh.new()
	malla.size = Vector2(0.028, 0.028) if nieve else Vector2(0.018, 0.28)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = (
		Color(0.92, 0.94, 1.0, 0.82) if nieve else Color(0.65, 0.75, 0.88, 0.62)
	)
	malla.material = material
	particulas.draw_pass_1 = malla
