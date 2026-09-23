## Construye un espacio andable a partir de su declaración.
##
## Un espacio es DATOS: suelo, muros, bultos y salidas. Este módulo los
## convierte en malla y colisión, y no conoce el nombre de ninguna sala — igual
## que `Marcas` no sabe pintar y `Combate` no sabe de pantallas. Añadir la
## oficina, la calle o la casa es una entrada más del catálogo; si para meter un
## sitio hiciera falta un `if` con su nombre aquí dentro, el diseño se ha roto.
##
## La geometría es deliberadamente pobre: cajas y planos, con la paleta de
## SIGA-98. No es un placeholder a la espera de arte — es el mismo argumento que
## la tipografía sin suavizar, que una oficina de 1998 se parece más a esto que
## a un render.
class_name Espacio3D
extends RefCounted

const ALTURA_MURO := 2.8
const GROSOR_MURO := 0.2

## Todo lo que se construye aquí se pinta con el mismo shader: el temblor de
## vértices y el color cortado no son un efecto de algunas superficies, son cómo
## dibuja esta máquina. Un solo material significa además que el día que haya
## que tocarlo se toca una vez.
const SHADER_PSX := "res://arte/psx.gdshader"

## La misma imagen con la luz por píxel. La pide el sitio que necesita sombras
## proyectadas —la oficina de #789—, porque la luz por vértice del shader
## canónico no las aplica: con `vertex_lighting` las sombras de #1121 se
## calculaban y el material las tiraba.
const SHADER_PSX_LUZ_PIXEL := "res://arte/psx_luz_pixel.gdshader"

## Cuánto se pinta a sí misma una superficie que se declara encendida.
const EMISION_PLENA := 0.9

## Nombre de las lámparas generales de un sitio. Godot le añade sufijo a los
## repetidos, así que se reconocen por prefijo.
const NOMBRE_LUZ_SALA := "LuzDeSala"

## Las ventanas y la luz que entra por ellas, con nombre por el mismo motivo: la
## hora la sabe `Jornada`, no este módulo, así que quien la lee tiene que poder
## encontrarlas para decidir de qué color es fuera y si entra sol (#789).
const NOMBRE_CRISTAL_VENTANA := "CristalVentana"
const NOMBRE_LUZ_VENTANA := "LuzDeVentana"

## Cada cuántos metros se pone un vértice de más. Es el mando que decide si una
## lámpara da un charco de luz o tiñe la pared entera.
const METROS_POR_VERTICE := 1.4
const TOPE_SUBDIVISION := 14

## A qué altura se escribe en una pared: a la de los ojos, que es donde se lee
## sin levantar la cabeza.
const ALTURA_CARTEL := 1.7

## Con qué se pinta el sitio que se está construyendo. Lo fija `construir()` al
## empezar, que es el único camino de entrada del módulo, y vale hasta que el
## siguiente sitio vuelva a fijarlo: entrar en la calle devuelve el canónico sin
## que la calle tenga que saber que la oficina pidió otra cosa.
static var _shader_del_sitio := SHADER_PSX


