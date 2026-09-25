## Los muebles que son malla de verdad y no una caja.
##
## `EspaciosCatalogo` ya lo había previsto: «una mesa es una caja **hasta que
## haya un asset con su ficha**; llamarla mesa aquí es lo que permite
## sustituirla luego sin tocar la geografía». Esto es ese *luego*. Un bulto
## declara `modelo` y le sale la malla encima; sin `modelo` sigue siendo la caja
## de siempre, así que ningún sitio existente cambia por esto.
##
## Tres reglas, y ninguna es de comodidad:
##
## 1. **La caja sigue mandando.** El modelo se ENCAJA en el `tam` declarado y la
##    colisión sigue siendo la del bulto. La geografía es del catálogo, no del
##    fichero que alguien descargó: si un `.glb` viniera con otra escala, lo que
##    no puede pasar es que la sala cambie de forma por debajo. Se puede
##    sustituir un modelo por otro y nadie se queda encerrado.
## 2. **Se viste con el mismo shader que todo lo demás.** `Espacio3D` dice que
##    un solo material es lo que hace que esto parezca una máquina y no un
##    render, y un mueble importado con su propio material sería justo eso: un
##    objeto de otro juego pegado en esta oficina. El modelo aporta la FORMA; el
##    color lo sigue declarando el catálogo, como el de cualquier bulto.
## 3. **Un modelo que falta no revienta la sala.** Se queda la caja. Un archivo
##    con un archivador cúbico es peor; un archivo que no abre es inaceptable.
class_name Modelos
extends RefCounted

const RUTA := "res://assets/modelos/"

## Las extensiones que puede tener un modelo, en orden de preferencia. Los
## muebles vienen en `.glb` y las personas en `.fbx`: el pack de figuras
## animadas no publica glTF, y Godot 4.7 importa FBX por su cuenta desde que
## lleva ufbx dentro. Quien pide un modelo no tiene por qué saber en qué formato
## lo publicó su autor.
const FORMATOS: Array[String] = [".glb", ".fbx"]

## La forma viene del asset; la MATERIA sigue siendo del proyecto. Esta tabla es
## deliberadamente semántica: un escritorio de otro pack sigue siendo melamina,
## no necesita copiar una textura casi idéntica en cada escena.
const MATERIALES_MUEBLE := {
	"desk": "melamina",
	"bookcaseClosed": "metal_pintado",
	"computerScreen": "plastico_abs",
	"chairDesk": "plastico_abs",
	"trashcan": "metal_pintado",
}

## Repeticiones por metro en el triplanar común. La escala pertenece al material,
## no a una instancia concreta: dos archivadores no deben tener arañazos de un
## tamaño distinto solo porque su caja declarada cambie.
const ESCALAS_MATERIAL := {
	"melamina": 2.2,
	"metal_pintado": 3.4,
	"plastico_abs": 5.0,
}

## Lo que mide una persona, en metros. No lo decide este módulo: lo fija
## `nodes/root_scale` en el `.import` de la figura, y aquí se declara para que
## quien le cuelgue el nombre encima no tenga que medirlo a ojo. Si cambia allí,
## cambia aquí.
const ALTO_PERSONA := 1.75

## Subcarpeta de `RUTA` con los avatares fotorrealistas (#275).
const CARPETA_REALISTAS := "rocketbox/"
const IDENTIDAD_ROCKETBOX := preload("res://guion/identidad_historica_rocketbox.gd")

const PERFILES_FACIALES := {
	"emperador":
	{"piel": Color(0.72, 0.56, 0.43), "cabello": Color(0.08, 0.07, 0.06), "x": 0.96, "z": 0.92},
	"aduanero_ny":
	{
		"piel": Color(0.66, 0.48, 0.36),
		"cabello": Color(0.18, 0.16, 0.14),
		"barba": Color(0.28, 0.25, 0.22),
		"x": 1.04,
		"z": 1.00,
	},
	"correspondencia":
	{"piel": Color(0.70, 0.53, 0.40), "cabello": Color(0.10, 0.08, 0.07), "x": 0.92, "z": 0.96},
	"riegos":
	{"piel": Color(0.73, 0.57, 0.43), "cabello": Color(0.16, 0.12, 0.09), "x": 1.08, "z": 1.02},
	"fielato":
	{"piel": Color(0.62, 0.46, 0.35), "cabello": Color(0.07, 0.06, 0.05), "x": 1.00, "z": 1.08},
}

## `retrato` sigue siendo la clave estable que llega desde el catálogo, pero la
## identidad visual deja de salir solo de un hash. Cada entrada de esta tabla
## habilita rasgos modelados para la persona histórica concreta. La misma clave
## sirve tanto al maniquí legacy como a los avatares Rocketbox: en estos últimos
## solo añade accesorios/volúmenes reconocibles y conserva intactos piel, cara y
## texturas del avatar. No se pega ninguna fotografía sobre la malla.
const PERSONAJES_FACIALES := {
	"emperador": "Puyi",
	"aduanero_ny": "Herman Melville",
	"correspondencia": "Fernando Pessoa",
	"riegos": "Constantino Cavafis",
	"fielato": "Henri Rousseau",
}

## Lo que se carga una vez y se reusa. Las salas repiten mueble —seis
## archivadores, cuatro puestos— y volver a leer el `.glb` por cada uno es leer
## el mismo fichero seis veces para obtener seis cosas idénticas.
static var _cache := {}


