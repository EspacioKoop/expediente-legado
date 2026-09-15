## Vestuario visual de las escaleras de #135.
##
## Capa exclusivamente artística: no crea colisiones, no mueve al jugador y no
## tiene autoridad sobre Jornada. Mantiene la geometría funcional como fuente
## de verdad y la viste con materiales PBR, señalética, barandillas y utilería.
extends Node3D

const MAT_PARED: Material = preload("res://arte/escaleras_135/materiales/hormigon_pintado.tres")
const MAT_TERRAZO: Material = preload("res://arte/escaleras_135/materiales/terrazo.tres")
const MAT_METAL: Material = preload("res://arte/escaleras_135/materiales/metal_pintado.tres")
const MAT_GOMA: Material = preload("res://arte/escaleras_135/materiales/goma_negra.tres")

const SENAL_4: Texture2D = preload("res://arte/escaleras_135/senaletica/planta_4.svg")
const SENAL_3: Texture2D = preload("res://arte/escaleras_135/senaletica/planta_3.svg")
const SENAL_2: Texture2D = preload("res://arte/escaleras_135/senaletica/planta_2.svg")
const SENAL_1: Texture2D = preload("res://arte/escaleras_135/senaletica/planta_1.svg")
const SENAL_PB: Texture2D = preload("res://arte/escaleras_135/senaletica/planta_pb.svg")
const SENAL_SALIDA: Texture2D = preload("res://arte/escaleras_135/senaletica/salida.svg")
const SENAL_INCENDIO: Texture2D = preload("res://arte/escaleras_135/senaletica/no_ascensor_incendio.svg")

const ANCHO_TRAMO := 2.15
const PUNTOS := [
	Vector3(0.0, 2.4, 3.0),
	Vector3(0.0, 1.2, -3.0),
	Vector3(3.0, 1.2, -3.0),
	Vector3(3.0, 0.0, 3.0),
	Vector3(0.0, 0.0, 3.0),
	Vector3(0.0, -1.2, -3.0),
	Vector3(3.0, -1.2, -3.0),
	Vector3(3.0, -2.4, 3.0),
	Vector3(3.0, -2.4, 5.0),
]


func _ready() -> void:
	_vestir_geometria_base()
	_ajustar_luz_base()
	_montar_barandillas()
	_montar_narices_peldanos()
	_montar_rellanos()
	_montar_senaletica()
	_montar_luces_ambiente()


func _vestir_geometria_base() -> void:
	var raiz := get_parent()
	if raiz == null:
		return
	for hijo in raiz.get_children():
		if not hijo is MeshInstance3D:
			continue
		var malla := hijo as MeshInstance3D
		var nombre := String(malla.name)
		if nombre.begins_with("Muro"):
			malla.material_override = MAT_PARED
		elif nombre.contains("_Escalon"):
			malla.material_override = MAT_TERRAZO
		elif nombre.begins_with("Rellano"):
			malla.material_override = MAT_TERRAZO
		elif nombre.begins_with("Portal"):
			malla.material_override = MAT_METAL


func _ajustar_luz_base() -> void:
	var raiz := get_parent()
	if raiz == null:
		return
	var direccional := raiz.get_node_or_null("LuzEscalera") as DirectionalLight3D
	if direccional != null:
		direccional.light_color = Color("c9d0cc")
		direccional.light_energy = 0.42
		direccional.shadow_enabled = true
	var portal := raiz.get_node_or_null("LuzPortal") as OmniLight3D
	if portal != null:
		portal.light_color = Color("f0c98b")
		portal.light_energy = 1.05
		portal.shadow_enabled = true


func _montar_barandillas() -> void:
	for i in PUNTOS.size() - 1:
		var desde: Vector3 = PUNTOS[i]
		var hasta: Vector3 = PUNTOS[i + 1]
		if is_equal_approx(desde.y, hasta.y):
			continue
		var horizontal := Vector3(hasta.x - desde.x, 0.0, hasta.z - desde.z)
		var direccion := horizontal.normalized()
		var lateral := Vector3(-direccion.z, 0.0, direccion.x) * (ANCHO_TRAMO * 0.53)
		for signo in [-1.0, 1.0]:
			var lado := lateral * signo
			var inicio := desde + lado + Vector3.UP * 0.52
			var fin := hasta + lado + Vector3.UP * 0.52
			_barra_entre("Pasamanos_%d_%s" % [i, "A" if signo < 0.0 else "B"], inicio, fin, 0.055, MAT_METAL)
			for poste in 4:
				var t := float(poste) / 3.0
				var base := desde.lerp(hasta, t) + lado
				_caja("Poste_%d_%d_%s" % [i, poste, "A" if signo < 0.0 else "B"], base + Vector3.UP * 0.27, Vector3(0.045, 0.54, 0.045), MAT_METAL)
				if poste < 3:
					var t2 := (float(poste) + 0.5) / 3.0
					var centro := desde.lerp(hasta, t2) + lado + Vector3.UP * 0.28
					_caja("Barrote_%d_%d_%s" % [i, poste, "A" if signo < 0.0 else "B"], centro, Vector3(0.035, 0.50, 0.035), MAT_METAL)
			_barra_entre("Grip_%d_%s" % [i, "A" if signo < 0.0 else "B"], inicio + Vector3.UP * 0.035, fin + Vector3.UP * 0.035, 0.028, MAT_GOMA)


