## Materialización 3D de la capa simbólica del Juicio (#779).
##
## No decide qué Arcano o mito corresponde: eso es `JuicioSimbolico`. Aquí solo
## convierte esa selección en presencia física dentro de la arena. Todo es
## procedural salvo el frontal del Tarot, que reutiliza el arte canónico si está
## disponible y conserva un fallback geométrico si no lo está.
class_name JuicioSimbolico3D
extends RefCounted

const POS_ARCANO := Vector3(0.0, 2.0, -5.25)
const POS_MITO := Vector3(3.8, 0.0, -3.55)


static func montar(raiz: Node3D, arcano: Dictionary, mito_id: String) -> Node3D:
	var simbolos := Node3D.new()
	simbolos.name = "SimbolosJuicio"
	raiz.add_child(simbolos)
	if not arcano.is_empty():
		_montar_arcano(simbolos, arcano)
	if not mito_id.is_empty():
		_montar_mito(simbolos, mito_id)
	JuicioFeedbackRitual.montar(raiz)
	return simbolos


static func _montar_arcano(raiz: Node3D, arcano: Dictionary) -> void:
	var carta := Node3D.new()
	carta.name = "ArcanoRector"
	carta.position = POS_ARCANO
	carta.set_meta("arcano_id", String(arcano.get("id", "")))
	raiz.add_child(carta)

	var marco := _caja(Vector3(0.82, 1.34, 0.055), Color("2a2530"))
	marco.name = "Marco"
	carta.add_child(marco)

	var frente := MeshInstance3D.new()
	frente.name = "Frente"
	var plano := QuadMesh.new()
	plano.size = Vector2(0.72, 1.22)
	frente.mesh = plano
	frente.position.z = 0.031
	frente.material_override = _material_arcano(JuicioSimbolico.ruta_arcano(arcano))
	carta.add_child(frente)

	var luz := OmniLight3D.new()
	luz.name = "LuzArcano"
	luz.position = Vector3(0.0, 0.0, 0.45)
	luz.light_color = TarotCinematica.FRENTE
	luz.light_energy = 0.45
	luz.omni_range = 2.6
	carta.add_child(luz)


static func _montar_mito(raiz: Node3D, mito_id: String) -> void:
	var descriptor := JuicioSimbolico.descriptor_mito(mito_id)
	if descriptor.is_empty():
		return
	var mito := Node3D.new()
	mito.name = "EcoMitologico"
	var forma := String(descriptor["forma"])
	if forma == "laberinto":
		# El glifo necesita más superficie que los símbolos verticales para leerse
		# desde la cámara alta del Juicio, sin invadir el centro jugable.
		mito.position = Vector3(3.05, 0.0, -2.75)
		mito.scale = Vector3.ONE * 0.92
	else:
		mito.position = POS_MITO
		mito.scale = Vector3.ONE * 0.72
	mito.set_meta("mito_id", mito_id)
	var modulacion := MitologiasRuntime.modulacion_juicio(mito_id)
	if not modulacion.is_empty():
		mito.position.y += float(modulacion.get("desplazamiento_y", 0.0))
		mito.scale.y *= float(modulacion.get("escala_y", 1.0))
		var ejes = descriptor.get("ejes_acp", {})
		if typeof(ejes) == TYPE_DICTIONARY:
			mito.set_meta("acp_ejes", ejes.duplicate(true))
		mito.set_meta("tradicion", String(descriptor.get("tradicion", "")))
	raiz.add_child(mito)

	var color: Color = descriptor["color"]
	match forma:
		"puerta":
			_forma_puerta(mito, color)
		"laberinto":
			_forma_laberinto(mito, color)
		"escudo":
			_forma_escudo(mito, color)
		"hidra":
			_forma_hidra(mito, color)
		"serpiente":
			_forma_serpiente(mito, color)
		"balanza":
			_forma_balanza(mito, color)
		"ala":
			_forma_ala(mito, color)
		"arbol":
			_forma_arbol(mito, color)
		"piedras":
			_forma_piedras(mito, color)
		"montana":
			_forma_montana(mito, color)
		"telarana":
			_forma_telarana(mito, color)
		"sol":
			_forma_sol(mito, color)


static func _forma_puerta(raiz: Node3D, color: Color) -> void:
	var izquierda := _caja(Vector3(0.28, 2.2, 0.32), color, true)
	izquierda.position = Vector3(-0.75, 1.1, 0.0)
	raiz.add_child(izquierda)
	var derecha := _caja(Vector3(0.28, 2.2, 0.32), color, true)
	derecha.position = Vector3(0.75, 1.1, 0.0)
	raiz.add_child(derecha)
	var dintel := _caja(Vector3(1.8, 0.3, 0.36), color, true)
	dintel.position = Vector3(0.0, 2.15, 0.0)
	raiz.add_child(dintel)


