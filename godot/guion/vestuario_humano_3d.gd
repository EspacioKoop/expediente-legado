## Pase visual no destructivo para las figuras humanas importadas.
##
## `Modelos.persona()` sigue siendo dueño de animación, materiales y rostro. Este
## autoload añade silueta corporal y ropa sobre `persona.fbx`: no cambia huesos,
## colisiones, navegación ni el asset fuente. La identidad se resuelve contra el
## roster de `Companeros`, de modo que #275 puede distinguir cuerpos y prendas
## por NPC sin duplicar el cuerpo base ni depender del orden de instanciación.
extends Node

const RUTA_PERSONA := "res://assets/modelos/persona.fbx"
const MARCA := "vestuario_humano_275"
const MARCA_IDENTIDAD := "vestuario_identidad_275"

const PERFILES_BASE := [
	{
		"nombre": "estrecho",
		"ancho": 0.92,
		"fondo": 0.90,
		"largo": 1.04,
		"hombros": 1.14,
		"cintura": 0.76,
		"manga": 0.080,
		"largo_manga": 0.28,
		"prenda": "traje",
	},
	{
		"nombre": "medio",
		"ancho": 1.00,
		"fondo": 0.96,
		"largo": 1.03,
		"hombros": 1.18,
		"cintura": 0.78,
		"manga": 0.085,
		"largo_manga": 0.27,
		"prenda": "chaqueta",
	},
	{
		"nombre": "robusto",
		"ancho": 1.07,
		"fondo": 1.03,
		"largo": 1.01,
		"hombros": 1.20,
		"cintura": 0.82,
		"manga": 0.092,
		"largo_manga": 0.26,
		"prenda": "chaqueta",
	},
]

## Perfiles explícitos para el roster de oficina. Son diferencias grandes y
## legibles a baja resolución: ancho/profundidad del torso, caída, hombros,
## cintura, mangas y familia de prenda. Los valores no alteran el Skeleton3D.
## Si entra una figura humana fuera del roster, cae al vocabulario BASE.
const PERFILES_PERSONAJE := {
	"emperador":
	{
		"nombre": "emperador",
		"ancho": 0.89,
		"fondo": 0.88,
		"largo": 1.08,
		"hombros": 1.10,
		"cintura": 0.80,
		"manga": 0.075,
		"largo_manga": 0.29,
		"prenda": "cuello_cerrado",
	},
	"aduanero_ny":
	{
		"nombre": "aduanero_ny",
		"ancho": 1.06,
		"fondo": 1.00,
		"largo": 1.08,
		"hombros": 1.23,
		"cintura": 0.84,
		"manga": 0.092,
		"largo_manga": 0.30,
		"prenda": "abrigo",
	},
	"correspondencia":
	{
		"nombre": "correspondencia",
		"ancho": 0.90,
		"fondo": 0.89,
		"largo": 1.05,
		"hombros": 1.13,
		"cintura": 0.74,
		"manga": 0.078,
		"largo_manga": 0.28,
		"prenda": "traje_chaleco",
	},
	"riegos":
	{
		"nombre": "riegos",
		"ancho": 1.03,
		"fondo": 0.96,
		"largo": 1.04,
		"hombros": 1.17,
		"cintura": 0.80,
		"manga": 0.086,
		"largo_manga": 0.27,
		"prenda": "traje",
	},
	"fielato":
	{
		"nombre": "fielato",
		"ancho": 0.97,
		"fondo": 0.95,
		"largo": 1.02,
		"hombros": 1.16,
		"cintura": 0.82,
		"manga": 0.088,
		"largo_manga": 0.26,
		"prenda": "chaqueta_trabajo",
	},
	"cunado":
	{
		"nombre": "cunado",
		"ancho": 1.04,
		"fondo": 1.00,
		"largo": 1.01,
		"hombros": 1.19,
		"cintura": 0.84,
		"manga": 0.090,
		"largo_manga": 0.26,
		"prenda": "chaqueta",
	},
	"becario":
	{
		"nombre": "becario",
		"ancho": 0.88,
		"fondo": 0.88,
		"largo": 1.05,
		"hombros": 1.10,
		"cintura": 0.74,
		"manga": 0.074,
		"largo_manga": 0.29,
		"prenda": "camisa",
	},
	"jubilacion":
	{
		"nombre": "jubilacion",
		"ancho": 1.06,
		"fondo": 1.04,
		"largo": 1.00,
		"hombros": 1.16,
		"cintura": 0.88,
		"manga": 0.088,
		"largo_manga": 0.25,
		"prenda": "chaleco",
	},
	"mesa_de_en_medio":
	{
		"nombre": "mesa_de_en_medio",
		"ancho": 1.00,
		"fondo": 0.98,
		"largo": 1.02,
		"hombros": 1.15,
		"cintura": 0.84,
		"manga": 0.086,
		"largo_manga": 0.27,
		"prenda": "jersey",
	},
	"telefono":
	{
		"nombre": "telefono",
		"ancho": 0.95,
		"fondo": 0.92,
		"largo": 1.04,
		"hombros": 1.14,
		"cintura": 0.76,
		"manga": 0.080,
		"largo_manga": 0.28,
		"prenda": "traje",
	},
}


