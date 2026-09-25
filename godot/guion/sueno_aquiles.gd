## Vertical del sueño de Aquiles (#438).
##
## La familia usa el contrato común de `SemillasOniricas`: la vigilia activa
## `aquiles` dentro de Jornada y este módulo solo consulta/consume ese estado.
## El modelo CC0 sigue siendo opcional hasta poder registrarlo en procedencia/LFS.
class_name SuenoAquiles
extends Node3D

const ID_MITO := "aquiles"
const CLAVE_SEMILLA := "semilla_onirica_aquiles"
const GIROS_MINIMOS := 1
const FUENTE_VIGILIA := "estampa:bautismo_aquiles_cc0"
const ACCIONES_RESOLUCION := ["tocar", "sellar", "enfocar", "colocar"]
const TRANSFORMACION := "papel_y_sellos"
const MODELO_CC0_RUTA := "res://assets/cc0/aquiles/modelo/achilles_spartan_greek_warrior.glb"
const MODELO_CC0_FUENTE := "https://opengameart.org/content/achilles-spartan-greek-warrior"
const POSTER_CC0_FUENTE := "https://www.clevelandart.org/art/2009.587"

const COLOR_PIEDRA := Color(0.54, 0.50, 0.46)
const COLOR_BRONCE := Color(0.34, 0.25, 0.16)
const COLOR_TALON := Color(0.78, 0.24, 0.12)
const COLOR_PAPEL := Color(0.76, 0.70, 0.57)

var _figura: Node3D
var _talon: MeshInstance3D
var _marca_sellado: MeshInstance3D
var _impactos: Array[MeshInstance3D] = []


## Una Jornada real consulta el catálogo común. El fallback plano conserva
## compatibilidad con prototipos guardados durante el primer corte de #438.
static func puede_entrar(estado: Dictionary) -> bool:
	if estado.has("dia"):
		return SemillasOniricas.familias_activas(estado).has(ID_MITO)
	return bool(estado.get(CLAVE_SEMILLA, false))


## Registrar exige manipulación deliberada y observación del talón.
##
## En Jornada se persiste mediante SemillasOniricas. El fallback plano solo
## existe para no romper harnesses/prototipos del corte anterior.
static func registrar_semilla(
	estado: Dictionary,
	giros: int,
	talon_observado: bool,
	fuente: String = FUENTE_VIGILIA,
	intensidad: int = 2,
) -> bool:
	if giros < GIROS_MINIMOS or not talon_observado:
		return false
	if estado.has("dia"):
		return (
			SemillasOniricas
			. activar_semilla_onirica(
				estado,
				ID_MITO,
				fuente,
				intensidad,
			)
		)
	estado[CLAVE_SEMILLA] = true
	return true


## El punto débil no se descubre probando superficies: aparece cuando la lectura
## espacial alinea una luz o un reflejo con el talón.
static func vulnerabilidad_visible(luz_alineada: bool, reflejo_alineado: bool) -> bool:
	return luz_alineada or reflejo_alineado


## Resolver no implica combate. Solo acciones de observación/manipulación tienen
## efecto y únicamente después de revelar la vulnerabilidad.
static func resolver(vulnerabilidad_revelada: bool, accion: String) -> Dictionary:
	var normalizada := accion.strip_edges().to_lower()
	var resuelta := vulnerabilidad_revelada and ACCIONES_RESOLUCION.has(normalizada)
	return {
		"resuelta": resuelta,
		"transformacion": TRANSFORMACION if resuelta else "",
		"accion": normalizada,
	}


## La misma solución se conserva con reducción de movimiento.
static func plan_transformacion(reduccion_movimiento: bool) -> Dictionary:
	return {
		"sacudida_camara": false,
		"flash": false,
		"duracion": 1.2 if reduccion_movimiento else 0.55,
		"modo": "escala_progresiva_y_fundido",
	}


func _ready() -> void:
	_montar_prototipo()


func aplicar_lectura_espacial(luz_alineada: bool, reflejo_alineado: bool) -> bool:
	var revelada := vulnerabilidad_visible(luz_alineada, reflejo_alineado)
	_talon.visible = revelada
	return revelada


