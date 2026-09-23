## Contrato puro para #955: combina objetos que ya viven en Inventario.
##
## No descubre recetas ni decide contenido narrativo. El llamador aporta un catálogo
## explícito y este servicio se limita a resolver la pareja, validar disponibilidad y
## aplicar el cambio de forma determinista. Las parejas son conmutativas: A+B y B+A
## representan la misma receta.
class_name CombinacionObjetos
extends RefCounted

const ESTADO_EXITO := "exito"
const ESTADO_FALLO := "fallo"


static func firma(objeto_a: String, objeto_b: String) -> String:
	var ids := [objeto_a, objeto_b]
	ids.sort()
	return "%s|%s" % [String(ids[0]), String(ids[1])]


static func receta_para(recetas: Array, objeto_a: String, objeto_b: String) -> Dictionary:
	if objeto_a.is_empty() or objeto_b.is_empty() or objeto_a == objeto_b:
		return {}
	var buscada := firma(objeto_a, objeto_b)
	for valor in recetas:
		if not valor is Dictionary:
			continue
		var receta: Dictionary = valor
		var ingredientes = receta.get("ingredientes", [])
		if not ingredientes is Array or ingredientes.size() != 2:
			continue
		var ingrediente_a := String(ingredientes[0])
		var ingrediente_b := String(ingredientes[1])
		if firma(ingrediente_a, ingrediente_b) == buscada:
			return receta.duplicate(true)
	return {}


static func previsualizar(
	inventario: Dictionary, recetas: Array, objeto_a: String, objeto_b: String
) -> Dictionary:
	Inventario.completar(inventario)
	if objeto_a.is_empty() or objeto_b.is_empty():
		return _fallo("slot_vacio")
	if objeto_a == objeto_b:
		return _fallo("mismo_objeto")
	if not Inventario.contiene(inventario, objeto_a) or not Inventario.contiene(
		inventario, objeto_b
	):
		return _fallo("objeto_ausente")

	var receta := receta_para(recetas, objeto_a, objeto_b)
	if receta.is_empty():
		return _fallo("sin_receta")
	var resultado = receta.get("resultado", {})
	if not resultado is Dictionary or String(resultado.get("id", "")).is_empty():
		return _fallo("receta_invalida")

	var consumir := _ids_consumidos(receta, objeto_a, objeto_b)
	if consumir.is_empty():
		return _fallo("receta_invalida")
	var resultado_id := String(resultado["id"])
	if Inventario.contiene(inventario, resultado_id) and resultado_id not in consumir:
		return _fallo("resultado_existente")

	return {
		"estado": ESTADO_EXITO,
		"motivo": "",
		"receta_id": String(receta.get("id", firma(objeto_a, objeto_b))),
		"resultado": resultado.duplicate(true),
		"consumir": consumir.duplicate(),
	}


static func combinar(
	inventario: Dictionary, recetas: Array, objeto_a: String, objeto_b: String
) -> Dictionary:
	var vista := previsualizar(inventario, recetas, objeto_a, objeto_b)
	if String(vista.get("estado", "")) != ESTADO_EXITO:
		return vista

	var retirados: Array[Dictionary] = []
	for objeto_id in vista["consumir"]:
		var retiro := Inventario.retirar(inventario, String(objeto_id))
		if not bool(retiro.get("retirado", false)):
			_restaurar(inventario, retirados)
			return _fallo("objeto_ausente")
		retirados.append(retiro)

	var resultado: Dictionary = vista["resultado"]
	if not Inventario.recoger(inventario, resultado):
		_restaurar(inventario, retirados)
		return _fallo("resultado_no_materializado")

	return vista


static func _ids_consumidos(receta: Dictionary, objeto_a: String, objeto_b: String) -> Array[String]:
	var bruto = receta.get("consumir", [objeto_a, objeto_b])
	if not bruto is Array:
		return []
	var permitidos := [objeto_a, objeto_b]
	var ids: Array[String] = []
	for valor in bruto:
		var objeto_id := String(valor)
		if objeto_id not in permitidos or objeto_id in ids:
			return []
		ids.append(objeto_id)
	return ids


static func _restaurar(inventario: Dictionary, retirados: Array[Dictionary]) -> void:
	Inventario.completar(inventario)
	for retiro in retirados:
		var ubicacion := String(retiro.get("ubicacion", ""))
		var objeto = retiro.get("objeto", {})
		if ubicacion not in [Inventario.CARRIED, Inventario.HOME_STORAGE]:
			continue
		if not objeto is Dictionary:
			continue
		inventario[ubicacion].append(objeto)


static func _fallo(motivo: String) -> Dictionary:
	return {
		"estado": ESTADO_FALLO,
		"motivo": motivo,
		"receta_id": "",
		"resultado": {},
		"consumir": [],
	}
