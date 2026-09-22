## Reparto de animación ambiental (#1230): presupuesto, LOD, atención y despertar.
extends RefCounted


## Anota lo que le llega en vez de moverse. Lo que se comprueba aquí es el
## reparto, no lo que cada consumidor haga con él.
class PiezaEspia:
	extends RefCounted

	var avisos: Array[Dictionary] = []

	func animar_pieza(id: String, tiempo: float, transcurrido: float, lod: String) -> void:
		avisos.append({"id": id, "tiempo": tiempo, "transcurrido": transcurrido, "lod": lod})


static func todo(comprobar: Callable) -> void:
	_planificador(comprobar)
	_presupuesto(comprobar)
	_desfase(comprobar)
	_animador(comprobar)
	_despertar(comprobar)
	_ventanas(comprobar)
	_viento(comprobar)
	_respiracion(comprobar)


static func _planificador(comprobar: Callable) -> void:
	var observador := {"posicion": Vector3.ZERO, "mirada": Vector3.FORWARD}
	var piezas := [
		_pieza("cerca", Vector3(0.0, 0.0, -8.0)),
		_pieza("media", Vector3(0.0, 0.0, -28.0)),
		_pieza("lejos", Vector3(0.0, 0.0, -60.0)),
		_pieza("fuera_de_alcance", Vector3(0.0, 0.0, -400.0)),
		_pieza("a_la_espalda", Vector3(0.0, 0.0, 30.0)),
		_pieza("detras_pero_cerca", Vector3(0.0, 0.0, 3.0)),
		_pieza("tenaz", Vector3(0.0, 0.0, 30.0), AnimacionAmbiental.PRIORIDAD_TENAZ),
	]
	var reparto := AnimacionAmbiental.planificar(piezas, observador)
	var por_id := _por_id(reparto)

	comprobar.call(
		"el reparto devuelve una entrada por pieza registrada",
		reparto.size() == piezas.size(),
		true
	)
	comprobar.call(
		"lo que está delante y a ocho metros se anima con todo el detalle",
		String(por_id["cerca"]["lod"]) == AnimacionAmbiental.LOD_CERCA,
		true
	)
	comprobar.call(
		"el detalle cercano se refresca en cada tick",
		is_equal_approx(float(por_id["cerca"]["periodo"]), AnimacionAmbiental.PERIODO_CERCA),
		true
	)
	comprobar.call(
		"a media distancia el detalle baja un escalón",
		String(por_id["media"]["lod"]) == AnimacionAmbiental.LOD_MEDIA,
		true
	)
	comprobar.call(
		"el escalón medio espacia el refresco",
		is_equal_approx(float(por_id["media"]["periodo"]), AnimacionAmbiental.PERIODO_MEDIA),
		true
	)
	comprobar.call(
		"lo lejano sigue vivo, pero a ritmo lento",
		String(por_id["lejos"]["lod"]) == AnimacionAmbiental.LOD_LEJOS,
		true
	)
	comprobar.call(
		"más allá del alcance de la niebla no se anima nada",
		not bool(por_id["fuera_de_alcance"]["activa"]),
		true
	)
	comprobar.call(
		"lo que queda fuera del cono de atención se duerme",
		not bool(por_id["a_la_espalda"]["activa"]),
		true
	)
	comprobar.call(
		"a tres metros se anima aunque quede a la espalda: se nota si se para",
		bool(por_id["detras_pero_cerca"]["activa"]),
		true
	)
	comprobar.call(
		"una pieza tenaz no se duerme por darle la espalda", bool(por_id["tenaz"]["activa"]), true
	)

	var repetido := AnimacionAmbiental.planificar(piezas, observador)
	comprobar.call(
		"el reparto es determinista para las mismas entradas",
		_firma(repetido) == _firma(reparto),
		true
	)


