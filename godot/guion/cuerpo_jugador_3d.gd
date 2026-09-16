## Cuerpo visual del protagonista para primera persona.
##
## Es deliberadamente independiente de CharacterBody3D: no crea colisiones ni
## cambia la escala del caminante. Su trabajo es que mirar hacia abajo revele
## una persona y no una cámara flotante, usando la configuración persistente de
## PerfilJugador.
class_name CuerpoJugador3D
extends Node3D

const SHADER := "res://arte/psx.gdshader"

var perfil: Dictionary = {}
var _camara: Camera3D


func _ready() -> void:
	_camara = get_parent().get_node_or_null("Camara") as Camera3D
	aplicar(PerfilJugador.cargar())


func aplicar(valor: Dictionary, persistir: bool = false) -> void:
	perfil = PerfilJugador.completar(valor)
	for hijo in get_children():
		hijo.queue_free()
	_construir()
	if persistir:
		PerfilJugador.guardar(perfil)


func _process(delta: float) -> void:
	# Al agacharse la cámara baja mucho. Se baja también la capa visual para que
	# el pecho no atraviese el near plane; la cápsula y la física no se tocan.
	if _camara == null:
		return
	var objetivo := -0.16 if _camara.position.y < 0.5 else 0.0
	position.y = lerpf(position.y, objetivo, minf(1.0, delta * 12.0))


func _construir() -> void:
	var apariencia: Dictionary = perfil["apariencia"]
	var base := PerfilJugador.perfil_cuerpo(String(apariencia["cuerpo"]))
	var altura := float(apariencia["altura"])
	var ancho := float(base["ancho"])
	var fondo := float(base["fondo"])
	var hombros := float(base["hombros"]) * float(apariencia["hombros"])
	var cintura := float(base["cintura"]) * float(apariencia["cintura"])
	var extremidad := float(base["extremidad"])
	var piel := Color.from_string(String(apariencia["piel"]), Color("c9916b"))
	var ropa := Color.from_string(String(apariencia["ropa"]), Color("59616b"))
	var pantalon := ropa.darkened(0.30)
	var zapatos := ropa.darkened(0.55)

	# El cuello es la única piel superior visible desde primera persona. No se
	# modela cabeza aquí: la cámara vive donde estaría y una cabeza local daría
	# clipping. El perfil sí conserva pelo/peinado para espejos/cinemáticas futuras.
	_cilindro("Cuello", Vector3(0.0, 0.43 * altura, 0.0), 0.075 * ancho, 0.13 * altura, piel)

	var torso_ancho := 0.42 * ancho * hombros
	var torso_fondo := 0.22 * fondo
	var torso_alto := 0.54 * altura
	_caja(
		"TorsoRopa",
		Vector3(0.0, 0.12 * altura, 0.0),
		Vector3(torso_ancho, torso_alto, torso_fondo),
		ropa
	)

	# Una segunda pieza de hombros evita que delgado/robusto sean solo un cambio
	# de escala uniforme y mantiene una silueta noventera low-poly legible.
	_caja(
		"HombrosRopa",
		Vector3(0.0, 0.34 * altura, 0.0),
		Vector3(torso_ancho * 1.10, 0.11 * altura, torso_fondo * 1.03),
		ropa.lightened(0.03)
	)

	var prenda := String(apariencia["prenda"])
	_detalle_prenda(prenda, torso_ancho, torso_fondo, torso_alto, ropa)

	var cadera_ancho := 0.30 * ancho * cintura
	_caja(
		"Cadera",
		Vector3(0.0, -0.20 * altura, 0.0),
		Vector3(cadera_ancho, 0.19 * altura, torso_fondo * 0.92),
		pantalon
	)

	var brazo_x := torso_ancho * 0.62
	var brazo_radio := 0.055 * extremidad
	for lado in [-1.0, 1.0]:
		var sufijo := "I" if lado < 0.0 else "D"
		_capsula(
			"Brazo" + sufijo,
			Vector3(brazo_x * lado, 0.08 * altura, 0.0),
			brazo_radio,
			0.48 * altura,
			ropa
		)
		_esfera(
			"Mano" + sufijo,
			Vector3(brazo_x * lado, -0.19 * altura, 0.0),
			Vector3(0.075, 0.095, 0.065) * extremidad,
			piel
		)

	var pierna_x := cadera_ancho * 0.24
	var pierna_radio := 0.072 * extremidad
	for lado in [-1.0, 1.0]:
		var sufijo := "I" if lado < 0.0 else "D"
		_capsula(
			"Pierna" + sufijo,
			Vector3(pierna_x * lado, -0.55 * altura, 0.0),
			pierna_radio,
			0.62 * altura,
			pantalon
		)
		_caja(
			"Zapato" + sufijo,
			Vector3(pierna_x * lado, -0.84 * altura, -0.045),
			Vector3(0.15, 0.09, 0.25) * extremidad,
			zapatos
		)