## Monta el espacio bajo [param raiz] y devuelve las salidas creadas, para que
## quien orquesta el día pueda escucharlas.
static func construir(raiz: Node3D, espacio: Dictionary) -> Array:
	# Lo primero, antes de crear una sola malla: todo lo que se monte debajo se
	# pinta con el shader que este sitio haya pedido.
	_shader_del_sitio = (
		SHADER_PSX_LUZ_PIXEL if espacio.get("luz_por_pixel", false) else SHADER_PSX
	)
	var color_suelo: Color = espacio.get("color_suelo", Color(0.35, 0.34, 0.32))
	var color_techo: Color = espacio.get("color_techo", Color(0.28, 0.28, 0.27))
	var color_muro: Color = espacio.get("color_muro", Color(0.55, 0.54, 0.5))
	var deformacion_textura: Vector3 = espacio.get("deformacion_textura", Vector3.ONE)
	var contraste_textura := float(espacio.get("contraste_textura", 1.0))
	var preservar_detalle_textura := bool(espacio.get("preservar_detalle_textura", false))

	# Tres formas de declarar un sitio. `contorno` es la generalización 3D no
	# ortogonal; `planta` conserva celdas arbitrarias y `suelo`, el rectángulo.
	# Ninguna ruta conoce el nombre del sitio que está construyendo.
	if espacio.has("contorno"):
		_por_contorno(
			raiz,
			espacio["contorno"],
			float(espacio.get("altura_contorno", ALTURA_MURO)),
			color_muro,
			espacio.get("textura_muro", ""),
			espacio.get("escala_textura", 1.2),
			deformacion_textura,
			contraste_textura,
			preservar_detalle_textura,
			espacio.get("tabiques_poligonales", [])
		)
	elif espacio.has("planta"):
		_por_planta(
			raiz,
			espacio["planta"],
			color_suelo,
			color_techo,
			color_muro,
			espacio.get("textura_suelo", ""),
			espacio.get("textura_muro", ""),
			espacio.get("textura_techo", ""),
			espacio.get("escala_textura", 1.2),
			deformacion_textura,
			contraste_textura,
			preservar_detalle_textura,
			PoliticaTecho.debe_tener(espacio)
		)
	else:
		# `centro_suelo` desplaza el rectángulo sin mover el origen del sitio:
		# así una vivienda puede crecer por un lado sin recolocar todo lo que
		# ya estaba anclado al otro (#785).
		var medidas: Vector2 = espacio.get("suelo", Vector2(10, 10))
		var centro: Vector2 = espacio.get("centro_suelo", Vector2.ZERO)
		_suelo(raiz, medidas, color_suelo, espacio.get("textura_suelo", ""), centro)
		if PoliticaTecho.debe_tener(espacio):
			_techo(
				raiz,
				medidas,
				color_techo,
				espacio.get("textura_techo", ""),
				centro,
				float(espacio.get("techo_emision", EMISION_PLENA))
			)
		_muros(raiz, medidas, color_muro, espacio.get("textura_muro", ""), centro)

	# #231 / #479: una mancha es dressing visual del espacio. Se monta después
	# de la arquitectura para que pueda separarse de ella, pero no crea física.
	DecalCompat.montar_todos(raiz, espacio)

	for bulto in espacio.get("bultos", []):
		var pieza := _caja(
			raiz,
			bulto["pos"],
			bulto["tam"],
			bulto.get("color", Color(0.45, 0.44, 0.42)),
			bulto.get("textura", "")
		)
		# Un mueble que es malla y no caja. La caja sigue estando —es la
		# colisión— y lo que se ve pasa a ser el modelo, encajado en el `tam`
		# que declara el catálogo. Sin `modelo`, nada cambia.
		#
		# La malla de la caja se apaga ANTES de meter el modelo, y no después
		# recorriendo los hijos: hecho después, un `.glb` cuya raíz sea ella
		# misma una malla se apagaría a sí mismo y el bulto quedaría invisible.
		var modelo: String = bulto.get("modelo", "")
		if not modelo.is_empty():
			var caja_visible := _malla_de(pieza)
			if caja_visible != null:
				caja_visible.visible = false
			if not Modelos.mueble(
				pieza, modelo, bulto["tam"], bulto.get("color", Color(0.45, 0.44, 0.42))
			):
				# Sin modelo se vuelve a la caja: un archivador cúbico es peor
				# que uno de verdad, pero un bulto invisible es un agujero con
				# el que te chocas.
				if caja_visible != null:
					caja_visible.visible = true

		# Un bulto que se enciende: la pantalla de un ordenador, un piloto. No
		# ilumina nada, solo se ve encendido — lo que alumbra es una luz.
		if bulto.get("emisivo", false):
			_emisivo(pieza, bulto.get("color", Color(0.45, 0.44, 0.42)))

	# Las pantallas son una superficie de contenido, no un bulto: no tienen
	# colisión ni alteran la geometría de la calle. Sin fichero muestran nieve.
	for pantalla in espacio.get("pantallas", []):
		Pantalla.montar(raiz, pantalla)

	# Una ventana no es un bulto con otro color: no se atraviesa pero se ve a
	# través, y de noche lo que se ve es que fuera está oscuro. Va emisiva
	# porque desde dentro, con la luz encendida, un cristal de noche es una
	# superficie que se ve y no un agujero negro.
	for ventana in espacio.get("ventanas", []):
		var cristal := _caja(
			raiz, ventana["pos"], ventana["tam"], ventana.get("color", Color(0.09, 0.11, 0.20))
		)
		_emisivo(cristal, ventana.get("color", Color(0.09, 0.11, 0.20)))
		# La luz que entra solo existe mirando desde dentro de una sala que la
		# pueda recibir. Las ventanas de la calle son fachada vista desde fuera:
		# un foco «hacia dentro» alumbraría la calzada, y el benchmark de #861
		# midió lo que cuestan sesenta focos que nadie enciende.
		if _shader_del_sitio == SHADER_PSX_LUZ_PIXEL:
			cristal.name = NOMBRE_CRISTAL_VENTANA
			_luz_de_ventana(raiz, ventana, espacio.get("centro_suelo", Vector2.ZERO))

	# Las figuras y los carteles son del sueño (#87), pero este módulo sigue sin
	# saberlo: aquí solo hay una silueta en un sitio y un texto contra un muro.
	var zonas := []
	for figura in espacio.get("figuras", []):
		var color_figura: Color = figura.get("color", Color(0.30, 0.28, 0.34))
		# Quien tiene cuerpo lo tiene; quien no, sigue siendo la silueta. Y eso
		# NO es una carencia pendiente de rellenar: la silueta sin cara es del
		# acusado y del sueño a propósito —«a quien acusas nunca le ves la cara,
		# porque es un comité, una empresa o un cargo»—, mientras que a un
		# compañero de mesa sí se la ves todos los días. Dar cuerpo a los dos
		# borraría esa diferencia justo cuando acaba de hacerse visible.
		var cuerpo: Node3D = null
		var modelo := String(figura.get("modelo", ""))
		if not modelo.is_empty():
			cuerpo = Node3D.new()
			# En el suelo: una figura llega con los pies en su origen, así que
			# su sitio es su sitio y no hay cuentas que hacer.
			cuerpo.position = figura["pos"]
			raiz.add_child(cuerpo)
			if not Modelos.persona(cuerpo, modelo, color_figura, String(figura.get("retrato", ""))):
				cuerpo.queue_free()
				cuerpo = null
		if cuerpo == null:
			cuerpo = FiguraSilueta.construir(raiz, figura["pos"], color_figura)
		if not figura.get("rotulo", "").is_empty():
			# El nombre va SOBRE la cabeza, y la cabeza está más alta o más baja
			# según se sea una silueta o una persona de verdad. Silueta y modelo
			# llegan los dos con los pies en su origen, así que la altura de cada
			# uno basta: hubo aquí una resta de media silueta que suponía un
			# origen a media altura, y con ella el nombre caía a la altura del
			# pecho, donde el mobiliario lo parte a media palabra.
			var alto_rotulo := (
				(Modelos.ALTO_PERSONA if not modelo.is_empty() else FiguraSilueta.altura()) + 0.35
			)
			var nombre := _cartel(
				cuerpo,
				figura["rotulo"],
				Vector3(0, alto_rotulo, 0),
				0.0,
				figura.get("color_rotulo", Color(0.75, 0.74, 0.78)),
				true
			)
			# El nombre de alguien es una etiqueta, no un cartel de pared: al
			# lado ocupaba media pantalla. Y se apaga de lejos, o la oficina es
			# una lista de nombres flotando sobre las mesas.
			nombre.pixel_size = 0.0026
			nombre.visibility_range_end = 11.0
			nombre.visibility_range_end_margin = 3.0
		# Quien tiene algo que decir lo dice al acercarte, no al pulsarle: esto
		# es un sitio y no un menú de diálogo. La zona es una más de las que se
		# pisan, así que quien orquesta el día no aprende un mecanismo nuevo.
		if not figura.get("frase", "").is_empty():
			(
				zonas
				. append(
					_salida(
						raiz,
						{
							"pos": figura["pos"] + Vector3(0, 1.0, 0),
							"destino": "",
							"frase": figura["frase"],
							"tam": Vector3(2.2, 2.0, 2.2),
							"visible": false,
						}
					)
				)
			)
		# Y quien se deja pelear (#88) se pelea igual: acercándose. Es la misma
		# zona que se pisa, con otro dato dentro — este módulo sigue sin saber
		# qué es un combate.
		if not figura.get("duelo", "").is_empty():
			var reto := _salida(
				raiz,
				{
					"pos": figura["pos"] + Vector3(0, 1.0, 0),
					"destino": "",
					"duelo": figura["duelo"],
					"tam": Vector3(2.2, 2.0, 2.2),
					"visible": false,
				}
			)
			# La zona se lleva puesto su cuerpo. A quien ganas deja de estar
			# ahí, y quien lo borra necesita poder borrar los dos: una silueta
			# muda a la que ya no se puede retar es peor que ninguna.
			reto.set_meta("cuerpo", cuerpo)
			zonas.append(reto)

	for cartel in espacio.get("carteles", []):
		_cartel(
			raiz,
			cartel["texto"],
			cartel["pos"] + Vector3(0, ALTURA_CARTEL, 0),
			cartel.get("giro", 0.0),
			cartel.get("color", Color(0.75, 0.74, 0.78)),
			false
		)

	# Se fumaba en la oficina, y en casa, y en la calle. Es un objeto del sitio
	# como cualquier otro y por eso lo declara el catálogo.
	for cigarro in espacio.get("cigarros", []):
		Cigarro.construir(raiz, cigarro)

	# Las luces las declara el sitio, igual que sus muebles. Un fluorescente no
	# es un efecto: es una lámpara que está en el techo del archivo y que se ve
	# desde debajo, y por eso va en el catálogo y no en la pantalla que lo monta.
	for luz in espacio.get("luces", []):
		_luz(raiz, luz)

	var salidas := zonas
	for salida in espacio.get("salidas", []):
		salidas.append(_salida(raiz, salida))
	return salidas


