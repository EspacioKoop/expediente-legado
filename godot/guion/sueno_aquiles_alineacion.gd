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
	super()
	_montar_puzzle()


func reflector() -> AquilesReflector:
	return _reflector


func sello() -> AquilesSello:
	return _sello


func esta_resuelta() -> bool:
	return _resuelta


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
	var revelada := aplicar_lectura_espacial(false, alineado)
	_sello.habilitar(revelada and not _resuelta)


func _al_sellado(_actor: Node) -> void:
	if _resuelta:
		return
	if not aplicar_resolucion("sellar", reduccion_movimiento):
		return
	_resuelta = true
	_sello.habilitar(false)