func aplicar_resolucion(accion: String, reduccion_movimiento: bool) -> bool:
	var resultado := resolver(_talon.visible, accion)
	if not resultado["resuelta"]:
		return false
	for impacto in _impactos:
		impacto.visible = false
	var papel := _material(COLOR_PAPEL)
	_revestir_geometria(_figura, papel)
	_marca_sellado.visible = true
	_marca_sellado.scale = Vector3(0.35, 1.0, 0.35)
	var plan := plan_transformacion(reduccion_movimiento)
	var duracion := float(plan["duracion"])
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	(
		tween
		. tween_property(
			_figura,
			"scale",
			Vector3(1.0, 0.055, 1.0),
			duracion,
		)
	)
	(
		tween
		. tween_property(
			_marca_sellado,
			"scale",
			Vector3(6.5, 1.0, 6.5),
			duracion,
		)
	)
	return true


func _montar_prototipo() -> void:
	_figura = Node3D.new()
	_figura.name = "FiguraAquiles"
	add_child(_figura)
	if not _montar_modelo_cc0():
		_montar_figura_fallback()
	_montar_talon()
	_montar_pasarela()
	_montar_impactos()
	_montar_marca_sellado()
	_montar_prop_panoplia()
	_montar_iluminacion()
	_montar_camara()


func _montar_modelo_cc0() -> bool:
	if not ResourceLoader.exists(MODELO_CC0_RUTA):
		return false
	var recurso := load(MODELO_CC0_RUTA)
	if recurso is PackedScene:
		var escena := recurso as PackedScene
		var instancia := escena.instantiate() as Node3D
		if instancia == null:
			return false
		_figura.add_child(instancia)
		instancia.scale = Vector3(4.5, 4.5, 4.5)
		return true
	if recurso is Mesh:
		var malla_recurso := recurso as Mesh
		var malla := MeshInstance3D.new()
		malla.mesh = malla_recurso
		malla.scale = Vector3(4.5, 4.5, 4.5)
		_figura.add_child(malla)
		return true
	return false


func _montar_figura_fallback() -> void:
	_crear_caja(
		_figura,
		"Torso",
		Vector3(3.3, 4.0, 1.5),
		Vector3(0.0, 6.2, 0.0),
		COLOR_PIEDRA,
	)
	_crear_caja(
		_figura,
		"PiernaIzquierda",
		Vector3(1.0, 4.3, 1.0),
		Vector3(-0.9, 2.2, 0.0),
		COLOR_PIEDRA,
	)
	_crear_caja(
		_figura,
		"PiernaDerecha",
		Vector3(1.0, 4.3, 1.0),
		Vector3(0.9, 2.2, 0.0),
		COLOR_PIEDRA,
	)
	_crear_caja(
		_figura,
		"BrazoIzquierdo",
		Vector3(0.8, 3.6, 0.8),
		Vector3(-2.0, 6.0, 0.0),
		COLOR_BRONCE,
	)
	_crear_caja(
		_figura,
		"BrazoDerecho",
		Vector3(0.8, 3.6, 0.8),
		Vector3(2.0, 6.0, 0.0),
		COLOR_BRONCE,
	)
	var cabeza_malla := SphereMesh.new()
	cabeza_malla.radius = 1.05
	cabeza_malla.height = 2.1
	var cabeza := MeshInstance3D.new()
	cabeza.name = "Cabeza"
	cabeza.mesh = cabeza_malla
	cabeza.position = Vector3(0.0, 9.2, 0.0)
	cabeza.material_override = _material(COLOR_PIEDRA)
	_figura.add_child(cabeza)


func _montar_talon() -> void:
	var malla := SphereMesh.new()
	malla.radius = 0.34
	malla.height = 0.68
	_talon = MeshInstance3D.new()
	_talon.name = "VulnerabilidadTalon"
	_talon.mesh = malla
	_talon.position = Vector3(0.9, 0.45, -0.56)
	_talon.material_override = _material(COLOR_TALON, true)
	_talon.visible = false
	_figura.add_child(_talon)