static func _forma_laberinto(raiz: Node3D, color: Color) -> void:
	# Espiral ortogonal abierta: desde la cámara de juego debe leerse como
	# laberinto y no como un simple sello angular en el suelo.
	var puntos := [
		Vector3(-1.35, 0.07, 1.15),
		Vector3(1.35, 0.07, 1.15),
		Vector3(1.35, 0.07, -1.15),
		Vector3(-1.35, 0.07, -1.15),
		Vector3(-1.35, 0.07, 0.65),
		Vector3(0.85, 0.07, 0.65),
		Vector3(0.85, 0.07, -0.65),
		Vector3(-0.75, 0.07, -0.65),
		Vector3(-0.75, 0.07, 0.18),
		Vector3(0.35, 0.07, 0.18),
		Vector3(0.35, 0.07, -0.22),
	]
	for i in puntos.size() - 1:
		raiz.add_child(_segmento(puntos[i], puntos[i + 1], 0.11, color, true))
	var centro := _esfera(0.18, color.lightened(0.12), true)
	centro.position = puntos[-1]
	raiz.add_child(centro)


static func _forma_escudo(raiz: Node3D, color: Color) -> void:
	var disco := _cilindro(0.82, 0.1, color, true, 24)
	disco.position = Vector3(0.0, 1.15, 0.0)
	disco.rotation_degrees.x = 90.0
	raiz.add_child(disco)
	var ombligo := _esfera(0.22, color.lightened(0.18), true)
	ombligo.position = Vector3(0.0, 1.15, 0.08)
	raiz.add_child(ombligo)


static func _forma_hidra(raiz: Node3D, color: Color) -> void:
	var cuerpo := _esfera(0.48, color, false)
	cuerpo.position = Vector3(0.0, 0.48, 0.0)
	raiz.add_child(cuerpo)
	for i in 5:
		var x := -0.8 + float(i) * 0.4
		var cabeza := Vector3(x, 1.55 + 0.15 * float(i % 2), -0.12 * absf(x))
		raiz.add_child(_segmento(Vector3(0.0, 0.75, 0.0), cabeza, 0.11, color, false))
		var esfera := _esfera(0.2, color, true)
		esfera.position = cabeza
		raiz.add_child(esfera)


static func _forma_serpiente(raiz: Node3D, color: Color) -> void:
	var anterior := Vector3(-1.0, 0.5, 0.0)
	for i in 7:
		var t := float(i) / 6.0
		var actual := Vector3(-1.0 + 2.0 * t, 0.5 + sin(t * PI) * 1.15, sin(t * TAU) * 0.28)
		if i > 0:
			raiz.add_child(_segmento(anterior, actual, 0.14, color, true))
		var cuerpo := _esfera(0.18 if i < 6 else 0.28, color, i == 6)
		cuerpo.position = actual
		raiz.add_child(cuerpo)
		anterior = actual


static func _forma_balanza(raiz: Node3D, color: Color) -> void:
	var columna := _caja(Vector3(0.16, 2.0, 0.16), color, true)
	columna.position = Vector3(0.0, 1.0, 0.0)
	raiz.add_child(columna)
	raiz.add_child(_segmento(Vector3(-1.1, 1.85, 0.0), Vector3(1.1, 1.85, 0.0), 0.1, color, true))
	for x in [-0.9, 0.9]:
		var hilo := _caja(Vector3(0.05, 0.62, 0.05), color, false)
		hilo.position = Vector3(x, 1.48, 0.0)
		raiz.add_child(hilo)
		var plato := _cilindro(0.42, 0.07, color, true, 20)
		plato.position = Vector3(x, 1.14, 0.0)
		raiz.add_child(plato)


static func _forma_ala(raiz: Node3D, color: Color) -> void:
	for i in 6:
		var inicio := Vector3(-0.65, 0.45 + 0.18 * float(i), 0.0)
		var fin := Vector3(0.35 + 0.18 * float(i), 1.0 + 0.22 * float(i), -0.08 * float(i))
		raiz.add_child(_segmento(inicio, fin, 0.13, color, i >= 4))


