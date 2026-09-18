## Catálogo y compra diegética de cartuchos/ROMs en el trayecto (#93/#800).
##
## La economía sigue perteneciendo a la jornada, pero la biblioteca comprada es
## permanente del perfil. PerfilRoms absorbe además las compras de guardados
## anteriores sin obligar a reescribirlos.
class_name TiendaVideojuegos
extends RefCounted

const CLAVE_COMPRAS := PerfilRoms.CLAVE_COMPRAS


## El catálogo sale del índice de ROMs propias (RomsPropias): jugables con
## precio. Precios provisionales hasta la calibración de #83. Las ROMs de
## user://roms siguen siendo aportadas por el jugador y nunca son mercancía.
static func catalogo() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for rom in RomsPropias.a_la_venta():
		(
			salida
			. append(
				{
					"id": String(rom["id"]),
					"nombre": String(rom["titulo"]),
					"precio": int(rom["precio"]),
					"ruta": String(rom["rom"]),
					"origen": "propia",
				}
			)
		)
	return salida


## Devuelve IDs válidos, únicos y conocidos. La jornada solo se consulta como
## fuente de migración del formato previo a #800; PerfilRoms es la autoridad.
static func compras(jornada: Dictionary) -> Array[String]:
	var bruto := PerfilRoms.migrar_desde_jornada(jornada)
	var salida: Array[String] = []
	for valor in bruto:
		var id_rom := String(valor)
		if id_rom.is_empty() or _buscar(id_rom).is_empty() or salida.has(id_rom):
			continue
		salida.append(id_rom)
	return salida


## Catálogo listo para UI: comprar y mostrar stock son decisiones separadas.
## Una ROM que todavía no ha sido generada por el build aparece sin stock y no
## puede cobrar dinero por error.
static func listar(jornada: Dictionary) -> Array[Dictionary]:
	var adquiridas := compras(jornada)
	var salida: Array[Dictionary] = []
	for base in catalogo():
		var entrada: Dictionary = base.duplicate(true)
		var id_rom := String(entrada.get("id", ""))
		entrada["comprada"] = adquiridas.has(id_rom)
		entrada["disponible"] = FileAccess.file_exists(String(entrada.get("ruta", "")))
		salida.append(entrada)
	return salida


## La tienda existe en el trayecto. Comprar no consume acciones ni concede
## ninguna: únicamente convierte dinero en contenido de ocio opcional.
static func comprar(jornada: Dictionary, id_rom: String) -> Dictionary:
	if String(jornada.get("fase", "")) != "trayecto":
		return _fallo(id_rom, "fuera_del_trayecto")
	if not jornada.has("dinero"):
		return _fallo(id_rom, "jornada_invalida")

	var entrada := _buscar(id_rom)
	if entrada.is_empty():
		return _fallo(id_rom, "rom_desconocida")

	var adquiridas := compras(jornada)
	if adquiridas.has(id_rom):
		return {
			"ok": true,
			"id": id_rom,
			"ya_comprada": true,
			"importe": 0,
			"dinero": int(jornada.get("dinero", 0)),
		}

	var ruta := String(entrada.get("ruta", ""))
	if ruta.is_empty() or not FileAccess.file_exists(ruta):
		return _fallo(id_rom, "sin_stock")

	var precio := int(entrada.get("precio", 0))
	if precio <= 0:
		return _fallo(id_rom, "precio_invalido")
	if not Jornada.gastar(jornada, precio):
		return _fallo(id_rom, "sin_dinero")

	# Cobro y propiedad forman una sola transacción lógica: si el perfil no se
	# puede escribir, se devuelve el dinero para no vender un cartucho fantasma.
	if not PerfilRoms.registrar(id_rom):
		jornada["dinero"] = int(jornada.get("dinero", 0)) + precio
		return _fallo(id_rom, "jornada_invalida")
	return {
		"ok": true,
		"id": id_rom,
		"ya_comprada": false,
		"importe": precio,
		"dinero": int(jornada["dinero"]),
	}


## El "manual de servicio" de Bit 98 se entrega al completar el catálogo que
## realmente existe en esta build. Es un desbloqueo de perfil: PerfilRoms ya es
## permanente y por tanto no hace falta otra bandera de campaña.
static func consola_trucos_desbloqueada(jornada: Dictionary = {}) -> bool:
	var adquiridas := compras(jornada)
	var exigidas: Array[String] = []
	for entrada in catalogo():
		var ruta := String(entrada.get("ruta", ""))
		if ruta.is_empty() or not FileAccess.file_exists(ruta):
			continue
		exigidas.append(String(entrada.get("id", "")))
	if exigidas.is_empty():
		return false
	for id_rom in exigidas:
		if not adquiridas.has(id_rom):
			return false
	return true


## Contrato que consume #124: solo devuelve contenido comprado y cuyo artefacto
## existe. No mezcla ni inspecciona user://roms.
static func roms_compradas(jornada: Dictionary) -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for entrada in listar(jornada):
		if bool(entrada.get("comprada", false)) and bool(entrada.get("disponible", false)):
			salida.append(entrada.duplicate(true))
	return salida


static func _buscar(id_rom: String) -> Dictionary:
	for entrada in catalogo():
		if String(entrada.get("id", "")) == id_rom:
			return entrada
	return {}


static func _fallo(id_rom: String, motivo: String) -> Dictionary:
	return {"ok": false, "id": id_rom, "motivo": motivo}
