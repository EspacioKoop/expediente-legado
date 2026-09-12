## Onboarding espacial mínimo del archivo (#272).
##
## El archivo ya comunica dónde está el jugador; esta capa responde a las dos
## preguntas que seguían abiertas en el playtest: cuál es su puesto y qué debe
## hacer primero. La señal no es un waypoint: vive solo en el primer arranque,
## ilumina el terminal que ya existe y desaparece en cuanto SIGA se abre.
extends "res://guion/dia_gato_app.gd"

const POS_PUESTO := Vector3(-4.0, 1.45, 1.0)
const TEXTO_ONBOARDING := (
	"PUESTO 4-B · SIGA-98\nAcérquese al terminal verde para abrir su primer expediente."
)

var _pista_puesto: PanelContainer
var _luz_puesto: OmniLight3D


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
	_pista_puesto.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_pista_puesto.offset_left = -290
	_pista_puesto.offset_top = -92
	_pista_puesto.offset_right = 290
	_pista_puesto.offset_bottom = -18
	_hud.add_child(_pista_puesto)

	var texto := Label.new()
	texto.text = TEXTO_ONBOARDING
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size.x = 560
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pista_puesto.add_child(texto)


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
