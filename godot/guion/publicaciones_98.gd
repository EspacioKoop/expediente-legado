## Publicaciones físicas de ocio/cultura de 1998 (#674).
##
## Este contrato no monta UI ni geometría. Centraliza catálogo, piezas hojeables
## y estado de lectura dentro de Jornada. Las compras de quiosco delegan en
## ComercioBarrio (#676), que a su vez reutiliza Jornada.gastar/Inventario (#93).
## Comprar o encontrar una publicación nunca activa #442: la semilla solo puede
## registrarse al cerrar tras haber leído deliberadamente las piezas requeridas.
class_name Publicaciones98
extends RefCounted

const CLAVE_LECTURAS := "publicaciones_98_lecturas"

const CATALOGO := [
	{
		"id": "revista_umbral_98",
		"titulo": "Umbral — nº 17",
		"categoria": "misterio",
		"procedencia": "quiosco",
		"comprable": true,
		"permite_casa": true,
		"semilla_onirica": "minotauro",
		"fuente_semilla": "publicacion:revista_umbral_98",
		"piezas_semilla": 2,
		"piezas":
		[
			{
				"id": "portada",
				"tipo": "portada",
				"titulo": "Los pasillos que vuelven al mismo sitio",
				"texto":
				"Una portada barata promete testimonios sobre edificios donde orientarse parece imposible.",
			},
			{
				"id": "dossier",
				"tipo": "articulo",
				"titulo": "El plano imposible",
				"texto":
				"Compara relatos contradictorios y dibuja un recorrido que se repliega sobre sí mismo.",
			},
			{
				"id": "cartas",
				"tipo": "correo_lectores",
				"titulo": "Cartas desde el sótano",
				"texto":
				"Tres lectores oyen ruidos tras los tabiques y recuerdan una puerta imposible.",
			},
		],
	},
	{
		"id": "libro_popol_wuj_98",
		"titulo": "Cuaderno cultural — Popol Wuj",
		"categoria": "cultura_kiche",
		"procedencia": "quiosco",
		"comprable": true,
		"permite_casa": true,
		"semilla_onirica": "popol_wuj",
		"fuente_semilla": "libro:popol_wuj_98",
		"piezas_semilla": 2,
		"piezas":
		[
			{
				"id": "portada",
				"tipo": "portada",
				"titulo": "Popol Wuj: relato k’iche’",
				"texto":
				"Un cuaderno presenta el Popol Wuj como relato k’iche’ y distingue otras tradiciones.",
			},
			{
				"id": "gemelos",
				"tipo": "articulo",
				"titulo": "Los Gemelos Héroes",
				"texto":
				"Una doble página resume a los Gemelos Héroes y su choque con los Señores del Inframundo.",
			},
			{
				"id": "correspondencias",
				"tipo": "comentario",
				"titulo": "Parejas y consecuencias",
				"texto":
				"El comentario invita a observar correspondencias sin convertir la cultura en un examen.",
			},
		],
	},
	{
		"id": "periodico_tarde_98",
		"titulo": "La Tarde Local",
		"categoria": "prensa_general",
		"procedencia": "quiosco",
		"comprable": true,
		"permite_casa": true,
		"piezas":
		[
			{
				"id": "portada",
				"tipo": "portada",
				"titulo": "Obras, lluvia y una tarde de tráfico lento",
				"texto":
				"La portada reúne obras, sucesos menores y una foto del centro bajo la lluvia.",
			},
			{
				"id": "local",
				"tipo": "noticia",
				"titulo": "El mercado ampliará su horario los viernes",
				"texto": "Vecinos y comerciantes discrepan sobre el nuevo horario del mercado.",
			},
			{
				"id": "agenda",
				"tipo": "agenda",
				"titulo": "Cineclub, mercadillo y charla de barrio",
				"texto": "La agenda reúne cineclub, mercadillo y una pequeña charla de barrio.",
			},
		],
	},
	{
		"id": "byte_domestico_42",
		"titulo": "Byte Doméstico — nº 42",
		"categoria": "informatica",
		"procedencia": "encontrable_casa",
		"comprable": false,
		"permite_casa": true,
		"piezas":
		[
			{
				"id": "portada",
				"tipo": "portada",
				"titulo": "Ordena tu disco antes de que sea tarde",
				"texto":
				"Una cubierta sobria promete mantenimiento, periféricos y redes domésticas.",
			},
			{
				"id": "tutorial",
				"tipo": "guia",
				"titulo": "Copias de seguridad sin misterio",
				"texto":
				"La guía separa documentos de programas y recomienda verificar cada copia.",
			},
		],
	},
	{
		"id": "marcador_98_deportes",
		"titulo": "Marcador 98 — jornada 9",
		"categoria": "deportes",
		"procedencia": "encontrable_trayecto",
		"comprable": false,
		"permite_casa": true,
		"piezas":
		[
			{
				"id": "cronica",
				"tipo": "cronica",
				"titulo": "Noventa minutos bajo el barro",
				"texto": "La crónica habla del barro, la grada y un partido sin nombres reales.",
			},
		],
	},
	{
		"id": "estratos_ciudad_06",
		"titulo": "Estratos y Ciudad — cuaderno 6",
		"categoria": "arqueologia_cultura",
		"procedencia": "encontrable_casa",
		"comprable": false,
		"permite_casa": true,
		"piezas":
		[
			{
				"id": "ensayo",
				"tipo": "ensayo",
				"titulo": "Cuando una calle tapa otra calle",
				"texto":
				"Un ensayo explica cómo las reformas dejan capas de memoria bajo la ciudad.",
			},
			{
				"id": "lamina",
				"tipo": "lamina",
				"titulo": "Sección de un patio excavado",
				"texto": "Una lámina separa relleno reciente, cimentación y un muro anterior.",
			},
		],
	},
	{
		"id": "manual_casa_98",
		"titulo": "Arreglos de casa para gente con prisa",
		"categoria": "guia_practica",
		"procedencia": "encontrable_casa",
		"comprable": false,
		"permite_casa": true,
		"piezas":
		[
			{
				"id": "indice",
				"tipo": "indice",
				"titulo": "Antes de tocar nada",
				"texto": "El índice aconseja cortar agua o corriente y no improvisar reparaciones.",
			},
		],
	},
]


