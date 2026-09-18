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


## Revoco urbano exterior: paños verticales gastados por lluvia y suciedad.
## No contiene carteles, números ni marcas que puedan convertirse en información
## narrativa; solo rompe la lectura de las fachadas como cajas de color plano.
static func revoco_urbano(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	imagen.fill(base)
	for x in LADO:
		var escorrentia := rng.randf_range(-0.035, 0.025)
		for y in LADO:
			var desgaste := escorrentia + float(y) / float(LADO) * -0.025
			var tono := base.lightened(desgaste) if desgaste >= 0.0 else base.darkened(-desgaste)
			imagen.set_pixel(x, y, tono)
	for i in LADO * LADO / 28:
		var x := rng.randi() % LADO
		var y := rng.randi() % LADO
		imagen.set_pixel(x, y, base.darkened(rng.randf_range(0.05, 0.13)))
	return ImageTexture.create_from_image(imagen)


## Loseta de acera: piezas rectangulares trabadas y juntas oscuras. Frente al
## asfalto, la regularidad y las juntas hacen legible el borde peatonal incluso
## cuando los masters PBR de #560 no están disponibles por Git LFS.
static func loseta_acera(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	for x in LADO:
		for y in LADO:
			var grano := rng.randf_range(-0.025, 0.025)
			var tono := base.lightened(grano) if grano >= 0.0 else base.darkened(-grano)
			imagen.set_pixel(x, y, tono)

	var junta := base.darkened(0.18)
	for y in range(0, LADO, 8):
		for x in LADO:
			imagen.set_pixel(x, y, junta)
	for fila in 8:
		var y_inicio := fila * 8
		var desfase := 0 if fila % 2 == 0 else 8
		for x in range(desfase, LADO, 16):
			for dy in 8:
				if y_inicio + dy < LADO:
					imagen.set_pixel(x, y_inicio + dy, junta)
	return ImageTexture.create_from_image(imagen)


## Cristal urbano: casi neutro, con velos verticales y pequeñas marcas de agua.
## El color y la transparencia los decide el shader de vidrio; esta textura solo
## aporta materia para que un escaparate no sea un plano perfectamente limpio.
static func cristal_urbano(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	imagen.fill(base)
	for x in LADO:
		var velo := rng.randf_range(-0.035, 0.02)
		for y in LADO:
			var tono := base.lightened(velo) if velo >= 0.0 else base.darkened(-velo)
			imagen.set_pixel(x, y, tono)
	for i in LADO * LADO / 36:
		var x := rng.randi() % LADO
		var y := rng.randi() % LADO
		imagen.set_pixel(x, y, base.darkened(rng.randf_range(0.04, 0.11)))
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


## Madera doméstica: veta más marcada e irregular que la melamina de oficina.
## Tiene bandas y pequeños nudos; debe leerse como mueble de casa, no como mesa
## administrativa laminada.
static func madera_domestica(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	for y in LADO:
		var banda := sin(float(y) * 0.42 + rng.randf_range(-0.25, 0.25)) * 0.055
		var tono := base.lightened(banda) if banda >= 0.0 else base.darkened(-banda)
		for x in LADO:
			imagen.set_pixel(x, y, tono)
	for i in 10:
		var x := rng.randi() % LADO
		var y := rng.randi() % LADO
		imagen.set_pixel(x, y, base.darkened(0.18))
		if x + 1 < LADO:
			imagen.set_pixel(x + 1, y, base.darkened(0.10))
	return ImageTexture.create_from_image(imagen)


## Tejido doméstico: urdimbre y trama visibles a resolución baja. El patrón
## diferencia un sofá o pantalla de lámpara de cualquier bloque pintado.
static func tejido_domestico(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	for x in LADO:
		for y in LADO:
			var trama := 0.035 if x % 4 < 2 else -0.025
			var urdimbre := 0.030 if y % 4 < 2 else -0.020
			var variacion := trama + urdimbre + rng.randf_range(-0.015, 0.015)
			imagen.set_pixel(
				x, y, base.lightened(variacion) if variacion >= 0.0 else base.darkened(-variacion)
			)
	return ImageTexture.create_from_image(imagen)


## Acero de cocina: cepillado fino y direccional. No tiene desconchones de chapa
## pintada; fregadero, nevera y herrajes deben leer como metal limpio de casa.
static func acero_cocina(base: Color, semilla: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var imagen := Image.create(LADO, LADO, false, Image.FORMAT_RGB8)
	for y in LADO:
		var linea := rng.randf_range(-0.035, 0.035)
		for x in LADO:
			var cepillado := 0.045 if x % 8 == 0 else linea
			imagen.set_pixel(
				x, y, base.lightened(cepillado) if cepillado >= 0.0 else base.darkened(-cepillado)
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
static func por_nombre(
	nombre: String, base: Color, semilla: int, contraste: float = 1.0
) -> Texture2D:
	# Una ruta explícita es ya la fuente de verdad. No se le añade ".jpg" ni
	# se intenta traducir a una procedural con un nombre que no existe.
	if nombre.begins_with("res://"):
		if not ResourceLoader.exists(nombre):
			return null
		return ResourceLoader.load(nombre, "Texture2D") as Texture2D

	var ruta := CARPETA % nombre
	if ResourceLoader.exists(ruta) and not _es_puntero_lfs(ruta):
		var traida := ResourceLoader.load(ruta, "Texture2D") as Texture2D
		if traida != null:
			return _contrastar_textura(traida, base, contraste)
	return calculada(nombre, base, semilla, contraste)


## Un checkout sin objetos LFS conserva un fichero de texto en la ruta del
## JPG. Se compara la cabecera como bytes: intentar decodificar un JPEG real
## como UTF-8 ensucia el log y convierte una detección inocua en un error.
static func _es_puntero_lfs(ruta: String) -> bool:
	if not FileAccess.file_exists(ruta):
		return false
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return false
	var esperada := "version https://git-lfs.github.com/spec/v1".to_utf8_buffer()
	var cabecera := archivo.get_buffer(esperada.size())
	if cabecera.size() != esperada.size():
		return false
	for i in esperada.size():
		if cabecera[i] != esperada[i]:
			return false
	return true


static func calculada(
	nombre: String, base: Color, semilla: int, contraste: float = 1.0
) -> ImageTexture:
	var textura: ImageTexture
	match nombre:
		"linoleo":
			textura = linoleo(base, semilla)
		"gotele":
			textura = gotele(base, semilla)
		"techo":
			textura = plancha_techo(base, semilla)
		"asfalto":
			textura = asfalto(base, semilla)
		"revoco_urbano":
			textura = revoco_urbano(base, semilla)
		"loseta_acera":
			textura = loseta_acera(base, semilla)
		"cristal_urbano":
			textura = cristal_urbano(base, semilla)
		"moqueta":
			textura = moqueta(base, semilla)
		"melamina":
			textura = melamina(base, semilla)
		"metal_pintado":
			textura = metal_pintado(base, semilla)
		"plastico_abs":
			textura = plastico_abs(base, semilla)
		"madera_domestica":
			textura = madera_domestica(base, semilla)
		"tejido_domestico":
			textura = tejido_domestico(base, semilla)
		"acero_cocina":
			textura = acero_cocina(base, semilla)
		_:
			return null
	return _contrastar_textura(textura, base, contraste)


## Crea una copia runtime contrastada ANTES de que el sampler lineal pierda
## la trama bajo iluminación baja y cuantización. Se usa para el fallback y
## para el JPG canónico nombrado; una ruta explícita res:// sale antes y queda
## intacta. El default 1.0 devuelve el recurso original sin trabajo extra.
static func _contrastar_textura(textura: Texture2D, base: Color, contraste: float) -> Texture2D:
	if is_equal_approx(contraste, 1.0):
		return textura
	var imagen := textura.get_image()
	var factor := maxf(contraste, 0.0)
	for x in imagen.get_width():
		for y in imagen.get_height():
			var pixel := imagen.get_pixel(x, y)
			(
				imagen
				. set_pixel(
					x,
					y,
					Color(
						clampf(base.r + (pixel.r - base.r) * factor, 0.0, 1.0),
						clampf(base.g + (pixel.g - base.g) * factor, 0.0, 1.0),
						clampf(base.b + (pixel.b - base.b) * factor, 0.0, 1.0),
						pixel.a,
					)
				)
			)
	return ImageTexture.create_from_image(imagen)