func _ready() -> void:
	get_tree().node_added.connect(_al_agregar_nodo)
	if get_tree().current_scene != null:
		_revisar_arbol(get_tree().current_scene)


func _al_agregar_nodo(nodo: Node) -> void:
	if String(nodo.scene_file_path) == RUTA_PERSONA:
		_vestir_diferido.call_deferred(nodo.get_instance_id())


## Se difiere el id y no la referencia. Entre el aviso de `node_added` y el
## volcado diferido la figura puede haber desaparecido —un cambio de fase o de
## sala libera el árbol entero—, y en ese caso `MessageQueue` descarta la
## llamada con un error antes de que `is_instance_valid` llegue a mirarla.
func _vestir_diferido(id: int) -> void:
	var pieza := instance_from_id(id)
	if pieza is Node:
		_vestir_si_persona(pieza)


func _revisar_arbol(nodo: Node) -> void:
	if String(nodo.scene_file_path) == RUTA_PERSONA:
		_vestir_si_persona(nodo)
	for hijo in nodo.get_children():
		_revisar_arbol(hijo)


func _vestir_si_persona(pieza: Node) -> void:
	if not is_instance_valid(pieza) or String(pieza.scene_file_path) != RUTA_PERSONA:
		return
	var esqueleto := _buscar_esqueleto(pieza)
	if esqueleto == null or esqueleto.has_meta(MARCA):
		return

	# La identidad del roster vive en Companeros. El material conserva exactamente
	# su color declarado, así que puede usarse como puente sin copiar ids ni
	# depender de Node.name/orden de instanciación. Figuras ajenas al roster usan
	# el fallback determinista previo.
	var color_base := _color_base(pieza)
	var identidad := _identidad_por_color(color_base)
	var clave := String(pieza.get_parent().name if pieza.get_parent() != null else pieza.name)
	vestir(pieza, _perfil_para(identidad, clave), color_base, identidad)