## Una lámpara. Va con su carcasa: una luz sin nada que la emita es una luz que
## viene de ninguna parte, y eso se nota antes de saber por qué.
static func _luz(raiz: Node3D, luz: Dictionary) -> void:
	var punto := OmniLight3D.new()
	# Con nombre para poder distinguirla: una sala tiene lámparas generales y
	# además puntos de luz diminutos —la brasa de un cigarro— que no alumbran
	# la sala ni deben proyectar sombra. Sin nombre no hay forma de exigirle
	# nada a unas sin exigírselo a las otras.
	punto.name = NOMBRE_LUZ_SALA
	punto.position = luz["pos"]
	punto.light_color = luz.get("color", Color(1, 1, 1))
	punto.light_energy = luz.get("energia", 1.0)
	punto.omni_range = luz.get("alcance", 8.0)
	# Con sombra desde #275. El argumento para apagarlas —«en un sitio de cajas
	# planas lo único que enseñan es que son cajas»— valía cuando la oficina era
	# cajas; hoy hay mesas, sillas y figuras humanas, y sin sombra de contacto
	# nada apoya en el suelo: la sala entera se lee como calcomanías pegadas.
	# El sesgo evita el acné de sombra en superficies casi paralelas a la luz.
	punto.shadow_enabled = true
	punto.shadow_bias = 0.04
	punto.shadow_normal_bias = 1.4
	# Paraboloide dual o cubo, y no es una preferencia: MEDIDO en #789 sobre la
	# oficina real en GPU, encender y apagar la sombra de estas cinco lámparas en
	# paraboloide dual da una imagen idéntica píxel a píxel. En Forward+ ese modo
	# no dibuja nada, así que la optimización de #1121 —dos pasadas en vez de
	# seis— estaba ahorrando sobre una sombra que no existía. En cubo la sombra
	# aparece.
	#
	# Solo lo pide el sitio que puede enseñarla: donde la envolvente se pinta con
	# el shader canónico, la luz va por vértice y el material descarta la sombra
	# llegue como llegue, así que pagar el cubo allí sería pagar por nada.
	punto.omni_shadow_mode = (
		OmniLight3D.SHADOW_CUBE
		if _shader_del_sitio == SHADER_PSX_LUZ_PIXEL
		else OmniLight3D.SHADOW_DUAL_PARABOLOID
	)
	raiz.add_child(punto)

	if not luz.get("carcasa", true):
		return
	var cuerpo := _caja(
		raiz, luz["pos"], luz.get("tam", Vector3(1.2, 0.08, 0.3)), luz.get("color", Color(1, 1, 1))
	)
	_emisivo(cuerpo, luz.get("color", Color(1, 1, 1)))
	# La carcasa envuelve a su propia lámpara: va en la misma posición. Mientras
	# no hubo sombras daba igual, pero en cuanto las hay el fluorescente se tapa
	# a sí mismo y la sala se queda a oscuras. Una lámpara no se hace sombra.
	_no_proyecta_sombra(cuerpo)


