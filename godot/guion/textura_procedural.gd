## Texturas generadas en el arranque, no traídas en un fichero.
##
## Es la misma regla que el resto del arte de este juego: el repositorio no
## lleva binarios, y lo que se ve se calcula. Aquí eso además NO es una
## renuncia — una textura de 1998 son 64×64 píxeles con ocho colores, y eso se
## describe mejor con seis líneas de código que con un PNG.
##
## Todas salen pequeñas y con filtro NEAREST a propósito: el aspecto de la
## época no está en la resolución sino en ver el píxel. Una textura de 1024 con
## suavizado sobre estas cajas sería un render moderno con las paredes rectas.
class_name TexturaProcedural
extends RefCounted

## El lado de una textura, en píxeles. Es el mando de escala de todas: subirlo
## no las mejora, las saca de época.
const LADO := 64

## Dónde viven las texturas TRAÍDAS, frente a las calculadas. El nombre de la
## superficie es el nombre del fichero: añadir un material es dejarlo aquí.
const CARPETA := "res://assets/texturas/%s.jpg"


## Linóleo de oficina: un tono plano con motas. Es el suelo de cualquier
## edificio público de los 90 y lo que lo identifica son las manchas, no el
## color.
static func linoleo(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	imagen.fill(base)
	for i in LADO * LADO / 6:
		var claro := rng.randf() < 0.5
		imagen.set_pixel(
			rng.randi() % LADO,
			rng.randi() % LADO,
			base.lightened(0.10) if claro else base.darkened(0.10)
		)
	return ImageTexture.create_from_image(imagen)


## Gotelé: la pared picada de toda oficina española de la época. Motas más
## gruesas que el linóleo y con sombra abajo, que es lo que hace que se lea
## como relieve y no como suciedad.
static func gotele(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	imagen.fill(base)
	for i in LADO * LADO / 10:
		var x := rng.randi() % LADO
		var y := rng.randi() % LADO
		imagen.set_pixel(x, y, base.lightened(0.14))
		if y + 1 < LADO:
			imagen.set_pixel(x, y + 1, base.darkened(0.12))
	return ImageTexture.create_from_image(imagen)


## Plancha de techo registrable: la retícula de perfiles y la placa perforada.
## Es lo que hay encima de la cabeza en el archivo, y es de las pocas cosas de
## una oficina que todo el mundo ha mirado fijamente alguna vez.
static func plancha_techo(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	imagen.fill(base)
	# Perforaciones, sorteadas pero no en el borde: la junta manda.
	for i in LADO * LADO / 14:
		var x := 2 + rng.randi() % (LADO - 4)
		var y := 2 + rng.randi() % (LADO - 4)
		imagen.set_pixel(x, y, base.darkened(0.18))
	# El perfil metálico entre placas.
	var junta := base.lightened(0.10)
	for i in LADO:
		imagen.set_pixel(i, 0, junta)
		imagen.set_pixel(i, LADO - 1, base.darkened(0.25))
		imagen.set_pixel(0, i, junta)
		imagen.set_pixel(LADO - 1, i, base.darkened(0.25))
	return ImageTexture.create_from_image(imagen)


## Asfalto: grano fino y oscuro, sin nada que se pueda leer como una señal.
## Una línea pintada en el suelo diría por dónde ir, y eso no lo ha decidido
## nadie.
static func asfalto(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	for x in LADO:
		for y in LADO:
			imagen.set_pixel(x, y, base.lightened(rng.randf() * 0.12 - 0.06))
	return ImageTexture.create_from_image(imagen)


## Moqueta de casa: trama regular con hilo suelto. La regularidad es lo que la
## separa del asfalto, que es ruido puro.
static func moqueta(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	for x in LADO:
		for y in LADO:
			var trama := 0.05 if (x + y) % 2 == 0 else -0.05
			imagen.set_pixel(x, y, base.lightened(trama + rng.randf() * 0.04))
	return ImageTexture.create_from_image(imagen)


## Melamina de escritorio: bandas largas y muy suaves. La veta está presente
## pero no convierte una mesa administrativa laminada en madera maciza.
static func melamina(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	for y in LADO:
		var variacion := rng.randf_range(-0.055, 0.055)
		var tono := base.lightened(variacion) if variacion >= 0.0 else base.darkened(-variacion)
		for x in LADO:
			imagen.set_pixel(x, y, tono)
	# Unas pocas juntas/rozaduras rompen la perfección sin convertirla en ruido.
	for i in 7:
		var y := rng.randi() % LADO
		for x in LADO:
			if rng.randf() < 0.42:
				imagen.set_pixel(x, y, base.darkened(0.10))
	return ImageTexture.create_from_image(imagen)


## Chapa pintada de archivador: superficie casi uniforme con arañazos largos y
## desconchones aislados. El desgaste tiene dirección y posición; no es ruido
## repartido por toda la pieza.
static func metal_pintado(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	imagen.fill(base)
	for i in 12:
		var x := rng.randi() % LADO
		var y := rng.randi() % LADO
		var largo := rng.randi_range(3, 11)
		for paso in largo:
			if x + paso < LADO:
				imagen.set_pixel(x + paso, y, base.darkened(0.16))
	for i in 9:
		imagen.set_pixel(rng.randi() % LADO, rng.randi() % LADO, base.lightened(0.08))
	return ImageTexture.create_from_image(imagen)


## ABS de equipos y sillas: grano fino, mate y discreto. Se distingue del metal
## por no tener arañazos direccionales ni juntas de veta.
static func plastico_abs(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	imagen.fill(base)
	for i in LADO * LADO / 18:
		var claro := rng.randf() < 0.45
		imagen.set_pixel(
			rng.randi() % LADO,
			rng.randi() % LADO,
			base.lightened(0.045) if claro else base.darkened(0.045)
		)
	return ImageTexture.create_from_image(imagen)


## La textura de una superficie: la traída si existe, y si no la calculada.
##
## Cada espacio la pide por NOMBRE y no importa este módulo, así que cambiar de
## dónde sale una superficie no toca a quien la usa.
##
## Las calculadas siguen aquí y siguen sirviendo: son la red para una superficie
## que todavía no tiene material, y lo que hace que el juego arranque sin
## depender de que los binarios de LFS hayan bajado. Pero donde hay material de
## verdad manda el material: un tono plano con motas dice "caja", por bonita que
## sea la mota.
static func por_nombre(nombre: String, base: Color, semilla: int) -> Texture2D:
	var ruta := CARPETA % nombre
	if ResourceLoader.exists(ruta):
		var traida := ResourceLoader.load(ruta, "Texture2D")
		if traida != null:
			return traida
	return calculada(nombre, base, semilla)


static func calculada(nombre: String, base: Color, semilla: int) -> ImageTexture:
	match nombre:
		"linoleo":
			return linoleo(base, semilla)
		"gotele":
			return gotele(base, semilla)
		"techo":
			return plancha_techo(base, semilla)
		"asfalto":
			return asfalto(base, semilla)
		"moqueta":
			return moqueta(base, semilla)
		"melamina":
			return melamina(base, semilla)
		"metal_pintado":
			return metal_pintado(base, semilla)
		"plastico_abs":
			return plastico_abs(base, semilla)
		_:
			return null