static func _presupuesto(comprobar: Callable) -> void:
	var observador := {"posicion": Vector3.ZERO, "mirada": Vector3.FORWARD}
	var piezas := [
		_pieza("tercera", Vector3(0.0, 0.0, -12.0)),
		_pieza("primera", Vector3(0.0, 0.0, -4.0)),
		_pieza("segunda", Vector3(0.0, 0.0, -8.0)),
	]
	var reparto := _por_id(AnimacionAmbiental.planificar(piezas, observador, 2))
	comprobar.call(
		"con cupo corto ganan las piezas más cercanas",
		bool(reparto["primera"]["activa"]) and bool(reparto["segunda"]["activa"]),
		true
	)
	comprobar.call(
		"la pieza que no cabe en el presupuesto se duerme aunque esté a la vista",
		not bool(reparto["tercera"]["activa"]),
		true
	)
	comprobar.call(
		"dormir por presupuesto deja el mismo LOD que dormir por distancia",
		String(reparto["tercera"]["lod"]) == AnimacionAmbiental.LOD_DORMIDA,
		true
	)

	var con_prioridad := [
		_pieza("humilde", Vector3(0.0, 0.0, -4.0)),
		_pieza("importante", Vector3(0.0, 0.0, -30.0), AnimacionAmbiental.PRIORIDAD_TENAZ),
	]
	var elegido := _por_id(AnimacionAmbiental.planificar(con_prioridad, observador, 1))
	comprobar.call(
		"la prioridad se impone a la cercanía cuando hay que recortar",
		bool(elegido["importante"]["activa"]) and not bool(elegido["humilde"]["activa"]),
		true
	)

	var vacio := _por_id(AnimacionAmbiental.planificar(con_prioridad, observador, 0))
	comprobar.call(
		"con cupo cero no se anima nada: es la palanca de emergencia",
		not bool(vacio["importante"]["activa"]) and not bool(vacio["humilde"]["activa"]),
		true
	)


static func _desfase(comprobar: Callable) -> void:
	var uno := AnimacionAmbiental.desfase("Ventana0_3", 7)
	var otro := AnimacionAmbiental.desfase("Ventana0_4", 7)
	comprobar.call(
		"el desfase de una pieza cae dentro de su ciclo",
		uno >= 0.0 and uno < 1.0 and otro >= 0.0 and otro < 1.0,
		true
	)
	comprobar.call(
		"dos piezas distintas no arrancan el ciclo a la vez", not is_equal_approx(uno, otro), true
	)
	comprobar.call(
		"el desfase no depende del reloj: misma semilla, mismo barrio",
		is_equal_approx(uno, AnimacionAmbiental.desfase("Ventana0_3", 7)),
		true
	)
	comprobar.call(
		"otra semilla reparte otros desfases",
		not is_equal_approx(uno, AnimacionAmbiental.desfase("Ventana0_3", 8)),
		true
	)


static func _animador(comprobar: Callable) -> void:
	var animador := AnimadorAmbiental3D.new()
	var espia := PiezaEspia.new()
	animador.observar_desde(Vector3.ZERO, Vector3.FORWARD)
	animador.registrar("delante", espia, Vector3(0.0, 0.0, -5.0))
	animador.registrar("lenta", espia, Vector3(0.0, 0.0, -28.0))

	animador.avanzar(0.3)
	comprobar.call(
		"el primer reparto avisa a las dos piezas a la vista", espia.avisos.size() == 2, true
	)

	espia.avisos.clear()
	for tick in 4:
		animador.avanzar(0.05)
	var cercanas := _avisos_de(espia, "delante")
	var lentas := _avisos_de(espia, "lenta")
	comprobar.call("la pieza cercana se refresca en todos los ticks", cercanas.size() == 4, true)
	comprobar.call(
		"la pieza a media distancia se refresca menos veces", lentas.size() < cercanas.size(), true
	)
	comprobar.call(
		"la pieza recibe el tiempo acumulado, no el delta del fotograma",
		float(cercanas[-1]["tiempo"]) > float(cercanas[0]["tiempo"]),
		true
	)

	var estado: Dictionary = animador.estado()
	comprobar.call("el animador conoce sus piezas", int(estado["piezas"]) == 2, true)
	comprobar.call(
		"ambas piezas están despiertas mirando hacia ellas", int(estado["activas"]) == 2, true
	)

	animador.fijar_presupuesto(0)
	espia.avisos.clear()
	animador.avanzar(0.3)
	comprobar.call("con el cupo a cero el animador deja de avisar", espia.avisos.is_empty(), true)

	animador.fijar_presupuesto(AnimacionAmbiental.PRESUPUESTO)
	animador.olvidar("lenta")
	espia.avisos.clear()
	animador.avanzar(0.3)
	comprobar.call(
		"una pieza olvidada deja de recibir avisos", _avisos_de(espia, "lenta").is_empty(), true
	)
	comprobar.call(
		"olvidar una pieza no descoloca el registro de las demás",
		not _avisos_de(espia, "delante").is_empty(),
		true
	)

	animador.limpiar()
	espia.avisos.clear()
	animador.avanzar(0.3)
	comprobar.call(
		"al limpiar el registro no queda nadie a quien avisar", espia.avisos.is_empty(), true
	)
	comprobar.call(
		"limpiar deja el animador sin piezas registradas",
		int(animador.estado()["piezas"]) == 0,
		true
	)
	animador.free()


