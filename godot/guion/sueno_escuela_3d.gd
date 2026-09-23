## Presentación 3D de la pesadilla escolar (#284).
##
## El id `crucero` ya no define la forma (#798). La arquitectura visible y la
## colisión pertenecen al contorno poligonal del espacio; esta capa no las
## sustituye. Solo conserva lenguaje escolar reutilizable —fluorescentes,
## puertas, pupitres, taquillas, reloj y pizarra— sobre esa silueta.
class_name SuenoEscuela3D
extends Node3D

const ESCENA_PUPITRE := preload("res://escenas/suenos/props_284/pupitre_escolar.tscn")
const ESCENA_TAQUILLAS := preload("res://escenas/suenos/props_284/taquillas_escolares.tscn")
const ESCENA_RELOJ := preload("res://escenas/suenos/props_284/reloj_escolar_anomalo.tscn")
const ALTURA := 2.8
const INTERVALO_TIMBRE := 7.5
# Se iluminan varios hitos del contorno fragmentado. La evidencia sin HUD de
# #282 mostró que dejar los quads autoiluminados sin luz local hunde la utilería
# cercana en sombra y hace leer la sala como vacío.
const FLUORESCENTES_CON_LUZ := [0, 2, 4, 5]

var _puertas: Array[Node3D] = []
var _numeros: Array[Label3D] = []
var _pupitres: Array[Node3D] = []
var _dibujo: MeshInstance3D
var _reloj_fantasma: Node3D
var _timbre: AudioStreamPlayer3D
var _voces: AudioStreamPlayer3D
var _tiempo := 0.0
var _proximo_timbre := INTERVALO_TIMBRE
var _variante := 0


static func montar(mundo: Node3D, espacio: Dictionary) -> Node3D:
	if mundo == null or String(espacio.get("identidad_onirica", "")) != SuenoEscuela.ID:
		return null
	var presentacion := SuenoEscuela3D.new()
	presentacion.name = "PresentacionEscuela284"
	mundo.add_child(presentacion)
	presentacion._configurar(espacio)
	return presentacion


func _configurar(espacio: Dictionary) -> void:
	var contorno: PackedVector2Array = espacio.get("contorno", PackedVector2Array())
	if contorno.size() < 3:
		return
	# La malla/collision de Espacio3D sigue visible: redibujar `planta` aquí
	# reintroduciría exactamente la cruz que #798 elimina.
	_montar_fluorescentes()
	_montar_puertas()
	_montar_pupitres(espacio)
	_montar_taquillas(espacio)
	_montar_reloj(espacio)
	_montar_pizarra()
	_montar_audio()
	_aplicar_variante()


func _process(delta: float) -> void:
	_tiempo += delta
	if _reloj_fantasma != null:
		_reloj_fantasma.rotation_degrees.z -= delta * 22.0
	if _dibujo != null:
		_dibujo.rotation_degrees.y = sin(_tiempo * 0.7) * 3.0
	if _tiempo < _proximo_timbre:
		return
	_proximo_timbre += INTERVALO_TIMBRE
	_variante = 1 - _variante
	_aplicar_variante()
	if _timbre != null:
		_timbre.play()


func _ocultar_arquitectura_base() -> void:
	var mundo := get_parent()
	if mundo == null:
		return
	for hijo in mundo.get_children():
		if not hijo is StaticBody3D:
			continue
		for nodo in hijo.find_children("*", "MeshInstance3D", true, false):
			var visual := nodo as MeshInstance3D
			if visual != null:
				visual.visible = false


func _montar_arquitectura(bloques: Array) -> void:
	_montar_superficie_celdas(bloques, 0.035, false, "LinoleoEscolar", Color(0.29, 0.31, 0.25))
	_montar_superficie_celdas(bloques, ALTURA - 0.02, true, "TechoEscolar", Color(0.69, 0.68, 0.59))

	for dato in Planta.contorno(bloques):
		var tramo: Dictionary = dato
		var inicio: Vector3
		var fin: Vector3
		if String(tramo["eje"]) == "x":
			inicio = Planta.esquina_en_metros(
				bloques, Vector2i(int(tramo["desde"]), int(tramo["linea"]))
			)
			fin = Planta.esquina_en_metros(
				bloques, Vector2i(int(tramo["hasta"]), int(tramo["linea"]))
			)
		else:
			inicio = Planta.esquina_en_metros(
				bloques, Vector2i(int(tramo["linea"]), int(tramo["desde"]))
			)
			fin = Planta.esquina_en_metros(
				bloques, Vector2i(int(tramo["linea"]), int(tramo["hasta"]))
			)
		_montar_pano(inicio, fin, 0.0, 1.05, Color(0.20, 0.31, 0.25), "ZocaloEscolar")
		_montar_pano(inicio, fin, 1.05, ALTURA, Color(0.72, 0.69, 0.56), "ParedEscolar")


