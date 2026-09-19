## Comercio pequeño del trayecto (#676).
##
## Contrato standalone: no monta geometría ni UI. Reutiliza Jornada para pagar,
## Inventario para materializar compras y TiendaVideojuegos para la superficie
## ya existente. La interacción cultural solo expone metadatos; comprar nunca
## activa por sí mismo una semilla onírica.
class_name ComercioBarrio
extends RefCounted

const CLAVE_COMPRAS := "comercio_barrio_compras"

const SUPERFICIES := [
	{
		"id": "quiosco",
		"nombre": "Quiosco Avenida",
		"tipo": "quiosco",
	},
	{
		"id": "videojuegos",
		"nombre": "Bit 98",
		"tipo": "videojuegos",
		"delegada": true,
	},
	{
		"id": "segunda_mano",
		"nombre": "El Trastero",
		"tipo": "segunda_mano",
	},
]

const CATALOGO := [
	{
		"id": "paquete_cigarrillos_98",
		"superficie": "quiosco",
		"nombre": "Paquete de cigarrillos",
		"precio": 8,
		"categoria": "consumo",
		"repetible": true,
		"vendible": false,
	},
	{
		"id": "revista_umbral_98",
		"superficie": "quiosco",
		"nombre": "Umbral — nº 17",
		"precio": 8,
		"destino": "carried",
		"categoria": "publicacion",
		"vendible": false,
		"semilla_onirica": "minotauro",
		"fuente_semilla": "publicacion:revista_umbral_98",
	},
	{
		"id": "libro_popol_wuj_98",
		"superficie": "quiosco",
		"nombre": "Cuaderno cultural — Popol Wuj",
		"precio": 10,
		"destino": "carried",
		"categoria": "publicacion",
		"vendible": false,
		"semilla_onirica": "popol_wuj",
		"fuente_semilla": "libro:popol_wuj_98",
	},
	{
		"id": "periodico_tarde_98",
		"superficie": "quiosco",
		"nombre": "La Tarde Local",
		"precio": 3,
		"destino": "carried",
		"categoria": "publicacion",
		"vendible": false,
	},
	{
		"id": "lampara_verde_usada",
		"superficie": "segunda_mano",
		"nombre": "Lámpara de sobremesa verde",
		"precio": 34,
		"destino": "home_storage",
		"categoria": "hogar",
		"vendible": true,
		"precio_reventa": 12,
	},
	{
		"id": "marco_latón_usado",
		"superficie": "segunda_mano",
		"nombre": "Marco de latón usado",
		"precio": 18,
		"destino": "home_storage",
		"categoria": "hogar",
		"vendible": true,
		"precio_reventa": 6,
	},
]


static func superficies() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for superficie in SUPERFICIES:
		salida.append(superficie.duplicate(true))
	return salida


static func compras(jornada: Dictionary) -> Array[String]:
	var bruto = jornada.get(CLAVE_COMPRAS, [])
	var salida: Array[String] = []
	if typeof(bruto) != TYPE_ARRAY:
		return salida
	for valor in bruto:
		var id_item := String(valor)
		if id_item.is_empty() or _buscar(id_item).is_empty() or salida.has(id_item):
			continue
		salida.append(id_item)
	return salida


static func listar(
	superficie_id: String, jornada: Dictionary, inventario: Dictionary
) -> Array[Dictionary]:
	if superficie_id == "videojuegos":
		return TiendaVideojuegos.listar(jornada)
	var adquiridas := compras(jornada)
	var salida: Array[Dictionary] = []
	for base in CATALOGO:
		if String(base.get("superficie", "")) != superficie_id:
			continue
		var entrada: Dictionary = base.duplicate(true)
		var id_item := String(entrada["id"])
		var repetible := bool(entrada.get("repetible", false))
		if repetible:
			entrada["comprada"] = false
		else:
			entrada["comprada"] = (
				adquiridas.has(id_item) or Inventario.contiene(inventario, id_item)
			)
		salida.append(entrada)
	return salida


