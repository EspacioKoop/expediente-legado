## Tercer corte jugable del sueño de Aquiles (#438).
##
## Conserva el vertical base y añade un puzzle diegético: girar el reflector
## hasta alinear el haz revela el talón; solo entonces el sello puede resolver
## la escena mediante la acción semántica `sellar`.
class_name SuenoAquilesAlineacion
extends SuenoAquiles

@export var reduccion_movimiento := false

var _reflector: AquilesReflector
var _sello: AquilesSello
var _resuelta := false


func _ready() -> void:
	if not is_instance_valid(_figura):
		super()
	if not is_instance_valid(_reflector):
		_montar_puzzle()


## Hace el vertical utilizable también desde instanciación programática y tests
## que todavía están dentro de `SceneTree._initialize()`, antes del primer frame.
func preparar() -> void:
	if not is_instance_valid(_figura):
		_montar_prototipo()
	if not is_instance_valid(_reflector):
		_montar_puzzle()


func reflector() -> AquilesReflector:
	return _reflector


func sello() -> AquilesSello:
	return _sello


func esta_resuelta() -> bool:
	return _resuelta


func estado_alineacion() -> String:
	if not is_instance_valid(_reflector):
		return "fuera"
	if _reflector.esta_alineado():
		return "alineado"
	var angulo := _reflector.angulo_actual()
	var diff := absf(wrapf(angulo - AquilesReflector.ANGULO_OBJETIVO, -180.0, 180.0))
	if diff <= 15.1:
		return "casi"
	return "fuera"


func esta_casi_alineado() -> bool:
	return estado_alineacion() == "casi"


func _montar_puzzle() -> void:
	_reflector = AquilesReflector.new()
	_reflector.name = "ReflectorAquiles"
	_reflector.position = Vector3(-4.6, 0.0, 4.8)
	add_child(_reflector)
	_reflector.configurar()
	if not _reflector.alineacion_cambiada.is_connected(_al_alineacion_cambiada):
		_reflector.alineacion_cambiada.connect(_al_alineacion_cambiada)

	_sello = AquilesSello.new()
	_sello.name = "SelloAquiles"
	_sello.position = Vector3(4.3, 0.0, 4.6)
	add_child(_sello)
	_sello.configurar()
	if not _sello.sellado.is_connected(_al_sellado):
		_sello.sellado.connect(_al_sellado)

	_al_alineacion_cambiada(_reflector.esta_alineado())


func _al_alineacion_cambiada(alineado: bool) -> void:
	if _resuelta:
		if is_instance_valid(_sello):
			_sello.habilitar(false)
		return
	alineado = alineado and estado_alineacion() == "alineado"
	var revelada := aplicar_lectura_espacial(false, alineado)
	_sello.habilitar(revelada and not _resuelta)
	_actualizar_feedback_visual(estado_alineacion())


func _actualizar_feedback_visual(estado: String) -> void:
	if not is_instance_valid(_reflector):
		return
	var disco := _reflector.get_node_or_null("DiscoReflector") as Node3D
	if disco == null:
		return
	var indicador := disco.get_node_or_null("IndicadorAlineacion") as MeshInstance3D
	var haz := disco.get_node_or_null("HazReflejado") as SpotLight3D
	if indicador == null or haz == null:
		return

	match estado:
		"alineado":
			indicador.material_override = _material_indicador(AquilesReflector.COLOR_REFLEJO, true)
			haz.light_energy = 5.0
		"casi":
			indicador.material_override = _material_indicador(AquilesReflector.COLOR_BRONCE, true)
			haz.light_energy = 2.2
		_:
			indicador.material_override = _material_indicador(AquilesReflector.COLOR_APAGADO, false)
			haz.light_energy = 0.35


func _material_indicador(color: Color, emision: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.72
	material.roughness = 0.22
	if emision:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.4
	return material


func _al_sellado(_actor: Node) -> void:
	if _resuelta:
		return
	if estado_alineacion() != "alineado":
		if is_instance_valid(_sello):
			_sello.habilitar(false)
		return
	if not aplicar_resolucion("sellar", reduccion_movimiento):
		return
	_resuelta = true
	_sello.habilitar(false)
