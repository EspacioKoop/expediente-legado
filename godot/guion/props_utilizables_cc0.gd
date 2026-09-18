## Catálogo standalone de props utilizables del pack Street Furniture (Kkryy, CC0-1.0; #680).
##
## Este corte no carga mallas: Crowbar/Flashlight todavía no están en main y deben
## entrar por Git LFS real. Aquí fijamos el contrato de inventario e interacción para
## que la importación visual posterior no cree un sistema paralelo.
class_name PropsUtilizablesCC0
extends RefCounted

const ORIGEN := "street_furniture_cc0"
const FUENTE := "https://kkryy.itch.io/streetfurniture"

const DEFINICIONES := {
	"palanca_kkryy": {
		"modelo": "Crowbar",
		"nombre": "palanca",
		"descripcion": "Una palanca de acero. Parece útil para hacer fuerza donde las manos no bastan.",
		"usos": ["forzar"],
		"categoria": "herramienta",
	},
	"linterna_kkryy": {
		"modelo": "Flashlight",
		"nombre": "linterna",
		"descripcion": "Una linterna de mano. Puede servir cuando la iluminación normal no alcanza.",
		"usos": ["iluminar"],
		"categoria": "herramienta",
	},
}


static func ids() -> Array[String]:
	var salida: Array[String] = []
	for item_id in DEFINICIONES:
		salida.append(String(item_id))
	salida.sort()
	return salida


static func definicion(item_id: String) -> Dictionary:
	var ficha = DEFINICIONES.get(item_id, {})
	return ficha.duplicate(true) if ficha is Dictionary else {}


static func objeto_inventario(item_id: String) -> Dictionary:
	var ficha := definicion(item_id)
	if ficha.is_empty():
		return {}
	return {
		"id": item_id,
		"nombre": String(ficha["nombre"]),
		"descripcion": String(ficha["descripcion"]),
		"usos": ficha["usos"].duplicate(),
		"categoria": String(ficha["categoria"]),
		"origen": ORIGEN,
		"vendible": false,
		"precio": 0,
		"fuente_asset": FUENTE,
		"modelo_street_furniture": String(ficha["modelo"]),
	}


static func crear_recogible(item_id: String, inventario: Dictionary) -> Recogible3D:
	var datos := objeto_inventario(item_id)
	if datos.is_empty():
		return null
	var recogible := Recogible3D.new()
	recogible.name = "PropUtilizable_%s" % item_id
	recogible.configurar(inventario, datos)
	recogible.set_meta("street_furniture_modelo", String(datos["modelo_street_furniture"]))
	recogible.set_meta("prop_utilizable_cc0", true)
	return recogible
