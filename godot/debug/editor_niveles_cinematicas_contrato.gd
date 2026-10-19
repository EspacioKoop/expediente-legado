extends RefCounted

const CATALOGO_ESPACIOS := preload("res://guion/espacios_catalogo.gd")
const MODELO_CINEMATICA := preload("res://guion/cinematica.gd")
const FORMATO_NIVEL := "siga98-nivel-v1"
const FORMATO_CINEMATICA := "siga98-cinematica-v1"
const TIPOS_RECURSO := [
	"bulto", "figura", "pantalla", "ventana", "luz", "cartel", "cigarro", "gato", "salida", "modelo"
]


static func validar_nivel(datos: Dictionary) -> PackedStringArray:
	var errores := PackedStringArray()
	var id := String(datos.get("id", "")).strip_edges()
	var version := String(datos.get("version", "")).strip_edges()
	var fase := String(datos.get("fase", "")).strip_edges()
	var colocaciones_var: Variant = datos.get("colocaciones", [])

	if id.is_empty():
		errores.append("Falta id")
	elif not id_ruta_valido(id):
		errores.append("El id contiene caracteres no válidos para un archivo")
	if version.is_empty():
		errores.append("Falta version")
	elif version != "1":
		errores.append("Versión no soportada: '%s' (esperada '1')" % version)
	if fase.is_empty():
		errores.append("Falta fase")
	elif not CATALOGO_ESPACIOS.POR_FASE.has(fase):
		errores.append(
			"Fase desconocida: '%s' (válidas: %s)" % [fase, CATALOGO_ESPACIOS.POR_FASE.keys()]
		)

	if not colocaciones_var is Array:
		errores.append("colocaciones debe ser un array")
	else:
		var colocaciones: Array = colocaciones_var
		for i in colocaciones.size():
			if not colocaciones[i] is Dictionary:
				errores.append("colocación %d debe ser un objeto" % i)
				continue
			var c: Dictionary = colocaciones[i]
			var cid := String(c.get("id", "")).strip_edges()
			var recurso := String(c.get("recurso", "")).strip_edges()
			var origen := String(c.get("origen", "")).strip_edges()
			var tiene_tipo := c.has("tipo")
			var tipo := String(c.get("tipo", "")).strip_edges()
			if tiene_tipo:
				if tipo.is_empty():
					errores.append("colocación %d: falta tipo" % i)
				elif not TIPOS_RECURSO.has(tipo):
					errores.append("colocación %d: tipo de recurso desconocido '%s'" % [i, tipo])
			elif origen.is_empty():
				errores.append("colocación %d: falta origen catalogado" % i)
			if cid.is_empty():
				errores.append("colocación %d: falta id" % i)
			elif not id_ruta_valido(cid):
				errores.append("colocación %d: id contiene caracteres no válidos" % i)
			if recurso.is_empty() and tipo != "salida" and tipo != "cartel":
				errores.append("colocación %d (%s): falta recurso" % [i, tipo])
			if c.has("transform"):
				var transform: Variant = c["transform"]
				if not transform is Dictionary:
					errores.append("colocación %d: transform debe ser un objeto" % i)
				else:
					for eje in ["posicion", "rotacion", "escala"]:
						if transform.has(eje) and not vector3_valido(transform[eje]):
							errores.append(
								"colocación %d: transform.%s debe tener 3 números" % [i, eje]
							)
	return errores


