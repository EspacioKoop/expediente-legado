extends RefCounted

const CATALOGO_ESPACIOS := preload("res://guion/espacios_catalogo.gd")
const MODELO_CINEMATICA := preload("res://guion/cinematica.gd")
const MODELOS := preload("res://guion/modelos.gd")
const ASSETS := preload("res://debug/editor_niveles_cinematicas_assets.gd")
## Lo que admite un id de documento: viaja a un nombre de archivo, así que todo
## lo demás se sustituye por un guion bajo en vez de rechazar el asset.
const CARACTERES_ID := "abcdefghijklmnopqrstuvwxyz0123456789_"
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
			if tipo == "modelo" and not recurso.is_empty() and not MODELOS.hay(recurso):
				errores.append("colocación %d: falta el recurso de modelo '%s'" % [i, recurso])
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
		if plano.has("rotulo_fuente"):
			var fuente: Variant = plano["rotulo_fuente"]
			if not fuente is String:
				errores.append("plano %d: rotulo_fuente debe ser una ruta" % i)
			elif ASSETS.tipo_de(String(fuente)) != "fuente":
				errores.append("plano %d: rotulo_fuente no es una fuente del proyecto" % i)
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
					if figura.has("textura"):
						var textura: Variant = figura["textura"]
						if not textura is String:
							errores.append(
								"plano %d: figura[%d].textura debe ser una ruta" % [i, j]
							)
						elif ASSETS.tipo_de(String(textura)) != "imagen":
							errores.append(
								(
									"plano %d: figura[%d].textura no es una imagen del proyecto"
									% [i, j]
								)
							)
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
		if plano.has("decorado"):
			var decorado: Variant = plano["decorado"]
			if not decorado is Dictionary:
				errores.append("plano %d: decorado debe ser un objeto" % i)
				continue
			var bultos: Variant = decorado.get("bultos", [])
			if not bultos is Array:
				errores.append("plano %d: decorado.bultos debe ser una lista" % i)
				continue
			for j in bultos.size():
				var bulto: Variant = bultos[j]
				if not bulto is Dictionary:
					errores.append("plano %d: decorado.bultos[%d] debe ser un objeto" % [i, j])
					continue
				if bulto.has("modelo"):
					var modelo: Variant = bulto["modelo"]
					if not modelo is String:
						errores.append(
							"plano %d: decorado.bultos[%d].modelo debe ser texto" % [i, j]
						)
					elif not String(modelo).is_empty() and not MODELOS.hay(String(modelo)):
						errores.append(
							"plano %d: falta el recurso de modelo '%s'" % [i, String(modelo)]
						)
			var figuras: Variant = decorado.get("figuras", [])
			if not figuras is Array:
				errores.append("plano %d: decorado.figuras debe ser una lista" % i)
			else:
				for j in figuras.size():
					var figura: Variant = figuras[j]
					if not figura is Dictionary:
						errores.append("plano %d: decorado.figuras[%d] debe ser un objeto" % [i, j])
						continue
					var personaje := String(figura.get("modelo", ""))
					if not personaje.is_empty() and not MODELOS.hay(personaje):
						errores.append(
							"plano %d: falta el modelo del personaje '%s'" % [i, personaje]
						)
					if not vector3_valido(figura.get("pos")):
						errores.append("plano %d: figura %d.pos debe tener 3 números" % [i, j])
					var giro: Variant = figura.get("giro", 0.0)
					if not (giro is int or giro is float):
						errores.append("plano %d: figura %d.giro debe ser número" % [i, j])
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


static func color_desde(valor: Variant, defecto: Color = Color.WHITE) -> Color:
	if valor is Color:
		return valor
	if valor is Array and (valor.size() == 3 or valor.size() == 4):
		var alfa := float(valor[3]) if valor.size() == 4 else 1.0
		return Color(float(valor[0]), float(valor[1]), float(valor[2]), alfa)
	return defecto


