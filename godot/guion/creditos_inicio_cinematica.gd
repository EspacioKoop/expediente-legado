## Apertura 3D de créditos de #795.
##
## Consume exclusivamente la fuente canónica de CreditosInicio y la presenta
## sobre espacios reales del juego mediante el reproductor común de cinemáticas.
## No persiste nada en Partida/Jornada: el menú decide que solo se reproduzca
## una vez por sesión.
class_name CreditosInicioCinematica
extends RefCounted

const ID := "creditos-inicio"
const ENTRADAS_POR_PLANO := 4


static func planos() -> Array:
	var salida: Array = []
	var bloques: Array = CreditosInicio.bloques_completos()
	for indice in bloques.size():
		var bloque: Dictionary = bloques[indice]
		var paginas := _paginas_de(bloque)
		if paginas.is_empty():
			paginas.append("")
		for pagina_indice in paginas.size():
			var camara := _camara_para(indice, pagina_indice)
			var plano := {
				"tipo": "3d",
				"nombre": "%s-%d" % [String(bloque.get("id", "bloque")), pagina_indice],
				"decorado": _decorado_para(indice),
				"camara_desde": camara["camara_desde"],
				"mira_desde": camara["mira_desde"],
				"camara": camara["camara"],
				"mira": camara["mira"],
				"segundos": _duracion_de(bloque, pagina_indice),
				"rotulo": _rotulo_de(bloque),
				"voz": String(paginas[pagina_indice]),
			}
			if String(bloque.get("id", "")) == "titulo":
				plano["fundido_desde"] = 0.0
				plano["fundido_hasta"] = 0.18
			salida.append(plano)
	return Cinematica.resolver(salida)


static func _paginas_de(bloque: Dictionary) -> Array:
	var bloque_id := String(bloque.get("id", ""))
	if bloque_id == "direccion":
		return [""]
	if bloque_id == "titulo":
		return [""]

	var entradas: Array = bloque.get("entradas", [])
	var lineas: Array = []
	for entrada in entradas:
		if not (entrada is Dictionary):
			continue
		var nombre := String(entrada.get("nombre", "")).strip_edges()
		if nombre.is_empty():
			continue
		var licencia := String(entrada.get("licencia", "")).strip_edges()
		lineas.append(nombre if licencia.is_empty() else "%s · %s" % [nombre, licencia])

	var paginas: Array = []
	var actual: Array = []
	for linea in lineas:
		actual.append(linea)
		if actual.size() >= ENTRADAS_POR_PLANO:
			paginas.append("  ·  ".join(PackedStringArray(actual)))
			actual.clear()
	if not actual.is_empty():
		paginas.append("  ·  ".join(PackedStringArray(actual)))
	return paginas


static func _rotulo_de(bloque: Dictionary) -> String:
	var bloque_id := String(bloque.get("id", ""))
	var entradas: Array = bloque.get("entradas", [])
	if (bloque_id == "direccion" or bloque_id == "titulo") and not entradas.is_empty():
		var primera = entradas[0]
		if primera is Dictionary:
			return String(primera.get("nombre", bloque.get("titulo", "")))
	return String(bloque.get("titulo", ""))


static func _duracion_de(bloque: Dictionary, pagina: int) -> float:
	if String(bloque.get("id", "")) == "titulo":
		return 4.6
	return 4.0 if pagina == 0 else 3.2


static func _decorado_para(indice: int) -> Dictionary:
	match indice % 5:
		0:
			return EspaciosCatalogo.OFICINA.duplicate(true)
		1:
			return EspaciosCatalogo.CALLE.duplicate(true)
		2:
			return EspaciosCatalogo.CASA.duplicate(true)
		3:
			return EspaciosCatalogo.OFICINA.duplicate(true)
		_:
			return EspaciosCatalogo.CALLE.duplicate(true)


static func _camara_para(indice: int, pagina: int) -> Dictionary:
	var deriva := float(pagina) * 0.18
	match indice % 5:
		0:
			return {
				"camara_desde": Vector3(-0.8 + deriva, 1.65, 3.0),
				"mira_desde": Vector3(-3.8, 1.0, 0.8),
				"camara": Vector3(-2.2 + deriva, 1.50, 2.05),
				"mira": Vector3(-4.0, 0.95, 0.7),
			}
		1:
			return {
				"camara_desde": Vector3(-1.9 + deriva, 1.65, -12.5),
				"mira_desde": Vector3(0.0, 1.1, -4.5),
				"camara": Vector3(-0.7 + deriva, 1.58, -9.3),
				"mira": Vector3(0.0, 1.05, -1.5),
			}
		2:
			return {
				"camara_desde": Vector3(2.6 + deriva, 1.62, 3.1),
				"mira_desde": Vector3(-1.1, 0.9, -0.8),
				"camara": Vector3(1.3 + deriva, 1.48, 1.5),
				"mira": Vector3(-2.4, 0.62, -2.0),
			}
		3:
			return {
				"camara_desde": Vector3(2.8 - deriva, 1.62, 2.9),
				"mira_desde": Vector3(5.4, 1.0, 1.8),
				"camara": Vector3(1.7 - deriva, 1.55, 2.4),
				"mira": Vector3(5.45, 1.0, -0.2),
			}
		_:
			return {
				"camara_desde": Vector3(1.6 - deriva, 1.7, 8.5),
				"mira_desde": Vector3(0.0, 1.0, 13.0),
				"camara": Vector3(0.4 - deriva, 1.55, 10.5),
				"mira": Vector3(0.0, 1.0, 15.0),
			}