## Un MUEBLE: la forma la pone el modelo y el color la casa.
##
## Se encaja en el `tam` declarado por el catálogo y se le impone el shader
## común, porque un mueble importado con su propio material sería un objeto de
## otro juego pegado en esta oficina. Un armario no tiene opinión sobre su color.
static func mueble(cuerpo: Node3D, nombre: String, tam: Vector3, color: Color) -> bool:
	var pieza := _instanciar(cuerpo, nombre)
	if pieza == null:
		return false
	_encajar(pieza, tam)
	_pintar(pieza, color, String(MATERIALES_MUEBLE.get(nombre, "")))
	return true


## Una PERSONA: conserva lo suyo.
##
## Va por otro lado que un mueble a propósito, y la diferencia no es de
## comodidad:
##
## - **Llega ya con su estatura.** No se encaja en ninguna caja: la escala la
##   fija `nodes/root_scale` en su `.import`, que es donde Godot la espera. Antes
##   se calculaba aquí y salía mal, porque el AABB de una malla con esqueleto
##   describe la pose de reposo y no dónde acaban los vértices — este modelo
##   además trae el esqueleto con una escala de 69, así que las dos medidas ni
##   estaban en la misma escala y la figura se hundía 36 cm bajo la moqueta.
## - **Se tiñe de SU color**, el que declara cada compañero, no del de un bulto.
##   Este modelo viene sin ropa, así que el color es su ropa: dejarle el material
##   crudo lo deja blanco de maniquí. Si algún día hay figuras vestidas, es aquí
##   donde se deja de teñir, y solo aquí.
## - **Respira.** Un esqueleto sin animación no se queda de pie: se queda en la
##   pose con la que se modeló.
## - **Puede tener cara**, y cinco de estos la tienen de verdad.
static func persona(cuerpo: Node3D, nombre: String, color: Color, retrato: String = "") -> bool:
	var pieza := _instanciar(cuerpo, nombre)
	if pieza == null:
		return false
	if es_realista(nombre):
		# Un avatar vestido trae su piel, su pelo y su ropa: teñirlo o sustituir
		# su cara por un volumen procedural volvería a convertirlo en maniquí.
		# Los históricos reciben solo geometría secundaria reconocible —gafas,
		# barba, bigote, sombrero o sienes— anclada a Head.
		_adaptar_realista(pieza)
		if not retrato.is_empty():
			IDENTIDAD_ROCKETBOX.aplicar(pieza, retrato)
		AnimacionesUAL.preparar_base(pieza)
		_animar(pieza)
		return true
	_pintar(pieza, color)
	_animar(pieza)
	if not retrato.is_empty():
		_poner_cara(pieza, retrato)
	return true


## Si [param nombre] es un avatar fotorrealista de #275 y no el maniquí.
##
## Los avatares son Microsoft Rocketbox (MIT) convertidos a `.glb` con sus
## texturas, e importados con el `BoneMap` humanoide: su esqueleto ya habla el
## perfil de Godot y las animaciones UAL se le aplican sin traducir nombres.
static func es_realista(nombre: String) -> bool:
	return nombre.begins_with(CARPETA_REALISTAS)


## Pasa el avatar al material del sitio conservando su textura y sus UV, como
## hace `AssetCc0` con los assets. Con el material importado sería la única
## figura sin el tratamiento de la máquina y, en la oficina, sin la luz por
## píxel de #789: volvería a leerse como una silueta sin sombra.
##
## Las superficies recortadas por alfa (pestañas, pelo) conservan el suyo: el
## shader PSX no descarta píxeles y las pintaría como tarjetas opacas.
##
## El relieve del mapa de normales solo se ve con luz por píxel. En un sitio que
## la pide, las superficies que lo traen van a `psx_pbr` (#399), que conserva el
## temblor, el color cortado y el dithering y además lee el mapa. En el resto
## del mundo la luz se calcula por vértice y el mapa no aportaría nada.
static func _adaptar_realista(pieza: Node3D) -> void:
	var por_pixel := Espacio3D.shader_del_sitio() == Espacio3D.SHADER_PSX_LUZ_PIXEL
	for nodo in _mallas(pieza):
		var malla: MeshInstance3D = nodo
		var adaptados: Array[Material] = []
		for superficie in malla.mesh.get_surface_count():
			var original := malla.get_active_material(superficie) as BaseMaterial3D
			if original == null or original.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				continue
			var relieve := por_pixel and original.normal_enabled and original.normal_texture != null
			var material := ShaderMaterial.new()
			material.shader = load(
				TexturasPBR.SHADER_PBR if relieve else Espacio3D.shader_del_sitio()
			)
			material.set_shader_parameter("usar_uv", true)
			material.set_shader_parameter("color_base", original.albedo_color)
			if original.albedo_texture != null:
				material.set_shader_parameter("textura", original.albedo_texture)
				if not relieve:
					material.set_shader_parameter("con_textura", true)
			if relieve:
				material.set_shader_parameter("mapa_normal", original.normal_texture)
				material.set_shader_parameter("con_normal", true)
				material.set_shader_parameter("fuerza_normal", original.normal_scale)
				material.set_shader_parameter("especular", original.metallic_specular)
			malla.set_surface_override_material(superficie, material)
			adaptados.append(material)
		# La malla suelta sus materiales por superficie ANTES de que el servidor
		# libere su instancia, y con malla de sombra y LOD importadas el servidor
		# aún los consulta: «Parameter "material" is null» al liberar la figura,
		# también en GPU. Los metadatos se sueltan después, así que los retienen.
		malla.set_meta(&"materiales_adaptados", adaptados)