static func espacio_para_vista(espacio: Dictionary) -> Dictionary:
	var salida := espacio.duplicate(true)
	for campo in ["suelo", "centro_suelo"]:
		if salida.has(campo):
			salida[campo] = vector2_desde(salida[campo])
	for campo in ["entrada", "deformacion_textura"]:
		if salida.has(campo):
			salida[campo] = vector3_desde(salida[campo])
	for campo in ["color_suelo", "color_techo", "color_muro"]:
		if salida.has(campo):
			salida[campo] = color_desde(salida[campo])
	for campo in ["luces", "ventanas", "salidas"]:
		var elementos: Variant = salida.get(campo, [])
		if not elementos is Array:
			continue
		for indice in elementos.size():
			var elemento: Variant = elementos[indice]
			if not elemento is Dictionary:
				continue
			elemento = elemento.duplicate(true)
			for vector in ["pos", "tam", "rotacion"]:
				if elemento.has(vector):
					elemento[vector] = vector3_desde(elemento[vector])
			if elemento.has("color"):
				elemento["color"] = color_desde(elemento["color"])
			elementos[indice] = elemento
		salida[campo] = elementos
	for campo in ["cigarros", "sitios_companeros"]:
		var vectores: Variant = salida.get(campo, [])
		if vectores is Array:
			for indice in vectores.size():
				vectores[indice] = vector3_desde(vectores[indice])
			salida[campo] = vectores
	var figuras: Variant = salida.get("figuras", [])
	if figuras is Array:
		for indice in figuras.size():
			if not figuras[indice] is Dictionary:
				continue
			var figura: Dictionary = figuras[indice].duplicate(true)
			if figura.has("pos"):
				figura["pos"] = vector3_desde(figura["pos"])
			if figura.has("color"):
				figura["color"] = color_desde(figura["color"])
			figuras[indice] = figura
		salida["figuras"] = figuras
	var contorno: Variant = salida.get("contorno", [])
	if contorno is Array:
		for indice in contorno.size():
			contorno[indice] = vector2_desde(contorno[indice])
			salida["contorno"] = contorno
	return salida


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


static func serializar_json(valor: Variant) -> Variant:
	if valor is Vector2:
		return [valor.x, valor.y]
	if valor is Vector3:
		return [valor.x, valor.y, valor.z]
	if valor is Color:
		return [valor.r, valor.g, valor.b, valor.a]
	if valor is Array:
		var salida: Array = []
		for elemento in valor:
			salida.append(serializar_json(elemento))
		return salida
	if valor is Dictionary:
		var salida: Dictionary = {}
		for clave in valor:
			salida[clave] = serializar_json(valor[clave])
		return salida
	return valor


static func escenario_catalogado_json(fase: String) -> Dictionary:
	var escenario: Variant = CATALOGO_ESPACIOS.POR_FASE.get(fase, {})
	if not escenario is Dictionary:
		return {}
	return serializar_json(escenario)


static func crear_biblioteca_muebles(
	al_agregar: Callable, texto_boton: String = "Añadir al nivel"
) -> Dictionary:
	var fila := HBoxContainer.new()
	var selector := OptionButton.new()
	var muebles: Array = MODELOS.MATERIALES_MUEBLE.keys()
	muebles.sort()
	for nombre in muebles:
		if MODELOS.hay(String(nombre)):
			selector.add_item(String(nombre))
	if selector.item_count == 0:
		selector.add_item("No hay modelos disponibles")
		selector.disabled = true
	fila.add_child(selector)
	var boton := Button.new()
	boton.text = texto_boton
	boton.pressed.connect(al_agregar)
	boton.disabled = selector.disabled
	fila.add_child(boton)
	return {"fila": fila, "selector": selector}


static func nuevo_mueble(recurso: String, numero: int) -> Dictionary:
	var tam := Vector3(1.0, 1.0, 1.0)
	match recurso:
		"desk":
			tam = Vector3(2.0, 0.75, 1.0)
		"bookcaseClosed":
			tam = Vector3(1.0, 1.8, 0.6)
		"computerScreen":
			tam = Vector3(0.5, 0.45, 0.4)
		"chairDesk":
			tam = Vector3(0.74, 1.14, 0.74)
		"trashcan":
			tam = Vector3(0.34, 0.45, 0.34)
	var posicion := Vector3(0.0, tam.y / 2.0, 0.0)
	return {
		"tipo": "modelo",
		"id": "mueble_%03d" % numero,
		"recurso": recurso,
		"origen": "biblioteca_catalogada",
		"transform":
		{
			"posicion": [posicion.x, posicion.y, posicion.z],
			"rotacion": [0.0, 0.0, 0.0],
			"escala": [1.0, 1.0, 1.0],
		},
		"extra": {"tam": [tam.x, tam.y, tam.z]},
	}


static func nuevo_bulto(recurso: String, numero: int) -> Dictionary:
	var colocacion := nuevo_mueble(recurso, numero)
	var transform: Dictionary = colocacion["transform"]
	var tam: Array = colocacion["extra"]["tam"]
	return {
		"id": colocacion["id"],
		"modelo": recurso,
		"pos": transform["posicion"],
		"tam": tam,
		"color": [0.45, 0.44, 0.42, 1.0],
	}


