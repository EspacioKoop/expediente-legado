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


## Red de seguridad del playtest (#784). Se mantiene aquí para que la cadena
## histórica `dia_calle_app.gd -> dia_onboarding_app.gd` permanezca intacta.
## En Godot 4 los callbacks heredados no se encadenan solos: conservar el
## `_process` base mantiene pasos, gato y reloj del sueño antes del rescate.
func _process(_delta: float) -> void:
	super(_delta)
	_rescatar_caida()


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
	_pista_puesto.offset_left = -310
	_pista_puesto.offset_top = 96
	_pista_puesto.offset_right = 310
	_pista_puesto.offset_bottom = 180
	_pista_puesto.add_theme_stylebox_override("panel", HUDEstilo.caja_tutorial())
	_hud.add_child(_pista_puesto)

	var contenido := VBoxContainer.new()
	contenido.name = "ContenidoPistaPuesto"
	contenido.add_theme_constant_override("separation", 3)
	_pista_puesto.add_child(contenido)

	var rol := Label.new()
	rol.name = "RolPistaPuesto"
	rol.text = tr(CLAVE_ROL_ONBOARDING)
	rol.add_theme_font_override("font", EstiloSiga.fuente_titulo())
	rol.add_theme_color_override("font_color", HUDEstilo.TITULO_TUTORIAL)
	contenido.add_child(rol)

	var texto := Label.new()
	texto.name = "TextoPistaPuesto"
	texto.text = "%s\n%s" % [tr(CLAVE_PUESTO_ONBOARDING), tr(CLAVE_ACCION_ONBOARDING)]
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size.x = 580
	texto.add_theme_color_override("font_color", HUDEstilo.TEXTO_TUTORIAL)
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(texto)


func _abrir_expediente() -> void:
	super._abrir_expediente()
	# Solo se considera cumplida la instrucción si el visor llegó a abrirse; un
	# fallo de guardado conserva la pista para que el jugador pueda reintentar.
	if _pantalla != null:
		_retirar_onboarding_archivo()


func _retirar_onboarding_archivo() -> void:
	if is_instance_valid(_pista_puesto):
		_pista_puesto.queue_free()
	_pista_puesto = null
	if is_instance_valid(_luz_puesto):
		_luz_puesto.queue_free()
	_luz_puesto = null