static func _instanciar(cuerpo: Node3D, nombre: String) -> Node3D:
	var escena := cargar(nombre)
	if escena == null:
		return null
	var pieza: Node3D = escena.instantiate()
	cuerpo.add_child(pieza)
	return pieza


## La escena del modelo, o nulo si no está. Cachea el recurso y NO la instancia:
## dos archivadores son dos nodos, no el mismo nodo en dos sitios.
static func cargar(nombre: String) -> PackedScene:
	if _cache.has(nombre):
		return _cache[nombre]
	var escena: PackedScene = null
	for formato in FORMATOS:
		var ruta := RUTA + nombre + formato
		if ResourceLoader.exists(ruta):
			escena = load(ruta)
			break
	if escena == null:
		push_warning("No hay modelo %s en %s" % [nombre, RUTA])
	_cache[nombre] = escena
	return escena


## Existe para las pruebas: el catálogo puede comprobar que todo `modelo` que
## nombra está de verdad en el árbol, sin montar una escena 3D para verlo.
static func hay(nombre: String) -> bool:
	for formato in FORMATOS:
		if ResourceLoader.exists(RUTA + nombre + formato):
			return true
	return false


## Que respiren.
##
## Estas figuras vienen con esqueleto, y un esqueleto SIN animación no se queda
## de pie: se queda en la pose de reposo con la que se modeló, brazos en cruz y
## rodillas rectas. Parece un maniquí caído, no un compañero de oficina — que es
## exactamente lo que se vio en la primera captura.
##
## `idle` está en los once modelos del pack. Se pone en bucle a mano porque el
## `.glb` no trae marcado el suyo: sin eso, cada uno respira una vez y se queda
## clavado en el último fotograma.
static func _animar(pieza: Node3D, cual: String = "idle") -> void:
	var reproductor := _reproductor(pieza)
	if reproductor == null:
		return

	# El nombre no es el mismo en todos los packs: uno la llama `idle` y otro
	# `CharacterArmature|Idle`, con el esqueleto por delante. Se busca por el
	# final y sin mayúsculas, que es lo único que comparten.
	var nombre := ""
	for candidata in reproductor.get_animation_list():
		if String(candidata).to_lower().ends_with(cual.to_lower()):
			nombre = candidata
			break
	if nombre.is_empty():
		return

	var animacion := reproductor.get_animation(nombre)
	animacion.loop_mode = Animation.LOOP_LINEAR
	# Cada uno por su sitio: once personas respirando al unísono son un coro, y
	# una oficina no lo es. El desfase sale del NOMBRE del modelo y no de
	# `randf()`: una partida se puede volver a ver (#147), y un sorteo sin raíz
	# haría que la misma vuelta no se repitiera igual. Además así cada compañero
	# respira siempre con su mismo compás.
	var desfase := float(absi(hash(pieza.name)) % 1000) / 1000.0
	reproductor.play(nombre)
	reproductor.seek(desfase * animacion.length, true)


## El reproductor de animaciones, esté donde esté: unos packs lo cuelgan de la
## raíz y otros lo meten bajo el nodo del modelo.
static func _reproductor(nodo: Node) -> AnimationPlayer:
	if nodo is AnimationPlayer:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _reproductor(hijo)
		if encontrado != null:
			return encontrado
	return null


## Integra una cara low-poly en el volumen de la cabeza.
##
## El primer corte de #275 ya eliminó el retrato 2D, pero dejó ojos, nariz y
## boca como piezas independientes por delante de la cabeza importada. El
## resultado seguía leyendo como una máscara pegada. Este segundo corte crea un
## volumen COMPLETO de cabeza con el material de piel y hunde los rasgos en la
## superficie elipsoidal. La cabeza y los rasgos comparten `BoneAttachment3D`,
## así que forman una sola silueta al girar y siguen el hueso `Head` al animar.
##
## `retrato` ya no se usa solo como semilla: cuando existe una entrada en
## `PERSONAJES_FACIALES`, añade geometría característica de esa persona sobre el
## mismo volumen. El fallback determinista se conserva para los compañeros que
## todavía no tienen su pase individual.