## Viste [param pieza] con un perfil explícito en vez del resuelto por roster.
## Lo usa el protagonista (#701), cuyo cuerpo y prenda salen de su ficha. Tras
## vestirla, la marca impide que el pase automático la vuelva a vestir.
## Devuelve falso si no es una figura con los huesos esperados o ya está vestida.
func vestir(pieza: Node, perfil: Dictionary, color_base: Color, identidad: String) -> bool:
	var esqueleto := _buscar_esqueleto(pieza)
	if esqueleto == null or esqueleto.has_meta(MARCA):
		return false
	var cadera := _buscar_hueso(esqueleto, ["Hips", "Pelvis"])
	var pecho := _buscar_hueso(esqueleto, ["Spine2", "Chest", "UpperChest", "Spine1", "Spine"])
	var cabeza := _buscar_hueso(esqueleto, ["Head"])
	if cadera < 0 or pecho < 0 or cabeza < 0:
		return false

	var color_chaqueta := color_base.darkened(0.24)
	var color_camisa := color_base.lightened(0.22)
	var color_pantalon := color_base.darkened(0.34)

	var alto_torso := _distancia_vertical(esqueleto, cadera, cabeza)
	# Los FBX de este pack pueden traer escalas internas poco intuitivas. La
	# distancia entre huesos mantiene todo en el mismo espacio que el esqueleto.
	alto_torso = maxf(alto_torso, 0.01)
	var ancho := alto_torso * 0.27 * float(perfil["ancho"])
	var fondo := alto_torso * 0.135 * float(perfil["fondo"])
	var largo := alto_torso * 0.47 * float(perfil["largo"])

	# Chaqueta/cuerpo principal: volumen largo y estrecho, con la proporción propia
	# del perfil y sin tocar la escala del esqueleto.
	var torso := _enganche(esqueleto, pecho, "VestuarioTorso")
	_caja(torso, Vector3(ancho, largo, fondo), Vector3(0.0, -largo * 0.24, 0.0), color_chaqueta)

	# Hombros y cintura dejan de ser constantes globales: la silueta completa ya
	# puede distinguir a dos compañeros antes de leer cara o rótulo.
	var hombros := _enganche(esqueleto, pecho, "VestuarioHombros")
	_caja(
		hombros,
		Vector3(ancho * float(perfil["hombros"]), largo * 0.12, fondo * 1.03),
		Vector3(0.0, -largo * 0.02, 0.0),
		color_chaqueta
	)

	# Camisa visible en el centro; una pieza fina rompe el bloque de chaqueta sin
	# recuperar la lectura de maniquí desnudo.
	_caja(
		torso,
		Vector3(ancho * 0.26, largo * 0.70, fondo * 1.035),
		Vector3(0.0, -largo * 0.21, -fondo * 0.025),
		color_camisa
	)

	var cintura := _enganche(esqueleto, cadera, "VestuarioCintura")
	_caja(
		cintura,
		Vector3(ancho * float(perfil["cintura"]), largo * 0.18, fondo * 0.90),
		Vector3(0.0, largo * 0.04, 0.0),
		color_pantalon
	)

	_poner_manga(
		esqueleto,
		["LeftArm", "UpperArm_L", "upperarm_l"],
		alto_torso,
		ancho,
		color_chaqueta,
		"L",
		float(perfil["manga"]),
		float(perfil["largo_manga"])
	)
	_poner_manga(
		esqueleto,
		["RightArm", "UpperArm_R", "upperarm_r"],
		alto_torso,
		ancho,
		color_chaqueta,
		"R",
		float(perfil["manga"]),
		float(perfil["largo_manga"])
	)

	_detalle_prenda(
		torso, hombros, String(perfil["prenda"]), ancho, fondo, largo, color_chaqueta, color_camisa
	)

	esqueleto.set_meta(MARCA, String(perfil["nombre"]))
	esqueleto.set_meta(MARCA_IDENTIDAD, identidad)
	return true


func _perfil_para(identidad: String, clave: String) -> Dictionary:
	if PERFILES_PERSONAJE.has(identidad):
		return PERFILES_PERSONAJE[identidad]
	var semilla := absi(hash(clave))
	return PERFILES_BASE[semilla % PERFILES_BASE.size()]


func _identidad_por_color(color: Color) -> String:
	for quien in [Companeros.CUNADO] + Array(Companeros.ROSTER):
		var esperado: Color = quien.get("color", Color.TRANSPARENT)
		if color.is_equal_approx(esperado):
			return String(quien.get("id", ""))
	return ""


## Un pequeño vocabulario de prendas reutilizables. No intenta modelar costuras:
## cambia la lectura de cuello/capa/pecho con pocas cajas PSX, suficiente para que
## traje, abrigo, camisa o chaleco no sean el mismo bloque teñido.
func _detalle_prenda(
	torso: Node3D,
	hombros: Node3D,
	prenda: String,
	ancho: float,
	fondo: float,
	largo: float,
	color_exterior: Color,
	color_interior: Color
) -> void:
	match prenda:
		"cuello_cerrado":
			_caja(
				torso,
				Vector3(ancho * 0.36, largo * 0.10, fondo * 1.06),
				Vector3(0.0, largo * 0.18, -fondo * 0.03),
				color_exterior.lightened(0.08)
			)
		"abrigo":
			_caja(
				torso,
				Vector3(ancho * 1.04, largo * 0.22, fondo * 1.06),
				Vector3(0.0, -largo * 0.56, 0.0),
				color_exterior.darkened(0.08)
			)
			_caja(
				hombros,
				Vector3(ancho * 0.34, largo * 0.16, fondo * 1.08),
				Vector3(0.0, -largo * 0.08, -fondo * 0.03),
				color_interior
			)
		"traje_chaleco":
			_caja(
				torso,
				Vector3(ancho * 0.58, largo * 0.54, fondo * 1.055),
				Vector3(0.0, -largo * 0.20, -fondo * 0.035),
				color_exterior.lightened(0.10)
			)
			_solapas(torso, ancho, fondo, largo, color_interior)
		"traje":
			_solapas(torso, ancho, fondo, largo, color_interior)
		"chaqueta_trabajo":
			_caja(
				torso,
				Vector3(ancho * 0.24, largo * 0.18, fondo * 1.06),
				Vector3(-ancho * 0.26, -largo * 0.16, -fondo * 0.035),
				color_exterior.lightened(0.10)
			)
		"camisa":
			_caja(
				torso,
				Vector3(ancho * 0.78, largo * 0.76, fondo * 1.05),
				Vector3(0.0, -largo * 0.20, -fondo * 0.035),
				color_interior
			)
		"chaleco":
			_caja(
				torso,
				Vector3(ancho * 0.72, largo * 0.62, fondo * 1.055),
				Vector3(0.0, -largo * 0.20, -fondo * 0.035),
				color_exterior.lightened(0.12)
			)
		"jersey":
			_caja(
				hombros,
				Vector3(ancho * 0.42, largo * 0.13, fondo * 1.08),
				Vector3(0.0, largo * 0.015, -fondo * 0.03),
				color_exterior.lightened(0.08)
			)


