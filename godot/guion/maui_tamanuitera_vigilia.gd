## Contraparte doméstica de Māui y Tamanuiterā (#657 / #442).
##
## Se usa un libro ilustrado ficticio y examinable, evitando convertir objetos
## rituales o iconografía superficial en atrezzo. La semilla requiere varias
## lecturas y cerrar el libro deliberadamente.
class_name MauiTamanuiteraVigilia
extends Interactuable3D

const ID_MITO := "maui_tamanuitera"
const FUENTE := "libro:maui_tamanuitera_98"
const LECTURAS_MINIMAS := 2

const COLOR_CUBIERTA := Color(0.25, 0.18, 0.12)
const COLOR_PAPEL := Color(0.82, 0.76, 0.62)
const COLOR_TINTA := Color(0.24, 0.22, 0.19)
const COLOR_SOL := Color(0.92, 0.69, 0.24)
const COLOR_ACTIVO := Color(0.88, 0.60, 0.18)

var _jornada: Dictionary = {}
var _libro: Node3D
var _pagina: MeshInstance3D
var _sol: MeshInstance3D
var _paginas_leidas := 0
var _cerrado := false
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


func paginas_leidas() -> int:
	return _paginas_leidas


func esta_cerrado() -> bool:
	return _cerrado


func esta_activada() -> bool:
	return _activada


## Las dos primeras interacciones avanzan por el material. La siguiente cierra
## el libro y completa la atención deliberada; no aparece ningún HUD de unlock.
func examinar() -> bool:
	if _paginas_leidas < LECTURAS_MINIMAS:
		_paginas_leidas += 1
	else:
		_cerrado = true
	_actualizar_feedback()
	return _intentar_activar()


func _al_examinar(_actor: Node) -> void:
	examinar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	_activada = (
		SuenoMauiTamanuitera
		. registrar_semilla(
			_jornada,
			_paginas_leidas,
			_cerrado,
			FUENTE,
			2,
		)
	)
	_actualizar_feedback()
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.EXAMINAR
	nombre_objeto = "libro ilustrado"


func _montar() -> void:
	_libro = Node3D.new()
	_libro.name = "LibroMauiTamanuitera"
	add_child(_libro)

	var colision := CollisionShape3D.new()
	colision.name = "ColisionLibro"
	var forma := BoxShape3D.new()
	forma.size = Vector3(1.8, 0.32, 1.35)
	colision.shape = forma
	colision.position = Vector3(0.0, 0.16, 0.0)
	add_child(colision)

	_agregar_caja(
		_libro,
		"Cubierta",
		Vector3(1.8, 0.12, 1.35),
		Vector3(0.0, 0.08, 0.0),
		COLOR_CUBIERTA,
	)
	_pagina = _agregar_caja(
		_libro,
		"Pagina",
		Vector3(1.62, 0.055, 1.16),
		Vector3(0.0, 0.17, -0.02),
		COLOR_PAPEL,
	)
	_sol = _agregar_caja(
		_libro,
		"MotivoSolar",
		Vector3(0.45, 0.045, 0.45),
		Vector3(0.42, 0.21, -0.12),
		COLOR_SOL,
	)
	for i in 3:
		_agregar_caja(
			_libro,
			"Linea%d" % (i + 1),
			Vector3(0.72, 0.03, 0.06),
			Vector3(-0.32, 0.21, -0.30 + i * 0.20),
			COLOR_TINTA,
		)
	_actualizar_feedback()


func _actualizar_feedback() -> void:
	if _libro == null:
		return
	_libro.rotation_degrees.x = 0.0 if _cerrado else -10.0
	if _pagina != null:
		_pagina.position.y = 0.17 + 0.025 * float(_paginas_leidas)
	if _sol == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_ACTIVO if _activada else COLOR_SOL
	material.roughness = 0.78
	material.emission_enabled = _paginas_leidas >= LECTURAS_MINIMAS
	if material.emission_enabled:
		material.emission = COLOR_SOL
		material.emission_energy_multiplier = 0.5 if not _activada else 1.0
	_sol.material_override = material


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
	material.roughness = 0.82
	nodo.material_override = material
	padre.add_child(nodo)
	return nodo