## La luz que entra por una ventana: un foco pegado al cristal que mira hacia
## dentro y hacia el suelo, que es donde el sol de una ventana deja su mancha.
## Nace APAGADA: este módulo no sabe qué hora es, y una ventana encendida por
## defecto sería sol a las once de la noche en cualquier sitio que no tenga
## quien lea la hora. La enciende quien sí la sabe.
static func _luz_de_ventana(raiz: Node3D, ventana: Dictionary, centro: Vector2) -> void:
	var pos: Vector3 = ventana["pos"]
	var tam: Vector3 = ventana["tam"]
	# Hacia dentro es perpendicular al lado fino del cristal y hacia el centro
	# del suelo; así sirve igual para una ventana en cualquiera de los muros.
	var dentro := (
		Vector3(-signf(pos.x - centro.x), 0, 0)
		if tam.x < tam.z
		else Vector3(0, 0, -signf(pos.z - centro.y))
	)
	var foco := SpotLight3D.new()
	foco.name = NOMBRE_LUZ_VENTANA
	var origen := pos + dentro * 0.35
	var objetivo := Vector3(pos.x, 0, pos.z) + dentro * 2.6
	foco.transform = Transform3D(Basis.IDENTITY, origen).looking_at(objetivo, Vector3.UP)
	foco.spot_range = 7.0
	# Haz cerrado y poca caída: el sol que entra por una ventana deja una
	# mancha con borde, no un halo. MEDIDO en GPU sobre la oficina (#789): con
	# un haz abierto la mancha se diluía en la moqueta oscura y a energía de
	# fluorescente el suelo bajo la ventana apenas pasaba de 37 a 51 sobre 255.
	foco.spot_angle = 38.0
	foco.spot_attenuation = 0.4
	foco.spot_angle_attenuation = 0.4
	foco.light_energy = 0.0
	foco.visible = false
	foco.shadow_enabled = true
	foco.shadow_bias = 0.04
	foco.shadow_normal_bias = 1.4
	# Nombre legible también para la segunda ventana: sin forzarlo, Godot llama
	# a la repetida «@SpotLight3D@…» y quien la busca por nombre no la encuentra.
	raiz.add_child(foco, true)