static func agregar_mueble_a_nivel(datos: Dictionary, recurso: String) -> int:
	if recurso.begins_with("res://"):
		return agregar_asset_a_nivel(datos, recurso)
	if not MODELOS.MATERIALES_MUEBLE.has(recurso) or not MODELOS.hay(recurso):
		return -1
	var colocaciones: Variant = datos.get("colocaciones", [])
	if not colocaciones is Array:
		return -1
	colocaciones.append(nuevo_mueble(recurso, colocaciones.size() + 1))
	datos["colocaciones"] = colocaciones
	return colocaciones.size() - 1


static func agregar_mueble_a_decorado(texto: String, recurso: String) -> Dictionary:
	if recurso.begins_with("res://"):
		return agregar_asset_a_decorado(texto, recurso)
	if not MODELOS.MATERIALES_MUEBLE.has(recurso) or not MODELOS.hay(recurso):
		return {"error": "Modelo fuera de la biblioteca catalogada"}
	var decorado: Variant = JSON.parse_string(texto) if not texto.strip_edges().is_empty() else {}
	if not decorado is Dictionary:
		return {"error": "Decorado: JSON inválido; corrígelo antes de añadir objetos"}
	var bultos: Variant = decorado.get("bultos", [])
	if not bultos is Array:
		return {"error": "Decorado: bultos debe ser una lista"}
	bultos.append(nuevo_bulto(recurso, bultos.size() + 1))
	decorado["bultos"] = bultos
	return {"decorado": decorado, "error": ""}


## Un asset cualquiera del proyecto como colocación de nivel (#2942).
##
## El `tam` no se inventa: se mide el AABB real del asset, porque `Modelos`
## encaja la pieza en el `tam` declarado y un tamaño de catálogo ajeno la
## deformaría. Si no se puede medir —un recurso sin mallas— se cae a un metro
## cúbico, que es editable a mano, en vez de a cero.
static func nuevo_asset(ruta: String, numero: int) -> Dictionary:
	var tam := ASSETS.medida(ruta)
	if tam == Vector3.ZERO:
		tam = Vector3.ONE
	var posicion := Vector3(0.0, tam.y / 2.0, 0.0)
	return {
		"tipo": "modelo",
		"id": "%s_%03d" % [id_desde_ruta(ruta), numero],
		"recurso": ruta,
		"origen": "biblioteca_proyecto",
		"transform":
		{
			"posicion": [posicion.x, posicion.y, posicion.z],
			"rotacion": [0.0, 0.0, 0.0],
			"escala": [1.0, 1.0, 1.0],
		},
		"extra": {"tam": [tam.x, tam.y, tam.z]},
	}


static func nuevo_bulto_asset(ruta: String, numero: int) -> Dictionary:
	var colocacion := nuevo_asset(ruta, numero)
	var transform: Dictionary = colocacion["transform"]
	return {
		"id": colocacion["id"],
		"modelo": ruta,
		"pos": transform["posicion"],
		"tam": colocacion["extra"]["tam"],
		"color": [0.45, 0.44, 0.42, 1.0],
	}


## Un identificador de documento a partir de la ruta del asset. El id viaja a un
## nombre de archivo, así que se queda solo con lo que `id_ruta_valido` admite.
static func id_desde_ruta(ruta: String) -> String:
	var base := ruta.get_file().get_basename().to_lower()
	var limpio := ""
	for indice in base.length():
		var caracter := base[indice]
		limpio += caracter if CARACTERES_ID.contains(caracter) else "_"
	limpio = limpio.lstrip("_")
	return limpio if not limpio.is_empty() else "asset"


static func agregar_asset_a_nivel(datos: Dictionary, ruta: String) -> int:
	if not ASSETS.es_colocable(ruta):
		return -1
	var colocaciones: Variant = datos.get("colocaciones", [])
	if not colocaciones is Array:
		return -1
	colocaciones.append(nuevo_asset(ruta, colocaciones.size() + 1))
	datos["colocaciones"] = colocaciones
	return colocaciones.size() - 1


static func agregar_asset_a_decorado(texto: String, ruta: String) -> Dictionary:
	if not ASSETS.es_colocable(ruta):
		return {"error": "El asset '%s' no es una pieza 3D colocable" % ruta}
	var decorado: Variant = JSON.parse_string(texto) if not texto.strip_edges().is_empty() else {}
	if not decorado is Dictionary:
		return {"error": "Decorado: JSON inválido; corrígelo antes de añadir objetos"}
	var bultos: Variant = decorado.get("bultos", [])
	if not bultos is Array:
		return {"error": "Decorado: bultos debe ser una lista"}
	bultos.append(nuevo_bulto_asset(ruta, bultos.size() + 1))
	decorado["bultos"] = bultos
	return {"decorado": decorado, "error": ""}


