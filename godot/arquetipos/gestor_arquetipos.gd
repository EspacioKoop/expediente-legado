extends Node

signal arquetipo_desbloqueado(arquetipo_id: String)
signal insight_cambiado(total: int)
signal puntos_habilidad_cambiados(total: int)

var arquetipos: Dictionary = {}
var insight_total: int = 0
var puntos_habilidad: int = 0


func _ready() -> void:
	_cargar_arquetipos()


func _cargar_arquetipos() -> void:
	arquetipos.clear()
	var archivo := FileAccess.open("res://datos/jungian_mitologia.json", FileAccess.READ)
	if archivo == null:
		push_error("No se pudo abrir datos/jungian_mitologia.json")
		return
	var data = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("jungian_mitologia.json no contiene un objeto JSON válido")
		return
	for bruto in data.get("arquetipos", []):
		if typeof(bruto) != TYPE_DICTIONARY:
			continue
		var arquetipo_id := String(bruto.get("id", ""))
		if arquetipo_id.is_empty():
			continue
		var script = load("res://arquetipos/%s.gd" % arquetipo_id)
		if script == null:
			push_warning("Arquetipo sin script: %s" % arquetipo_id)
			continue
		var instancia = script.new()
		arquetipos[arquetipo_id] = instancia
		add_child(instancia)


func ganar_insight(cantidad: int) -> void:
	if cantidad <= 0:
		return
	insight_total += cantidad
	insight_cambiado.emit(insight_total)
	_verificar_desbloqueos()


func desbloquear_arquetipo(arquetipo_id: String) -> bool:
	var arquetipo = obtener_arquetipo(arquetipo_id)
	if arquetipo == null or not arquetipo.desbloquear():
		return false
	puntos_habilidad += 1
	arquetipo_desbloqueado.emit(arquetipo_id)
	puntos_habilidad_cambiados.emit(puntos_habilidad)
	return true


func _verificar_desbloqueos() -> void:
	for arquetipo_id in arquetipos:
		var arquetipo = arquetipos[arquetipo_id]
		if not arquetipo.desbloqueado and insight_total >= arquetipo.puntos_insight_requeridos:
			desbloquear_arquetipo(String(arquetipo_id))


func obtener_arquetipo(arquetipo_id: String):
	return arquetipos.get(arquetipo_id)


func obtener_efectos_activos() -> Array:
	var efectos: Array = []
	for arquetipo in arquetipos.values():
		if arquetipo.desbloqueado:
			efectos.append(arquetipo.obtener_efecto())
	return efectos


func efectos_combinados() -> Dictionary:
	var combinados := {}
	for efecto in obtener_efectos_activos():
		for clave in efecto:
			var valor = efecto[clave]
			if typeof(valor) in [TYPE_INT, TYPE_FLOAT]:
				combinados[clave] = float(combinados.get(clave, 0.0)) + float(valor)
			else:
				combinados[clave] = valor
	return combinados


func reiniciar() -> void:
	insight_total = 0
	puntos_habilidad = 0
	for arquetipo in arquetipos.values():
		arquetipo.desbloqueado = false
	insight_cambiado.emit(insight_total)
	puntos_habilidad_cambiados.emit(puntos_habilidad)
