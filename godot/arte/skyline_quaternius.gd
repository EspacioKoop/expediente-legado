## LOD de skyline derivado de tres modelos CC0 de Quaternius.
##
## Fuente oficial: https://quaternius.com/packs/ultimatetexturedbuildings.html
## Licencia: CC0-1.0.
## Espejo textual auditado: ERKPRIME/last_land@113de616a675a17fcad81bf61d9cbc62211408be
## Modelos de referencia:
## - 3Story_Balcony_Mat.obj
## - 4Story_Mat.obj
## - 6Story_Stack_Mat.obj
##
## No vendoreamos cientos de KB de OBJ para un fondo que nunca se visita. Este
## fichero conserva únicamente un LOD manual de sus siluetas/proporciones: cuerpo,
## balcones/retranqueos y ritmo de ventanas. El material original se descarta y el
## acabado lo pone el shader común de SIGA-98. No hay colisión ni interacción.
class_name SkylineQuaternius
extends RefCounted

const FUENTE := "https://quaternius.com/packs/ultimatetexturedbuildings.html"
const ESPEJO_COMMIT := "113de616a675a17fcad81bf61d9cbc62211408be"
const MODELO_BALCON := "3Story_Balcony_Mat.obj"
const MODELO_CUATRO := "4Story_Mat.obj"
const MODELO_PILA := "6Story_Stack_Mat.obj"


static func crear(modelo: String, color: Color) -> Node3D:
	var raiz := Node3D.new()
	match modelo:
		MODELO_BALCON:
			_tres_pisos_balcon(raiz, color)
		MODELO_CUATRO:
			_cuatro_pisos(raiz, color)
		MODELO_PILA:
			_seis_pisos_pila(raiz, color)
		_:
			push_warning("LOD de skyline desconocido: %s" % modelo)
	return raiz


static func _tres_pisos_balcon(raiz: Node3D, color: Color) -> void:
	_bloque(raiz, Vector3(2.16, 4.20, 2.50), Vector3(0, 2.10, 0), color)
	for y in [1.25, 2.35, 3.45]:
		_bloque(raiz, Vector3(1.82, 0.12, 0.42), Vector3(0, y, 1.38), color.lightened(0.08))
	_ventanas(raiz, 3, 3, Vector3(0, 0, 1.27), 1.05, 0.55)


static func _cuatro_pisos(raiz: Node3D, color: Color) -> void:
	_bloque(raiz, Vector3(2.45, 5.35, 2.30), Vector3(0, 2.675, 0), color)
	_bloque(raiz, Vector3(2.58, 0.18, 2.42), Vector3(0, 5.44, 0), color.darkened(0.10))
	_ventanas(raiz, 4, 3, Vector3(0, 0, 1.17), 1.08, 0.62)


static func _seis_pisos_pila(raiz: Node3D, color: Color) -> void:
	# La referencia alterna volúmenes apilados; el LOD conserva ese perfil en
	# tres cuerpos retranqueados en vez de resolverlo como una torre rectangular.
	_bloque(raiz, Vector3(2.75, 2.55, 2.55), Vector3(0, 1.275, 0), color)
	_bloque(raiz, Vector3(2.35, 2.55, 2.25), Vector3(0.18, 3.825, -0.08), color.lightened(0.035))
	_bloque(raiz, Vector3(1.95, 2.55, 2.00), Vector3(-0.10, 6.375, -0.16), color.lightened(0.07))
	_ventanas(raiz, 6, 2, Vector3(0, 0, 1.30), 1.10, 0.70)


static func _ventanas(
	raiz: Node3D, pisos: int, columnas: int, frente: Vector3, paso_y: float, separacion_x: float
) -> void:
	var vidrio := Color(0.11, 0.14, 0.17)
	for piso in range(pisos):
		for columna in range(columnas):
			var centro := float(columnas - 1) * 0.5
			var x := (float(columna) - centro) * separacion_x
			_bloque(
				raiz,
				Vector3(0.32, 0.42, 0.035),
				Vector3(x, 0.72 + float(piso) * paso_y, frente.z),
				vidrio
			)


static func _bloque(raiz: Node3D, tam: Vector3, posicion: Vector3, color: Color) -> void:
	var instancia := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tam
	instancia.mesh = malla
	instancia.position = posicion
	instancia.material_override = _material(color)
	raiz.add_child(instancia)


static func _material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	return material
