## Onboarding espacial mínimo del archivo (#272).
##
## El archivo ya comunica dónde está el jugador; esta capa responde a las dos
## preguntas que seguían abiertas en el playtest: cuál es su puesto y qué debe
## hacer primero. La señal no es un waypoint: vive solo en el primer arranque,
## ilumina el terminal que ya existe y desaparece en cuanto SIGA se abre.
extends "res://guion/dia_gato_app.gd"

const POS_PUESTO := Vector3(-4.0, 1.45, 1.0)
const CLAVE_ROL_ONBOARDING := "ONBOARDING_OBJETIVO_INICIAL"
const CLAVE_PUESTO_ONBOARDING := "ONBOARDING_PUESTO_SIGA"
const CLAVE_ACCION_ONBOARDING := "ONBOARDING_ACCION_SIGA"
const UMBRAL_RESCATE_CAIDA := -8.0

var _pista_puesto: PanelContainer
var _luz_puesto: OmniLight3D
var _guia_fase: PanelContainer
var _texto_guia_fase: Label
var _ultimo_consejo := ""
var _segundos_hasta_guia := 0.0
var _senal_fin_turno: Label3D


## Red de seguridad del playtest (#784). Se mantiene aquí para que la cadena
## histórica `dia_calle_app.gd -> dia_onboarding_app.gd` permanezca intacta.
## En Godot 4 los callbacks heredados no se encadenan solos: conservar el
## `_process` base mantiene pasos, gato y reloj del sueño antes del rescate.
func _process(_delta: float) -> void:
	super(_delta)
	_rescatar_caida()
	_segundos_hasta_guia -= _delta
	if _segundos_hasta_guia <= 0.0:
		_segundos_hasta_guia = 0.25
		_refrescar_guia_fase()
		_sincronizar_salida_turno()


## `body_entered` llega durante el paso de física. Las capas superiores pueden
## preparar estado, pero desmontar `_mundo` desde ese callback deja Areas en uso
## por el servidor físico. La transición base espera al siguiente frame normal.
func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	if Engine.is_in_physics_frame():
		_continuar_salida_fuera_de_fisica(cuerpo, salida)
		return
	super._al_pisar_salida(cuerpo, salida)


func _continuar_salida_fuera_de_fisica(cuerpo: Node3D, salida: Area3D) -> void:
	await get_tree().process_frame
	if not is_instance_valid(cuerpo) or not is_instance_valid(salida):
		return
	super._al_pisar_salida(cuerpo, salida)


func _rescatar_caida() -> void:
	if not is_instance_valid(_caminante) or _espacio_actual.is_empty():
		return
	if _caminante.position.y >= UMBRAL_RESCATE_CAIDA:
		return
	var entrada: Vector3 = _espacio_actual.get("entrada", Vector3.ZERO)
	_caminante.situar(entrada, _espacio_actual.get("mirada", NAN))


func _entrar_en(fase: String) -> void:
	_retirar_onboarding_archivo()
	super._entrar_en(fase)
	if _onboarding_pendiente(fase):
		_montar_onboarding_archivo()
	_montar_guia_fase()
	_refrescar_guia_fase()
	_sincronizar_salida_turno()


func _onboarding_pendiente(fase: String) -> bool:
	return (
		fase == "archivo"
		and int(jornada.get("dia", 0)) == 1
		and int(jornada.get("acciones", -1)) == Jornada.ACCIONES_POR_DIA
		and jornada.get("leido_hoy", []).is_empty()
	)