## Deja de proyectar sombra sin dejar de verse. Es para lo que está DENTRO de
## una luz o pegado a ella, donde la sombra propia no describe nada.
static func _no_proyecta_sombra(nodo: Node) -> void:
	if nodo is GeometryInstance3D:
		(nodo as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for hijo in nodo.get_children():
		_no_proyecta_sombra(hijo)


## Un texto en el mundo, no en la interfaz.
##
## Lo que se escribe en una pared del sueño está EN la pared: hay que acercarse
## y hay que mirar. Puesto en la interfaz sería una nota al margen, y una frase
## que te sigue por la pantalla no es lo mismo que una frase que está escrita
## en un sitio.
##
## [param sigue] hace que el texto mire siempre al jugador. Lo lleva el nombre
## de una figura —que se lee desde donde sea— y NO un texto de pared, que si
## girase dejaría de estar escrito en la pared.
static func _cartel(
	raiz: Node3D, texto: String, pos: Vector3, giro: float, color: Color, sigue: bool
) -> Label3D:
	var cartel := Label3D.new()
	cartel.text = texto
	cartel.position = pos
	cartel.rotation.y = giro
	cartel.modulate = color
	# En la letra del archivo, sin suavizar: una frase gatillo en el sueño es la
	# MISMA frase del documento, y en otra tipografía sería una cita.
	cartel.font = EstiloSiga.fuente_mono()
	cartel.font_size = 48
	cartel.pixel_size = 0.006
	cartel.outline_size = 12
	cartel.outline_modulate = Color(0, 0, 0, 0.85)
	cartel.width = 1400
	cartel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cartel.billboard = (
		BaseMaterial3D.BILLBOARD_FIXED_Y if sigue else BaseMaterial3D.BILLBOARD_DISABLED
	)
	# Se lee de noche: sin esto la letra queda tan a oscuras como el muro que
	# tiene detrás, y una frase que no se lee no está escrita.
	cartel.shaded = false
	raiz.add_child(cartel)
	return cartel


## Un contorno poligonal ya trae suelo, techo, paredes y su colisión desde la
## misma `ArrayMesh` (#448). Aquí solo se le aplica el material común del mundo;
## la forma y la física no vuelven a separarse en dos representaciones.
static func _por_contorno(
	raiz: Node3D,
	contorno: PackedVector2Array,
	altura: float,
	color: Color,
	textura: String = "",
	metros: float = 1.2,
	deformacion: Vector3 = Vector3.ONE,
	contraste: float = 1.0,
	preservar_detalle_textura: bool = false,
	tabiques: Array = []
) -> void:
	var cuerpo := SuenoGeometria.cuerpo_sala(contorno, altura, tabiques)
	var malla := _malla_de(cuerpo)
	if malla != null:
		var material := ShaderMaterial.new()
		material.shader = load(_shader_del_sitio)
		material.set_shader_parameter("color_base", color)
		if not textura.is_empty():
			var imagen := TexturaProcedural.por_nombre(textura, color, hash(textura), contraste)
			if imagen != null:
				material.set_shader_parameter("textura", imagen)
				material.set_shader_parameter(
					"preservar_detalle_textura", preservar_detalle_textura
				)
				material.set_shader_parameter("con_textura", true)
				material.set_shader_parameter("escala_textura", 1.0 / metros)
				material.set_shader_parameter("deformacion_textura", deformacion)
		malla.material_override = material
	raiz.add_child(cuerpo)


## Una planta cualquiera: losas donde hay celda y muros donde no hay vecina.
##
## Nada de esto conoce la forma que está montando. El anillo del sueño sale con
## el muro de su patio porque el patio es contorno igual que el borde de fuera,
## no porque nadie haya declarado un patio.
static func _por_planta(
	raiz: Node3D,
	bloques: Array,
	color_suelo: Color,
	color_techo: Color,
	color_muro: Color,
	textura_suelo: String = "",
	textura_muro: String = "",
	textura_techo: String = "",
	metros: float = 1.2,
	deformacion: Vector3 = Vector3.ONE,
	contraste: float = 1.0,
	preservar_detalle_textura: bool = false,
	con_techo: bool = true
) -> void:
	for rect in Planta.rectangulos(bloques):
		var esquina := Planta.esquina_en_metros(bloques, rect.position)
		var tam := Vector3(rect.size.x * Planta.CELDA, GROSOR_MURO, rect.size.y * Planta.CELDA)
		var centro := esquina + Vector3(tam.x / 2.0, 0, tam.z / 2.0)
		_caja(
			raiz,
			centro + Vector3(0, -GROSOR_MURO / 2.0, 0),
			tam,
			color_suelo,
			textura_suelo,
			metros,
			deformacion,
			contraste,
			preservar_detalle_textura
		)
		if con_techo:
			var techo := _caja(
				raiz,
				centro + Vector3(0, ALTURA_MURO + GROSOR_MURO / 2.0, 0),
				tam,
				color_techo,
				textura_techo,
				metros,
				deformacion,
				contraste,
				preservar_detalle_textura
			)
			_emisivo(techo, color_techo)

	for tramo in Planta.contorno(bloques):
		var largo: float = (tramo["hasta"] - tramo["desde"]) * Planta.CELDA
		var a: Vector2i
		var tam: Vector3
		if tramo["eje"] == "x":
			a = Vector2i(tramo["desde"], tramo["linea"])
			tam = Vector3(largo, ALTURA_MURO, GROSOR_MURO)
		else:
			a = Vector2i(tramo["linea"], tramo["desde"])
			tam = Vector3(GROSOR_MURO, ALTURA_MURO, largo)
		var esquina := Planta.esquina_en_metros(bloques, a)
		var centro := (
			esquina
			+ Vector3(
				tam.x / 2.0 if tramo["eje"] == "x" else 0.0,
				ALTURA_MURO / 2.0,
				0.0 if tramo["eje"] == "x" else tam.z / 2.0
			)
		)
		_caja(
			raiz,
			centro,
			tam,
			color_muro,
			textura_muro,
			metros,
			deformacion,
			contraste,
			preservar_detalle_textura
		)


static func _suelo(
	raiz: Node3D, medidas: Vector2, color: Color, textura: String = "", centro := Vector2.ZERO
) -> void:
	var cuerpo := _caja(
		raiz,
		Vector3(centro.x, -GROSOR_MURO / 2.0, centro.y),
		Vector3(medidas.x, GROSOR_MURO, medidas.y),
		color,
		textura
	)
	# El suelo recibe sombra pero no la proyecta: debajo no hay nada que mirar,
	# y es la superficie más grande de la sala. Sale gratis de cada pasada.
	_no_proyecta_sombra(cuerpo)


## El techo va EMISIVO, no solo claro. La luz del motor viene de arriba, así
## que la cara de abajo de un techo está siempre en el mínimo y sale negra por
## construcción — mirar arriba en cualquiera de estas salas era mirar a un
## agujero. Un techo que se pinta a sí mismo es además lo que hay: en 1998 esa
## superficie eran paneles de fluorescente.
static func _techo(
	raiz: Node3D,
	medidas: Vector2,
	color: Color,
	textura: String = "",
	centro := Vector2.ZERO,
	emision: float = EMISION_PLENA
) -> void:
	var cuerpo := _caja(
		raiz,
		Vector3(centro.x, ALTURA_MURO + GROSOR_MURO / 2.0, centro.y),
		Vector3(medidas.x, GROSOR_MURO, medidas.y),
		color,
		textura
	)
	_emisivo(cuerpo, color, emision)
	# Un techo emisivo que además tapara la luz de sus propias lámparas dejaría
	# la sala a oscuras por el mismo motivo que la carcasa del fluorescente.
	_no_proyecta_sombra(cuerpo)


## La malla de la caja de un bulto. Es su primer hijo por construcción, pero se
## busca por TIPO: desde que un bulto puede llevar modelo encima, «el primer
## hijo» dejó de ser una descripción fiable de dónde está.
static func _malla_de(cuerpo: Node3D) -> MeshInstance3D:
	for hijo in cuerpo.get_children():
		if hijo is MeshInstance3D:
			return hijo
	return null


## [param fuerza] es cuánto se pinta a sí misma la superficie. El valor por
## defecto es el de siempre; un sitio con luz por píxel puede pedir menos para su
## techo, porque ahí la emisión ya no está tapando un agujero negro (#789).
static func _emisivo(cuerpo: StaticBody3D, color: Color, fuerza: float = EMISION_PLENA) -> void:
	var malla := _malla_de(cuerpo)
	if malla == null:
		return
	var material: ShaderMaterial = malla.material_override
	material.set_shader_parameter("emision", color)
	material.set_shader_parameter("emision_fuerza", fuerza)


## Los cuatro muros salen de lo que mide el suelo, no escritos uno a uno: un
## espacio no puede quedarse con un lado abierto por un descuido.
static func _muros(
	raiz: Node3D, medidas: Vector2, color: Color, textura: String = "", centro := Vector2.ZERO
) -> void:
	var mitad_x := medidas.x / 2.0
	var mitad_z := medidas.y / 2.0
	var alto := ALTURA_MURO / 2.0
	_caja(
		raiz,
		Vector3(centro.x, alto, centro.y - mitad_z),
		Vector3(medidas.x, ALTURA_MURO, GROSOR_MURO),
		color,
		textura
	)
	_caja(
		raiz,
		Vector3(centro.x, alto, centro.y + mitad_z),
		Vector3(medidas.x, ALTURA_MURO, GROSOR_MURO),
		color,
		textura
	)
	_caja(
		raiz,
		Vector3(centro.x - mitad_x, alto, centro.y),
		Vector3(GROSOR_MURO, ALTURA_MURO, medidas.y),
		color,
		textura
	)
	_caja(
		raiz,
		Vector3(centro.x + mitad_x, alto, centro.y),
		Vector3(GROSOR_MURO, ALTURA_MURO, medidas.y),
		color,
		textura
	)


static func _caja(
	raiz: Node3D,
	pos: Vector3,
	tam: Vector3,
	color: Color,
	textura: String = "",
	metros: float = 1.2,
	deformacion: Vector3 = Vector3.ONE,
	contraste: float = 1.0,
	preservar_detalle_textura: bool = false
) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = pos

	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	# La luz se calcula por VÉRTICE (es lo que hacía la máquina que se imita),
	# así que una caja de catorce metros con ocho vértices se ilumina entera de
	# un tono y las lámparas del techo no se notan. Subdividir es lo que hacían
	# aquellos juegos por el mismo motivo, y es lo que devuelve el charco de luz
	# debajo de cada fluorescente. El tope evita que un suelo grande se convierta
	# en miles de caras por una lámpara.
	caja.subdivide_width = clampi(int(tam.x / METROS_POR_VERTICE), 0, TOPE_SUBDIVISION)
	caja.subdivide_height = clampi(int(tam.y / METROS_POR_VERTICE), 0, TOPE_SUBDIVISION)
	caja.subdivide_depth = clampi(int(tam.z / METROS_POR_VERTICE), 0, TOPE_SUBDIVISION)
	malla.mesh = caja
	var material := ShaderMaterial.new()
	material.shader = load(_shader_del_sitio)
	material.set_shader_parameter("color_base", color)
	if not textura.is_empty():
		var imagen := TexturaProcedural.por_nombre(textura, color, hash(textura), contraste)
		if imagen != null:
			material.set_shader_parameter("textura", imagen)
			material.set_shader_parameter("preservar_detalle_textura", preservar_detalle_textura)
			material.set_shader_parameter("con_textura", true)
			# La textura se pega a las coordenadas del MUNDO: un muro de
			# catorce metros y uno de dos tienen así el mismo grano. Pegada a
			# la caja, cada pared contaría una escala distinta.
			material.set_shader_parameter("escala_textura", 1.0 / metros)
			material.set_shader_parameter("deformacion_textura", deformacion)
	malla.material_override = material
	cuerpo.add_child(malla)

	var forma := CollisionShape3D.new()
	var caja_col := BoxShape3D.new()
	caja_col.size = tam
	forma.shape = caja_col
	cuerpo.add_child(forma)

	raiz.add_child(cuerpo)
	return cuerpo


## Una salida es una zona que se pisa, no un botón: en un walking simulator lo
## que decide es dónde estás.
static func _salida(raiz: Node3D, salida: Dictionary) -> Area3D:
	var zona := Area3D.new()
	zona.position = salida["pos"]
	zona.set_meta("destino", salida["destino"])
	zona.set_meta("rotulo", salida.get("rotulo", ""))
	zona.set_meta("frase", salida.get("frase", ""))
	zona.set_meta("duelo", salida.get("duelo", ""))
	zona.set_meta("evento", salida.get("evento", ""))

	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = salida.get("tam", Vector3(1.4, 2.2, 1.4))
	forma.shape = caja
	zona.add_child(forma)

	# Se ve: una salida invisible es una trampa. Va en el color de lo accionable
	# y no en el del mobiliario.
	#
	# La excepción es el sueño (#90), donde encontrarla ES el juego, y por eso
	# la excepción se DECLARA aquí en vez de que el sueño se monte su propia
	# zona: una salida sin marca sigue siendo una salida y no otra cosa.
	if not salida.get("visible", true):
		raiz.add_child(zona)
		return zona

	var marca := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = salida.get("tam", Vector3(1.4, 2.2, 1.4))
	marca.mesh = malla
	var material := StandardMaterial3D.new()
	# Se ve pero no tapa: una marca opaca sobre la cama escondería la cama.
	material.albedo_color = Color(0.15, 0.2, 0.75, 0.16)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 1.0
	marca.material_override = material
	zona.add_child(marca)

	raiz.add_child(zona)
	return zona
