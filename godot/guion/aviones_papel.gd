## Núcleo puro del minijuego de aviones de papel (#160).
##
## No conoce escenas, nodos ni Partida. Calcula una trayectoria sencilla y
## acotada a partir de dirección, altura, potencia y modelo; administra tres
## lanzamientos por participante y fija estrategias deterministas para los
## compañeros. La futura escena de pasillo puede consumir este contrato sin
## duplicar reglas ni convertirlo en un simulador físico.
class_name AvionesPapel
extends RefCounted

const LANZAMIENTOS_POR_PARTICIPANTE := 3
const PASO := 0.05
const TIEMPO_MAX := 8.0
const LIMITE_LATERAL := 5.5
const LIMITE_FONDO := 32.0
const ALTURA_INICIAL := 1.35
const GRAVEDAD := 9.8
const RADIO_ZONA := 1.6
const OBJETIVO := Vector2(0.0, 22.0)
const OBJETIVO_PAPELERA := Vector2(2.4, 18.0)

const MODELOS := {
	"estable": {"velocidad": 0.94, "sustentacion": 1.08, "deriva": 0.02},
	"rapido": {"velocidad": 1.12, "sustentacion": 0.88, "deriva": 0.01},
	"impredecible": {"velocidad": 1.00, "sustentacion": 0.96, "deriva": 0.20},
}

const ESTRATEGIAS := {
	"distancia": {"modelo": "rapido", "direccion": 0.0, "altura": 18.0, "potencia": 0.94},
	"papelera": {"modelo": "estable", "direccion": 0.13, "altura": 12.0, "potencia": 0.72},
	"cunado": {
		"modelo": "impredecible", "direccion": -0.34, "altura": 27.0, "potencia": 0.83
	},
}


static func nueva(participantes: Array, modalidad: String = "distancia") -> Dictionary:
	var resultados := {}
	for participante in participantes:
		resultados[String(participante)] = []
	return {
		"participantes": participantes.duplicate(),
		"modalidad": modalidad if modalidad in ["distancia", "precision", "zona"] else "distancia",
		"turno": 0,
		"lanzamiento": 0,
		"resultados": resultados,
		"terminada": participantes.is_empty(),
		"abandonada": false,
	}


## Simulación intencionalmente simple: no integra rigid bodies ni colisiones.
## Siempre termina por aterrizaje, borde del pasillo o TIEMPO_MAX.
static func simular(
	modelo: String, direccion: float, altura: float, potencia: float, objetivo: Vector2 = OBJETIVO
) -> Dictionary:
	var ficha: Dictionary = MODELOS.get(modelo, MODELOS["estable"])
	var lateral := clampf(direccion, -1.0, 1.0)
	var angulo := deg_to_rad(clampf(altura, -20.0, 55.0))
	var fuerza := lerpf(5.5, 14.0, clampf(potencia, 0.0, 1.0)) * float(ficha["velocidad"])
	var velocidad := Vector3(lateral * fuerza * 0.34, sin(angulo) * fuerza, cos(angulo) * fuerza)
	var posicion := Vector3(0.0, ALTURA_INICIAL, 0.0)
	var tiempo := 0.0
	var motivo := "tiempo"
	var pasos_maximos := int(ceil(TIEMPO_MAX / PASO))

	for paso in pasos_maximos:
		var oscilacion := sin(float(paso) * 0.77 + fuerza) * float(ficha["deriva"])
		velocidad.x += oscilacion * PASO
		velocidad.y -= GRAVEDAD * PASO * (2.0 - float(ficha["sustentacion"]))
		velocidad.z *= 1.0 - (0.018 * PASO)
		posicion += velocidad * PASO
		tiempo += PASO

		if posicion.y <= 0.0:
			posicion.y = 0.0
			motivo = "aterrizaje"
			break
		if absf(posicion.x) >= LIMITE_LATERAL or posicion.z >= LIMITE_FONDO:
			posicion.x = clampf(posicion.x, -LIMITE_LATERAL, LIMITE_LATERAL)
			posicion.z = minf(posicion.z, LIMITE_FONDO)
			motivo = "borde"
			break

	var punto := Vector2(posicion.x, posicion.z)
	var error := punto.distance_to(objetivo)
	return {
		"modelo": modelo if MODELOS.has(modelo) else "estable",
		"posicion": posicion,
		"distancia": maxf(posicion.z, 0.0),
		"precision": maxf(0.0, 100.0 - error * 7.5),
		"zona": error <= RADIO_ZONA,
		"tiempo": minf(tiempo, TIEMPO_MAX),
		"motivo": motivo,
	}