func _montar_onboarding_archivo() -> void:
	# Una luz localizada hace que uno de los cuatro puestos idénticos deje de
	# competir visualmente con los demás. Se retira al abrir SIGA; no persigue
	# al jugador ni marca una ruta por el suelo.
	_luz_puesto = OmniLight3D.new()
	_luz_puesto.name = "LuzPuestoPropio"
	_luz_puesto.position = POS_PUESTO
	_luz_puesto.omni_range = 3.0
	_luz_puesto.light_energy = 1.35
	_luz_puesto.light_color = Color(0.55, 0.86, 0.62)
	_luz_puesto.shadow_enabled = false
	_mundo.add_child(_luz_puesto)

	_pista_puesto = PanelContainer.new()
	_pista_puesto.name = "PistaPuestoPropio"
	_pista_puesto.theme = EstiloSiga.tema()
	_pista_puesto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# El diálogo vive abajo. El objetivo inicial ocupa una banda superior y,
	# cuando HUDLayer lo arbitra, nunca compite con fase/diálogo/modal.
	_pista_puesto.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	# #2597: el primer objetivo tiene que ser legible a 1080p desde el Beelink.
	# Reservar ancho REAL, no confiar en el tamaño mínimo de un Label con wrap.
	_pista_puesto.offset_left = -450
	_pista_puesto.offset_top = 90
	_pista_puesto.offset_right = 450
	_pista_puesto.offset_bottom = 240
	_pista_puesto.add_theme_stylebox_override("panel", HUDEstilo.caja_tutorial())
	_hud.add_child(_pista_puesto)

	var contenido := VBoxContainer.new()
	contenido.name = "ContenidoPistaPuesto"
	contenido.add_theme_constant_override("separation", 3)
	_pista_puesto.add_child(contenido)

	var rol := Label.new()
	rol.name = "RolPistaPuesto"
	rol.text = tr(CLAVE_ROL_ONBOARDING)
	rol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rol.add_theme_font_size_override("font_size", 28)
	rol.add_theme_font_override("font", EstiloSiga.fuente_titulo())
	rol.add_theme_color_override("font_color", HUDEstilo.TITULO_TUTORIAL)
	contenido.add_child(rol)

	var texto := Label.new()
	texto.name = "TextoPistaPuesto"
	texto.text = "%s\n%s" % [tr(CLAVE_PUESTO_ONBOARDING), tr(CLAVE_ACCION_ONBOARDING)]
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size.x = 820
	texto.custom_minimum_size.y = 68
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto.add_theme_font_size_override("font_size", 24)
	texto.add_theme_color_override("font_color", HUDEstilo.TEXTO_TUTORIAL)
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(texto)


func _abrir_expediente() -> void:
	super._abrir_expediente()
	# Solo se considera cumplida la instrucción si el visor llegó a abrirse; un
	# fallo de guardado conserva la pista para que el jugador pueda reintentar.
	if _pantalla != null:
		_retirar_onboarding_archivo()
		_refrescar_guia_fase()


func _retirar_onboarding_archivo() -> void:
	if is_instance_valid(_pista_puesto):
		_pista_puesto.queue_free()
	_pista_puesto = null
	if is_instance_valid(_luz_puesto):
		_luz_puesto.queue_free()
	_luz_puesto = null


## La guía no desaparece para siempre tras abrir SIGA. El jugador necesita
## saber qué hacer también DESPUÉS del primer expediente y en cada fase.
## Esta pista es una ayuda funcional, no sustituye la narración diegética.
func _montar_guia_fase() -> void:
	if is_instance_valid(_guia_fase):
		return
	if _hud == null:
		return
	_guia_fase = PanelContainer.new()
	_guia_fase.name = "GuiaFaseJugable"
	_guia_fase.theme = EstiloSiga.tema()
	_guia_fase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guia_fase.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_guia_fase.offset_left = -644
	_guia_fase.offset_top = 222
	_guia_fase.offset_right = -24
	_guia_fase.offset_bottom = 346
	_guia_fase.add_theme_stylebox_override("panel", HUDEstilo.caja_tutorial())
	_hud.add_child(_guia_fase)

	_texto_guia_fase = Label.new()
	_texto_guia_fase.name = "TextoGuiaFaseJugable"
	_texto_guia_fase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto_guia_fase.custom_minimum_size.x = 575
	_texto_guia_fase.custom_minimum_size.y = 92
	_texto_guia_fase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto_guia_fase.add_theme_font_size_override("font_size", 23)
	_texto_guia_fase.add_theme_color_override("font_color", HUDEstilo.TEXTO_TUTORIAL)
	_texto_guia_fase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guia_fase.add_child(_texto_guia_fase)
	_ultimo_consejo = ""


