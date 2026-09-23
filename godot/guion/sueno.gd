## La noche: qué se sueña y qué queda de ello.
##
## Tres cosas y ninguna más (#86): elegir las TRES escenas de esta noche,
## encadenarlas, y hacer crecer el mapa con lo que se va viendo. Lo que hay
## DENTRO de cada escena es #87, y de dónde se sale es #90 — aquí la salida es
## la celda más lejos de la entrada porque eso ya se puede calcular, no porque
## esté decidido cómo se busca.
##
## **El sueño no es aleatorio: es el archivo devuelto deforme** (#79). Aquí eso
## se cumple de la única forma que este issue puede cumplirlo todavía: la
## semilla sale de lo LEÍDO ese día, así que dos días distintos sueñan distinto
## y el mismo día repetido sueña lo mismo. Un sueño que cambiara al recargar la
## partida sería un generador de ruido con otro nombre.
##
## **El mapa vive en la vuelta y no en la memoria de por vida** (decidido en
## #86): cada vida laboral sueña lo suyo. No hace falta borrarlo en ningún
## sitio — está en `Jornada.nueva()`, que es lo que el despido vuelve a poner.
class_name Sueno
extends RefCounted

## Cuántas escenas tiene una noche NORMAL. Ni una sala grande ni un recorrido
## largo: tres. #210 permite que otra variante pida menos sin cambiar este
## valor ni duplicar la selección; la noche corriente sigue usando tres.
const ESCENAS_POR_NOCHE := 3

## Cómo se ve un sospechoso, y cómo se ve el que firmaste. La diferencia es
## todo lo que hace falta: aparecen todos los del expediente que tocaste, pero
## haberle puesto el nombre a uno se nota (#87). Y es el mismo que se deja
## pelear (#88): lo que se ve distinto es lo que se puede tocar.
const COLOR_FIGURA := Color(0.30, 0.28, 0.34)
const COLOR_ACUSADO := Color(0.46, 0.20, 0.20)
const COLOR_TEXTO := Color(0.78, 0.77, 0.80)
const COLOR_ACUSADO_TEXTO := Color(0.86, 0.62, 0.58)

## La salida sigue sin marca ni volumen visible (#90), pero el playtest #9
## demostró que una zona completamente muda se lee como bloqueo. Este resplandor
## no dice "salida" ni se ve desde toda la sala: solo altera el ambiente cuando
## el jugador ya está cerca, suficiente para que buscar tenga feedback y no sea
## rozar paredes a ciegas.
const COLOR_PISTA_SALIDA := Color(0.48, 0.58, 0.74)
const ENERGIA_PISTA_SALIDA := 1.15
const ALCANCE_PISTA_SALIDA := 4.2

## Lo que se separa un cartel de su muro. Tiene que ser MAYOR que medio grosor
## de muro, y ese es el número que importa: un muro es una caja centrada en la
## línea de la planta, así que separarse seis centímetros de la línea deja el
## texto DENTRO de la pared y no se ve nada. No es un parpadeo que se note al
## pasar: la frase sencillamente no está. Hay prueba que lo exige.
const SEPARACION_PARED := 0.2

## A cuántas celdas de la entrada se planta la primera figura. Lo bastante
## lejos para que no te la encuentres encima, lo bastante cerca para verla al
## llegar.
const PASOS_PRIMERA_FIGURA := 5

## Cuántas veces el camino directo se da por bueno para encontrar la salida.
##
## La salida NO se ve (#90), así que el tiempo no puede ser el que cuesta ir a
## ella: es el que cuesta BUSCARLA, que es andar la sala varias veces. Tres y
## media es lo que hay entre cruzar una nave y haberla recorrido entera un par
## de veces con vueltas.
const MARGEN_DE_BUSQUEDA := 3.5

## Lo que anda el caminante, en metros por segundo. Copiado a propósito de
## `caminante.gd` y no importado: esto es lógica pura y no debe depender de un
## nodo de escena. Hay prueba de que los dos números siguen siendo el mismo.
const VELOCIDAD := 2.6


