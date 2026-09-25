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
				"Un bloque de viviendas ocupa la portada bajo un titular enorme. La revista promete testimonios sobre corredores que parecen cambiar de longitud, puertas que reaparecen y vecinos que ya no se fían de sus propios planos.",
			},
			{
				"id": "dossier",
				"tipo": "articulo",
				"titulo": "El plano imposible",
				"texto":
				"El redactor superpone cuatro croquis enviados por lectores. Ninguno coincide del todo, pero tres repiten el mismo detalle: después del cuarto giro siempre aparece una puerta sin número. El artículo admite que no pudo verificar los relatos, aunque imprime el recorrido como si fuera una prueba.",
			},
			{
				"id": "croquis",
				"tipo": "lamina",
				"titulo": "Siete giros y una puerta",
				"texto":
				"Una página central muestra un dibujo deliberadamente confuso: rellanos, flechas, escaleras y un patio interior. En el margen alguien ha anotado a bolígrafo: «si vuelves al ascensor, no has salido; has empezado otra vez».",
			},
			{
				"id": "cartas",
				"tipo": "correo_lectores",
				"titulo": "Cartas desde el sótano",
				"texto":
				"Tres lectores describen golpes detrás de tabiques, una bombilla que siempre está encendida y una puerta que juraban no haber visto antes. La propia revista remata la sección con una nota pequeña: «relatos no comprobados; no derribe paredes por su cuenta».",
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
				"El cuaderno presenta el Popol Wuj como un relato de tradición k’iche’ y avisa desde la primera página de que no debe usarse «maya» como etiqueta intercambiable para pueblos, épocas y tradiciones distintas.",
			},
			{
				"id": "gemelos",
				"tipo": "articulo",
				"titulo": "Los Gemelos Héroes",
				"texto":
				"Una doble página resume el ciclo de los Gemelos Héroes y su confrontación con los Señores del Inframundo. El texto insiste menos en memorizar nombres que en observar cómo la pareja responde a pruebas mediante atención, correspondencia y astucia.",
			},
			{
				"id": "ecos",
				"tipo": "comentario",
				"titulo": "Parejas, ecos y consecuencias",
				"texto":
				"El comentario editorial propone una lectura sencilla: dos acciones separadas pueden reflejarse entre sí sin ser idénticas. El cuaderno lo ilustra con dos columnas de ejemplos cotidianos y evita convertir la tradición en un cuestionario.",
			},
			{
				"id": "contexto",
				"tipo": "nota",
				"titulo": "Una nota antes de seguir",
				"texto":
				"La nota final recuerda que el cuaderno es una introducción y no una reconstrucción histórica, religiosa o visual de Xibalbá. Recomienda distinguir fuentes, contexto y traducciones antes de sacar conclusiones generales.",
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
				"La portada reúne tres asuntos que compiten por espacio: obras en una avenida, una tarde de lluvia persistente y retenciones junto al mercado. La foto principal muestra paraguas, vallas y faros reflejados en el asfalto.",
			},
			{
				"id": "local",
				"tipo": "noticia",
				"titulo": "El mercado ampliará su horario los viernes",
				"texto":
				"Vecinos y comerciantes discrepan sobre el nuevo horario. Los tenderos esperan más ventas al final del día; quienes viven encima piden que la carga y descarga termine antes de la noche. El ayuntamiento probará el cambio durante un mes.",
			},
			{
				"id": "sucesos",
				"tipo": "breves",
				"titulo": "Tres breves de última hora",
				"texto":
				"Un autobús quedó detenido por una avería sin heridos, apareció una bicicleta encadenada desde hace semanas en la plaza y la policía local devolvió una cartera encontrada en un portal. Ninguna historia ocupa más de seis líneas.",
			},
			{
				"id": "agenda",
				"tipo": "agenda",
				"titulo": "Cineclub, mercadillo y charla de barrio",
				"texto":
				"La agenda anuncia una proyección en 16 mm, un mercadillo de segunda mano y una charla sobre la historia del barrio. Al pie hay horarios de biblioteca, farmacia de guardia y dos teléfonos útiles escritos con tipografía diminuta.",
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
				"Una cubierta sobria promete mantenimiento, periféricos, módems y redes domésticas. En una esquina, un reclamo asegura que organizar carpetas «también ahorra discusiones cuando el ordenador es de toda la casa».",
			},
			{
				"id": "tutorial",
				"tipo": "guia",
				"titulo": "Copias de seguridad sin misterio",
				"texto":
				"La guía separa documentos de programas, recomienda copiar primero lo irremplazable y verificar después la copia abriendo varios archivos al azar. También advierte que guardar todo en el mismo disco no es una copia de seguridad.",
			},
			{
				"id": "modem",
				"tipo": "articulo",
				"titulo": "Cuando la línea comunica",
				"texto":
				"Un artículo de dos columnas explica por qué una conexión por módem ocupa la línea telefónica y propone acordar horarios en casas compartidas. El autor admite que la mejor solución técnica sigue siendo, a veces, avisar antes de conectarse.",
			},
			{
				"id": "consultorio",
				"tipo": "consultorio",
				"titulo": "El lector pregunta: «¿por qué va más lento?»",
				"texto":
				"El consultorio descarta una causa única: poco espacio libre, demasiados programas al inicio y discos desordenados pueden parecer el mismo problema. La respuesta termina con una recomendación poco espectacular: cambiar una cosa cada vez y anotar qué mejora.",
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
				"id": "portada",
				"tipo": "portada",
				"titulo": "Jornada embarrada",
				"texto":
				"La portada dedica casi todo el espacio a una fotografía de botas cubiertas de barro y una grada bajo paraguas. Los resultados aparecen en una columna lateral, sin clubes ni marcas reales.",
			},
			{
				"id": "cronica",
				"tipo": "cronica",
				"titulo": "Noventa minutos bajo el barro",
				"texto":
				"La crónica describe un partido trabado, con pases cortos, balones que se frenan en charcos y dos ocasiones claras en toda la segunda parte. El público celebra más una carrera imposible por la banda que el empate final.",
			},
			{
				"id": "tactica",
				"tipo": "analisis",
				"titulo": "Cinco metros que cambiaron el partido",
				"texto":
				"Un diagrama sencillo compara dos dibujos defensivos. La pieza sostiene que adelantar una línea apenas cinco metros obligó al rival a jugar de espaldas y convirtió una tarde caótica en un partido algo más controlable.",
			},
			{
				"id": "vestuario",
				"tipo": "breves",
				"titulo": "Del vestuario al autobús",
				"texto":
				"Una columna de breves habla de botas secándose sobre radiadores, bocadillos repartidos tarde y un portero suplente que terminó ayudando a empujar el autobús fuera de un aparcamiento embarrado.",
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
				"id": "portada",
				"tipo": "portada",
				"titulo": "La ciudad debajo de la ciudad",
				"texto":
				"La cubierta reproduce un dibujo técnico ficticio de una calle cortada en sección: asfalto, tuberías, cimentaciones y muros de épocas distintas aparecen como capas superpuestas.",
			},
			{
				"id": "ensayo",
				"tipo": "ensayo",
				"titulo": "Cuando una calle tapa otra calle",
				"texto":
				"El ensayo explica que una reforma rara vez borra por completo lo anterior. Cambian cotas, usos y fachadas, pero sobreviven medianeras, trazas de cimentación y decisiones urbanas que todavía condicionan por dónde se puede abrir una zanja.",
			},
			{
				"id": "lamina",
				"tipo": "lamina",
				"titulo": "Sección de un patio excavado",
				"texto":
				"Una lámina separa relleno reciente, cimentación moderna, un suelo anterior y un muro más antiguo. Las notas insisten en no interpretar una capa aislada sin mirar qué corta, qué cubre y con qué se relaciona.",
			},
			{
				"id": "diario_campo",
				"tipo": "nota_campo",
				"titulo": "Martes, 17:40 — aparece otra pared",
				"texto":
				"Una nota de campo ficticia cuenta que el equipo esperaba encontrar una canalización y encontró un muro. La anotación no celebra un «tesoro»: pide fotografiar, medir, revisar planos viejos y retrasar cualquier conclusión hasta comparar el conjunto.",
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
				"id": "portada",
				"tipo": "portada",
				"titulo": "Treinta arreglos que empiezan por no empeorarlo",
				"texto":
				"La portada promete soluciones rápidas, pero el subtítulo rebaja expectativas: «saber cuándo parar también cuenta como reparación».",
			},
			{
				"id": "indice",
				"tipo": "indice",
				"titulo": "Antes de tocar nada",
				"texto":
				"El índice aconseja cortar agua o corriente cuando proceda, despejar la zona, guardar tornillos en un recipiente y hacer una foto antes de desmontar algo que luego haya que recordar cómo estaba.",
			},
			{
				"id": "grifo",
				"tipo": "guia",
				"titulo": "El grifo que gotea a las tres de la mañana",
				"texto":
				"La guía propone empezar por lo básico: cerrar el paso, comprobar de dónde sale realmente el agua y no forzar piezas agarrotadas. Si hay que aplicar mucha fuerza, el manual recomienda parar antes de convertir una fuga pequeña en una avería grande.",
			},
			{
				"id": "enchufe",
				"tipo": "advertencia",
				"titulo": "Electricidad: aquí se acaba el bricolaje",
				"texto":
				"Una página enmarcada recuerda que un aparato desenchufado no convierte toda una instalación en segura y desaconseja intervenir en cuadros, cableado empotrado o averías cuyo origen no se entienda. «Llamar a un profesional también es terminar el trabajo».",
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
