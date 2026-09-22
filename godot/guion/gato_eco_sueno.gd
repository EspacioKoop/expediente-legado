## Memoria corta del gato entre casa y sueño (#787).
##
## No mide afecto ni concede progreso. Conserva únicamente acciones observables
## del día actual dentro del diccionario persistente del propio gato. El día
## etiqueta la huella para que una noche nunca herede gestos de jornadas viejas.
class_name GatoEcoSueno
extends RefCounted

const CLAVE := "eco_sueno_hoy"
const MAX_ACCIONES := 6

const LLAMAR := "llamar"
const ACARICIAR := "acariciar"
const COGER := "coger"
const ALIMENTAR := "alimentar"
const ACCIONES_VALIDAS := [LLAMAR, ACARICIAR, COGER, ALIMENTAR]


static func accion_de_verbo(verbo: int) -> String:
	match verbo:
		Interactuable3D.Verbo.LLAMAR:
			return LLAMAR
		Interactuable3D.Verbo.ACARICIAR:
			return ACARICIAR
		Interactuable3D.Verbo.COGER:
			return COGER
		Interactuable3D.Verbo.DAR:
			return ALIMENTAR
	return ""


static func registrar(gato: Dictionary, dia: int, accion: String) -> bool:
	if not ACCIONES_VALIDAS.has(accion):
		return false
	var eco: Dictionary = gato.get(CLAVE, {})
	if int(eco.get("dia", -1)) != dia:
		eco = {"dia": dia, "acciones": []}
	var acciones: Array = eco.get("acciones", [])
	acciones.append(accion)
	while acciones.size() > MAX_ACCIONES:
		acciones.pop_front()
	eco["acciones"] = acciones
	gato[CLAVE] = eco
	return true


static func validar(gato: Dictionary) -> Array:
	var errores := []
	if not gato.has(CLAVE):
		return errores
	var eco = gato[CLAVE]
	if typeof(eco) != TYPE_DICTIONARY:
		return ["%s no es un objeto" % CLAVE]
	if not eco.has("dia"):
		errores.append("%s.dia ausente" % CLAVE)
	else:
		var dia = eco["dia"]
		if (
			typeof(dia) not in [TYPE_INT, TYPE_FLOAT]
			or not is_finite(float(dia))
			or floor(float(dia)) != float(dia)
			or float(dia) < 0.0
		):
			errores.append("%s.dia inválido" % CLAVE)
	if not eco.has("acciones"):
		errores.append("%s.acciones ausente" % CLAVE)
	elif typeof(eco["acciones"]) != TYPE_ARRAY:
		errores.append("%s.acciones no es una lista" % CLAVE)
	else:
		var acciones: Array = eco["acciones"]
		if acciones.size() > MAX_ACCIONES:
			errores.append("%s.acciones excede el máximo" % CLAVE)
		for accion in acciones:
			if typeof(accion) != TYPE_STRING or not ACCIONES_VALIDAS.has(String(accion)):
				errores.append("%s.acciones contiene una acción inválida" % CLAVE)
				break
	return errores


static func acciones_de(gato: Dictionary, dia: int) -> Array:
	var eco: Dictionary = gato.get(CLAVE, {})
	if int(eco.get("dia", -1)) != dia:
		return []
	var acciones: Array = eco.get("acciones", [])
	return acciones.duplicate()


## Devuelve solo presentación. No hay coordenadas de objetivos, pistas, casos ni
## estado de progresión: el dueño del sueño decide el rumbo por su cuenta.
static func efecto(gato: Dictionary, dia: int) -> Dictionary:
	var acciones := acciones_de(gato, dia)
	if acciones.is_empty():
		return {}
	var ultima := String(acciones.back())
	var repeticiones := acciones.count(ultima)
	match ultima:
		ALIMENTAR:
			# Saciedad recordada: aparece ya hecho un ovillo, reconocible y normal.
			return {"accion": ultima, "estado": "durmiendo", "distancia": 1.15}
		ACARICIAR:
			# El roce vuelve como una proximidad voluntaria, no como una recompensa.
			return {"accion": ultima, "estado": "mimos", "distancia": 0.90}
		COGER:
			# Tras haberlo tenido en brazos, reaparece más cerca pero quieto.
			return {"accion": ultima, "estado": "sentado", "distancia": 0.72}
		LLAMAR:
			# Repetir la llamada solo acorta la distancia; nunca cambia el rumbo.
			var distancia := 0.78 if repeticiones >= 2 else 1.05
			return {"accion": ultima, "estado": "observando", "distancia": distancia}
	return {}