static func catalogo() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for entrada in CATALOGO:
		salida.append(entrada.duplicate(true))
	return salida


static func por_id(item_id: String) -> Dictionary:
	for entrada in CATALOGO:
		if String(entrada.get("id", "")) == item_id:
			return entrada.duplicate(true)
	return {}


static func comprables() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	for entrada in CATALOGO:
		if bool(entrada.get("comprable", false)):
			salida.append(entrada.duplicate(true))
	return salida


## Adaptador económico: no conoce precios ni toca dinero directamente.
static func comprar(jornada: Dictionary, inventario: Dictionary, item_id: String) -> Dictionary:
	var entrada := por_id(item_id)
	if entrada.is_empty() or not bool(entrada.get("comprable", false)):
		return {"ok": false, "id": item_id, "motivo": "no_comprable"}
	return ComercioBarrio.comprar(jornada, inventario, "quiosco", item_id)


## Devuelve una pieza y deja constancia persistente de que fue vista. Abrir una
## publicación o repetir la misma página no crea progreso artificial.
static func hojear(jornada: Dictionary, item_id: String, pieza_id: String) -> Dictionary:
	var entrada := por_id(item_id)
	if entrada.is_empty():
		return {"ok": false, "id": item_id, "motivo": "publicacion_desconocida"}
	var pieza := _buscar_pieza(entrada, pieza_id)
	if pieza.is_empty():
		return {"ok": false, "id": item_id, "motivo": "pieza_desconocida"}

	var estado := _estado_mutable(jornada, item_id)
	var vistas: Array = estado["piezas_vistas"]
	var nueva := not vistas.has(pieza_id)
	if nueva:
		vistas.append(pieza_id)
	estado["ultima_pieza"] = pieza_id
	return {
		"ok": true,
		"id": item_id,
		"pieza": pieza.duplicate(true),
		"nueva": nueva,
		"vistas": vistas.size(),
	}


