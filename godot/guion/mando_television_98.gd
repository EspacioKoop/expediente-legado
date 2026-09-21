## Mando a distancia doméstico de finales de los 90 para el televisor de casa (#95).
##
## Es una pieza original y genérica: carcasa negra/gris, botón rojo de encendido,
## cruceta de volumen/canal y teclado numérico sugerido mediante botones sin logos.
## Solo el encendido está conectado porque es la única función real del televisor;
## los demás botones son geometría y no fingen canales o audio inexistentes.
class_name MandoTelevision98
extends Interactuable3D

var _televisor: Node


func configurar(televisor: Node) -> void:
	_televisor = televisor
	verbo = Verbo.USAR
	nombre_objeto = "mando del televisor"
	# USAR es mudo por defecto: aquí sí hay un botón físico bajo el dedo.
	sonido = "pulsar"
	_montar_colision()
	_montar_carcasa()
	activado.connect(_usar)


func _usar(_actor: Node) -> void:
	if _televisor == null or not is_instance_valid(_televisor):
		return
	if _televisor.has_method("alternar_desde_mando"):
		_televisor.call("alternar_desde_mando")


func _montar_colision() -> void:
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.12, 0.035, 0.31)
	colision.position = Vector3(0, 0.025, 0)
	colision.shape = forma
	add_child(colision)


func _montar_carcasa() -> void:
	_agregar_caja(Vector3.ZERO, Vector3(0.105, 0.028, 0.29), Color(0.12, 0.12, 0.13))
	# Frente ligeramente elevado, típico de mandos IR gruesos de la época.
	_agregar_caja(Vector3(0, 0.020, -0.125), Vector3(0.09, 0.025, 0.035), Color(0.08, 0.08, 0.09))

	# Encendido rojo separado del resto de controles.
	_agregar_boton(Vector3(-0.030, 0.027, -0.105), 0.012, Color(0.56, 0.10, 0.10))

	# Volumen/canal: cuatro botones grandes alrededor de un centro neutro.
	_agregar_boton(Vector3(-0.025, 0.027, -0.025), 0.010, Color(0.40, 0.40, 0.42))
	_agregar_boton(Vector3(0.025, 0.027, -0.025), 0.010, Color(0.40, 0.40, 0.42))
	_agregar_boton(Vector3(-0.025, 0.027, 0.020), 0.010, Color(0.36, 0.36, 0.38))
	_agregar_boton(Vector3(0.025, 0.027, 0.020), 0.010, Color(0.36, 0.36, 0.38))

	# Teclado numérico sugerido: 3x3 botones pequeños, sin texto ni iconografía.
	for fila in range(3):
		for columna in range(3):
			_agregar_boton(
				Vector3(-0.028 + columna * 0.028, 0.027, 0.080 + fila * 0.032),
				0.007,
				Color(0.30, 0.30, 0.32),
			)


func _agregar_caja(pos: Vector3, tam: Vector3, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tam
	malla.mesh = caja
	malla.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	malla.material_override = material
	add_child(malla)


func _agregar_boton(pos: Vector3, radio: float, color: Color) -> void:
	var malla := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = radio
	cilindro.bottom_radius = radio
	cilindro.height = 0.010
	malla.mesh = cilindro
	malla.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	malla.material_override = material
	add_child(malla)
