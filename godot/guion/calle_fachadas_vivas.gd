## Fachadas vivas: una vertical slice de interiores aparentes para #861.
##
## Esta capa no perfora la geometría jugable ni añade colisiones. Toma nueve
## ventanas del primer tramo residencial y construye una "caja de sombra" muy
## poco profunda por delante del revoco: marco con volumen, cristal translúcido,
## fondo oscuro y props 3D simples. La selección, la iluminación y el LOD son
## deterministas.
class_name CalleFachadasVivas
extends RefCounted

const MAX_VENTANAS := 9
const PREFIJO_TRAMO := "Ventana0_"
const SALIENTE_EXTRA_CRISTAL := 0.05
const GROSOR_CRISTAL := 0.008
const PROFUNDIDAD_INTERIOR := 0.055
const PROFUNDIDAD_MARCO := 0.065
const LOD_CERCA_FIN := 18.0
const LOD_MEDIA_FIN := 36.0
const LOD_LEJOS_FIN := 72.0
const VARIANTES := ["escritorio", "estanteria", "salon_tv"]
const ESTADOS_LUZ := ["calida", "apagada", "fria_tv", "tenue", "persiana"]


static func montar(calle: Node3D) -> Node3D:
	if calle == null:
		return null
	var existente := calle.get_node_or_null("FachadasVivas") as Node3D
	if existente != null:
		return existente
	var pisos := calle.get_node_or_null("PisosFachada") as Node3D
	if pisos == null:
		return null

	var raiz := Node3D.new()
	raiz.name = "FachadasVivas"
	calle.add_child(raiz)

	var materiales := _materiales_compartidos()
	var mallas := _mallas_compartidas()
	var decoradas := 0
	for hijo in pisos.get_children():
		if decoradas >= MAX_VENTANAS:
			break
		var ventana := hijo as MeshInstance3D
		if ventana == null or not String(ventana.name).begins_with(PREFIJO_TRAMO):
			continue
		_decorar(raiz, ventana, decoradas, materiales, mallas)
		decoradas += 1
	return raiz


static func _decorar(
	raiz: Node3D, ventana: MeshInstance3D, indice: int, materiales: Dictionary, mallas: Dictionary
) -> void:
	var variante := indice % VARIANTES.size()
	var estado_luz := String(ESTADOS_LUZ[indice % ESTADOS_LUZ.size()])
	var hacia_calle := 1.0 if ventana.position.x < 0.0 else -1.0
	ventana.position.x += hacia_calle * SALIENTE_EXTRA_CRISTAL
	var cristal := ventana.mesh as BoxMesh
	if cristal != null:
		var tam_cristal := cristal.size
		tam_cristal.x = GROSOR_CRISTAL
		cristal.size = tam_cristal
	ventana.material_override = materiales["cristal"]

	var grupo := Node3D.new()
	grupo.name = "Interior_" + String(ventana.name)
	grupo.set_meta("ventana", String(ventana.name))
	grupo.set_meta("variante", VARIANTES[variante])
	grupo.set_meta("estado_luz", estado_luz)
	grupo.set_meta("hacia_calle", hacia_calle)
	raiz.add_child(grupo)

	var centro := ventana.position
	var x_fondo := centro.x - hacia_calle * PROFUNDIDAD_INTERIOR
	var x_marco := centro.x - hacia_calle * (PROFUNDIDAD_MARCO * 0.5)
	var x_prop := centro.x - hacia_calle * 0.032

	_pieza(
		grupo,
		"Fondo",
		Vector3(x_fondo, centro.y, centro.z),
		mallas["fondo"],
		_material_fondo(materiales, estado_luz),
		LOD_LEJOS_FIN
	)
	_pieza(
		grupo,
		"MarcoSuperior",
		Vector3(x_marco, centro.y + 0.62, centro.z),
		mallas["marco_h"],
		materiales["marco"],
		LOD_MEDIA_FIN
	)
	_pieza(
		grupo,
		"MarcoInferior",
		Vector3(x_marco, centro.y - 0.62, centro.z),
		mallas["marco_h"],
		materiales["marco"],
		LOD_MEDIA_FIN
	)
	_pieza(
		grupo,
		"MarcoIzquierdo",
		Vector3(x_marco, centro.y, centro.z - 0.49),
		mallas["marco_v"],
		materiales["marco"],
		LOD_MEDIA_FIN
	)
	_pieza(
		grupo,
		"MarcoDerecho",
		Vector3(x_marco, centro.y, centro.z + 0.49),
		mallas["marco_v"],
		materiales["marco"],
		LOD_MEDIA_FIN
	)

	if estado_luz == "persiana":
		_pieza(
			grupo,
			"Persiana",
			Vector3(x_prop, centro.y, centro.z),
			mallas["persiana"],
			materiales["persiana"],
			LOD_MEDIA_FIN
		)

	match variante:
		0:
			_componer_escritorio(grupo, Vector3(x_prop, centro.y, centro.z), materiales, mallas)
		1:
			_componer_estanteria(grupo, Vector3(x_prop, centro.y, centro.z), materiales, mallas)
		_:
			_componer_salon(grupo, Vector3(x_prop, centro.y, centro.z), materiales, mallas)