## Una única puerta de compra para las superficies del issue. Videojuegos conserva
## su contrato especializado: ROM propia y stock de artefacto; las ROMs externas
## siguen fuera de esta economía.
static func comprar(
	jornada: Dictionary, inventario: Dictionary, superficie_id: String, item_id: String
) -> Dictionary:
	if superficie_id == "videojuegos":
		return TiendaVideojuegos.comprar(jornada, item_id)
	if String(jornada.get("fase", "")) != "trayecto":
		return _fallo(superficie_id, item_id, "fuera_del_trayecto")
	if not jornada.has("dinero"):
		return _fallo(superficie_id, item_id, "jornada_invalida")

	var entrada := _buscar(item_id)
	if entrada.is_empty() or String(entrada.get("superficie", "")) != superficie_id:
		return _fallo(superficie_id, item_id, "item_desconocido")

	var repetible := bool(entrada.get("repetible", false))
	var adquiridas := compras(jornada)
	if not repetible:
		Inventario.completar(inventario)
		if adquiridas.has(item_id) or Inventario.contiene(inventario, item_id):
			return {
				"ok": true,
				"superficie": superficie_id,
				"id": item_id,
				"ya_comprado": true,
				"importe": 0,
				"dinero": int(jornada.get("dinero", 0)),
			}

	var precio := int(entrada.get("precio", 0))
	if precio <= 0:
		return _fallo(superficie_id, item_id, "precio_invalido")
	if not Jornada.gastar(jornada, precio):
		return _fallo(superficie_id, item_id, "sin_dinero")

	if repetible:
		return {
			"ok": true,
			"superficie": superficie_id,
			"id": item_id,
			"ya_comprado": false,
			"repetible": true,
			"consumido": true,
			"importe": precio,
			"dinero": int(jornada["dinero"]),
			"destino": "consumido",
		}

	var objeto := _objeto_inventario(entrada)
	if not Inventario.recoger(inventario, objeto):
		jornada["dinero"] = int(jornada.get("dinero", 0)) + precio
		return _fallo(superficie_id, item_id, "inventario_rechazado")
	if String(entrada.get("destino", "carried")) == "home_storage":
		if not Inventario.guardar_en_casa(inventario, item_id):
			# Estado imposible bajo el contrato actual de Inventario: rollback seguro.
			Inventario.vender(inventario, item_id)
			jornada["dinero"] = int(jornada.get("dinero", 0)) + precio
			return _fallo(superficie_id, item_id, "almacenamiento_rechazado")

	adquiridas.append(item_id)
	jornada[CLAVE_COMPRAS] = adquiridas
	return {
		"ok": true,
		"superficie": superficie_id,
		"id": item_id,
		"ya_comprado": false,
		"importe": precio,
		"dinero": int(jornada["dinero"]),
		"destino": String(entrada.get("destino", "carried")),
	}


## Reventa del inventario en El Trastero (#61/#97).
##
## La superficie no teletransporta objetos desde casa: fuera de casa solo existe
## lo que el jugador lleva encima. Para vender home_storage hay que sacarlo antes
## mediante el almacenamiento doméstico. Inventario sigue siendo la autoridad que
## decide si un objeto es vendible y bloquea siempre los de origen onírico.
static func vender(
	jornada: Dictionary, inventario: Dictionary, superficie_id: String, item_id: String
) -> Dictionary:
	if superficie_id != "segunda_mano":
		return _fallo_reventa(jornada, superficie_id, item_id, "superficie_sin_reventa")
	if String(jornada.get("fase", "")) != "trayecto":
		return _fallo_reventa(jornada, superficie_id, item_id, "fuera_del_trayecto")
	if not jornada.has("dinero"):
		return _fallo_reventa(jornada, superficie_id, item_id, "jornada_invalida")

	Inventario.completar(inventario)
	if not _llevado(inventario, item_id):
		return _fallo_reventa(jornada, superficie_id, item_id, "no_llevado")

	var venta := Inventario.vender(inventario, item_id)
	if not bool(venta.get("vendido", false)):
		return _fallo_reventa(
			jornada,
			superficie_id,
			item_id,
			String(venta.get("motivo", "reventa_rechazada")),
		)

	var importe := maxi(0, int(venta.get("dinero", 0)))
	jornada["dinero"] = int(jornada.get("dinero", 0)) + importe
	return {
		"ok": true,
		"superficie": superficie_id,
		"id": item_id,
		"importe": importe,
		"dinero": int(jornada["dinero"]),
	}


## Metadatos para #442. El consumidor debe llamarlo únicamente tras una
## interacción cultural deliberada (leer/jugar), nunca al comprar.
static func fuente_cultural(item_id: String) -> Dictionary:
	var entrada := _buscar(item_id)
	var id_semilla := String(entrada.get("semilla_onirica", ""))
	var fuente := String(entrada.get("fuente_semilla", ""))
	if id_semilla.is_empty() or fuente.is_empty():
		return {}
	return {"id_semilla": id_semilla, "fuente": fuente}


static func _llevado(inventario: Dictionary, item_id: String) -> bool:
	for objeto in inventario[Inventario.CARRIED]:
		if objeto is Dictionary and String(objeto.get("id", "")) == item_id:
			return true
	return false


static func _buscar(item_id: String) -> Dictionary:
	for entrada in CATALOGO:
		if String(entrada.get("id", "")) == item_id:
			return entrada
	return {}


static func _objeto_inventario(entrada: Dictionary) -> Dictionary:
	return {
		"id": String(entrada["id"]),
		"nombre": String(entrada["nombre"]),
		"categoria": String(entrada.get("categoria", "objeto")),
		"origen": "comercio_barrio",
		"vendible": bool(entrada.get("vendible", false)),
		"precio": int(entrada.get("precio_reventa", 0)),
	}


static func _fallo_reventa(
	jornada: Dictionary, superficie_id: String, item_id: String, motivo: String
) -> Dictionary:
	var fallo := _fallo(superficie_id, item_id, motivo)
	fallo["dinero"] = int(jornada.get("dinero", 0))
	return fallo


static func _fallo(superficie_id: String, item_id: String, motivo: String) -> Dictionary:
	return {
		"ok": false,
		"superficie": superficie_id,
		"id": item_id,
		"motivo": motivo,
	}
