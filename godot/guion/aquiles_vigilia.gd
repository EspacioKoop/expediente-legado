## Contraparte de vigilia del sueño de Aquiles (#438 / #442).
##
## La estampa puede existir toda la tarde sin contaminar nada: solo una
## manipulación deliberada que cambie el ángulo y termine observando el talón
## activa la familia. No muestra HUD ni texto de "desbloqueado".
class_name AquilesVigilia
extends Interactuable3D

const ID_MITO := "aquiles"
const FUENTE := "estampa:bautismo_aquiles_cc0"
const FUENTE_CC0_URL := "https://www.clevelandart.org/art/2009.587"
const GIRO_POR_INTERACCION := 18.0
const GIRO_MINIMO_OBSERVACION := 15.0

const COLOR_MARCO := Color(0.24, 0.18, 0.12)
const COLOR_LAMINA := Color(0.72, 0.66, 0.54)
const COLOR_TALON_APAGADO := Color(0.32, 0.22, 0.17)
const COLOR_TALON_ACTIVO := Color(0.78, 0.35, 0.16)

var _jornada: Dictionary = {}
var _lamina: Node3D
var _marca_talon: MeshInstance3D
var _giro_acumulado := 0.0
var _talon_observado := false
var _activada := false


func _ready() -> void:
	_configurar_prompt()
	if _lamina == null:
		_montar()


func configurar(jornada: Dictionary) -> void:
	_jornada = jornada
	_configurar_prompt()
	if _lamina == null:
		_montar()
	if not activado.is_connected(_al_examinar):
		activado.connect(_al_examinar)
	_intentar_activar()


func giro_acumulado() -> float:
	return _giro_acumulado


func talon_observado() -> bool:
	return _talon_observado


func esta_activada() -> bool:
	return _activada


## La observación solo cuenta después de cambiar el ángulo lo suficiente como
## para que mirar el objeto sea una acción deliberada y no pasar el cursor.
func observar_talon() -> bool:
	if absf(_giro_acumulado) < GIRO_MINIMO_OBSERVACION:
		return false
	_talon_observado = true
	_actualizar_feedback()
	_intentar_activar()
	return true


func _al_examinar(_actor: Node) -> void:
	_giro_acumulado += GIRO_POR_INTERACCION
	if _lamina != null:
		_lamina.rotation_degrees.y = wrapf(_giro_acumulado, -35.0, 35.0)
	_intentar_activar()


func _intentar_activar() -> bool:
	if _activada or _jornada.is_empty():
		return _activada
	var giros := 1 if absf(_giro_acumulado) >= GIRO_MINIMO_OBSERVACION else 0
	_activada = (
		SuenoAquiles
		. registrar_semilla(
			_jornada,
			giros,
			_talon_observado,
			FUENTE,
			2,
		)
	)
	_actualizar_feedback()
	return _activada


func _configurar_prompt() -> void:
	verbo = Verbo.EXAMINAR
	nombre_objeto = "estampa de Aquiles"


func _montar() -> void:
	_lamina = Node3D.new()
	_lamina.name = "LaminaAquiles"
	add_child(_lamina)

	var colision := CollisionShape3D.new()
	colision.name = "ColisionEstampaAquiles"
	var forma := BoxShape3D.new()
	forma.size = Vector3(2.4, 1.7, 0.16)
	colision.shape = forma
	add_child(colision)

	_agregar_caja(
		_lamina,
		"Marco",
		Vector3(2.6, 1.9, 0.10),
		Vector3(0.0, 0.0, 0.05),
		COLOR_MARCO,
	)
	_agregar_caja(
		_lamina,
		"Lamina",
		Vector3(2.35, 1.65, 0.04),
		Vector3(0.0, 0.0, -0.02),
		COLOR_LAMINA,
	)

	var marca := SphereMesh.new()
	marca.radius = 0.10
	marca.height = 0.20
	_marca_talon = MeshInstance3D.new()
	_marca_talon.name = "DetalleTalon"
	_marca_talon.mesh = marca
	_marca_talon.position = Vector3(0.72, -0.58, -0.08)
	_lamina.add_child(_marca_talon)
	_actualizar_feedback()


func _actualizar_feedback() -> void:
	if _marca_talon == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR_TALON_ACTIVO if _talon_observado else COLOR_TALON_APAGADO
	material.roughness = 0.72
	material.emission_enabled = _activada
	if _activada:
		material.emission = COLOR_TALON_ACTIVO
		material.emission_energy_multiplier = 1.15
	_marca_talon.material_override = material


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
	material.roughness = 0.78
	nodo.material_override = material
	padre.add_child(nodo)
	return nodo
