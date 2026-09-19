## Primera recompensa física que puede salir del sueño (#61/#97).
##
## El objeto no concede economía, acciones, vidas ni pistas. Su valor está en un
## uso semántico normal de Inventario: puede sustituir a otra herramienta en una
## interacción que acepte "forzar". Así el sueño puede dejar una utilidad real
## sin crear buffs, estadísticas ni una segunda fuente de verdad.
class_name RecompensaOnirica
extends RefCounted

const ID := "cuna_imposible"
const USO := "forzar"


static func objeto() -> Dictionary:
	return {
		"id": ID,
		"nombre": "Cuña imposible",
		"descripcion":
		"Una pieza translúcida con un ángulo que no termina de encajar. "
		+ "Hace palanca mejor de lo que debería.",
		"usos": [USO],
		"categoria": "reliquia_onirica",
		"origen": "sueno",
		"vendible": false,
		"precio": 0,
	}


## Materializa la recompensa directamente en carried. Inventario mantiene la
## idempotencia: resolver de nuevo un puzzle no duplica el objeto.
static func conceder(estado_partida: Dictionary) -> bool:
	var bruto = estado_partida.get("inventario", null)
	if typeof(bruto) != TYPE_DICTIONARY:
		estado_partida["inventario"] = Inventario.nuevo()
	var inventario: Dictionary = estado_partida["inventario"]
	Inventario.completar(inventario)
	return Inventario.recoger(inventario, objeto())