## Cuántos segundos dura una noche.
##
## Sale de la GEOMETRÍA de las salas que toquen esa noche, no de un número
## escrito a mano: una nave de cuarenta metros y un pasillo de diez no se
## buscan en el mismo tiempo, y con una constante única una de las dos estaría
## mal siempre.
static func segundos_de_noche(escenas: Array) -> float:
	var total := 0.0
	for id in escenas:
		var forma := SuenoFormas.de(id)
		var medida := Planta.distancias_desde(forma["bloques"], forma["entrada"])
		total += float(medida["pasos"]) * Planta.CELDA / VELOCIDAD * MARGEN_DE_BUSQUEDA
	return total


## La semilla de esta noche: el día y lo que se leyó en él.
##
## El día entra para que dos noches con la misma lectura no sean la misma
## noche; lo leído entra para que la noche sea de su día. Sin lo leído, el
## sueño sería una función del calendario.
## [param raiz] es la semilla de la partida (#147): entra para que dos partidas
## distintas con el mismo día y la misma lectura no sueñen lo mismo. Sin ella
## el sueño sería una función del contenido y no de quien lo soñó.
static func semilla(
	dia: int, leido_hoy: Array, raiz: int = 0, seleccion_nocturna: Array = []
) -> int:
	var texto := str(dia)
	var folios := leido_hoy.duplicate()
	folios.sort()
	for folio in folios:
		texto += "|" + str(folio)
	# La lectura diaria se ordena porque es un conjunto de hechos; la memoria
	# nocturna NO: orden y repetición son decisiones de #162 y deben producir
	# una noche reproducible distinta sin introducir documentos nuevos.
	for folio in seleccion_nocturna:
		texto += "|memoria:" + str(folio)
	# Por Azar y no por `hash()`: `hash()` puede cambiar de una versión de
	# Godot a otra, y una noche que cambia al actualizar el motor no se puede
	# volver a ver cuando alguien informa de que salió rara.
	return Azar.derivar_texto(raiz, "sueno", texto, [dia])


## Las escenas de esta noche, en orden.
##
## Por defecto conserva la regla de #86: tres escenas y lo NUEVO primero.
## `opciones` existe para que #84 pueda pedir una variante degradada sin copiar
## este algoritmo ni decidir aquí cuál será esa política. Dos claves bastan:
##
## - `cantidad`: cuántas escenas pedir; se limita de 0 al catálogo disponible.
## - `priorizar_vistas`: si es `true`, las salas ya conocidas van antes.
##
## La semilla y el barajado no cambian: misma entrada + misma política produce
## siempre el mismo itinerario, también al recargar.
static func noche(
	dia: int, leido_hoy: Array, mapa: Array, raiz: int = 0, opciones: Dictionary = {}
) -> Array:
	var seleccion_nocturna: Array = opciones.get("seleccion_nocturna", [])
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla(dia, leido_hoy, raiz, seleccion_nocturna)

	var nuevas := SuenoFormas.ids().filter(func(id): return not mapa.has(id))
	var vistas := SuenoFormas.ids().filter(func(id): return mapa.has(id))
	_barajar(nuevas, rng)
	_barajar(vistas, rng)

	var priorizar_vistas := bool(opciones.get("priorizar_vistas", false))
	var escenas := vistas + nuevas if priorizar_vistas else nuevas + vistas
	var cantidad := clampi(int(opciones.get("cantidad", ESCENAS_POR_NOCHE)), 0, escenas.size())
	return escenas.slice(0, cantidad)


## Anota una sala en el mapa. El mapa es lo que se ha visto, así que una sala
## repetida no se apunta dos veces: crecer es conocer sitios, no acumular
## noches.
static func recordar(mapa: Array, id: String) -> bool:
	if mapa.has(id):
		return false
	mapa.append(id)
	return true