static func _componer_escritorio(
	padre: Node3D, centro: Vector3, materiales: Dictionary, mallas: Dictionary
) -> void:
	_pieza(
		padre,
		"Escritorio",
		centro + Vector3(0.0, -0.34, 0.02),
		mallas["mesa"],
		materiales["madera"]
	)
	_pieza(
		padre,
		"Monitor",
		centro + Vector3(0.0, -0.05, -0.12),
		mallas["monitor"],
		materiales["pantalla"]
	)
	_pieza(
		padre,
		"Lampara",
		centro + Vector3(0.0, 0.18, 0.22),
		mallas["lampara"],
		materiales["luz_calida"]
	)


static func _componer_estanteria(
	padre: Node3D, centro: Vector3, materiales: Dictionary, mallas: Dictionary
) -> void:
	_pieza(
		padre,
		"Estanteria",
		centro + Vector3(0.0, 0.0, -0.22),
		mallas["estanteria"],
		materiales["madera"]
	)
	for fila in 3:
		_pieza(
			padre,
			"Balda%d" % fila,
			centro + Vector3(0.0, -0.30 + fila * 0.30, -0.22),
			mallas["balda"],
			materiales["madera_clara"]
		)
	_pieza(
		padre, "Planta", centro + Vector3(0.0, -0.17, 0.23), mallas["planta"], materiales["verde"]
	)


static func _componer_salon(
	padre: Node3D, centro: Vector3, materiales: Dictionary, mallas: Dictionary
) -> void:
	_pieza(padre, "Sofa", centro + Vector3(0.0, -0.30, -0.10), mallas["sofa"], materiales["tela"])
	_pieza(
		padre,
		"PantallaInterior",
		centro + Vector3(0.0, 0.05, 0.24),
		mallas["televisor"],
		materiales["pantalla"]
	)
	_pieza(
		padre,
		"CortinaIzquierda",
		centro + Vector3(0.0, 0.08, -0.36),
		mallas["cortina"],
		materiales["cortina"]
	)
	_pieza(
		padre,
		"CortinaDerecha",
		centro + Vector3(0.0, 0.08, 0.36),
		mallas["cortina"],
		materiales["cortina"]
	)


static func _material_fondo(materiales: Dictionary, estado_luz: String) -> Material:
	match estado_luz:
		"calida":
			return materiales["fondo_calido"]
		"fria_tv":
			return materiales["fondo_frio"]
		"tenue":
			return materiales["fondo_tenue"]
		"persiana":
			return materiales["fondo_persiana"]
		_:
			return materiales["fondo_apagado"]


static func _materiales_compartidos() -> Dictionary:
	return {
		"cristal": _material_cristal(Color(0.34, 0.42, 0.48, 0.24)),
		"marco": _material(Color(0.12, 0.11, 0.10)),
		"fondo_calido": _material(Color(0.30, 0.20, 0.12)),
		"fondo_apagado": _material(Color(0.055, 0.06, 0.07)),
		"fondo_frio": _material(Color(0.08, 0.11, 0.22)),
		"fondo_tenue": _material(Color(0.14, 0.10, 0.07)),
		"fondo_persiana": _material(Color(0.07, 0.065, 0.06)),
		"persiana": _material(Color(0.20, 0.18, 0.15)),
		"madera": _material(Color(0.30, 0.20, 0.13)),
		"madera_clara": _material(Color(0.42, 0.31, 0.20)),
		"pantalla": _material(Color(0.18, 0.42, 0.58)),
		"luz_calida": _material(Color(0.78, 0.54, 0.28)),
		"verde": _material(Color(0.18, 0.34, 0.20)),
		"tela": _material(Color(0.28, 0.18, 0.16)),
		"cortina": _material(Color(0.36, 0.30, 0.26)),
	}


static func _mallas_compartidas() -> Dictionary:
	return {
		"fondo": _malla(Vector3(0.010, 1.02, 0.78)),
		"marco_h": _malla(Vector3(PROFUNDIDAD_MARCO, 0.08, 0.98)),
		"marco_v": _malla(Vector3(PROFUNDIDAD_MARCO, 1.20, 0.08)),
		"persiana": _malla(Vector3(0.016, 0.96, 0.74)),
		"mesa": _malla(Vector3(0.028, 0.12, 0.58)),
		"monitor": _malla(Vector3(0.022, 0.26, 0.30)),
		"lampara": _malla(Vector3(0.025, 0.32, 0.12)),
		"estanteria": _malla(Vector3(0.028, 0.92, 0.26)),
		"balda": _malla(Vector3(0.032, 0.05, 0.42)),
		"planta": _malla(Vector3(0.030, 0.30, 0.24)),
		"sofa": _malla(Vector3(0.035, 0.32, 0.60)),
		"televisor": _malla(Vector3(0.022, 0.28, 0.30)),
		"cortina": _malla(Vector3(0.018, 0.84, 0.16)),
	}


static func _pieza(
	padre: Node3D,
	nombre: String,
	posicion: Vector3,
	malla: Mesh,
	material: Material,
	rango_fin: float = LOD_CERCA_FIN
) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.name = nombre
	pieza.position = posicion
	pieza.mesh = malla
	pieza.material_override = material
	pieza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pieza.visibility_range_end = rango_fin
	padre.add_child(pieza)
	return pieza


static func _malla(tam: Vector3) -> BoxMesh:
	var malla := BoxMesh.new()
	malla.size = tam
	return malla


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material


static func _material_cristal(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.roughness = 0.18
	return material