func _detalle_prenda(prenda: String, ancho: float, fondo: float, alto: float, color: Color) -> void:
	match prenda:
		"jersey":
			_caja(
				"CuelloJersey",
				Vector3(0.0, 0.38, -fondo * 0.03),
				Vector3(ancho * 0.34, alto * 0.10, fondo * 1.05),
				color.lightened(0.05)
			)
		"chaqueta":
			_caja(
				"SolapaI",
				Vector3(-ancho * 0.12, 0.19, -fondo * 0.51),
				Vector3(ancho * 0.14, alto * 0.55, fondo * 0.06),
				color.darkened(0.08)
			)
			_caja(
				"SolapaD",
				Vector3(ancho * 0.12, 0.19, -fondo * 0.51),
				Vector3(ancho * 0.14, alto * 0.55, fondo * 0.06),
				color.darkened(0.08)
			)
		_:
			_caja(
				"CamisaCentro",
				Vector3(0.0, 0.16, -fondo * 0.51),
				Vector3(ancho * 0.24, alto * 0.70, fondo * 0.055),
				color.lightened(0.20)
			)


func _caja(nombre: String, posicion: Vector3, tam: Vector3, color: Color) -> void:
	var malla := BoxMesh.new()
	malla.size = tam
	var instancia := MeshInstance3D.new()
	instancia.name = nombre
	instancia.mesh = malla
	instancia.position = posicion
	instancia.material_override = _material(color)
	add_child(instancia)


func _capsula(nombre: String, posicion: Vector3, radio: float, alto: float, color: Color) -> void:
	var malla := CapsuleMesh.new()
	malla.radius = radio
	malla.height = maxf(alto, radio * 2.05)
	malla.radial_segments = 6
	malla.rings = 3
	var instancia := MeshInstance3D.new()
	instancia.name = nombre
	instancia.mesh = malla
	instancia.position = posicion
	instancia.material_override = _material(color)
	add_child(instancia)


func _esfera(nombre: String, posicion: Vector3, escala: Vector3, color: Color) -> void:
	var malla := SphereMesh.new()
	malla.radial_segments = 6
	malla.rings = 4
	malla.height = 1.0
	malla.radius = 0.5
	var instancia := MeshInstance3D.new()
	instancia.name = nombre
	instancia.mesh = malla
	instancia.position = posicion
	instancia.scale = escala
	instancia.material_override = _material(color)
	add_child(instancia)


func _cilindro(nombre: String, posicion: Vector3, radio: float, alto: float, color: Color) -> void:
	var malla := CylinderMesh.new()
	malla.top_radius = radio
	malla.bottom_radius = radio * 1.04
	malla.height = alto
	malla.radial_segments = 6
	var instancia := MeshInstance3D.new()
	instancia.name = nombre
	instancia.mesh = malla
	instancia.position = posicion
	instancia.material_override = _material(color)
	add_child(instancia)


func _material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(SHADER)
	material.set_shader_parameter("color_base", color)
	return material