## El espacio de una escena, listo para `Espacio3D`.
##
## [param quedan] es cuántas escenas faltan DESPUÉS de esta. La última lleva a
## despertar y las demás a la siguiente: el sueño se sale por donde se acaba,
## no por una tecla.
static func espacio(id: String, quedan: int, contenido: Dictionary = {}) -> Dictionary:
	var forma := SuenoFormas.de(id)
	var bloques: Array = forma["bloques"]
	var entrada: Vector2i = forma["entrada"]
	var familia_id := String(forma.get("familia_poligonal", ""))
	var familia := SuenoFamilias.de(familia_id) if not familia_id.is_empty() else {}
	var es_poligonal := not familia.is_empty()
	var salida := Planta.mas_lejana(bloques, entrada)
	var posicion_entrada := (
		Vector3(familia["entrada"]) if es_poligonal else Planta.centro_en_metros(bloques, entrada)
	)
	# Mantiene el contrato histórico de #90 para las salas de `Planta`; una
	# familia poligonal sustituye después esa base sin cambiar cómo se derivan
	# la zona de salida ni su pista ambiental.
	var posicion_salida := Planta.centro_en_metros(bloques, salida)
	if es_poligonal:
		posicion_salida = _salida_poligonal(familia)
	var base_salida := posicion_salida
	posicion_salida += Vector3(0, 1.1, 0)

	# Las figuras se reparten por la sala, lejos entre sí y lejos de por donde
	# se entra y se sale: un sospechoso plantado en la puerta se ve antes de
	# haber entrado, y lo que hace el sueño es que te los encuentres.
	var figuras := []
	var quienes: Array = contenido.get("figuras", [])
	var celdas := []
	var sitios_poligonales := _sitios_poligonales(familia, base_salida) if es_poligonal else []
	if not es_poligonal and not quienes.is_empty():
		# La primera, DELANTE: al llegar hay alguien. Las demás repartidas por
		# la sala. Todas lejos es lo mismo que ninguna en una nave de cuarenta
		# metros — se llega, no se ve nada, y el sueño parece vacío.
		celdas.append(Planta.a_la_vista(bloques, entrada, PASOS_PRIMERA_FIGURA))
		celdas.append_array(
			Planta.repartidas(bloques, quienes.size() - 1, [entrada, salida, celdas[0]])
		)
	for i in quienes.size():
		var quien: Dictionary = quienes[i]
		var posicion_figura := (
			Vector3(sitios_poligonales[i % sitios_poligonales.size()])
			if es_poligonal
			else Planta.centro_en_metros(bloques, celdas[i])
		)
		(
			figuras
			. append(
				{
					"pos": posicion_figura,
					"color": COLOR_ACUSADO if quien.get("acusado", false) else COLOR_FIGURA,
					"rotulo": quien.get("nombre", ""),
					"color_rotulo":
					# Con el que firmaste se pelea (#88). Va como un dato de la figura
					# —su id— y no como una bandera: quien lo pise tiene que saber
					COLOR_ACUSADO_TEXTO if quien.get("acusado", false) else COLOR_TEXTO,
					# CONTRA QUIÉN, porque ganar se apunta por persona.
					"duelo": quien.get("id", "") if quien.get("acusado", false) else "",
					"ataques": quien.get("ataques", []),
				}
			)
		)

	# Las frases van a los paños más anchos, y solo caben las que caben: un
	# muro por frase. Lo que sobra no se apila en el mismo sitio — se queda
	# fuera, que es lo que hace que una pared diga UNA cosa.
	var frases: Array = contenido.get("frases", [])
	var carteles := _carteles_poligonales(familia, frases) if es_poligonal else []
	if not es_poligonal:
		var paredes := Planta.paredes(bloques)
		for i in mini(frases.size(), paredes.size()):
			var sitio := Planta.en_pared(bloques, paredes[i], SEPARACION_PARED)
			(
				carteles
				. append(
					{
						"texto": frases[i],
						"pos": sitio["pos"],
						"giro": sitio["giro"],
						"color": COLOR_TEXTO,
					}
				)
			)

	# Conserva las luces propias de cada forma y añade una señal local al final
	# del recorrido. No lleva carcasa: en el sueño puede haber una luz sin
	# lámpara, y precisamente así evita convertirse en una puerta/waypoint.
	var luces: Array = forma.get("luces", []).duplicate(true)
	(
		luces
		. append(
			{
				"pos": posicion_salida + Vector3(0, 0.8, 0),
				"color": COLOR_PISTA_SALIDA,
				"energia": ENERGIA_PISTA_SALIDA,
				"alcance": ALCANCE_PISTA_SALIDA,
				"carcasa": false,
			}
		)
	)

	var resultado := {
		"rotulo": forma["rotulo"],
		# La planta se conserva incluso en la primera familia poligonal: sigue
		# siendo el contrato de timing/mapa y permite comparar el corte nuevo con
		# el recorrido anterior. `Espacio3D` prioriza `contorno` cuando existe.
		"planta": bloques,
		"color_suelo": forma["color_suelo"],
		"color_muro": forma["color_muro"],
		"color_techo": forma["color_techo"],
		"textura_suelo": forma.get("textura_suelo", ""),
		"textura_muro": forma.get("textura_muro", ""),
		"escala_textura": forma.get("escala_textura", 1.2),
		"deformacion_textura": forma.get("deformacion_textura", Vector3.ONE),
		"contraste_textura": forma.get("contraste_textura", 1.0),
		"preservar_detalle_textura": forma.get("preservar_detalle_textura", false),
		"ambiente": forma.get("ambiente", Color(0.20, 0.19, 0.24)),
		"ambiente_energia": forma.get("ambiente_energia", 0.32),
		"sol": forma.get("sol", 0.05),
		"luces": luces,
		"entrada": posicion_entrada,
		"figuras": figuras,
		"carteles": carteles,
		"salidas":
		[
			{
				"pos": posicion_salida,
				"destino": "sueño" if quedan > 0 else "archivo",
				"rotulo": "SALIDA_DESPERTAR" if quedan == 0 else "SUENO_ROTULO",
				# No se ve (#90): hay que dar con ella. El resplandor cercano da
				# feedback ambiental, pero la zona sigue sin geometría ni marca.
				"visible": false,
				# Y por eso es más ancha que una puerta: buscar a ciegas un cuadro
				# de metro y medio en una nave de cuarenta es otro juego, y no uno
				# mejor.
				"tam": Vector3(3.2, 2.4, 3.2),
			}
		],
	}
	if es_poligonal:
		resultado["contorno"] = familia["contorno"]
		resultado["altura_contorno"] = float(familia.get("altura", 3.2))
		# Las familias pueden declarar planos internos además del perímetro. Se
		# propagan desde el contrato genérico para que cualquier forma que adopte
		# FRAGMENTADA obtenga la misma geometría visible y física, sin adaptadores.
		resultado["tabiques_poligonales"] = familia.get("tabiques", []).duplicate(true)

	# #284: la forma decide si tiene una identidad onírica fuerte. `Sueno`
	# termina primero el contrato espacial genérico y solo después delega la
	# presentación, de modo que visual y colisión siguen naciendo del mismo
	# contorno poligonal de #451. El contenido conocido se pasa sin modificar.
	var identidad_onirica := String(forma.get("identidad_onirica", ""))
	if identidad_onirica == SuenoCastillo.ID:
		var estado_presentacion: Dictionary = forma.get("estado_presentacion", {}).duplicate(true)
		estado_presentacion.merge(contenido.get("estado_presentacion", {}), true)
		resultado = SuenoCastillo.adaptar_espacio(resultado, estado_presentacion, contenido)
	return resultado


