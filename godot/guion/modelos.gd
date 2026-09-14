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

## Lo que mide una persona, en metros. No lo decide este módulo: lo fija
## `nodes/root_scale` en el `.import` de la figura, y aquí se declara para que
## quien le cuelgue el nombre encima no tenga que medirlo a ojo. Si cambia allí,
## cambia aquí.
const ALTO_PERSONA := 1.75

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
	_pintar(pieza, color)
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
	_pintar(pieza, color)
	_animar(pieza)
	if not retrato.is_empty():
		_poner_cara(pieza, retrato)
	return true


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
## `retrato` no vuelve a cargarse como imagen: solo sirve de semilla estable
## para pequeñas diferencias de proporción y tono entre compañeros.
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
	var radio_x := alto * (0.34 + float(semilla % 5) * 0.008)
	var radio_y := alto * 0.50
	var radio_z := alto * (0.38 + float((semilla / 5) % 5) * 0.008)
	var centro_y := alto * 0.48
	var separacion := radio_x * (0.50 + float((semilla / 25) % 5) * 0.015)
	var altura_ojos := centro_y + alto * 0.12

	var oscuro := Color(0.10, 0.08, 0.07)
	var piel := Color(0.58, 0.43, 0.34).lerp(Color(0.82, 0.68, 0.54), float(semilla % 7) / 6.0)

	# La cabeza procedural envuelve el cráneo importado: no hay una placa frontal
	# que pueda verse de canto. Las pequeñas variaciones conservan el roster sin
	# recuperar fotografías ni materiales ajenos al shader común.
	_volumen_cabeza(
		enganche,
		Vector3(0.0, centro_y, 0.0),
		Vector3(radio_x, radio_y, radio_z),
		piel
	)

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
	_rasgo_esfera(
		enganche,
		Vector3(ojo_izq.x, ojo_izq.y, z_ojo_izq),
		Vector3(alto * 0.050, alto * 0.040, alto * 0.025),
		oscuro
	)
	_rasgo_esfera(
		enganche,
		Vector3(ojo_der.x, ojo_der.y, z_ojo_der),
		Vector3(alto * 0.050, alto * 0.040, alto * 0.025),
		oscuro
	)

	var nariz_y := centro_y - alto * 0.035
	var z_nariz := _frente_cabeza(0.0, nariz_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.015
	_rasgo_esfera(
		enganche,
		Vector3(0.0, nariz_y, z_nariz),
		Vector3(alto * 0.050, alto * 0.105, alto * 0.060),
		piel
	)

	var boca_y := centro_y - alto * 0.20
	var z_boca := _frente_cabeza(0.0, boca_y, centro_y, radio_x, radio_y, radio_z) - alto * 0.010
	_rasgo_esfera(
		enganche,
		Vector3(0.0, boca_y, z_boca),
		Vector3(alto * (0.13 + float(semilla % 4) * 0.010), alto * 0.018, alto * 0.012),
		oscuro
	)


## Profundidad del frente de un elipsoide en un punto X/Y de la cara.
##
## En lugar de asumir que todo el rostro está en un mismo plano Z, cada rasgo
## sigue la curvatura real del volumen de cabeza. Fuera del elipsoide se devuelve
## 0 para que una proporción extrema nunca produzca NaN.
static func _frente_cabeza(
	x: float,
	y: float,
	centro_y: float,
	radio_x: float,
	radio_y: float,
	radio_z: float
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
	material.shader = load(Espacio3D.SHADER_PSX)
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


## Le pone a cada malla el material de la casa. El modelo pone la forma y el
## catálogo el color, que es lo que evita que un mueble importado se vea como
## de otro juego.
static func _pintar(nodo: Node3D, color: Color) -> void:
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
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