static func contenido_visto(jornada: Dictionary, item_id: String) -> Array[String]:
	var lecturas := _lecturas(jornada)
	var bruto = lecturas.get(item_id, {})
	if typeof(bruto) != TYPE_DICTIONARY:
		return []
	var vistas_crudas = bruto.get("piezas_vistas", [])
	if typeof(vistas_crudas) != TYPE_ARRAY:
		return []
	var salida: Array[String] = []
	for valor in vistas_crudas:
		var pieza_id := String(valor)
		if not pieza_id.is_empty() and not salida.has(pieza_id):
			salida.append(pieza_id)
	return salida


static func puede_sembrar(jornada: Dictionary, item_id: String) -> bool:
	var entrada := por_id(item_id)
	if entrada.is_empty():
		return false
	var id_mito := String(entrada.get("semilla_onirica", ""))
	var fuente := String(entrada.get("fuente_semilla", ""))
	if id_mito.is_empty() or fuente.is_empty():
		return false
	var minimo := maxi(1, int(entrada.get("piezas_semilla", 1)))
	return contenido_visto(jornada, item_id).size() >= minimo


## Gesto deliberado final. Leer páginas puede preparar una semilla, pero no la
## activa hasta cerrar la publicación tras la lectura requerida.
static func cerrar_tras_lectura(jornada: Dictionary, item_id: String) -> Dictionary:
	var entrada := por_id(item_id)
	if entrada.is_empty():
		return {"ok": false, "id": item_id, "motivo": "publicacion_desconocida"}
	var id_mito := String(entrada.get("semilla_onirica", ""))
	var fuente := String(entrada.get("fuente_semilla", ""))
	if id_mito.is_empty() or fuente.is_empty():
		return {"ok": true, "id": item_id, "semilla_activada": false, "motivo": "sin_semilla"}
	if not puede_sembrar(jornada, item_id):
		return {
			"ok": true,
			"id": item_id,
			"semilla_activada": false,
			"motivo": "lectura_insuficiente",
		}

	var activada := SemillasOniricas.activar_semilla_onirica(jornada, id_mito, fuente, 1)
	return {
		"ok": activada,
		"id": item_id,
		"semilla_activada": activada,
		"id_semilla": id_mito,
		"fuente": fuente,
	}


static func _buscar_pieza(entrada: Dictionary, pieza_id: String) -> Dictionary:
	var piezas = entrada.get("piezas", [])
	if typeof(piezas) != TYPE_ARRAY:
		return {}
	for pieza in piezas:
		if typeof(pieza) == TYPE_DICTIONARY and String(pieza.get("id", "")) == pieza_id:
			return pieza
	return {}


static func _lecturas(jornada: Dictionary) -> Dictionary:
	if not jornada.has(CLAVE_LECTURAS) or typeof(jornada.get(CLAVE_LECTURAS)) != TYPE_DICTIONARY:
		jornada[CLAVE_LECTURAS] = {}
	return jornada[CLAVE_LECTURAS]


static func _estado_mutable(jornada: Dictionary, item_id: String) -> Dictionary:
	var lecturas := _lecturas(jornada)
	var crudo = lecturas.get(item_id, {})
	if typeof(crudo) != TYPE_DICTIONARY:
		crudo = {}
	var estado: Dictionary = crudo
	if typeof(estado.get("piezas_vistas", [])) != TYPE_ARRAY:
		estado["piezas_vistas"] = []
	if not estado.has("piezas_vistas"):
		estado["piezas_vistas"] = []
	lecturas[item_id] = estado
	return estado