func _solapas(torso: Node3D, ancho: float, fondo: float, largo: float, color: Color) -> void:
	_caja(
		torso,
		Vector3(ancho * 0.13, largo * 0.30, fondo * 1.07),
		Vector3(-ancho * 0.13, largo * 0.02, -fondo * 0.04),
		color
	)
	_caja(
		torso,
		Vector3(ancho * 0.13, largo * 0.30, fondo * 1.07),
		Vector3(ancho * 0.13, largo * 0.02, -fondo * 0.04),
		color
	)


func _poner_manga(
	esqueleto: Skeleton3D,
	candidatos: Array[String],
	alto: float,
	ancho_torso: float,
	color: Color,
	sufijo: String,
	radio_relativo: float,
	largo_relativo: float
) -> void:
	var hueso := _buscar_hueso(esqueleto, candidatos)
	if hueso < 0:
		return
	var brazo := _enganche(esqueleto, hueso, "VestuarioManga" + sufijo)
	var malla := CapsuleMesh.new()
	malla.radius = ancho_torso * radio_relativo
	malla.height = maxf(alto * largo_relativo, malla.radius * 2.05)
	malla.radial_segments = 6
	malla.rings = 3
	var instancia := MeshInstance3D.new()
	instancia.mesh = malla
	instancia.position.y = -malla.height * 0.26
	instancia.material_override = _material(color)
	brazo.add_child(instancia)


func _enganche(esqueleto: Skeleton3D, hueso: int, nombre: String) -> BoneAttachment3D:
	var enganche := BoneAttachment3D.new()
	enganche.name = nombre
	enganche.bone_idx = hueso
	esqueleto.add_child(enganche)
	return enganche


func _caja(padre: Node3D, tam: Vector3, posicion: Vector3, color: Color) -> void:
	var malla := BoxMesh.new()
	malla.size = tam
	var instancia := MeshInstance3D.new()
	instancia.mesh = malla
	instancia.position = posicion
	instancia.material_override = _material(color)
	padre.add_child(instancia)


func _material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.SHADER_PSX)
	material.set_shader_parameter("color_base", color)
	return material


func _color_base(nodo: Node) -> Color:
	if nodo is MeshInstance3D:
		var material: Material = (nodo as MeshInstance3D).material_override
		if material is ShaderMaterial:
			var parametro: Variant = material.get_shader_parameter("color_base")
			if parametro is Color:
				return parametro
	for hijo in nodo.get_children():
		var encontrado: Variant = _color_base_opcional(hijo)
		if encontrado != null:
			return encontrado
	return Color(0.36, 0.39, 0.42)


func _color_base_opcional(nodo: Node) -> Variant:
	if nodo is MeshInstance3D:
		var material: Material = (nodo as MeshInstance3D).material_override
		if material is ShaderMaterial:
			var parametro: Variant = material.get_shader_parameter("color_base")
			if parametro is Color:
				return parametro
	for hijo in nodo.get_children():
		var encontrado: Variant = _color_base_opcional(hijo)
		if encontrado != null:
			return encontrado
	return null


func _buscar_esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _buscar_esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null


func _buscar_hueso(esqueleto: Skeleton3D, candidatos: Array[String]) -> int:
	for candidato in candidatos:
		var exacto := esqueleto.find_bone(candidato)
		if exacto >= 0:
			return exacto
	for i in range(esqueleto.get_bone_count()):
		var nombre := String(esqueleto.get_bone_name(i)).to_lower()
		for candidato in candidatos:
			var buscado := candidato.to_lower()
			if nombre.ends_with(":" + buscado) or nombre.ends_with("_" + buscado):
				return i
	return -1


func _distancia_vertical(esqueleto: Skeleton3D, a: int, b: int) -> float:
	return absf(
		esqueleto.get_bone_global_pose(b).origin.y - esqueleto.get_bone_global_pose(a).origin.y
	)
