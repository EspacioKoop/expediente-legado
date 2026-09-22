extends Node

# Autoload: GestorMomentum
signal momentum_cambiado(nivel_actual, max_nivel)
signal finisher_disponible
signal finisher_ejecutado(tipo)

# Configuración de thresholds
const THRESHOLD_FINISHER: float = 75.0
const THRESHOLD_SUPER_FINISHER: float = 100.0

var momentum_actual: float = 0.0
var momentum_max: float = 100.0
var decay_rate: float = 5.0  # por segundo
var en_combate: bool = false
var ultimo_golpe_time: float = 0.0
var combo_actual: int = 0
var multiplicador_momentum: float = 1.0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if en_combate and momentum_actual > 0:
		momentum_actual = max(0.0, momentum_actual - decay_rate * delta * multiplicador_momentum)
		momentum_cambiado.emit(momentum_actual, momentum_max)

	# Reset combo si pasa mucho tiempo
	if en_combate and Time.get_ticks_msec() / 1000.0 - ultimo_golpe_time > 3.0:
		combo_actual = 0


func registrar_golpe(es_critico: bool = false, tipo_danio: String = "fisico") -> void:
	if not en_combate:
		en_combate = true

	ultimo_golpe_time = Time.get_ticks_msec() / 1000.0
	combo_actual += 1

	var ganancia := 10.0 * multiplicador_momentum
	if es_critico:
		ganancia *= 1.5
	if tipo_danio == "sombra":
		ganancia *= 1.3
	if tipo_danio == "divino":
		ganancia *= 1.2

	# Bonus por combo
	ganancia *= 1.0 + (combo_actual * 0.05)

	momentum_actual = min(momentum_max, momentum_actual + ganancia)
	momentum_cambiado.emit(momentum_actual, momentum_max)

	if momentum_actual >= THRESHOLD_FINISHER and momentum_actual < THRESHOLD_SUPER_FINISHER:
		finisher_disponible.emit()
	elif momentum_actual >= THRESHOLD_SUPER_FINISHER:
		finisher_disponible.emit()  # Super finisher


func registrar_danio_recibido() -> void:
	# Perder momentum al recibir daño
	momentum_actual = max(0.0, momentum_actual - 20.0)
	combo_actual = 0
	momentum_cambiado.emit(momentum_actual, momentum_max)


func ejecutar_finisher(tipo: String = "normal") -> bool:
	if momentum_actual >= THRESHOLD_FINISHER:
		var costo := THRESHOLD_SUPER_FINISHER if tipo == "super" else THRESHOLD_FINISHER
		if momentum_actual >= costo:
			momentum_actual -= costo
			finisher_ejecutado.emit(tipo)
			momentum_cambiado.emit(momentum_actual, momentum_max)
			return true
	return false


func salir_combate() -> void:
	en_combate = false
	combo_actual = 0
	# Momentum decae naturalmente


func obtener_nivel_momentum() -> float:
	return momentum_actual / momentum_max


func aplicar_modificador_arquetipo(arquetipo_id: String) -> void:
	match arquetipo_id:
		"sombra":
			multiplicador_momentum = 1.2
		"anima":
			decay_rate = 3.0
		"persona":
			pass
		"self":
			momentum_max = 150.0