static func _despertar(comprobar: Callable) -> void:
	var animador := AnimadorAmbiental3D.new()
	var espia := PiezaEspia.new()
	animador.observar_desde(Vector3.ZERO, Vector3.FORWARD)
	animador.registrar("a_la_espalda", espia, Vector3(0.0, 0.0, 30.0))

	animador.avanzar(0.3)
	comprobar.call(
		"mirando al lado contrario la pieza no gasta ni un aviso", espia.avisos.is_empty(), true
	)
	comprobar.call(
		"el animador sabe decir que esa pieza está dormida",
		animador.lod_de("a_la_espalda") == AnimacionAmbiental.LOD_DORMIDA,
		true
	)

	for tick in 20:
		animador.avanzar(1.0)
	comprobar.call(
		"veinte segundos de espalda siguen sin costar nada", espia.avisos.is_empty(), true
	)

	animador.observar_desde(Vector3.ZERO, Vector3.BACK)
	animador.avanzar(0.3)
	comprobar.call("al volverse, la pieza dormida despierta", espia.avisos.size() == 1, true)
	var aviso := espia.avisos[0] as Dictionary
	comprobar.call(
		"la pieza despierta sabiendo cuánto tiempo estuvo dormida, para ponerse al día",
		float(aviso["transcurrido"]) > 20.0,
		true
	)
	comprobar.call(
		"el tiempo acumulado no se detiene mientras la pieza duerme",
		is_equal_approx(float(aviso["tiempo"]), float(aviso["transcurrido"])),
		true
	)
	animador.free()


## Las ventanas de la calle: el ciclo es una función del tiempo, y eso se puede
## leer sin montar el barrio entero.
static func _ventanas(comprobar: Callable) -> void:
	var ventanas := CalleVentanasVivas.new()

	var estados := {}
	for paso in 40:
		estados[ventanas.estado_de_paso(3, paso)] = true
	comprobar.call(
		"una ventana recorre varios estados a lo largo de la noche", estados.size() >= 3, true
	)
	for estado in estados:
		comprobar.call(
			"el estado %s tiene color declarado" % estado,
			CalleVentanasVivas.COLORES.has(estado),
			true
		)
	var otra := CalleVentanasVivas.new()
	comprobar.call(
		"dos montajes distintos cuentan la misma noche",
		_secuencia(otra, 3) == _secuencia(ventanas, 3),
		true
	)
	comprobar.call(
		"dos ventanas no cuentan la misma noche",
		_secuencia(ventanas, 3) != _secuencia(ventanas, 4),
		true
	)
	otra.free()

	var arranque := ventanas.estado_en(0, 0.0, true)
	comprobar.call(
		"el dato de instancia lleva el color de la habitación",
		arranque.r >= 0.0 and arranque.g >= 0.0 and arranque.b >= 0.0,
		true
	)
	comprobar.call(
		"el alfa del dato dice si esa luz tiembla", arranque.a == 0.0 or arranque.a == 1.0, true
	)
	var colores := {}
	for salto in 8:
		colores[ventanas.estado_en(0, CalleVentanasVivas.CICLO * float(salto), true).to_html()] = true
	comprobar.call(
		"a lo largo de la noche esa ventana enciende más de una luz", colores.size() > 1, true
	)
	comprobar.call(
		"sin la calle montada no hay lote que animar", ventanas.ventanas_animadas() == 0, true
	)
	ventanas.free()


## El viento adopta follaje que todavía no estaba puesto al montarse.
static func _viento(comprobar: Callable) -> void:
	var sitio := Node3D.new()
	var animador := AnimadorAmbiental3D.new()
	animador.observar_desde(Vector3.ZERO, Vector3.FORWARD)

	var viento := VientoAmbiental.new()
	comprobar.call("sin follaje no hay nada que mecer", viento.adoptar(sitio, animador) == 0, true)

	var arbol := _superficie(Vector3(1.0, 6.0, 1.0))
	arbol.add_to_group(VientoAmbiental.GRUPO_FOLLAJE)
	sitio.add_child(arbol)
	animador.avanzar(0.3)
	comprobar.call(
		"el viento vuelve a mirar y encuentra el árbol que llegó tarde",
		viento.materiales() == 1,
		true
	)
	comprobar.call(
		"el follaje adoptado se mece de verdad",
		float(arbol.material_override.get_shader_parameter(VientoAmbiental.PARAMETRO_FUERZA)) > 0.0,
		true
	)

	var sereno := viento.fuerza_actual()
	viento.fijar_clima("lluvia")
	comprobar.call("con lluvia el follaje se mueve más", viento.fuerza_actual() > sereno, true)
	viento.fijar_clima("niebla")
	comprobar.call("la niebla es aire quieto", viento.fuerza_actual() < sereno, true)

	viento.free()
	animador.free()
	sitio.free()