func _montar_narices_peldanos() -> void:
	for i in PUNTOS.size() - 1:
		var desde: Vector3 = PUNTOS[i]
		var hasta: Vector3 = PUNTOS[i + 1]
		if is_equal_approx(desde.y, hasta.y):
			continue
		var horizontal := Vector3(hasta.x - desde.x, 0.0, hasta.z - desde.z)
		var por_x := absf(horizontal.x) > absf(horizontal.z)
		for escalon in 12:
			var t := (float(escalon) + 0.5) / 12.0
			var posicion := desde.lerp(hasta, t)
			var tamano := Vector3(0.065, 0.018, ANCHO_TRAMO * 0.96) if por_x else Vector3(ANCHO_TRAMO * 0.96, 0.018, 0.065)
			_caja("Nosing_%d_%02d" % [i, escalon], posicion - Vector3(0.0, 0.012, 0.0), tamano, MAT_GOMA)


func _montar_rellanos() -> void:
	var plantas := [
		{"y": 2.4, "z": 2.25},
		{"y": 1.2, "z": -2.20},
		{"y": 0.0, "z": 2.20},
		{"y": -1.2, "z": -2.20},
	]
	for i in plantas.size():
		var p: Dictionary = plantas[i]
		var suelo := float(p["y"])
		var z := float(p["z"])
		_puerta_cortafuegos("Puerta_%d" % i, Vector3(4.20, suelo + 0.43, z))
		_luz_emergencia("Emergencia_%d" % i, Vector3(4.10, suelo + 0.91, z))
		if i % 2 == 0:
			_radiador("Radiador_%d" % i, Vector3(-1.20, suelo + 0.25, z - 0.65))
		else:
			_cuadro_electrico("Cuadro_%d" % i, Vector3(-1.20, suelo + 0.42, z - 0.62))
		_extintor("Extintor_%d" % i, Vector3(-1.18, suelo + 0.30, z + 0.63))

	_puerta_cortafuegos("PuertaPortal", Vector3(4.20, -1.97, 4.55))
	_luz_emergencia("EmergenciaPortal", Vector3(3.85, -1.43, 4.62))


func _montar_senaletica() -> void:
	_senal_pared("Planta4", SENAL_4, Vector3(-1.205, 3.03, 2.60), Vector3(0.0, 90.0, 0.0), 0.00082)
	_senal_pared("Planta3", SENAL_3, Vector3(-1.205, 1.83, -2.55), Vector3(0.0, 90.0, 0.0), 0.00082)
	_senal_pared("Planta2", SENAL_2, Vector3(-1.205, 0.63, 2.55), Vector3(0.0, 90.0, 0.0), 0.00082)
	_senal_pared("Planta1", SENAL_1, Vector3(-1.205, -0.57, -2.55), Vector3(0.0, 90.0, 0.0), 0.00082)
	_senal_pared("PlantaPB", SENAL_PB, Vector3(4.205, -1.77, 3.65), Vector3(0.0, -90.0, 0.0), 0.00082)
	_senal_pared("Salida", SENAL_SALIDA, Vector3(3.0, -1.22, 5.18), Vector3(0.0, 180.0, 0.0), 0.00105)
	_senal_pared("Incendio", SENAL_INCENDIO, Vector3(4.205, 2.83, 1.52), Vector3(0.0, -90.0, 0.0), 0.00062)


func _montar_luces_ambiente() -> void:
	var puntos := [
		Vector3(1.5, 3.05, 0.2),
		Vector3(1.5, 1.85, -1.6),
		Vector3(1.5, 0.65, 1.5),
		Vector3(1.5, -0.55, -1.5),
		Vector3(3.0, -1.70, 4.10),
	]
	for i in puntos.size():
		var luz := OmniLight3D.new()
		luz.name = "Fluorescente_%d" % i
		luz.position = puntos[i]
		luz.light_color = Color("e7ddc3") if i < 4 else Color("f1bd79")
		luz.light_energy = 0.62 if i < 4 else 0.92
		luz.omni_range = 3.1
		luz.shadow_enabled = i == 4
		add_child(luz)