func _montar_superficie_celdas(
	bloques: Array, altura: float, invertida: bool, nombre: String, color: Color
) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for dato in Planta.celdas(bloques).keys():
		var celda: Vector2i = dato
		var p := Planta.esquina_en_metros(bloques, celda)
		var a := Vector3(p.x, altura, p.z)
		var b := a + Vector3(Planta.CELDA, 0.0, 0.0)
		var c := a + Vector3(Planta.CELDA, 0.0, Planta.CELDA)
		var d := a + Vector3(0.0, 0.0, Planta.CELDA)
		if invertida:
			_anadir_triangulos(st, a, d, c, b)
		else:
			_anadir_triangulos(st, a, b, c, d)
	st.generate_normals()
	var superficie := MeshInstance3D.new()
	superficie.name = nombre
	superficie.mesh = st.commit()
	superficie.material_override = _material(color, 0.88)
	add_child(superficie)


func _montar_pano(
	inicio: Vector3, fin: Vector3, y0: float, y1: float, color: Color, nombre: String
) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(inicio.x, y0, inicio.z)
	var b := Vector3(fin.x, y0, fin.z)
	var c := Vector3(fin.x, y1, fin.z)
	var d := Vector3(inicio.x, y1, inicio.z)
	_anadir_triangulos(st, a, b, c, d)
	_anadir_triangulos(st, b, a, d, c)
	st.generate_normals()
	var pano := MeshInstance3D.new()
	pano.name = nombre
	pano.mesh = st.commit()
	pano.material_override = _material(color, 0.92)
	add_child(pano)


func _anadir_triangulos(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)


func _montar_fluorescentes() -> void:
	var posiciones := [
		Vector3(-8.0, 2.72, -9.0),
		Vector3(-2.0, 2.72, -10.0),
		Vector3(6.0, 2.72, -7.0),
		Vector3(-6.0, 2.72, 2.0),
		Vector3(2.0, 2.72, 5.0),
		Vector3(5.0, 2.72, 10.0),
	]
	for i in posiciones.size():
		var lampara := MeshInstance3D.new()
		lampara.name = "Fluorescente%02d" % (i + 1)
		var forma := QuadMesh.new()
		forma.size = Vector2(2.4, 0.22)
		lampara.mesh = forma
		lampara.position = posiciones[i]
		lampara.rotation_degrees.x = -90.0
		var material := _material(Color(0.92, 0.90, 0.70), 0.18)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lampara.material_override = material
		add_child(lampara)
		if FLUORESCENTES_CON_LUZ.has(i):
			var luz := OmniLight3D.new()
			luz.name = "LuzFluorescente%02d" % (i + 1)
			luz.position = posiciones[i] + Vector3(0.0, -0.18, 0.0)
			luz.light_color = Color(0.80, 0.84, 0.65)
			luz.light_energy = 0.62
			luz.omni_range = 8.0
			add_child(luz)


func _montar_puertas() -> void:
	for i in 4:
		var puerta := MeshInstance3D.new()
		puerta.name = "PuertaAula%02d" % (i + 1)
		var forma := QuadMesh.new()
		forma.size = Vector2(1.55, 2.10)
		puerta.mesh = forma
		puerta.material_override = _material(Color(0.24, 0.13, 0.075), 0.86)
		add_child(puerta)
		_puertas.append(puerta)

		var numero := Label3D.new()
		numero.name = "NumeroAula%02d" % (i + 1)
		numero.pixel_size = 0.006
		numero.font_size = 28
		numero.modulate = Color(0.90, 0.86, 0.68)
		add_child(numero)
		_numeros.append(numero)


func _montar_pupitres(espacio: Dictionary) -> void:
	var posiciones := [
		Vector3(-7.0, 0.0, -5.0),
		Vector3(-3.5, 0.0, -5.5),
		Vector3(0.0, 0.0, -4.5),
		Vector3(-4.5, 0.0, 2.5),
		Vector3(-1.0, 0.0, 4.5),
		Vector3(3.0, 0.0, 6.5),
	]
	for i in posiciones.size():
		var pupitre := ESCENA_PUPITRE.instantiate() as Node3D
		pupitre.name = "Pupitre%02d" % (i + 1)
		pupitre.position = posiciones[i]
		pupitre.rotation_degrees.y = 90.0
		add_child(pupitre)
		_pupitres.append(pupitre)

	var interactivo := ESCENA_PUPITRE.instantiate() as Node3D
	interactivo.name = "PupitreDelDibujo"
	interactivo.position = espacio.get("escuela_pupitre_pos", SuenoEscuela.PUPITRE_INTERACCION)
	interactivo.rotation_degrees.y = 90.0
	add_child(interactivo)
	_pupitres.append(interactivo)

	var forma := QuadMesh.new()
	forma.size = Vector2(0.48, 0.62)
	_dibujo = MeshInstance3D.new()
	_dibujo.name = "DibujoMutante"
	_dibujo.mesh = forma
	_dibujo.position = interactivo.position + Vector3(0.0, 0.90, 0.0)
	_dibujo.rotation_degrees = Vector3(-82.0, 0.0, 8.0)
	_dibujo.material_override = _material(Color(0.82, 0.76, 0.57), 0.94)
	add_child(_dibujo)