static func validar_cinematica(datos: Dictionary) -> PackedStringArray:
	var errores := PackedStringArray()
	var id := String(datos.get("id", "")).strip_edges()
	var version := String(datos.get("version", "")).strip_edges()
	var planos_var: Variant = datos.get("planos", [])

	if id.is_empty():
		errores.append("Falta id")
	elif not id_ruta_valido(id):
		errores.append("El id contiene caracteres no válidos para un archivo")
	if version.is_empty():
		errores.append("Falta version")
	elif version != "1":
		errores.append("Versión no soportada: '%s' (esperada '1')" % version)

	if not planos_var is Array:
		errores.append("planos debe ser un array")
		return errores

	var planos: Array = planos_var
	var planos_validos: Array = []
	for indice in planos.size():
		if planos[indice] is Dictionary:
			planos_validos.append(planos[indice])
		else:
			errores.append("plano %d debe ser un objeto" % indice)
	errores.append_array(MODELO_CINEMATICA.validar(planos_validos))

	for i in planos_validos.size():
		var plano: Dictionary = planos_validos[i]
		var tipo := String(plano.get("tipo", "")).strip_edges()
		if tipo == "3d":
			for campo in ["camara", "mira"]:
				if not vector3_valido(plano.get(campo)):
					errores.append("plano %d: %s debe tener 3 números" % [i, campo])
			for campo in ["camara_desde", "mira_desde"]:
				if plano.has(campo) and not vector3_valido(plano[campo]):
					errores.append("plano %d: %s debe tener 3 números" % [i, campo])
		elif tipo == "2d":
			var figuras: Variant = plano.get("figura", [])
			if not vector2_valido(plano.get("desde")):
				errores.append("plano %d: desde debe tener 2 números" % i)
			if not vector2_valido(plano.get("hasta")):
				errores.append("plano %d: hasta debe tener 2 números" % i)
			if figuras is Array:
				for j in figuras.size():
					var figura: Variant = figuras[j]
					if not figura is Dictionary:
						errores.append("plano %d: figura[%d] debe ser un objeto" % [i, j])
						continue
					var rect: Variant = figura.get("rect")
					var color: Variant = figura.get("color")
					if rect is Dictionary:
						for campo in ["x", "y", "width", "height"]:
							var componente: Variant = rect.get(campo)
							if not (componente is int or componente is float):
								errores.append(
									"plano %d: figura[%d].rect.%s debe ser número" % [i, j, campo]
								)
					else:
						errores.append("plano %d: figura[%d].rect debe ser un objeto" % [i, j])
					if not color is Array or color.size() < 3 or color.size() > 4:
						errores.append(
							"plano %d: figura[%d].color debe tener 3 o 4 números" % [i, j]
						)
					else:
						for componente in color:
							if not (componente is int or componente is float):
								errores.append(
									(
										"plano %d: figura[%d].color contiene un valor no numérico"
										% [i, j]
									)
								)
								break
	return errores


static func id_ruta_valido(id: String) -> bool:
	for prohibido in ["..", "/", "\\", ":", "*", "?", '"', "<", ">", "|"]:
		if id.contains(prohibido):
			return false
	return true


static func vector3_valido(valor: Variant) -> bool:
	if not valor is Array or valor.size() != 3:
		return false
	for componente in valor:
		if not (componente is int or componente is float):
			return false
	return true


static func vector3_desde(valor: Variant, defecto: Vector3 = Vector3.ZERO) -> Vector3:
	if valor is Vector3:
		return valor
	if vector3_valido(valor):
		return Vector3(float(valor[0]), float(valor[1]), float(valor[2]))
	return defecto


static func vector2_valido(valor: Variant) -> bool:
	if not valor is Array or valor.size() != 2:
		return false
	for componente in valor:
		if not (componente is int or componente is float):
			return false
	return true


static func vector2_desde(valor: Variant, defecto: Vector2 = Vector2.ZERO) -> Vector2:
	if valor is Vector2:
		return valor
	if vector2_valido(valor):
		return Vector2(float(valor[0]), float(valor[1]))
	return defecto


static func paquete_nivel(datos: Dictionary) -> Dictionary:
	return {"formato": FORMATO_NIVEL, "documento": datos}


static func paquete_cinematica(datos: Dictionary) -> Dictionary:
	return {"formato": FORMATO_CINEMATICA, "documento": datos}


static func datos_desde_paquete(paquete: Variant) -> Dictionary:
	if not paquete is Dictionary:
		return {}
	var formato := String(paquete.get("formato", ""))
	if formato != FORMATO_NIVEL and formato != FORMATO_CINEMATICA:
		return {}
	var documento: Variant = paquete.get("documento", {})
	if not documento is Dictionary:
		return {}
	var tipo_esperado := "nivel" if formato == FORMATO_NIVEL else "cinematica"
	if String(documento.get("tipo", "")) != tipo_esperado:
		return {}
	return documento
