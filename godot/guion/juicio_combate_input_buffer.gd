## Política pura de buffer de entrada y ventanas de cancelación del combate (#2435).
##
## No conoce animaciones, nodos, daño, momentum ni Partida. El host entrega la
## acción que está ejecutándose y un progreso normalizado 0..1; esta capa decide
## si la entrada pendiente puede consumirse ahora.
class_name JuicioCombateInputBuffer
extends RefCounted

const NINGUNA := ""
const LIGERO := "ligero"
const FUERTE := "fuerte"
const ESQUIVA := "esquiva"
const FINISHER := "finisher"

const ACCIONES_BUFFER := [LIGERO, FUERTE, ESQUIVA]

## Ventana deliberadamente corta: absorbe una pulsación ligeramente temprana
## sin convertir el buffer en una cola de órdenes.
const BUFFER_SEGUNDOS := 0.18

## Aperturas normalizadas de cancelación. El host puede mapearlas a cualquier
## duración de animación sin ligar la política a FPS ni a AnimationPlayer.
const LIGERO_A_LIGERO := 0.48
const LIGERO_A_FUERTE := 0.60
const ATAQUE_A_ESQUIVA := 0.35
const FUERTE_A_LIGERO := 0.82


static func nuevo() -> Dictionary:
	return {"accion": NINGUNA, "restante": 0.0}


static func encolar(estado: Dictionary, accion: String) -> Dictionary:
	var salida := _normalizar(estado)
	if accion not in ACCIONES_BUFFER:
		return salida

	var pendiente := String(salida["accion"])
	# Una esquiva ya pendiente protege la intención defensiva frente a pulsaciones
	# ofensivas posteriores dentro de la misma ventana.
	if pendiente == ESQUIVA and accion != ESQUIVA:
		return salida

	salida["accion"] = accion
	salida["restante"] = BUFFER_SEGUNDOS
	return salida


static func avanzar(estado: Dictionary, delta: float) -> Dictionary:
	var salida := _normalizar(estado)
	if String(salida["accion"]).is_empty():
		return salida

	salida["restante"] = maxf(0.0, float(salida["restante"]) - maxf(0.0, delta))
	if float(salida["restante"]) <= 0.0:
		return nuevo()
	return salida


## Intenta consumir la entrada pendiente sin modificar el diccionario recibido.
##
## Devuelve:
## - estado: buffer restante (vacío si se consume);
## - ejecutar: acción semántica a iniciar, o "" si todavía no toca.
static func consumir(estado: Dictionary, accion_actual: String, progreso: float) -> Dictionary:
	var salida := _normalizar(estado)
	var pendiente := String(salida["accion"])
	if pendiente.is_empty() or float(salida["restante"]) <= 0.0:
		return {"estado": nuevo(), "ejecutar": NINGUNA}

	if puede_cancelar(accion_actual, pendiente, progreso):
		return {"estado": nuevo(), "ejecutar": pendiente}
	return {"estado": salida, "ejecutar": NINGUNA}


static func puede_cancelar(accion_actual: String, siguiente: String, progreso: float) -> bool:
	if siguiente not in ACCIONES_BUFFER:
		return false

	var t := clampf(progreso, 0.0, 1.0)
	if accion_actual.is_empty():
		return true

	# El finisher conserva compromiso completo en este primer corte.
	if accion_actual == FINISHER:
		return false

	if accion_actual == LIGERO:
		if siguiente == ESQUIVA:
			return t >= ATAQUE_A_ESQUIVA
		if siguiente == LIGERO:
			return t >= LIGERO_A_LIGERO
		if siguiente == FUERTE:
			return t >= LIGERO_A_FUERTE
		return false

	if accion_actual == FUERTE:
		if siguiente == ESQUIVA:
			return t >= ATAQUE_A_ESQUIVA
		if siguiente == LIGERO:
			return t >= FUERTE_A_LIGERO
		return false

	# La esquiva es una acción comprometida: no se encadena desde esta política.
	if accion_actual == ESQUIVA:
		return false

	# Un estado no reconocido no gana cancelaciones implícitas.
	return false


static func _normalizar(estado: Dictionary) -> Dictionary:
	var accion := String(estado.get("accion", NINGUNA))
	var restante := maxf(0.0, float(estado.get("restante", 0.0)))
	if accion not in ACCIONES_BUFFER or restante <= 0.0:
		return nuevo()
	return {"accion": accion, "restante": restante}