func _montar_taquillas(espacio: Dictionary) -> void:
	var centro: Vector3 = espacio.get("escuela_taquillas_pos", SuenoEscuela.TAQUILLAS_REFERENCIA)
	for desplazamiento in [-3.0, 0.0, 3.0]:
		var taquillas := ESCENA_TAQUILLAS.instantiate() as Node3D
		taquillas.position = centro + Vector3(desplazamiento, 0.0, 1.7)
		taquillas.rotation_degrees.y = 180.0
		add_child(taquillas)


func _montar_reloj(espacio: Dictionary) -> void:
	var reloj := ESCENA_RELOJ.instantiate() as Node3D
	reloj.name = "RelojTresAgujas"
	reloj.position = espacio.get("escuela_reloj_pos", SuenoEscuela.RELOJ_REFERENCIA)
	add_child(reloj)
	_reloj_fantasma = reloj.get_node_or_null("AgujaFantasma") as Node3D


func _montar_pizarra() -> void:
	var pizarra := MeshInstance3D.new()
	pizarra.name = "PizarraVacia"
	var forma := QuadMesh.new()
	forma.size = Vector2(4.8, 1.45)
	pizarra.mesh = forma
	pizarra.position = Vector3(-8.0, 1.62, 1.0)
	pizarra.rotation_degrees.y = 90.0
	pizarra.material_override = _material(Color(0.055, 0.16, 0.12), 0.78)
	add_child(pizarra)


func _montar_audio() -> void:
	_timbre = AudioStreamPlayer3D.new()
	_timbre.name = "TimbreFueraDeHorario"
	_timbre.stream = SuenoEscuelaAudio.timbre()
	_timbre.position = Vector3(0.0, 2.45, 0.0)
	_timbre.volume_db = -8.0
	_timbre.unit_size = 14.0
	_timbre.max_distance = 55.0
	add_child(_timbre)

	_voces = AudioStreamPlayer3D.new()
	_voces.name = "VocesAulaVacia"
	_voces.stream = SuenoEscuelaAudio.voces_vacias()
	_voces.position = Vector3(0.0, 1.55, 13.0)
	_voces.volume_db = -24.0
	_voces.unit_size = 7.0
	_voces.max_distance = 38.0
	add_child(_voces)
	_voces.play()


func _aplicar_variante() -> void:
	var posiciones_a := [
		Vector3(-7.0, 1.06, -6.0),
		Vector3(-3.0, 1.06, 3.0),
		Vector3(5.0, 1.06, -5.0),
		Vector3(5.0, 1.06, 6.0),
	]
	var posiciones_b := [
		Vector3(-5.0, 1.06, -8.0),
		Vector3(1.0, 1.06, -5.0),
		Vector3(-4.0, 1.06, 7.0),
		Vector3(6.0, 1.06, 4.0),
	]
	var posiciones := posiciones_a if _variante == 0 else posiciones_b
	for i in _puertas.size():
		_puertas[i].position = posiciones[i]
		_puertas[i].rotation_degrees.y = (180.0 if posiciones[i].z > 0.0 else 0.0)
		_numeros[i].position = (
			posiciones[i] + Vector3(0.0, 1.45, -0.025 if posiciones[i].z > 0.0 else 0.025)
		)
		_numeros[i].rotation_degrees.y = _puertas[i].rotation_degrees.y
		_numeros[i].text = str(2 + i + _variante * 7)

	for i in _pupitres.size():
		_pupitres[i].rotation_degrees.y = 90.0 if _variante == 0 else -90.0

	if _dibujo != null:
		var material := _dibujo.material_override as StandardMaterial3D
		if material != null:
			material.albedo_color = (
				Color(0.82, 0.76, 0.57) if _variante == 0 else Color(0.62, 0.72, 0.54)
			)


func _material(color: Color, rugosidad: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rugosidad
	return material