## Añade una pieza con imagen a la figura de un plano 2D.
##
## La imagen entra como RUTA en una pieza normal, con su propio `rect` y un
## `color` blanco de modulación: así una figura mezcla rectángulos planos e
## imágenes, y un documento viejo sigue válido. El encuadre se mide con el
## tamaño real de la textura —centrado en el origen— porque una imagen estirada
## a un rectángulo inventado se reconoce peor que el propio hueco.
static func agregar_imagen_a_figura(texto: String, ruta: String) -> Dictionary:
	if ASSETS.tipo_de(ruta) != "imagen":
		return {"error": "El asset '%s' no es una imagen del proyecto" % ruta}
	var figura: Variant = JSON.parse_string(texto) if not texto.strip_edges().is_empty() else []
	if not figura is Array:
		return {"error": "Figura: JSON inválido; corrígelo antes de añadir imágenes"}
	var tam := Vector2(160.0, 90.0)
	if ResourceLoader.exists(ruta):
		var recurso: Resource = load(ruta)
		if recurso is Texture2D:
			var medida: Vector2 = (recurso as Texture2D).get_size()
			if medida.x > 0.0 and medida.y > 0.0:
				tam = medida
	(
		figura
		. append(
			{
				"rect": {"x": -tam.x / 2.0, "y": -tam.y / 2.0, "width": tam.x, "height": tam.y},
				"color": [1.0, 1.0, 1.0, 1.0],
				"textura": ruta,
			}
		)
	)
	return {"figura": figura, "error": ""}


## Devuelve el identificador que `Modelos.persona` espera para un avatar
## Rocketbox del catálogo de assets, o vacío para cualquier otro recurso.
static func modelo_personaje_desde_ruta(ruta: String) -> String:
	const PREFIJO := "res://assets/modelos/"
	if not ruta.begins_with(PREFIJO):
		return ""
	var nombre := ruta.trim_prefix(PREFIJO).get_basename()
	if not MODELOS.es_realista(nombre) or not MODELOS.hay(nombre):
		return ""
	return nombre


static func agregar_personaje_a_decorado(texto: String, ruta: String) -> Dictionary:
	var modelo := modelo_personaje_desde_ruta(ruta)
	if modelo.is_empty():
		return {"error": "El asset seleccionado no es un personaje humano disponible"}
	var decorado: Variant = JSON.parse_string(texto) if not texto.strip_edges().is_empty() else {}
	if not decorado is Dictionary:
		return {"error": "Decorado: JSON inválido; corrígelo antes de añadir personajes"}
	var figuras: Variant = decorado.get("figuras", [])
	if not figuras is Array:
		return {"error": "Decorado: figuras debe ser una lista"}
	(
		figuras
		. append(
			{
				"modelo": modelo,
				"pos": [0.0, 0.0, 0.0],
				"giro": 0.0,
				"color": [0.30, 0.28, 0.34, 1.0],
				"rotulo": "",
			}
		)
	)
	decorado["figuras"] = figuras
	return {"decorado": decorado, "error": ""}


static func actualizar_posicion(
	datos: Dictionary, tipo: String, indice: int, indice_plano: int, posicion: Vector3
) -> Dictionary:
	if tipo == "nivel":
		var colocaciones: Variant = datos.get("colocaciones", [])
		if not colocaciones is Array or indice < 0 or indice >= colocaciones.size():
			return {}
		var colocacion: Variant = colocaciones[indice]
		if not colocacion is Dictionary:
			return {}
		var transform: Variant = colocacion.get("transform", {})
		if not transform is Dictionary:
			transform = {}
		transform["posicion"] = [posicion.x, posicion.y, posicion.z]
		colocacion["transform"] = transform
		colocaciones[indice] = colocacion
		datos["colocaciones"] = colocaciones
		return {"tipo": "nivel", "ok": true}
	var planos: Variant = datos.get("planos", [])
	if not planos is Array or indice_plano < 0 or indice_plano >= planos.size():
		return {}
	var plano: Variant = planos[indice_plano]
	if not plano is Dictionary:
		return {}
	var decorado: Variant = plano.get("decorado", {})
	if not decorado is Dictionary:
		return {}
	var bultos: Variant = decorado.get("bultos", [])
	if not bultos is Array or indice < 0 or indice >= bultos.size():
		return {}
	var bulto: Variant = bultos[indice]
	if not bulto is Dictionary:
		return {}
	bulto["pos"] = [posicion.x, posicion.y, posicion.z]
	bultos[indice] = bulto
	decorado["bultos"] = bultos
	plano["decorado"] = decorado
	planos[indice_plano] = plano
	datos["planos"] = planos
	return {"tipo": "cinematica", "ok": true, "indice_plano": indice_plano, "decorado": decorado}


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