## Una familia poligonal no puede heredar las coordenadas de una planta de
## celdas: hacerlo sería volver al fallo que #448 evita, con objetos y triggers
## al otro lado de una pared visible. La salida usa el ancla más alejada de la
## entrada declarada por la familia.
static func _salida_poligonal(familia: Dictionary) -> Vector3:
	var entrada: Vector3 = familia.get("entrada", Vector3.ZERO)
	var mejor := entrada
	var distancia := -1.0
	for dato in familia.get("anclas", []):
		var ancla: Vector3 = dato
		var candidata := entrada.distance_squared_to(ancla)
		if candidata > distancia:
			distancia = candidata
			mejor = ancla
	return mejor


## Sitios seguros para figuras: primero un punto de llegada legible, después las
## anclas del catálogo y finalmente puntos interiores derivados del contorno.
## No se escriben coordenadas especiales para `embudo`: cualquier forma que
## declare una familia poligonal entra por el mismo contrato.
static func _sitios_poligonales(familia: Dictionary, salida: Vector3) -> Array:
	var contorno: PackedVector2Array = familia.get("contorno", PackedVector2Array())
	var entrada: Vector3 = familia.get("entrada", Vector3.ZERO)
	var centro := _centro_contorno(contorno)
	var sitios := []
	var entrada_2d := Vector2(entrada.x, entrada.z)
	var cerca := entrada_2d.lerp(centro, 0.38)
	sitios.append(Vector3(cerca.x, 0, cerca.y))

	for dato in familia.get("anclas", []):
		var ancla: Vector3 = dato
		if ancla.distance_to(salida) > 2.5 and ancla.distance_to(entrada) > 2.5:
			sitios.append(ancla)

	for punto in contorno:
		var interior := centro.lerp(punto, 0.42)
		var sitio := Vector3(interior.x, 0, interior.y)
		if sitio.distance_to(salida) > 2.5 and sitio.distance_to(entrada) > 2.5:
			sitios.append(sitio)

	if sitios.is_empty():
		sitios.append(Vector3(centro.x, 0, centro.y))
	return sitios