## Instrucciones orientativas basadas en la fase real y el progreso; ninguna
## instrucción altera la jornada, marca expedientes ni modifica guardados.
func _consejo_de_fase() -> String:
	match String(jornada.get("fase", "")):
		"archivo":
			if int(jornada.get("acciones", 0)) > 0:
				return (
					"OBJETIVO · ARCHIVO\n"
					+ "Busca tu puesto: al acercarte se abre SIGA-98. "
					+ "Lee expedientes y decide qué hacer con las pruebas."
				)
			return (
				"OBJETIVO · FIN DE TURNO\n"
				+ "No quedan acciones. Sigue la señal FIN DE TURNO, "
				+ "atraviesa la puerta de salida y recoge tu nómina."
			)
		"trayecto":
			return (
				"OBJETIVO · REGRESAR A CASA\n"
				+ "Camina hasta el portal del otro extremo de la calle. "
				+ "WASD: caminar · Ratón: mirar. Entra al acercarte."
			)
		"casa":
			return (
				"OBJETIVO · DESCANSAR\n"
				+ "Busca la cama y acércate para dormir. "
				+ "Si tienes comida, pasa junto al cuenco del gato."
			)
		"sueño":
			return (
				"OBJETIVO · SUEÑO\n"
				+ "Busca el umbral de salida: su luz azulada aparece al acercarte. "
				+ "Atraviesa cada salida antes de agotar la noche."
			)
	return ""


func _refrescar_guia_fase() -> void:
	if not is_instance_valid(_guia_fase) or not is_instance_valid(_texto_guia_fase):
		return
	var mostrar := (
		_pantalla == null
		and not is_instance_valid(_pista_puesto)
		and _hud != null
		and _hud.visible
		and _caminante != null
		and _caminante.is_physics_processing()
	)
	_guia_fase.visible = mostrar
	if not mostrar:
		return
	var consejo := _consejo_de_fase()
	if _ultimo_consejo != consejo:
		_ultimo_consejo = consejo
		_texto_guia_fase.text = consejo
	_guia_fase.visible = not consejo.is_empty()


## El portal de la oficina es deliberadamente invisible en el mapa (#90),
## pero eso no puede convertir el fin de turno en un softlock de orientación.
## La indicación se monta sobre la salida REAL del espacio y solo al agotarse
## las acciones. No crea otra zona física ni modifica el flujo de la jornada.
func _sincronizar_salida_turno() -> void:
	var mostrar := (
		String(jornada.get("fase", "")) == "archivo"
		and int(jornada.get("acciones", 0)) <= 0
		and is_instance_valid(_mundo)
	)
	if not mostrar:
		if is_instance_valid(_senal_fin_turno):
			_senal_fin_turno.queue_free()
		_senal_fin_turno = null
		return
	if is_instance_valid(_senal_fin_turno):
		return
	var salida_puesto := Vector3.ZERO
	var encontrada := false
	for salida in _espacio_actual.get("salidas", []):
		if String(salida.get("destino", "")) == "trayecto":
			salida_puesto = salida.get("pos", Vector3.ZERO)
			encontrada = true
			break
	if not encontrada:
		return
	_senal_fin_turno = Label3D.new()
	_senal_fin_turno.name = "SenalSalidaFinTurno"
	_senal_fin_turno.text = "FIN DE TURNO  ·  SALIDA"
	_senal_fin_turno.position = salida_puesto + Vector3(0.0, 0.9, 0.0)
	_senal_fin_turno.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_senal_fin_turno.font = EstiloSiga.fuente_titulo()
	_senal_fin_turno.font_size = 40
	_senal_fin_turno.pixel_size = 0.006
	_senal_fin_turno.shaded = false
	_senal_fin_turno.modulate = Color(1.0, 0.93, 0.70)
	_senal_fin_turno.outline_size = 12
	_senal_fin_turno.outline_modulate = Color(0.02, 0.02, 0.03)
	_mundo.add_child(_senal_fin_turno)