func _montar_pasarela() -> void:
	_crear_caja(
		self,
		"PasarelaNorte",
		Vector3(13.0, 0.3, 2.0),
		Vector3(0.0, -0.15, -6.0),
		COLOR_BRONCE,
	)
	_crear_caja(
		self,
		"PasarelaSur",
		Vector3(13.0, 0.3, 2.0),
		Vector3(0.0, -0.15, 6.0),
		COLOR_BRONCE,
	)
	_crear_caja(
		self,
		"PasarelaEste",
		Vector3(2.0, 0.3, 10.0),
		Vector3(5.5, -0.15, 0.0),
		COLOR_BRONCE,
	)
	_crear_caja(
		self,
		"PasarelaOeste",
		Vector3(2.0, 0.3, 10.0),
		Vector3(-5.5, -0.15, 0.0),
		COLOR_BRONCE,
	)
	var espejo := _crear_caja(
		self,
		"EspejoLateral",
		Vector3(0.18, 4.0, 3.2),
		Vector3(-6.1, 2.0, -1.5),
		Color(0.42, 0.48, 0.52),
	)
	var material := espejo.material_override as StandardMaterial3D
	material.metallic = 0.85
	material.roughness = 0.18


func _montar_impactos() -> void:
	var posiciones := [
		Vector3(-2.6, 6.8, 1.5),
		Vector3(2.5, 5.9, 1.1),
		Vector3(0.7, 8.0, 1.2),
	]
	for i in posiciones.size():
		var impacto := _crear_caja(
			self,
			"ImpactoAdministrativo%d" % (i + 1),
			Vector3(0.72, 0.12, 0.52),
			posiciones[i],
			COLOR_PAPEL,
		)
		impacto.rotation_degrees = Vector3(12.0 * i, 24.0 * i, -18.0 + 9.0 * i)
		_impactos.append(impacto)


func _montar_marca_sellado() -> void:
	var malla := CylinderMesh.new()
	malla.top_radius = 1.0
	malla.bottom_radius = 1.0
	malla.height = 0.05
	malla.radial_segments = 48
	_marca_sellado = MeshInstance3D.new()
	_marca_sellado.name = "MarcaSelladoFinal"
	_marca_sellado.mesh = malla
	_marca_sellado.position = Vector3(0.0, 0.035, 0.0)
	_marca_sellado.scale = Vector3(0.35, 1.0, 0.35)
	_marca_sellado.material_override = _material(COLOR_TALON)
	_marca_sellado.visible = false
	add_child(_marca_sellado)


func _revestir_geometria(nodo: Node, material: Material) -> int:
	var revestidas := 0
	if nodo is GeometryInstance3D:
		(nodo as GeometryInstance3D).material_override = material
		revestidas += 1
	for hijo in nodo.get_children():
		revestidas += _revestir_geometria(hijo, material)
	return revestidas


func _montar_prop_panoplia() -> void:
	var prop := Mitologias435Props.panoplia_aquiles()
	prop.name = "PropPanopliaAquiles"
	prop.position = Vector3(4.35, 0.0, 3.45)
	prop.rotation_degrees = Vector3(0.0, -24.0, 0.0)
	prop.scale = Vector3.ONE * 0.78
	prop.set_meta("mitologias_435_solo_visual", true)
	add_child(prop)


func _montar_iluminacion() -> void:
	var general := DirectionalLight3D.new()
	general.name = "LuzGeneral"
	general.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	general.light_energy = 1.35
	add_child(general)

	var lectura := SpotLight3D.new()
	lectura.name = "LuzDeLectura"
	lectura.position = Vector3(0.8, 3.0, 5.6)
	lectura.light_color = Color(0.86, 0.72, 0.48)
	lectura.light_energy = 7.0
	lectura.spot_range = 11.0
	add_child(lectura)
	lectura.look_at(Vector3(0.9, 0.45, -0.56), Vector3.UP)


func _montar_camara() -> void:
	var camara := Camera3D.new()
	camara.name = "CamaraStandalone"
	camara.position = Vector3(0.0, 6.2, 18.0)
	camara.current = true
	add_child(camara)
	camara.look_at(Vector3(0.0, 4.6, 0.0), Vector3.UP)


func _crear_caja(
	padre: Node3D,
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tam
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = _material(color)
	padre.add_child(nodo)
	return nodo


func _material(color: Color, emision: bool = false) -> StandardMaterial3D:
	if color == COLOR_PIEDRA:
		return Mitologias435Materiales.crear("caliza_duat", color, false, emision)
	if color == COLOR_BRONCE:
		return Mitologias435Materiales.crear("bronce_votivo", color, false, emision)
	if color == COLOR_PAPEL:
		var papel := Mitologias435Materiales.crear(
			"papel_archivo_envejecido", color, false, emision
		)
		papel.albedo_color = color
		return papel
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	if emision:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.8
	return material
