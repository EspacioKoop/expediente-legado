extends Node

# Autoload: GestorArquetipos
signal arquetipo_desbloqueado(arquetipo_id)

var arquetipos: Dictionary = {}
var insight_total: int = 0
var puntos_habilidad: int = 0


func _ready() -> void:
	var archivo := FileAccess.open("res://datos/jungian_mitologia.json", FileAccess.READ)
	if archivo == null:
		return
	var data = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if not (data is Dictionary):
		return
	var entradas = data.get("arquetipos", [])
	if not (entradas is Array):
		return
	for entrada in entradas:
		if not (entrada is Dictionary):
			continue
		var id := String(entrada.get("id", ""))
		if id.is_empty():
			continue
		var script = load("res://arquetipos/%s.gd" % id)
		if script == null:
			continue
		var instancia = script.new()
		arquetipos[id] = instancia


func reiniciar() -> void:
	insight_total = 0
	puntos_habilidad = 0
	for arquetipo in arquetipos.values():
		if arquetipo != null:
			arquetipo.desbloqueado = false


func ganar_insight(cantidad: int) -> void:
	insight_total += cantidad
	_verificar_desbloqueos()


func _verificar_desbloqueos() -> void:
	for id in arquetipos:
		var arquetipo = arquetipos[id]
		if (
			arquetipo != null
			and not bool(arquetipo.desbloqueado)
			and insight_total >= int(arquetipo.puntos_insight_requeridos)
		):
			arquetipo.desbloquear()
			puntos_habilidad += 1
			arquetipo_desbloqueado.emit(id)


func obtener_arquetipo(id: String):
	return arquetipos.get(id)


func obtener_efectos_activos() -> Array:
	var efectos: Array = []
	for arquetipo in arquetipos.values():
		if arquetipo != null and bool(arquetipo.desbloqueado):
			efectos.append(arquetipo.obtener_efecto())
	return efectos


func efectos_combinados() -> Dictionary:
	var combinados: Dictionary = {}
	for efecto in obtener_efectos_activos():
		if not (efecto is Dictionary):
			continue
		for clave in efecto:
			var valor = efecto[clave]
			if typeof(valor) == TYPE_INT or typeof(valor) == TYPE_FLOAT:
				combinados[clave] = float(combinados.get(clave, 0.0)) + float(valor)
			elif typeof(valor) == TYPE_BOOL:
				combinados[clave] = bool(combinados.get(clave, false)) or bool(valor)
			elif not combinados.has(clave):
				combinados[clave] = valor
	if combinados.has("curacion_aliados") and not combinados.has("curacion"):
		combinados["curacion"] = float(combinados["curacion_aliados"])
	return combinados