func _puerta_cortafuegos(nombre: String, posicion: Vector3) -> void:
	_caja(nombre, posicion, Vector3(0.085, 0.82, 0.82), MAT_METAL)
	_caja(nombre + "_MarcoA", posicion + Vector3(-0.025, 0.0, -0.45), Vector3(0.13, 0.90, 0.065), MAT_METAL)
	_caja(nombre + "_MarcoB", posicion + Vector3(-0.025, 0.0, 0.45), Vector3(0.13, 0.90, 0.065), MAT_METAL)
	_caja(nombre + "_Dintel", posicion + Vector3(-0.025, 0.45, 0.0), Vector3(0.13, 0.065, 0.96), MAT_METAL)
	var rojo := _material_color(Color("8f1e18"), 0.58, 0.1)
	_caja(nombre + "_Antipanico", posicion + Vector3(-0.070, -0.02, 0.0), Vector3(0.055, 0.055, 0.58), rojo)


func _radiador(nombre: String, posicion: Vector3) -> void:
	var metal_claro := _material_color(Color("b7b0a0"), 0.72, 0.18)
	for i in 7:
		_caja("%s_Aleta%d" % [nombre, i], posicion + Vector3(0.0, 0.0, (i - 3) * 0.075), Vector3(0.07, 0.47, 0.048), metal_claro)
	_caja(nombre + "_ColectorSup", posicion + Vector3(0.0, 0.235, 0.0), Vector3(0.075, 0.05, 0.53), metal_claro)
	_caja(nombre + "_ColectorInf", posicion - Vector3(0.0, 0.235, 0.0), Vector3(0.075, 0.05, 0.53), metal_claro)


func _cuadro_electrico(nombre: String, posicion: Vector3) -> void:
	var gris := _material_color(Color("77766f"), 0.76, 0.24)
	_caja(nombre, posicion, Vector3(0.08, 0.48, 0.36), gris)
	_caja(nombre + "_Tapa", posicion + Vector3(0.045, 0.0, 0.0), Vector3(0.02, 0.42, 0.31), gris)
	var amarillo := _material_color(Color("d3ad2e"), 0.72, 0.0)
	_caja(nombre + "_Aviso", posicion + Vector3(0.058, 0.02, 0.0), Vector3(0.012, 0.13, 0.13), amarillo)


func _extintor(nombre: String, posicion: Vector3) -> void:
	var rojo := _material_color(Color("a32118"), 0.46, 0.16)
	var cilindro := MeshInstance3D.new()
	cilindro.name = nombre
	var malla := CylinderMesh.new()
	malla.height = 0.48
	malla.top_radius = 0.095
	malla.bottom_radius = 0.095
	malla.radial_segments = 12
	cilindro.mesh = malla
	cilindro.position = posicion
	cilindro.material_override = rojo
	add_child(cilindro)
	_caja(nombre + "_Soporte", posicion + Vector3(-0.055, 0.0, 0.0), Vector3(0.035, 0.42, 0.22), MAT_METAL)
	_barra_entre(nombre + "_Manguera", posicion + Vector3(0.0, 0.21, 0.0), posicion + Vector3(0.0, 0.28, 0.15), 0.018, MAT_GOMA)


func _luz_emergencia(nombre: String, posicion: Vector3) -> void:
	var carcasa := _material_color(Color("8b887d"), 0.82, 0.0)
	var emisor := _material_emisivo(Color("efe3b7"), 2.2)
	_caja(nombre + "_Carcasa", posicion, Vector3(0.10, 0.18, 0.54), carcasa)
	_caja(nombre + "_Difusor", posicion + Vector3(-0.058, 0.0, 0.0), Vector3(0.018, 0.13, 0.45), emisor)


func _senal_pared(nombre: String, textura: Texture2D, posicion: Vector3, rotacion: Vector3, pixel: float) -> void:
	var sprite := Sprite3D.new()
	sprite.name = nombre
	sprite.texture = textura
	sprite.position = posicion
	sprite.rotation_degrees = rotacion
	sprite.pixel_size = pixel
	sprite.shaded = true
	add_child(sprite)


func _barra_entre(nombre: String, desde: Vector3, hasta: Vector3, grosor: float, material: Material) -> void:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	var malla := BoxMesh.new()
	malla.size = Vector3(grosor, grosor, desde.distance_to(hasta))
	nodo.mesh = malla
	nodo.position = desde.lerp(hasta, 0.5)
	nodo.material_override = material
	add_child(nodo)
	nodo.look_at(to_global(hasta), Vector3.UP)


func _caja(nombre: String, posicion: Vector3, tamano: Vector3, material: Material) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	var malla := BoxMesh.new()
	malla.size = tamano
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = material
	add_child(nodo)
	return nodo


func _material_color(color: Color, rugosidad: float, metalico: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rugosidad
	material.metallic = metalico
	return material


func _material_emisivo(color: Color, energia: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.45
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energia
	return material