static func _poner_cara(pieza: Node3D, retrato: String) -> void:
	var esqueleto := _esqueleto(pieza)
	if esqueleto == null:
		return
	var hueso := esqueleto.find_bone("Head")
	if hueso < 0:
		return

	var enganche := BoneAttachment3D.new()
	enganche.bone_idx = hueso
	esqueleto.add_child(enganche)

	var alto := _alto_cabeza(esqueleto, hueso)
	var semilla := absi(hash(retrato))
	var perfil: Dictionary = PERFILES_FACIALES.get(retrato, {})
	var personaje := String(PERSONAJES_FACIALES.get(retrato, ""))
	var radio_x := alto * (0.34 + float(semilla % 5) * 0.008) * float(perfil.get("x", 1.0))
	var radio_y := alto * 0.50
	var radio_z := alto * (0.38 + float((semilla / 5) % 5) * 0.008) * float(perfil.get("z", 1.0))
	var centro_y := alto * 0.48
	var separacion := radio_x * (0.50 + float((semilla / 25) % 5) * 0.015)
	if personaje == "Puyi":
		# Sus retratos adultos se leen sobre todo por el rostro estrecho y las
		# gafas redondas. Acercamos ligeramente los ojos para que el armazón no
		# invada las sienes y siga integrado en la elipse.
		separacion = radio_x * 0.47
	elif personaje == "Herman Melville":
		# En los retratos de madurez la barba domina una cara relativamente larga;
		# dejamos los ojos algo más juntos para reservar volumen a las sienes y a
		# la masa de barba que envuelve la mandíbula.
		separacion = radio_x * 0.49
	elif personaje == "Fernando Pessoa":
		# Las gafas redondas son muy visibles y quedan mejor algo recogidas hacia
		# el puente, sin invadir las sienes bajo el ala del sombrero.
		separacion = radio_x * 0.48
	elif personaje == "Constantino Cavafis":
		# Las gafas quedan algo más abiertas sobre el rostro ancho de `riegos`.
		separacion = radio_x * 0.50
	var altura_ojos := centro_y + alto * 0.12

	var oscuro := Color(0.10, 0.08, 0.07)
	var piel: Color = perfil.get(
		"piel", Color(0.58, 0.43, 0.34).lerp(Color(0.82, 0.68, 0.54), float(semilla % 7) / 6.0)
	)
	var cabello: Color = perfil.get("cabello", oscuro)
	var barba: Color = perfil.get("barba", cabello)

	# La cabeza procedural envuelve el cráneo importado: no hay una placa frontal
	# que pueda verse de canto. Las pequeñas variaciones conservan el roster sin
	# recuperar fotografías ni materiales ajenos al shader común.
	_volumen_cabeza(enganche, Vector3(0.0, centro_y, 0.0), Vector3(radio_x, radio_y, radio_z), piel)
	# Una pieza superior sencilla distingue peinados y silueta sin convertir el
	# retrato en una textura plana. Puyi recibe una tapa algo más ceñida: el
	# mechón lateral específico se modela más abajo con el resto de sus rasgos.
	var pelo_y := centro_y + radio_y * 0.72
	var pelo_escala := Vector3(radio_x * 1.04, alto * 0.16, radio_z * 0.88)
	if personaje == "Puyi":
		pelo_y = centro_y + radio_y * 0.76
		pelo_escala = Vector3(radio_x * 0.99, alto * 0.13, radio_z * 0.84)
	elif personaje == "Herman Melville":
		# Frente alta y pelo retirado/peinado hacia atrás en los retratos de
		# madurez. Las sienes específicas completan la silueta más abajo.
		pelo_y = centro_y + radio_y * 0.82
		pelo_escala = Vector3(radio_x * 0.94, alto * 0.11, radio_z * 0.78)
	elif personaje == "Fernando Pessoa":
		# El sombrero tapa casi toda la coronilla; una tapa menor evita que el pelo
		# atraviese el ala y deja apenas lectura en sienes y nuca.
		pelo_y = centro_y + radio_y * 0.76
		pelo_escala = Vector3(radio_x * 0.90, alto * 0.09, radio_z * 0.76)
	elif personaje == "Constantino Cavafis":
		# Los retratos de madurez dejan una frente muy despejada: la tapa se reduce
		# casi a coronilla y `_rasgos_cavafis` recupera pelo solo en las sienes.
		pelo_y = centro_y + radio_y * 0.88
		pelo_escala = Vector3(radio_x * 0.92, alto * 0.055, radio_z * 0.55)
	_cabello_cabeza(enganche, Vector3(0.0, pelo_y, -radio_z * 0.04), pelo_escala, cabello)

	# Los centros de ojos y boca se colocan unos milímetros DENTRO de la
	# superficie del elipsoide. Solo asoma la parte necesaria del volumen, de
	# modo que a 3/4 no aparecen bolitas o barras flotando delante de la cara.
	var hundido := alto * 0.018
	var ojo_izq := Vector2(-separacion, altura_ojos)
	var ojo_der := Vector2(separacion, altura_ojos)
	var z_ojo_izq := (
		_frente_cabeza(ojo_izq.x, ojo_izq.y, centro_y, radio_x, radio_y, radio_z) - hundido
	)
	var z_ojo_der := (
		_frente_cabeza(ojo_der.x, ojo_der.y, centro_y, radio_x, radio_y, radio_z) - hundido
	)
	var escala_ojo := Vector3(alto * 0.050, alto * 0.040, alto * 0.025)
	if personaje == "Puyi":
		escala_ojo = Vector3(alto * 0.043, alto * 0.032, alto * 0.020)
	elif personaje == "Fernando Pessoa":
		escala_ojo = Vector3(alto * 0.041, alto * 0.032, alto * 0.020)
	elif personaje == "Constantino Cavafis":
		escala_ojo = Vector3(alto * 0.044, alto * 0.034, alto * 0.021)
	_rasgo_esfera(enganche, Vector3(ojo_izq.x, ojo_izq.y, z_ojo_izq), escala_ojo, oscuro)
	_rasgo_esfera(enganche, Vector3(ojo_der.x, ojo_der.y, z_ojo_der), escala_ojo, oscuro)

	if personaje == "Puyi":
		_rasgos_puyi(
			enganche,
			alto,
			centro_y,
			radio_x,
			radio_y,
			radio_z,
			separacion,
			altura_ojos,
			oscuro,
			cabello
		)
	elif personaje == "Herman Melville":
		_rasgos_melville(enganche, alto, centro_y, radio_x, radio_y, radio_z, cabello, barba)
	elif personaje == "Fernando Pessoa":
		_rasgos_pessoa(
			enganche, alto, centro_y, radio_x, radio_y, radio_z, separacion, altura_ojos, oscuro
		)
	elif personaje == "Constantino Cavafis":
		_rasgos_cavafis(
			enganche,
			alto,
			centro_y,
			radio_x,
			radio_y,
			radio_z,
			separacion,
			altura_ojos,
			oscuro,
			cabello
		)

	var nariz_y := centro_y - alto * 0.035
	var z_nariz := _frente_cabeza(0.0, nariz_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.015
	var nariz_escala := Vector3(alto * 0.050, alto * 0.105, alto * 0.060)
	if personaje == "Puyi":
		nariz_escala = Vector3(alto * 0.043, alto * 0.100, alto * 0.052)
	elif personaje == "Herman Melville":
		nariz_escala = Vector3(alto * 0.048, alto * 0.118, alto * 0.064)
	elif personaje == "Fernando Pessoa":
		nariz_escala = Vector3(alto * 0.043, alto * 0.116, alto * 0.055)
	elif personaje == "Constantino Cavafis":
		nariz_escala = Vector3(alto * 0.052, alto * 0.125, alto * 0.064)
	_rasgo_esfera(enganche, Vector3(0.0, nariz_y, z_nariz), nariz_escala, piel)

	var boca_y := centro_y - alto * 0.20
	var z_boca := _frente_cabeza(0.0, boca_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.010
	var ancho_boca := alto * (0.13 + float(semilla % 4) * 0.010)
	if personaje == "Puyi":
		ancho_boca = alto * 0.105
	elif personaje == "Herman Melville":
		ancho_boca = alto * 0.10
	elif personaje == "Fernando Pessoa":
		ancho_boca = alto * 0.095
	elif personaje == "Constantino Cavafis":
		ancho_boca = alto * 0.105
	_rasgo_esfera(
		enganche,
		Vector3(0.0, boca_y, z_boca),
		Vector3(ancho_boca, alto * 0.018, alto * 0.012),
		oscuro
	)


## Puyi no se distingue por un color distinto, sino por rasgos concretos.
##
## El armazón de las gafas es volumen real y se hunde levemente en el frente de
## la cabeza; por eso de perfil no aparece un plano atravesando la cara. El
## puente comparte la misma curvatura y el mechón frontal rompe la tapa de pelo
## genérica sin depender de una fotografía o textura externa.
static func _rasgos_puyi(
	padre: Node3D,
	alto: float,
	centro_y: float,
	radio_x: float,
	radio_y: float,
	radio_z: float,
	separacion: float,
	altura_ojos: float,
	oscuro: Color,
	cabello: Color
) -> void:
	var hundido_gafas := alto * 0.006
	var z_izq := (
		_frente_cabeza(-separacion, altura_ojos, centro_y, radio_x, radio_y, radio_z)
		- hundido_gafas
	)
	var z_der := (
		_frente_cabeza(separacion, altura_ojos, centro_y, radio_x, radio_y, radio_z) - hundido_gafas
	)
	var radio_gafa := alto * 0.080
	var grosor_gafa := alto * 0.012
	_aro_gafa(padre, Vector3(-separacion, altura_ojos, z_izq), radio_gafa, grosor_gafa, oscuro)
	_aro_gafa(padre, Vector3(separacion, altura_ojos, z_der), radio_gafa, grosor_gafa, oscuro)

	var z_puente := (
		_frente_cabeza(0.0, altura_ojos, centro_y, radio_x, radio_y, radio_z) - hundido_gafas
	)
	_rasgo_esfera(
		padre,
		Vector3(0.0, altura_ojos, z_puente),
		Vector3(separacion * 0.34, alto * 0.010, alto * 0.010),
		oscuro
	)

	# Cejas rectas y finas por encima del armazón; también quedan parcialmente
	# embebidas en el elipsoide para que el 3/4 siga leyendo como una sola cara.
	var ceja_y := altura_ojos + alto * 0.095
	for lado in [-1.0, 1.0]:
		var x_ceja: float = separacion * lado
		var z_ceja := (
			_frente_cabeza(x_ceja, ceja_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.012
		)
		_rasgo_esfera(
			padre,
			Vector3(x_ceja, ceja_y, z_ceja),
			Vector3(alto * 0.105, alto * 0.012, alto * 0.010),
			oscuro
		)

	# Raya/mechón lateral peinado hacia atrás, inspirado en los retratos adultos.
	# Son dos elipsoides pequeños sobre el mismo cráneo, no una lámina frontal.
	var mechon_y := centro_y + radio_y * 0.63
	var mechon_x := -radio_x * 0.26
	var z_mechon := (
		_frente_cabeza(mechon_x, mechon_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.035
	)
	_rasgo_esfera(
		padre,
		Vector3(mechon_x, mechon_y, z_mechon),
		Vector3(radio_x * 0.48, alto * 0.055, radio_z * 0.10),
		cabello
	)


## Melville se reconoce por la masa de barba y bigote, no por una textura.
##
## Las piezas se solapan dentro del elipsoide de cabeza para construir una
## mandíbula barbada continua a 3/4. Las sienes añaden el pelo peinado hacia
## atrás de sus retratos de madurez y dejan visible una frente alta.
static func _rasgos_melville(
	padre: Node3D,
	alto: float,
	centro_y: float,
	radio_x: float,
	radio_y: float,
	radio_z: float,
	cabello: Color,
	barba: Color
) -> void:
	var barba_y := centro_y - alto * 0.22
	var barba_x := radio_x * 0.23
	var z_barba_izq := (
		_frente_cabeza(-barba_x, barba_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.020
	)
	var z_barba_der := (
		_frente_cabeza(barba_x, barba_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.020
	)
	var escala_barba := Vector3(radio_x * 0.38, alto * 0.17, radio_z * 0.18)
	_rasgo_esfera(padre, Vector3(-barba_x, barba_y, z_barba_izq), escala_barba, barba)
	_rasgo_esfera(padre, Vector3(barba_x, barba_y, z_barba_der), escala_barba, barba)

	# Una tercera masa prolonga la barba por debajo de la mandíbula. Al compartir
	# volumen con las dos mejillas no queda un bloque suelto visto de perfil.
	var menton_y := centro_y - alto * 0.34
	var z_menton := (
		_frente_cabeza(0.0, menton_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.020
	)
	_rasgo_esfera(
		padre,
		Vector3(0.0, menton_y, z_menton),
		Vector3(radio_x * 0.62, alto * 0.22, radio_z * 0.20),
		barba
	)

	# Bigote partido: dos volúmenes pequeños que nacen bajo la nariz y se funden
	# con la barba. No se dibuja una raya frontal sobre la cara.
	var bigote_y := centro_y - alto * 0.13
	var bigote_x := alto * 0.050
	var z_bigote_izq := (
		_frente_cabeza(-bigote_x, bigote_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.008
	)
	var z_bigote_der := (
		_frente_cabeza(bigote_x, bigote_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.008
	)
	var escala_bigote := Vector3(alto * 0.095, alto * 0.028, alto * 0.034)
	_rasgo_esfera(padre, Vector3(-bigote_x, bigote_y, z_bigote_izq), escala_bigote, barba)
	_rasgo_esfera(padre, Vector3(bigote_x, bigote_y, z_bigote_der), escala_bigote, barba)

	# Dos masas laterales, estrechas y altas, continúan la tapa retirada hacia
	# atrás. Así la frente queda despejada sin que el pelo parezca un casco.
	var sien_y := centro_y + radio_y * 0.48
	var sien_x := radio_x * 0.56
	var z_sien_izq := (
		_frente_cabeza(-sien_x, sien_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.030
	)
	var z_sien_der := (
		_frente_cabeza(sien_x, sien_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.030
	)
	var escala_sien := Vector3(radio_x * 0.28, alto * 0.10, radio_z * 0.12)
	_rasgo_esfera(padre, Vector3(-sien_x, sien_y, z_sien_izq), escala_sien, cabello)
	_rasgo_esfera(padre, Vector3(sien_x, sien_y, z_sien_der), escala_sien, cabello)


## Pessoa conserva tres señales que sobreviven bien al low-poly: gafas redondas,
## bigote fino y sombrero oscuro de ala ancha. Todo es volumen real unido al
## hueso de cabeza; ninguna fotografía entra en materiales o texturas.
static func _rasgos_pessoa(
	padre: Node3D,
	alto: float,
	centro_y: float,
	radio_x: float,
	radio_y: float,
	radio_z: float,
	separacion: float,
	altura_ojos: float,
	oscuro: Color
) -> void:
	var hundido_gafas := alto * 0.006
	var z_izq := (
		_frente_cabeza(-separacion, altura_ojos, centro_y, radio_x, radio_y, radio_z)
		- hundido_gafas
	)
	var z_der := (
		_frente_cabeza(separacion, altura_ojos, centro_y, radio_x, radio_y, radio_z) - hundido_gafas
	)
	var radio_gafa := alto * 0.072
	var grosor_gafa := alto * 0.010
	_aro_gafa(padre, Vector3(-separacion, altura_ojos, z_izq), radio_gafa, grosor_gafa, oscuro)
	_aro_gafa(padre, Vector3(separacion, altura_ojos, z_der), radio_gafa, grosor_gafa, oscuro)

	var z_puente := (
		_frente_cabeza(0.0, altura_ojos, centro_y, radio_x, radio_y, radio_z) - hundido_gafas
	)
	_rasgo_esfera(
		padre,
		Vector3(0.0, altura_ojos, z_puente),
		Vector3(separacion * 0.30, alto * 0.009, alto * 0.009),
		oscuro
	)

	# Bigote corto y partido, colocado sobre la misma curvatura de la cara.
	var bigote_y := centro_y - alto * 0.135
	var bigote_x := alto * 0.043
	var z_bigote_izq := (
		_frente_cabeza(-bigote_x, bigote_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.008
	)
	var z_bigote_der := (
		_frente_cabeza(bigote_x, bigote_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.008
	)
	var escala_bigote := Vector3(alto * 0.080, alto * 0.022, alto * 0.025)
	_rasgo_esfera(padre, Vector3(-bigote_x, bigote_y, z_bigote_izq), escala_bigote, oscuro)
	_rasgo_esfera(padre, Vector3(bigote_x, bigote_y, z_bigote_der), escala_bigote, oscuro)

	# El ala es un cilindro muy bajo y la copa otro cilindro algo troncocónico.
	# Se solapan con la coronilla para que el sombrero siga la cabeza al animar.
	var ala := MeshInstance3D.new()
	var malla_ala := CylinderMesh.new()
	malla_ala.top_radius = radio_x * 1.58
	malla_ala.bottom_radius = radio_x * 1.58
	malla_ala.height = alto * 0.035
	malla_ala.radial_segments = 10
	ala.mesh = malla_ala
	ala.position = Vector3(0.0, centro_y + radio_y * 0.95, -radio_z * 0.02)
	ala.scale = Vector3(1.0, 1.0, 0.72)
	ala.material_override = _material_rasgo(oscuro)
	padre.add_child(ala)

	var copa := MeshInstance3D.new()
	var malla_copa := CylinderMesh.new()
	malla_copa.top_radius = radio_x * 0.68
	malla_copa.bottom_radius = radio_x * 0.80
	malla_copa.height = alto * 0.26
	malla_copa.radial_segments = 10
	copa.mesh = malla_copa
	copa.position = Vector3(0.0, centro_y + radio_y * 1.18, -radio_z * 0.04)
	copa.scale = Vector3(1.0, 1.0, 0.82)
	copa.material_override = _material_rasgo(oscuro)
	padre.add_child(copa)


## Cavafis se separa de Pessoa por una silueta más ancha y despejada: gafas
## redondas, bigote más amplio y pelo retirado que solo conserva masa lateral.
## Los rasgos siguen la curvatura del mismo elipsoide y el mismo hueso de cabeza.
static func _rasgos_cavafis(
	padre: Node3D,
	alto: float,
	centro_y: float,
	radio_x: float,
	radio_y: float,
	radio_z: float,
	separacion: float,
	altura_ojos: float,
	oscuro: Color,
	cabello: Color
) -> void:
	var hundido_gafas := alto * 0.007
	var z_izq := (
		_frente_cabeza(-separacion, altura_ojos, centro_y, radio_x, radio_y, radio_z)
		- hundido_gafas
	)
	var z_der := (
		_frente_cabeza(separacion, altura_ojos, centro_y, radio_x, radio_y, radio_z) - hundido_gafas
	)
	var radio_gafa := alto * 0.074
	var grosor_gafa := alto * 0.010
	_aro_gafa(padre, Vector3(-separacion, altura_ojos, z_izq), radio_gafa, grosor_gafa, oscuro)
	_aro_gafa(padre, Vector3(separacion, altura_ojos, z_der), radio_gafa, grosor_gafa, oscuro)

	var z_puente := (
		_frente_cabeza(0.0, altura_ojos, centro_y, radio_x, radio_y, radio_z) - hundido_gafas
	)
	_rasgo_esfera(
		padre,
		Vector3(0.0, altura_ojos, z_puente),
		Vector3(separacion * 0.31, alto * 0.009, alto * 0.009),
		oscuro
	)

	# Bigote ancho y algo más pesado que el de Pessoa, pero sin convertirse en
	# barba: dos volúmenes que siguen la curva bajo la nariz.
	var bigote_y := centro_y - alto * 0.13
	var bigote_x := alto * 0.055
	var z_bigote_izq := (
		_frente_cabeza(-bigote_x, bigote_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.008
	)
	var z_bigote_der := (
		_frente_cabeza(bigote_x, bigote_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.008
	)
	var escala_bigote := Vector3(alto * 0.102, alto * 0.027, alto * 0.030)
	_rasgo_esfera(padre, Vector3(-bigote_x, bigote_y, z_bigote_izq), escala_bigote, oscuro)
	_rasgo_esfera(padre, Vector3(bigote_x, bigote_y, z_bigote_der), escala_bigote, oscuro)

	# La coronilla queda casi limpia; dos masas laterales reconstruyen el pelo
	# retirado de los retratos sin volver a formar un casco sobre la frente.
	var sien_cabello_y := centro_y + radio_y * 0.46
	var sien_cabello_x := radio_x * 0.61
	var z_sien_izq := (
		_frente_cabeza(-sien_cabello_x, sien_cabello_y, centro_y, radio_x, radio_y, radio_z)
		- alto * 0.028
	)
	var z_sien_der := (
		_frente_cabeza(sien_cabello_x, sien_cabello_y, centro_y, radio_x, radio_y, radio_z)
		- alto * 0.028
	)
	var escala_sien := Vector3(radio_x * 0.22, alto * 0.13, radio_z * 0.14)
	_rasgo_esfera(padre, Vector3(-sien_cabello_x, sien_cabello_y, z_sien_izq), escala_sien, cabello)
	_rasgo_esfera(padre, Vector3(sien_cabello_x, sien_cabello_y, z_sien_der), escala_sien, cabello)


static func _aro_gafa(
	padre: Node3D, posicion: Vector3, radio: float, grosor: float, color: Color
) -> void:
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = maxf(radio * 0.2, radio - grosor)
	toro.outer_radius = radio
	toro.rings = 12
	toro.ring_segments = 4
	aro.mesh = toro
	aro.position = posicion
	# TorusMesh nace alrededor del eje Y; al girarlo, el hueco mira hacia el
	# frente Z de la misma superficie usada por `_frente_cabeza`.
	aro.rotation.x = PI / 2.0
	aro.material_override = _material_rasgo(color)
	padre.add_child(aro)


## Profundidad del frente de un elipsoide en un punto X/Y de la cara.
##
## En lugar de asumir que todo el rostro está en un mismo plano Z, cada rasgo
## sigue la curvatura real del volumen de cabeza. Fuera del elipsoide se devuelve
## 0 para que una proporción extrema nunca produzca NaN.
static func _frente_cabeza(
	x: float, y: float, centro_y: float, radio_x: float, radio_y: float, radio_z: float
) -> float:
	var nx := x / maxf(radio_x, 0.0001)
	var ny := (y - centro_y) / maxf(radio_y, 0.0001)
	var restante := maxf(0.0, 1.0 - nx * nx - ny * ny)
	return radio_z * sqrt(restante)


static func _alto_cabeza(esqueleto: Skeleton3D, hueso: int) -> float:
	var alto := 0.012
	var coronilla := esqueleto.find_bone("HeadTop_End")
	if coronilla < 0:
		return alto
	return maxf(
		absf(
			(
				esqueleto.get_bone_global_pose(coronilla).origin.y
				- esqueleto.get_bone_global_pose(hueso).origin.y
			)
		),
		alto
	)


static func _volumen_cabeza(
	padre: Node3D, posicion: Vector3, escala: Vector3, color: Color
) -> void:
	var cabeza := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = 8
	esfera.rings = 5
	cabeza.mesh = esfera
	cabeza.position = posicion
	cabeza.scale = escala
	cabeza.material_override = _material_rasgo(color)
	padre.add_child(cabeza)


static func _cabello_cabeza(
	padre: Node3D, posicion: Vector3, escala: Vector3, color: Color
) -> void:
	var cabello := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = 8
	esfera.rings = 4
	cabello.mesh = esfera
	cabello.position = posicion
	cabello.scale = escala
	cabello.material_override = _material_rasgo(color)
	padre.add_child(cabello)


static func _rasgo_esfera(padre: Node3D, posicion: Vector3, escala: Vector3, color: Color) -> void:
	var rasgo := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = 6
	esfera.rings = 4
	rasgo.mesh = esfera
	rasgo.position = posicion
	rasgo.scale = escala
	rasgo.material_override = _material_rasgo(color)
	padre.add_child(rasgo)


static func _material_rasgo(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.shader_del_sitio())
	material.set_shader_parameter("color_base", color)
	return material


## El esqueleto de una figura, si lo tiene.
static func _esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null


## Escala el modelo para que quepa en [param tam] y lo APOYA en el suelo.
##
## Se apoya en vez de centrarse porque las cosas descansan en el suelo: centrado
## por su caja, una silla más baja de lo declarado flotaría.
##
## La escala es **uniforme** y sale del eje que peor va: estirar una silla para
## llenar una caja que no tiene sus proporciones da una silla derretida, y la
## caja de un bulto es una medida de sitio ocupado, no un molde.
##
## Esto es para MUEBLES. Una persona no se encaja en nada: llega ya con su
## estatura desde la importación.
static func _encajar(pieza: Node3D, tam: Vector3) -> void:
	var caja := _limites(pieza)
	if caja.size.x <= 0.0 or caja.size.y <= 0.0 or caja.size.z <= 0.0:
		return

	var escala := minf(minf(tam.x / caja.size.x, tam.y / caja.size.y), tam.z / caja.size.z)
	pieza.scale = Vector3.ONE * escala

	# El centro del modelo no tiene por qué ser el de su malla, así que se
	# recoloca por sus límites REALES: primero se centra en horizontal y luego se
	# baja hasta que su base toque la del bulto.
	var centro := caja.get_center() * escala
	pieza.position = Vector3(-centro.x, -tam.y / 2.0 - caja.position.y * escala, -centro.z)


## Los límites de todo lo que cuelga de un nodo, en coordenadas del nodo. Godot
## da el AABB de UNA malla; un mueble suele ser varias.
static func _limites(nodo: Node3D) -> AABB:
	var total := AABB()
	var primero := true
	for hijo in _mallas(nodo):
		var malla: MeshInstance3D = hijo
		var caja: AABB = malla.get_aabb()
		# Del espacio de la malla al del nodo raíz, que es donde se encaja.
		var trans: Transform3D = nodo.global_transform.affine_inverse() * malla.global_transform
		caja = trans * caja
		if primero:
			total = caja
			primero = false
		else:
			total = total.merge(caja)
	return total


## Le pone a cada malla el material de la casa. El modelo aporta la forma y el
## proyecto aporta color + materia, para que un asset importado no vuelva a
## convertirse en una superficie plana de otro juego.
static func _pintar(nodo: Node3D, color: Color, textura: String = "") -> void:
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.shader_del_sitio())
	material.set_shader_parameter("color_base", color)
	if not textura.is_empty():
		var imagen := TexturaProcedural.por_nombre(textura, color, hash(textura))
		if imagen != null:
			material.set_shader_parameter("textura", imagen)
			material.set_shader_parameter("con_textura", true)
			material.set_shader_parameter(
				"escala_textura", float(ESCALAS_MATERIAL.get(textura, 1.0))
			)
	for hijo in _mallas(nodo):
		var malla: MeshInstance3D = hijo
		malla.material_override = material


static func _mallas(nodo: Node) -> Array:
	var encontradas := []
	if nodo is MeshInstance3D:
		encontradas.append(nodo)
	for hijo in nodo.get_children():
		encontradas.append_array(_mallas(hijo))
	return encontradas