## Las frases siguen perteneciendo a paredes. En un polígono las paredes son
## sus aristas: se priorizan las largas, se coloca el texto un poco hacia el
## centro y se orienta su frente hacia el interior.
static func _carteles_poligonales(familia: Dictionary, frases: Array) -> Array:
	var contorno: PackedVector2Array = familia.get("contorno", PackedVector2Array())
	if contorno.size() < 2 or frases.is_empty():
		return []
	var centro := _centro_contorno(contorno)
	var paredes := []
	for i in contorno.size():
		var a := contorno[i]
		var b := contorno[(i + 1) % contorno.size()]
		paredes.append({"a": a, "b": b, "largo": a.distance_squared_to(b)})
	paredes.sort_custom(func(a, b): return a["largo"] > b["largo"])

	var carteles := []
	for i in mini(frases.size(), paredes.size()):
		var pared: Dictionary = paredes[i]
		var a: Vector2 = pared["a"]
		var b: Vector2 = pared["b"]
		var medio := (a + b) / 2.0
		var hacia_dentro := centro - medio
		if not is_zero_approx(hacia_dentro.length()):
			hacia_dentro = hacia_dentro.normalized()
		var posicion := medio + hacia_dentro * SEPARACION_PARED
		(
			carteles
			. append(
				{
					"texto": frases[i],
					"pos": Vector3(posicion.x, 0, posicion.y),
					"giro": atan2(hacia_dentro.x, hacia_dentro.y),
					"color": COLOR_TEXTO,
				}
			)
		)
	return carteles


static func _centro_contorno(contorno: PackedVector2Array) -> Vector2:
	if contorno.is_empty():
		return Vector2.ZERO
	var centro := Vector2.ZERO
	for punto in contorno:
		centro += punto
	return centro / float(contorno.size())


## Lo que queda de noche, dicho sin un número.
##
## Un reloj con cifras dentro de un sueño es una interfaz de videojuego en la
## parte del juego que menos tiene que parecerlo. Pero algo tiene que haber: un
## límite del que no avisa nada se lee como que el programa te ha echado.
static func senal_de_noche(restante: float) -> String:
	if restante > 0.66:
		return "·  ·  ·"
	if restante > 0.33:
		return "·  ·"
	return "·"


static func _barajar(lista: Array, rng: RandomNumberGenerator) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var guardado = lista[i]
		lista[i] = lista[j]
		lista[j] = guardado
