## Consola de sobremesa original para el rincón de televisión de la casa (#95).
##
## Reutiliza el backend ya aislado de ConsolaPortatil98: catálogo de ROMs,
## EmuladorPortatilApp, pausa/salida y ausencia de efectos sobre campaña/progreso.
## Solo cambia la presencia física para que los minijuegos de #95 se jueguen
## desde una consola reconocible junto al televisor, no desde la portátil.
class_name ConsolaSobremesa98
extends ConsolaPortatil98

const ETIQUETA_CAZA_PIXELES := "res://arte/consola98/cartuchos/caza_pixeles_98.jpg"
const ETIQUETA_PAPER_PLANES := "res://arte/consola98/cartuchos/paper_planes_98.jpg"
const ETIQUETA_CROC_RIDERS := "res://arte/consola98/cartuchos/croc_riders_98.jpg"


func configurar() -> void:
	verbo = Verbo.USAR
	nombre_objeto = "consola de sobremesa"
	_montar_colision()
	_montar_carcasa()
	activado.connect(_alternar)


func _montar_colision() -> void:
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.58, 0.22, 0.44)
	colision.position = Vector3(0, 0.12, 0)
	colision.shape = forma
	add_child(colision)


func _montar_carcasa() -> void:
	# Cuerpo bajo y ancho, deliberadamente genérico: sin logos ni siluetas de
	# hardware comercial. La ranura superior sugiere cartucho sin representarlo.
	_agregar_caja(
		Vector3(0, 0.12, 0),
		Vector3(0.48, 0.16, 0.34),
		Color(0.20, 0.20, 0.22),
	)
	_agregar_caja(
		Vector3(0, 0.205, -0.015),
		Vector3(0.27, 0.018, 0.16),
		Color(0.08, 0.08, 0.09),
	)

	# Dos puertos de mando en el frontal y un interruptor físico.
	for x in [-0.12, 0.02]:
		_agregar_caja(
			Vector3(x, 0.105, -0.177),
			Vector3(0.075, 0.045, 0.018),
			Color(0.07, 0.07, 0.08),
		)
	_agregar_boton(Vector3(0.17, 0.105, -0.182), Color(0.22, 0.22, 0.23))

	# El LED comparte el estado visual del backend heredado. Es la única pieza
	# emisiva de la consola y no representa ninguna recompensa o estado de juego.
	var led := _agregar_caja(
		Vector3(0.205, 0.155, -0.177),
		Vector3(0.026, 0.026, 0.012),
		Color(0.20, 0.28, 0.22),
	)
	_material_pantalla = led.material_override as StandardMaterial3D
	_material_pantalla.emission_enabled = true
	_material_pantalla.emission = Color(0.08, 0.12, 0.09)
	_material_pantalla.emission_energy_multiplier = 0.15

	# Los tres minijuegos propios ya existentes en #95 tienen ahora presencia
	# material junto a la consola. Son cartuchos decorativos: no cargan ROMs,
	# no mutan campaña y solo usan arte original del proyecto.
	_montar_cartuchos_expositor()


func _montar_cartuchos_expositor() -> void:
	_agregar_cartucho(
		Vector3(0.34, 0.018, -0.10),
		-8.0,
		ETIQUETA_CAZA_PIXELES,
	)
	_agregar_cartucho(
		Vector3(0.37, 0.020, 0.00),
		5.0,
		ETIQUETA_PAPER_PLANES,
	)
	_agregar_cartucho(
		Vector3(0.33, 0.022, 0.10),
		-3.0,
		ETIQUETA_CROC_RIDERS,
	)


func _agregar_cartucho(posicion: Vector3, rotacion: float, ruta_textura: String) -> void:
	var cuerpo := _agregar_caja(
		posicion,
		Vector3(0.145, 0.028, 0.095),
		Color(0.19, 0.19, 0.21),
	)
	cuerpo.rotation_degrees.y = rotacion

	var etiqueta := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.118, 0.072)
	etiqueta.mesh = quad
	etiqueta.position = posicion + Vector3(0.0, 0.016, 0.0)
	etiqueta.rotation_degrees = Vector3(-90.0, 0.0, rotacion)

	var material := StandardMaterial3D.new()
	var textura := load(ruta_textura)
	if textura is Texture2D:
		material.albedo_texture = textura
	material.roughness = 0.82
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	etiqueta.material_override = material
	add_child(etiqueta)