static func lanzar(
	estado: Dictionary, modelo: String, direccion: float, altura: float, potencia: float
) -> Dictionary:
	if estado.get("terminada", false) or estado.get("abandonada", false):
		return estado
	var participantes: Array = estado.get("participantes", [])
	if participantes.is_empty():
		estado["terminada"] = true
		return estado

	var indice := int(estado.get("turno", 0))
	var nombre := String(participantes[indice])
	var vuelo := simular(modelo, direccion, altura, potencia, OBJETIVO)
	vuelo["puntos"] = _puntos(vuelo, String(estado.get("modalidad", "distancia")))
	estado["resultados"][nombre].append(vuelo)
	estado["lanzamiento"] = int(estado.get("lanzamiento", 0)) + 1

	if int(estado["lanzamiento"]) >= LANZAMIENTOS_POR_PARTICIPANTE:
		estado["lanzamiento"] = 0
		estado["turno"] = indice + 1
		if int(estado["turno"]) >= participantes.size():
			estado["terminada"] = true
	return estado


## Aplica una estrategia fija. El identificador de estrategia no depende de RNG,
## de modo que recargar la misma ronda produce exactamente el mismo lanzamiento.
static func lanzar_companero(estado: Dictionary, estrategia: String) -> Dictionary:
	var plan: Dictionary = ESTRATEGIAS.get(estrategia, ESTRATEGIAS["distancia"])
	if estrategia == "papelera":
		return _lanzar_a_objetivo(estado, plan, OBJETIVO_PAPELERA)
	return lanzar(
		estado,
		String(plan["modelo"]),
		float(plan["direccion"]),
		float(plan["altura"]),
		float(plan["potencia"])
	)


static func _lanzar_a_objetivo(estado: Dictionary, plan: Dictionary, objetivo: Vector2) -> Dictionary:
	if estado.get("terminada", false) or estado.get("abandonada", false):
		return estado
	var participantes: Array = estado.get("participantes", [])
	if participantes.is_empty():
		estado["terminada"] = true
		return estado
	var indice := int(estado.get("turno", 0))
	var nombre := String(participantes[indice])
	var vuelo := simular(
		String(plan["modelo"]),
		float(plan["direccion"]),
		float(plan["altura"]),
		float(plan["potencia"]),
		objetivo
	)
	vuelo["puntos"] = _puntos(vuelo, String(estado.get("modalidad", "distancia")))
	estado["resultados"][nombre].append(vuelo)
	estado["lanzamiento"] = int(estado.get("lanzamiento", 0)) + 1
	if int(estado["lanzamiento"]) >= LANZAMIENTOS_POR_PARTICIPANTE:
		estado["lanzamiento"] = 0
		estado["turno"] = indice + 1
		if int(estado["turno"]) >= participantes.size():
			estado["terminada"] = true
	return estado


static func abandonar(estado: Dictionary) -> Dictionary:
	estado["abandonada"] = true
	return resultado(estado)


static func resultado(estado: Dictionary) -> Dictionary:
	var totales := {}
	for nombre in estado.get("resultados", {}):
		var puntos := 0.0
		for vuelo in estado["resultados"][nombre]:
			puntos += float(vuelo.get("puntos", 0.0))
		totales[nombre] = puntos

	var mejor := -1.0
	var ganadores := []
	for nombre in totales:
		var puntos := float(totales[nombre])
		if puntos > mejor:
			mejor = puntos
			ganadores = [nombre]
		elif is_equal_approx(puntos, mejor):
			ganadores.append(nombre)
	return {
		"ganador": ganadores[0] if ganadores.size() == 1 else "empate",
		"ganadores": ganadores,
		"puntuaciones": totales,
		"completa": estado.get("terminada", false) and not estado.get("abandonada", false),
		"abandonada": estado.get("abandonada", false),
	}


static func _puntos(vuelo: Dictionary, modalidad: String) -> float:
	match modalidad:
		"precision":
			return float(vuelo.get("precision", 0.0))
		"zona":
			return 100.0 if vuelo.get("zona", false) else float(vuelo.get("precision", 0.0)) * 0.25
		_:
			return float(vuelo.get("distancia", 0.0))
