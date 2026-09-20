## Representación 3D ligera de una marca persistida por MarcadoresMundo.
##
## No crea cuerpos ni colisiones: una marca recuerda y orienta, nunca altera la
## navegación. La geometría procedural evita sumar assets binarios al primer corte.
class_name MarcadorMundo3D
extends Node3D

const GROSOR := 0.006
const DESPLAZAMIENTO_ESTRES_MAX := 0.035

var marcador: Dictionary = {}


func configurar(datos: Dictionary, en_sueno := false, estres := 0.0) -> void:
	marcador = datos.duplicate(true)
	name = "Marcador_%s" % String(marcador.get("id", "sin_id"))
	set_meta("marcador_id", String(marcador.get("id", "")))
	visible = MarcadoresMundo.visible_en(marcador, en_sueno)

	var normal := MarcadoresMundo.normal_de(marcador)
	var posicion := MarcadoresMundo.posicion_de(marcador)
	var desplazamiento := desplazamiento_estres(String(marcador.get("id", "")), estres)
	transform = Transform3D(Basis(Quaternion(Vector3.UP, normal)), posicion + desplazamiento)

	if not visible:
		return

	var tipo := String(marcador.get("tipo", MarcadoresMundo.TIPO_TIZA))
	var color := _color_de(String(marcador.get("color", MarcadoresMundo.COLOR_BLANCO)))
	var alpha := 0.72 if en_sueno else 0.94
	color.a = alpha

	match tipo:
		MarcadoresMundo.TIPO_TIZA:
			_montar_cruz(color, 0.18, 0.024)
		MarcadoresMundo.TIPO_CARBON:
			_montar_cruz(color.darkened(0.45), 0.16, 0.032)
		MarcadoresMundo.TIPO_CINTA:
			_montar_lamina(color, Vector3(0.26, GROSOR, 0.075))
			_montar_texto(color.darkened(0.8))
		MarcadoresMundo.TIPO_NOTA:
			_montar_lamina(color, Vector3(0.16, GROSOR, 0.16))
			_montar_texto(color.darkened(0.82))
		MarcadoresMundo.TIPO_OBJETO:
			_montar_objeto(color)


static func desplazamiento_estres(marcador_id: String, estres: float) -> Vector3:
	var intensidad := clampf(estres, 0.0, 1.0)
	if intensidad <= 0.0:
		return Vector3.ZERO
	var fase := float(posmod(marcador_id.hash(), 1009)) / 1009.0 * TAU
	return Vector3(sin(fase), 0.0, cos(fase * 1.71)) * DESPLAZAMIENTO_ESTRES_MAX * intensidad


func _montar_cruz(color: Color, largo: float, ancho: float) -> void:
	var primera := _caja(Vector3(largo, GROSOR, ancho), color)
	primera.rotation.y = deg_to_rad(18.0)
	add_child(primera)

	var segunda := _caja(Vector3(ancho, GROSOR, largo), color)
	segunda.rotation.y = deg_to_rad(-12.0)
	add_child(segunda)


func _montar_lamina(color: Color, tamano: Vector3) -> void:
	add_child(_caja(tamano, color))


func _montar_objeto(color: Color) -> void:
	var cuerpo := _caja(Vector3(0.085, 0.025, 0.055), color.darkened(0.15))
	cuerpo.position.y = 0.0125
	cuerpo.rotation.y = deg_to_rad(27.0)
	add_child(cuerpo)


func _montar_texto(color: Color) -> void:
	var texto := String(marcador.get("texto", ""))
	if texto.is_empty():
		return
	var etiqueta := Label3D.new()
	etiqueta.name = "Texto"
	etiqueta.text = texto
	etiqueta.font_size = 18
	etiqueta.pixel_size = 0.0023
	etiqueta.outline_size = 1
	etiqueta.modulate = color
	etiqueta.position = Vector3(0.0, GROSOR + 0.001, 0.0)
	etiqueta.rotation_degrees.x = -90.0
	add_child(etiqueta)


func _caja(tamano: Vector3, color: Color) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tamano
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var instancia := MeshInstance3D.new()
	instancia.mesh = malla
	instancia.material_override = material
	return instancia


static func _color_de(id: String) -> Color:
	match id:
		MarcadoresMundo.COLOR_AMARILLO:
			return Color(0.86, 0.69, 0.24)
		MarcadoresMundo.COLOR_ROJO:
			return Color(0.68, 0.22, 0.20)
		MarcadoresMundo.COLOR_AZUL:
			return Color(0.25, 0.43, 0.62)
		MarcadoresMundo.COLOR_VERDE:
			return Color(0.28, 0.48, 0.31)
		_:
			return Color(0.83, 0.80, 0.70)
