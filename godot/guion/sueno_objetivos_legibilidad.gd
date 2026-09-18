## Capa diegética de legibilidad para los objetivos oníricos (#281).
##
## No decide ni concede progreso. Observa las Area3D creadas por dia_gato_app.gd
## y añade una luz local, pequeña y estática a los objetivos pendientes anclados
## a contenido significativo. La señal desaparece cuando el caminante entra en
## la zona; el handler dueño del objetivo sigue siendo el único que actualiza
## SuenoObjetivos.
class_name SuenoObjetivosLegibilidad
extends Node

const NOMBRE_ECO := "EcoLegibilidadObjetivo"
const SUFIJO_FOCO_LEGADO := ":2"
const RANGO_ECO := 3.4
const ENERGIA_ECO := 0.42
const ALTURA_ECO := 0.35

var _mundo_montado_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	if String(dia.jornada.get("fase", "")) != "sueño":
		_mundo_montado_id = 0
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return

	var caminante := dia.get("_caminante") as Node3D
	montar_en(mundo, caminante)
	_mundo_montado_id = mundo_id


func montar_en(mundo: Node3D, caminante: Node3D = null) -> Array:
	var ecos: Array = []
	for nodo in mundo.find_children("ObjetivoSueno_*", "Area3D", true, false):
		var zona := nodo as Area3D
		if zona == null or not zona.monitoring or _es_foco_legado(zona):
			continue
		var luz := zona.get_node_or_null(NOMBRE_ECO) as OmniLight3D
		if luz == null:
			luz = _crear_eco(zona)
			zona.body_entered.connect(_al_entrar_objetivo.bind(zona, luz, caminante))
		ecos.append(luz)
	return ecos


func _es_foco_legado(zona: Area3D) -> bool:
	var objetivo_id := String(zona.get_meta("objetivo", ""))
	return objetivo_id.ends_with(SUFIJO_FOCO_LEGADO)


func _crear_eco(zona: Area3D) -> OmniLight3D:
	var luz := OmniLight3D.new()
	luz.name = NOMBRE_ECO
	luz.position = Vector3(0.0, ALTURA_ECO, 0.0)
	luz.omni_range = RANGO_ECO
	luz.light_energy = ENERGIA_ECO
	luz.shadow_enabled = false
	zona.add_child(luz)
	return luz


func _al_entrar_objetivo(
	cuerpo: Node3D, _zona: Area3D, luz: OmniLight3D, caminante: Node3D
) -> void:
	if caminante != null and cuerpo != caminante:
		return
	if is_instance_valid(luz):
		luz.visible = false
