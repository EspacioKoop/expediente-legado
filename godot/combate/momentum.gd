extends Node

signal momentum_cambiado(nivel_actual: float, max_nivel: float)
signal finisher_disponible(es_super: bool)
signal finisher_ejecutado(tipo: String)

const THRESHOLD_FINISHER := 75.0
const THRESHOLD_SUPER_FINISHER := 100.0
const TIEMPO_GRACIA_DECAIMIENTO := 0.75

var momentum_actual: float = 0.0
var momentum_max: float = 100.0
var decay_rate: float = 5.0
var en_combate: bool = false
var ultimo_golpe_time: float = 0.0
var combo_actual: int = 0
var multiplicador_ganancia: float = 1.0

var _umbral_anterior := 0


func _process(delta: float) -> void:
	if not en_combate or momentum_actual <= 0.0:
		return
	var ahora := Time.get_ticks_msec() / 1000.0
	if ahora - ultimo_golpe_time > TIEMPO_GRACIA_DECAIMIENTO:
		_set_momentum(momentum_actual - decay_rate * delta)
	if ahora - ultimo_golpe_time > 3.0:
		combo_actual = 0


func registrar_golpe(es_critico: bool = false, tipo_dano: String = "fisico") -> float:
	en_combate = true
	ultimo_golpe_time = Time.get_ticks_msec() / 1000.0
	combo_actual += 1

	var ganancia := 10.0 * multiplicador_ganancia
	if es_critico:
		ganancia *= 1.5
	if tipo_dano == "sombra":
		ganancia *= 1.3
	elif tipo_dano == "divino":
		ganancia *= 1.2
	ganancia *= 1.0 + float(combo_actual) * 0.05

	agregar_momentum(ganancia)
	return ganancia


func agregar_momentum(cantidad: float) -> void:
	if cantidad <= 0.0:
		return
	_set_momentum(momentum_actual + cantidad)


func registrar_dano_recibido() -> void:
	combo_actual = 0
	_set_momentum(momentum_actual - 20.0)


func ejecutar_finisher(tipo: String = "normal") -> bool:
	var costo := THRESHOLD_SUPER_FINISHER if tipo == "super" else THRESHOLD_FINISHER
	if momentum_actual < costo:
		return false
	_set_momentum(momentum_actual - costo)
	finisher_ejecutado.emit(tipo)
	return true


func salir_combate() -> void:
	en_combate = false
	combo_actual = 0


func obtener_nivel_momentum() -> float:
	if momentum_max <= 0.0:
		return 0.0
	return momentum_actual / momentum_max


func aplicar_modificador_arquetipo(arquetipo_id: String) -> void:
	match arquetipo_id:
		"sombra":
			multiplicador_ganancia = maxf(multiplicador_ganancia, 1.2)
		"anima":
			decay_rate = minf(decay_rate, 3.0)
		"self":
			momentum_max = maxf(momentum_max, 150.0)
			_set_momentum(momentum_actual)


func reiniciar() -> void:
	momentum_actual = 0.0
	momentum_max = 100.0
	decay_rate = 5.0
	en_combate = false
	ultimo_golpe_time = 0.0
	combo_actual = 0
	multiplicador_ganancia = 1.0
	_umbral_anterior = 0
	momentum_cambiado.emit(momentum_actual, momentum_max)


func _set_momentum(valor: float) -> void:
	momentum_actual = clampf(valor, 0.0, momentum_max)
	momentum_cambiado.emit(momentum_actual, momentum_max)
	var umbral := _umbral_actual()
	if umbral > _umbral_anterior:
		finisher_disponible.emit(umbral >= 2)
	_umbral_anterior = umbral


func _umbral_actual() -> int:
	if momentum_actual >= THRESHOLD_SUPER_FINISHER:
		return 2
	if momentum_actual >= THRESHOLD_FINISHER:
		return 1
	return 0
