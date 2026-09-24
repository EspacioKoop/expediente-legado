## Contrato de los avatares fotorrealistas de oficina (#275).
##
## Monta cada compañero por la misma ruta que la oficina —`Companeros.cuerpo_de`
## y `Modelos.persona`— y comprueba lo que en los intentos anteriores solo se
## veía en captura: que el avatar es el suyo y no el maniquí, que conserva su
## ropa en vez de teñirse, que se anima con los clips comunes y que, animado,
## pisa el suelo y mira hacia donde mira `persona.fbx`.
extends SceneTree

## Tolerancias en metros. El tobillo queda unos centímetros sobre el suelo. El
## hueso `Head` está en la base del cráneo, a ~88 % de la estatura: 1,35-1,75 m
## cubre de una adulta de 1,55 m a un adulto de casi 2 m.
const PIE_MIN := -0.05
const PIE_MAX := 0.20
const CABEZA_MIN := 1.35
const CABEZA_MAX := 1.75

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	process_frame.connect(_ejecutar, CONNECT_ONE_SHOT)


func _ejecutar() -> void:
	_probar_roster_con_cuerpo_propio()
	for quien in [Companeros.CUNADO] + Array(Companeros.ROSTER):
		await _probar_avatar(quien)
	await _probar_clip_de_oficina()
	_probar_maniqui_intacto()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_roster_con_cuerpo_propio() -> void:
	var vistos := {}
	for quien in [Companeros.CUNADO] + Array(Companeros.ROSTER):
		var cuerpo := Companeros.cuerpo_de(quien)
		_comprobar(Modelos.es_realista(cuerpo), "%s tiene avatar realista" % quien["id"])
		_comprobar(Modelos.hay(cuerpo), "el avatar de %s existe" % quien["id"])
		_comprobar(not vistos.has(cuerpo), "%s no comparte avatar" % quien["id"])
		vistos[cuerpo] = true


func _probar_avatar(quien: Dictionary) -> void:
	var id := String(quien["id"])
	var cuerpo := Node3D.new()
	root.add_child(cuerpo)
	var creada := Modelos.persona(
		cuerpo, Companeros.cuerpo_de(quien), quien["color"], String(quien.get("retrato", ""))
	)
	_comprobar(creada, "%s se monta" % id)
	var pieza := cuerpo.get_child(0) as Node3D
	_comprobar(
		String(pieza.scene_file_path).begins_with(Modelos.RUTA + Modelos.CARPETA_REALISTAS),
		"%s no es el maniquí" % id
	)
	var tintadas := 0
	for malla in pieza.find_children("*", "MeshInstance3D", true, false):
		if (malla as MeshInstance3D).material_override != null:
			tintadas += 1
	_comprobar(tintadas == 0, "%s conserva su ropa y su piel" % id)
	_comprobar_materiales(pieza, id)
	_comprobar(
		pieza.find_children("*", "BoneAttachment3D", true, false).is_empty(),
		"%s no lleva cara ni ropa procedural encima" % id
	)

	var reproductor := Modelos._reproductor(pieza)
	_comprobar(reproductor != null, "%s tiene reproductor" % id)
	if reproductor == null:
		cuerpo.free()
		return
	_comprobar(reproductor.current_animation == "base/idle", "%s respira con el idle" % id)
	await _asentar(reproductor)
	_comprobar_postura(pieza, id + " en idle")
	cuerpo.free()


## Los gestos de oficina de UAL (#134) llegan al avatar igual que al maniquí.
func _probar_clip_de_oficina() -> void:
	var cuerpo := Node3D.new()
	root.add_child(cuerpo)
	Modelos.persona(cuerpo, Companeros.cuerpo_de(Companeros.CUNADO), Color.GRAY)
	var pieza := cuerpo.get_child(0) as Node3D
	for clip in ["telefono", "brazos_cruzados", "conversar"]:
		_comprobar(AnimacionesUAL.reproducir(pieza, clip, 0.3), "el avatar sabe hacer %s" % clip)
		await _asentar(Modelos._reproductor(pieza))
		_comprobar_postura(pieza, "avatar en " + clip)
	Modelos._animar(pieza, "walk")
	_comprobar(Modelos._reproductor(pieza).current_animation == "base/walk", "el avatar sabe andar")
	cuerpo.free()


## El resto de figuras (bolos, careo, jugador) siguen con `persona.fbx` hasta su
## propio corte: el avatar no puede colarse por el nombre genérico.
func _probar_maniqui_intacto() -> void:
	_comprobar(
		not Modelos.es_realista(Companeros.CUERPO), "el cuerpo genérico sigue siendo el de siempre"
	)
	_comprobar(Companeros.cuerpo_de({}) == "", "sin id no hay cuerpo")


## Las superficies opacas pasan al shader del sitio con SU textura —para que la
## oficina las ilumine por píxel (#789)— y las recortadas por alfa conservan el
## recorte en vez de pintarse como tarjetas opacas.
func _comprobar_materiales(pieza: Node3D, id: String) -> void:
	var del_sitio := 0
	var ajenas := 0
	for nodo in pieza.find_children("*", "MeshInstance3D", true, false):
		var malla: MeshInstance3D = nodo
		for superficie in malla.mesh.get_surface_count():
			var material := malla.get_active_material(superficie)
			if material is BaseMaterial3D:
				if material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
					ajenas += 1
			elif (
				material is ShaderMaterial
				and material.shader.resource_path == Espacio3D.shader_del_sitio()
				and material.get_shader_parameter("con_textura")
				and material.get_shader_parameter("usar_uv")
			):
				del_sitio += 1
			else:
				ajenas += 1
	_comprobar(del_sitio > 0, "%s usa el shader del sitio con su textura" % id)
	_comprobar(ajenas == 0, "%s no deja superficies opacas con otro material" % id)


func _comprobar_postura(pieza: Node3D, que: String) -> void:
	var esqueleto := Modelos._esqueleto(pieza)
	var suelo := pieza.global_position.y
	var pie_i := _hueso_global(esqueleto, "LeftFoot")
	var pie_d := _hueso_global(esqueleto, "RightFoot")
	var cabeza := _hueso_global(esqueleto, "Head")
	var pie := minf(pie_i.y, pie_d.y) - suelo
	_comprobar(pie > PIE_MIN and pie < PIE_MAX, "%s pisa el suelo (pie a %.2f m)" % [que, pie])
	var alto := cabeza.y - suelo
	_comprobar(
		alto > CABEZA_MIN and alto < CABEZA_MAX, "%s tiene altura de adulto (%.2f m)" % [que, alto]
	)
	# `persona.fbx` mira a su +Z local; los dedos del pie van por delante del
	# tobillo en la dirección en que se mira.
	var puntera := _hueso_global(esqueleto, "LeftToes") - pie_i
	var adelante := pieza.global_transform.basis.z
	_comprobar(puntera.dot(adelante) > 0.0, "%s mira hacia +Z como el maniquí" % que)


func _hueso_global(esqueleto: Skeleton3D, nombre: String) -> Vector3:
	var hueso := esqueleto.find_bone(nombre)
	if hueso < 0:
		_comprobar(false, "existe el hueso %s" % nombre)
		return Vector3.ZERO
	return (esqueleto.global_transform * esqueleto.get_bone_global_pose(hueso)).origin


func _asentar(reproductor: AnimationPlayer) -> void:
	reproductor.advance(0.0)
	await process_frame
	await process_frame


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + descripcion)