static func _forma_arbol(raiz: Node3D, color: Color) -> void:
	var tronco := _caja(Vector3(0.32, 1.9, 0.32), color.darkened(0.18), false)
	tronco.position = Vector3(0.0, 0.95, 0.0)
	raiz.add_child(tronco)
	for fin in [Vector3(-0.9, 2.25, 0.0), Vector3(0.9, 2.15, 0.0), Vector3(0.0, 2.55, -0.35)]:
		raiz.add_child(_segmento(Vector3(0.0, 1.55, 0.0), fin, 0.14, color, false))
		var copa := _esfera(0.38, color, true)
		copa.position = fin
		raiz.add_child(copa)


static func _forma_piedras(raiz: Node3D, color: Color) -> void:
	for i in 3:
		var alto := 1.5 + 0.25 * float(i % 2)
		var piedra := _caja(Vector3(0.42, alto, 0.34), color, i == 1)
		piedra.position = Vector3(-0.7 + 0.7 * float(i), alto * 0.5, 0.0)
		piedra.rotation_degrees.y = -12.0 + 12.0 * float(i)
		raiz.add_child(piedra)


static func _forma_montana(raiz: Node3D, color: Color) -> void:
	var monte := MeshInstance3D.new()
	var cono := CylinderMesh.new()
	cono.top_radius = 0.08
	cono.bottom_radius = 1.05
	cono.height = 1.8
	cono.radial_segments = 7
	monte.mesh = cono
	monte.position = Vector3(0.0, 0.9, 0.0)
	monte.material_override = _material(color, false)
	raiz.add_child(monte)
	var nube := _esfera(0.38, color.lightened(0.15), true)
	nube.scale = Vector3(1.7, 0.6, 0.8)
	nube.position = Vector3(0.0, 2.15, 0.0)
	raiz.add_child(nube)


static func _forma_telarana(raiz: Node3D, color: Color) -> void:
	var centro := Vector3(0.0, 1.2, 0.0)
	var exterior: Array[Vector3] = []
	for i in 8:
		var angulo := TAU * float(i) / 8.0
		var punto := centro + Vector3(cos(angulo), sin(angulo), 0.0) * 1.05
		exterior.append(punto)
		raiz.add_child(_segmento(centro, punto, 0.035, color, true))
	for i in exterior.size():
		raiz.add_child(
			_segmento(exterior[i], exterior[(i + 1) % exterior.size()], 0.035, color, true)
		)


static func _forma_sol(raiz: Node3D, color: Color) -> void:
	var disco := _cilindro(0.62, 0.08, color, true, 24)
	disco.position = Vector3(0.0, 1.25, 0.0)
	disco.rotation_degrees.x = 90.0
	raiz.add_child(disco)
	var centro := Vector3(0.0, 1.25, 0.0)
	for i in 8:
		var angulo := TAU * float(i) / 8.0
		var inicio := centro + Vector3(cos(angulo), sin(angulo), 0.0) * 0.72
		var fin := centro + Vector3(cos(angulo), sin(angulo), 0.0) * 1.15
		raiz.add_child(_segmento(inicio, fin, 0.07, color, true))


static func _caja(tamano: Vector3, color: Color, emision: bool = false) -> MeshInstance3D:
	var instancia := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	instancia.mesh = malla
	instancia.material_override = _material(color, emision)
	return instancia


static func _cilindro(
	radio: float, alto: float, color: Color, emision: bool = false, segmentos: int = 16
) -> MeshInstance3D:
	var instancia := MeshInstance3D.new()
	var malla := CylinderMesh.new()
	malla.top_radius = radio
	malla.bottom_radius = radio
	malla.height = alto
	malla.radial_segments = segmentos
	instancia.mesh = malla
	instancia.material_override = _material(color, emision)
	return instancia


static func _esfera(radio: float, color: Color, emision: bool = false) -> MeshInstance3D:
	var instancia := MeshInstance3D.new()
	var malla := SphereMesh.new()
	malla.radius = radio
	malla.height = radio * 2.0
	instancia.mesh = malla
	instancia.material_override = _material(color, emision)
	return instancia


static func _segmento(
	desde: Vector3, hasta: Vector3, grosor: float, color: Color, emision: bool = false
) -> MeshInstance3D:
	var instancia := _caja(Vector3(grosor, grosor, desde.distance_to(hasta)), color, emision)
	instancia.position = (desde + hasta) * 0.5
	instancia.basis = Basis.looking_at(hasta - desde, Vector3.UP)
	return instancia


static func _material(color: Color, emision: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	if emision:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.75
	return material


static func _material_arcano(ruta: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = TarotCinematica.FRENTE
	material.roughness = 0.5
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not ruta.is_empty() and ResourceLoader.exists(ruta):
		material.albedo_texture = load(ruta)
	return material