## La respiración del sueño: qué adopta, qué deja en paz y cómo se suelta.
static func _respiracion(comprobar: Callable) -> void:
	var sala := Node3D.new()
	var muro := _superficie(Vector3(6.0, 3.0, 0.2))
	var suelo := _superficie(Vector3(6.0, 0.2, 6.0))
	sala.add_child(muro)
	sala.add_child(suelo)

	var respiracion := SuenoRespiracion.new()
	var adoptados := respiracion.adoptar(sala, null)
	comprobar.call("la respiración adopta los muros de la sala", adoptados == 1, true)
	comprobar.call(
		"el suelo no respira: un suelo que sube y baja es un mareo",
		suelo.material_override.get_shader_parameter(SuenoRespiracion.PARAMETRO_FUERZA) == null,
		true
	)

	var inicial: float = muro.material_override.get_shader_parameter(
		SuenoRespiracion.PARAMETRO_FUERZA
	)
	comprobar.call("al entrar la sala apenas respira", inicial < SuenoRespiracion.AMPLITUD, true)

	respiracion.animar_pieza("x", SuenoRespiracion.ASENTAMIENTO * 2.0, 1.0, "cerca")
	var asentada: float = muro.material_override.get_shader_parameter(
		SuenoRespiracion.PARAMETRO_FUERZA
	)
	comprobar.call("quedarse en la sala la hace respirar más hondo", asentada > inicial, true)
	comprobar.call(
		"la respiración no pasa de su amplitud declarada",
		asentada <= SuenoRespiracion.AMPLITUD + 0.0001,
		true
	)

	respiracion.fijar_intensidad(0.0)
	respiracion.animar_pieza("x", SuenoRespiracion.ASENTAMIENTO * 2.0, 1.0, "cerca")
	comprobar.call(
		"una noche sin intensidad deja la sala quieta",
		is_zero_approx(
			muro.material_override.get_shader_parameter(SuenoRespiracion.PARAMETRO_FUERZA)
		),
		true
	)

	respiracion.fijar_intensidad(1.0)
	respiracion.animar_pieza("x", 10.0, 1.0, "cerca")
	respiracion.soltar()
	comprobar.call(
		"soltar devuelve la sala a su forma exacta",
		is_zero_approx(
			muro.material_override.get_shader_parameter(SuenoRespiracion.PARAMETRO_FUERZA)
		),
		true
	)
	respiracion.free()
	sala.free()


static func _superficie(tam: Vector3) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	malla.material_override = material
	return malla


static func _secuencia(ventanas: CalleVentanasVivas, indice: int) -> String:
	var pasos: Array[String] = []
	for paso in 12:
		pasos.append(ventanas.estado_de_paso(indice, paso))
	return "|".join(pasos)


static func _mismo_color(uno: Color, otro: Color) -> bool:
	return is_equal_approx(uno.r, otro.r) and is_equal_approx(uno.b, otro.b)


static func _pieza(id: String, posicion: Vector3, prioridad: int = 1) -> Dictionary:
	return {"id": id, "posicion": posicion, "prioridad": prioridad}


static func _por_id(reparto: Array) -> Dictionary:
	var indexado := {}
	for entrada in reparto:
		indexado[String((entrada as Dictionary)["id"])] = entrada
	return indexado


static func _firma(reparto: Array) -> String:
	var partes: Array[String] = []
	for entrada in reparto:
		var dato := entrada as Dictionary
		partes.append("%s:%s" % [String(dato["id"]), String(dato["lod"])])
	return "|".join(partes)


static func _avisos_de(espia: PiezaEspia, id: String) -> Array[Dictionary]:
	var propios: Array[Dictionary] = []
	for aviso in espia.avisos:
		if String(aviso["id"]) == id:
			propios.append(aviso)
	return propios
