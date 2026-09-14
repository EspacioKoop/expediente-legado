## Contraparte doméstica/de ocio de Gilgamesh (#436 / #442).
##
## El libro puede estar presente toda la tarde sin activar nada. Para contaminar
## el sueño hay que examinar varias páginas y después abrir deliberadamente la
## reproducción final de la tablilla. No usa HUD ni mensaje de desbloqueo.
class_name GilgameshVigilia
extends Interactuable3D

const ID_MITO := "gilgamesh"
const FUENTE := "libro:arqueologia_uruk_98"
const PAGINAS_MINIMAS := 3

const COLOR_CUBIERTA := Color(0.24, 0.16, 0.10)
const COLOR_PAPEL := Color(0.70, 0.64, 0.50)
const COLOR_TINTA := Color(0.30, 0.22, 0.16)
const COLOR_TABLILLA := Color(0.56, 0.34, 0.19)
const COLOR_ACTIVO := Color(0.84, 0.56, 0.25)

var _jornada: Dictionary = {}
var _libro: Node3D
var _pagina_movil: MeshInstance3D
var _tablilla: MeshInstance3D
var _paginas_examinadas := 0
var _tablilla_observada := false
var _activada := false


func _ready() -> void:
	_configurar_prompt()
	if _libro == null:
		_montar()


func configurar(jornada: Dictionary) -> void:
	_jornada = jornada
	_configurar_prompt()
	if _libro == null:
		_montar()
	if not activado.is_connected(_al_examinar):
		activado.connect(_al_examinar)
	_intentar_activar()


func paginas_examinadas() -> int:
	return _paginas_examinadas


func tablilla_observada() -> bool:
	return _tablilla_observada


func esta_activada() -> bool:
	return _activada


## Cada activación representa una decisión física sobre el objeto. Las tres
## primeras avanzan páginas; la siguiente despliega y examina la reproducción.
func examinar() -> bool:
	if _paginas_examinadas < PAGINAS_MINIMAS:
		_paginas_examinadas += 1
		_actualizar_pagina()
	else:
		_tablilla_observada = true
		_actualizar_feedback()
	return _intentar_activar()


func _al_examinar(_actor: Node) -> void:
	examinar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	_activada = SuenoGilgamesh.registrar_semilla(
		_jornada,
		_paginas_examinadas,
		_tablilla_observada,
		FUENTE,
		2,
	)
	_actualizar_feedback()
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.EXAMINAR
	nombre_objeto = "libro de arqueología"


func _montar() -> void:
	_libro = Node3D.new()
	_libro.name = "LibroArqueologia"
	add_child(_libro)

	var colision := CollisionShape3D.new()
	colision.name = "ColisionLibroGilgamesh"
	var forma := BoxShape3D.new()
	forma.size = Vector3(2.4, 0.38, 1.7)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.18, 0.0)
	add_child(colision)

	_agregar_caja(
		_libro,
		"CubiertaInferior",
		Vector3(2.45, 0.12, 1.72),
		Vector3(0.0, 0.06, 0.0),
		COLOR_CUBIERTA,
	)
	_agregar_caja(
		_libro,
		"BloquePaginas",
		Vector3(2.28, 0.20, 1.56),
		Vector3(0.0, 0.20, 0.0),
		COLOR_PAPEL,
	)
	_pagina_movil = _agregar_caja(
		_libro,
		"PaginaMovil",
		Vector3(2.26, 0.035, 1.54),
		Vector3(0.0, 0.33, 0.0),
		COLOR_PAPEL,
	)
	_agregar_caja(
		_libro,
		"Lomo",
		Vector3(0.16, 0.40, 1.76),
		Vector3(-1.18, 0.20, 0.0),
		COLOR_CUBIERTA,
	)

	## La reproducción es procedural y deliberadamente abstracta: no introduce
	## texto histórico ni depende de un asset externo para validar la mecánica.
	_tablilla = _agregar_caja(
		_libro,
		"ReproduccionTablilla",
		Vector3(0.92, 0.08, 0.68),
		Vector3(0.48, 0.39, 0.08),
		COLOR_TABLILLA,
	)
	_tablilla.visible = false
	for i in 3:
		_agregar_caja(
			_tablilla,
			"Marca%d" % (i + 1),
			Vector3(0.10 + i * 0.04, 0.025, 0.04),
			Vector3(-0.24 + i * 0.22, 0.055, -0.12 + i * 0.10),
			COLOR_TINTA,
		)
	_actualizar_feedback()


func _actualizar_pagina() -> void:
	if _pagina_movil == null:
		return
	_pagina_movil.rotation_degrees.z = -8.0 * float(_paginas_examinadas)
	_pagina_movil.position.y = 0.33 + 0.015 * float(_paginas_examinadas)
	if _paginas_examinadas >= PAGINAS_MINIMAS and _tablilla != null:
		_tablilla.visible = true


func _actualizar_feedback() -> void:
	if _tablilla == null:
		return
	if _paginas_examinadas >= PAGINAS_MINIMAS:
		_tablilla.visible = true
	var color := COLOR_ACTIVO if _activada else COLOR_TABLILLA
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	material.emission_enabled = _tablilla_observada
	if _tablilla_observada:
		material.emission = COLOR_ACTIVO
		material.emission_energy_multiplier = 0.75 if not _activada else 1.25
	_tablilla.material_override = material


func _agregar_caja(
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
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.80
	nodo.material_override = material
	padre.add_child(nodo)
	return nodo
