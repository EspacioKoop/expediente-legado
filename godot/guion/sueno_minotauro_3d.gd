## Materialización 3D del contrato topológico de Minotauro (#437).
##
## `SuenoMinotauro` sigue siendo la única fuente de verdad: este nodo traduce su
## grafo estable a corredores físicos, sus marcas a hilo visible y su topología
## aparente a grandes cuerpos de archivo que cambian de sitio sin tocar la ruta
## real. La presencia nunca combate ni bloquea físicamente al jugador.
class_name SuenoMinotauro3D
extends Node3D

const ID_MITO := "minotauro"
const ANCHO_CORREDOR := 5.2
const ALTURA_MURO := 5.4
const GROSOR_MURO := 0.55
const MARGEN_CRUCE := 3.0

const COLOR_SUELO := Color(0.18, 0.19, 0.17)
const COLOR_ARCHIVO := Color(0.33, 0.35, 0.31)
const COLOR_ARCHIVO_OSCURO := Color(0.19, 0.20, 0.18)
const COLOR_MADERA := Color(0.34, 0.24, 0.16)
const COLOR_ARIADNA := Color(0.72, 0.16, 0.11)
const COLOR_BISAGRA := Color(0.68, 0.55, 0.24)
const COLOR_MINOTAURO := Color(0.075, 0.055, 0.045)
const COLOR_OJO := Color(0.64, 0.12, 0.07)

@export var reduccion_movimiento := false

var _estado := SuenoMinotauro.estado_nuevo()
var _anclajes: Dictionary = {}
var _alas: Dictionary = {}
var _marcas_visibles := 0
var _raiz_marcas: Node3D
var _minotauro: Node3D
var _luz_minotauro: OmniLight3D
var _ultima_respuesta := {
	"presencia": SuenoMinotauro.PRESENCIAS[0],
	"bloqueo": "",
	"ruta_recuperable": true,
}


func _ready() -> void:
	preparar()


func preparar() -> void:
	if get_node_or_null("ArquitecturaMinotauro") != null:
		return
	var arquitectura := Node3D.new()
	arquitectura.name = "ArquitecturaMinotauro"
	add_child(arquitectura)
	_montar_corredores(arquitectura)
	_montar_archivadores(arquitectura)
	_montar_anclajes(arquitectura)
	_montar_repliegue(arquitectura)
	_montar_minotauro(arquitectura)
	_montar_iluminacion(arquitectura)

	_raiz_marcas = Node3D.new()
	_raiz_marcas.name = "MarcasAriadna"
	arquitectura.add_child(_raiz_marcas)
	_actualizar_repliegue(false)
	_actualizar_marcas()
	_actualizar_minotauro(SuenoMinotauro.ENTRADA)


func estado_topologico() -> Dictionary:
	return _estado.duplicate(true)


func lectura_marca(indice: int) -> Dictionary:
	return SuenoMinotauro.leer_marca(_estado, indice)


func cantidad_marcas_visibles() -> int:
	return _marcas_visibles


func presencia_actual() -> String:
	return String(_ultima_respuesta.get("presencia", SuenoMinotauro.PRESENCIAS[0]))


func ruta_recuperable() -> bool:
	return bool(_ultima_respuesta.get("ruta_recuperable", false))


func _montar_corredores(raiz: Node3D) -> void:
	var corredores := Node3D.new()
	corredores.name = "Corredores"
	raiz.add_child(corredores)
	var plano := SuenoMinotauro.plano()
	var vecinos: Dictionary = plano.get("vecinos", {})
	var vistas := {}
	for desde_crudo in vecinos.keys():
		var desde := String(desde_crudo)
		for hasta_crudo in vecinos[desde_crudo]:
			var hasta := String(hasta_crudo)
			var pareja := [desde, hasta]
			pareja.sort()
			var clave := "%s|%s" % [String(pareja[0]), String(pareja[1])]
			if vistas.has(clave):
				continue
			vistas[clave] = true
			_crear_corredor(
				corredores,
				clave.replace("|", "_"),
				SuenoMinotauro.posicion(desde),
				SuenoMinotauro.posicion(hasta),
			)


func _crear_corredor(padre: Node3D, nombre: String, desde: Vector3, hasta: Vector3) -> void:
	var direccion: Vector3 = hasta - desde
	direccion.y = 0.0
	var largo: float = direccion.length()
	if largo <= MARGEN_CRUCE * 1.25:
		return
	var unidad: Vector3 = direccion.normalized()
	var normal := Vector3(-unidad.z, 0.0, unidad.x)
	var longitud_muro: float = maxf(0.8, largo - MARGEN_CRUCE)
	var centro: Vector3 = desde.lerp(hasta, 0.5)

	_crear_tramo_visual(
		padre,
		"Suelo_%s" % nombre,
		desde,
		hasta,
		ANCHO_CORREDOR - 0.7,
		0.12,
		COLOR_SUELO,
	)
	for lado in [-1.0, 1.0]:
		var lado_float := float(lado)
		var posicion: Vector3 = centro + normal * lado_float * ANCHO_CORREDOR * 0.5
		_crear_muro_fisico(
			padre,
			"Muro_%s_%s" % [nombre, "A" if lado_float < 0.0 else "B"],
			posicion,
			unidad,
			longitud_muro,
			COLOR_ARCHIVO_OSCURO if lado_float < 0.0 else COLOR_ARCHIVO,
		)


func _crear_muro_fisico(
	padre: Node3D,
	nombre: String,
	posicion: Vector3,
	direccion: Vector3,
	longitud: float,
	color: Color,
) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	cuerpo.position = posicion
	padre.add_child(cuerpo)
	cuerpo.look_at(posicion + direccion, Vector3.UP)

	var tam := Vector3(GROSOR_MURO, ALTURA_MURO, longitud)
	var malla := BoxMesh.new()
	malla.size = tam
	var visual := MeshInstance3D.new()
	visual.name = "Archivo"
	visual.mesh = malla
	visual.position.y = ALTURA_MURO * 0.5
	visual.material_override = _material(color)
	cuerpo.add_child(visual)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	colision.position.y = ALTURA_MURO * 0.5
	cuerpo.add_child(colision)


func _montar_archivadores(raiz: Node3D) -> void:
	var archivo := Node3D.new()
	archivo.name = "ArchivoDeformado"
	raiz.add_child(archivo)
	var ids := [
		SuenoMinotauro.VESTIBULO,
		SuenoMinotauro.CRUCE_NORTE,
		SuenoMinotauro.CRUCE_SUR,
		SuenoMinotauro.ARCHIVO_ESTE,
		SuenoMinotauro.ARCHIVO_RETORNO,
		SuenoMinotauro.CENTRO,
	]
	for indice in range(ids.size()):
		var id_nodo := String(ids[indice])
		var base: Vector3 = SuenoMinotauro.posicion(id_nodo)
		var lado := -1.0 if indice % 2 == 0 else 1.0
		var torre := Node3D.new()
		torre.name = "Archivador_%s" % id_nodo
		torre.position = base + Vector3(lado * 3.1, 0.0, 0.0)
		torre.rotation_degrees.y = float((indice * 23) % 70) - 35.0
		archivo.add_child(torre)
		_crear_caja(
			torre,
			"Cuerpo",
			Vector3(1.6, 4.4 + float(indice % 3), 2.0),
			Vector3(0.0, 2.2 + float(indice % 3) * 0.5, 0.0),
			COLOR_ARCHIVO,
		)
		for cajon in range(3):
			_crear_caja(
				torre,
				"Tirador%d" % cajon,
				Vector3(0.55, 0.08, 0.08),
				Vector3(0.0, 1.2 + float(cajon) * 0.75, -1.03),
				COLOR_MADERA,
			)


func _montar_anclajes(raiz: Node3D) -> void:
	var anclajes := Node3D.new()
	anclajes.name = "AnclajesAriadna"
	raiz.add_child(anclajes)
	for id_nodo in [
		SuenoMinotauro.CRUCE_NORTE,
		SuenoMinotauro.CRUCE_SUR,
		SuenoMinotauro.ARCHIVO_ESTE,
		SuenoMinotauro.ARCHIVO_RETORNO,
	]:
		var id_aparente := String(id_nodo)
		var anclaje := Interactuable3D.new()
		anclaje.name = "Marca_%s" % id_aparente
		anclaje.position = SuenoMinotauro.posicion(id_aparente) + Vector3(0.0, 0.8, 0.0)
		anclaje.verbo = Interactuable3D.Verbo.USAR
		anclaje.nombre_objeto = "hilo de Ariadna"
		anclaje.activado.connect(_poner_marca.bind(id_aparente))
		anclajes.add_child(anclaje)

		var forma := CylinderShape3D.new()
		forma.radius = 0.7
		forma.height = 1.4
		var colision := CollisionShape3D.new()
		colision.shape = forma
		anclaje.add_child(colision)

		var carrete := CylinderMesh.new()
		carrete.top_radius = 0.42
		carrete.bottom_radius = 0.42
		carrete.height = 0.42
		carrete.radial_segments = 8
		var visual := MeshInstance3D.new()
		visual.name = "Carrete"
		visual.mesh = carrete
		visual.material_override = _material(COLOR_ARIADNA)
		anclaje.add_child(visual)
		_crear_caja(
			anclaje,
			"Estaca",
			Vector3(0.18, 1.5, 0.18),
			Vector3(0.0, -0.05, 0.0),
			COLOR_BISAGRA,
		)
		_anclajes[id_aparente] = anclaje

	_montar_umbral_topologico(raiz, "BisagraTopologica", SuenoMinotauro.BISAGRA)
	_montar_umbral_topologico(raiz, "CentroTopologico", SuenoMinotauro.CENTRO)


func _montar_umbral_topologico(raiz: Node3D, nombre: String, id_nodo: String) -> void:
	var umbral := Interactuable3D.new()
	umbral.name = nombre
	umbral.position = SuenoMinotauro.posicion(id_nodo) + Vector3(0.0, 1.3, 0.0)
	umbral.verbo = Interactuable3D.Verbo.USAR
	umbral.nombre_objeto = "paso imposible"
	umbral.activado.connect(_cruzar_umbral.bind(id_nodo))
	raiz.add_child(umbral)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(2.2, 2.6, 2.2)
	colision.shape = forma
	umbral.add_child(colision)
	for lado in [-1.0, 1.0]:
		var lado_float := float(lado)
		var jamba := _crear_caja(
			umbral,
			"Jamba%s" % ("A" if lado_float < 0.0 else "B"),
			Vector3(0.22, 3.4, 0.22),
			Vector3(lado_float * 1.1, 0.4, 0.0),
			COLOR_BISAGRA,
		)
		jamba.rotation_degrees.z = lado_float * 11.0


func _montar_repliegue(raiz: Node3D) -> void:
	var repliegue := Node3D.new()
	repliegue.name = "RepliegueTopologico"
	raiz.add_child(repliegue)
	for id_nodo in [
		SuenoMinotauro.CRUCE_NORTE,
		SuenoMinotauro.CRUCE_SUR,
		SuenoMinotauro.ARCHIVO_ESTE,
		SuenoMinotauro.ARCHIVO_RETORNO,
	]:
		var real := String(id_nodo)
		var ala := Node3D.new()
		ala.name = "Ala_%s" % real
		repliegue.add_child(ala)
		_crear_caja(
			ala,
			"BloqueArchivo",
			Vector3(2.6, 5.8, 3.8),
			Vector3.ZERO,
			COLOR_ARCHIVO_OSCURO,
		)
		for indice in range(4):
			_crear_caja(
				ala,
				"Etiqueta%d" % indice,
				Vector3(1.0, 0.10, 0.10),
				Vector3(0.0, -1.6 + float(indice) * 1.0, -1.95),
				COLOR_BISAGRA,
			)
		_alas[real] = ala


func _montar_minotauro(raiz: Node3D) -> void:
	_minotauro = Node3D.new()
	_minotauro.name = "PresenciaMinotauro"
	raiz.add_child(_minotauro)

	var torso := CylinderMesh.new()
	torso.top_radius = 0.58
	torso.bottom_radius = 0.78
	torso.height = 3.0
	torso.radial_segments = 7
	var torso_visual := MeshInstance3D.new()
	torso_visual.name = "Torso"
	torso_visual.mesh = torso
	torso_visual.position.y = 1.6
	torso_visual.material_override = _material(COLOR_MINOTAURO)
	_minotauro.add_child(torso_visual)

	var cabeza := SphereMesh.new()
	cabeza.radius = 0.72
	cabeza.height = 1.35
	cabeza.radial_segments = 8
	cabeza.rings = 5
	var cabeza_visual := MeshInstance3D.new()
	cabeza_visual.name = "Cabeza"
	cabeza_visual.mesh = cabeza
	cabeza_visual.position = Vector3(0.0, 3.35, -0.12)
	cabeza_visual.scale = Vector3(1.2, 0.9, 1.25)
	cabeza_visual.material_override = _material(COLOR_MINOTAURO)
	_minotauro.add_child(cabeza_visual)

	for lado in [-1.0, 1.0]:
		var lado_float := float(lado)
		var cuerno := CylinderMesh.new()
		cuerno.top_radius = 0.04
		cuerno.bottom_radius = 0.18
		cuerno.height = 1.15
		cuerno.radial_segments = 6
		var visual := MeshInstance3D.new()
		visual.name = "Cuerno%s" % ("A" if lado_float < 0.0 else "B")
		visual.mesh = cuerno
		visual.position = Vector3(lado_float * 0.55, 3.85, 0.0)
		visual.rotation_degrees.z = lado_float * -34.0
		visual.material_override = _material(Color(0.44, 0.40, 0.31))
		_minotauro.add_child(visual)

	for lado in [-1.0, 1.0]:
		var lado_float := float(lado)
		var ojo := SphereMesh.new()
		ojo.radius = 0.075
		ojo.height = 0.15
		ojo.radial_segments = 6
		ojo.rings = 4
		var ojo_visual := MeshInstance3D.new()
		ojo_visual.name = "Ojo%s" % ("A" if lado_float < 0.0 else "B")
		ojo_visual.mesh = ojo
		ojo_visual.position = Vector3(lado_float * 0.27, 3.48, -0.70)
		ojo_visual.material_override = _material_emisivo(COLOR_OJO)
		_minotauro.add_child(ojo_visual)

	_luz_minotauro = OmniLight3D.new()
	_luz_minotauro.name = "LuzPresencia"
	_luz_minotauro.position = Vector3(0.0, 3.4, -0.4)
	_luz_minotauro.light_color = COLOR_OJO
	_luz_minotauro.light_energy = 0.55
	_luz_minotauro.omni_range = 3.5
	_minotauro.add_child(_luz_minotauro)


func _montar_iluminacion(raiz: Node3D) -> void:
	var luz := OmniLight3D.new()
	luz.name = "LuzArchivo"
	luz.position = Vector3(0.0, 4.8, -2.0)
	luz.light_color = Color(0.47, 0.43, 0.34)
	luz.light_energy = 2.2
	luz.omni_range = 24.0
	raiz.add_child(luz)


func _poner_marca(_actor: Node, nodo_aparente: String) -> void:
	if not SuenoMinotauro.poner_marca(_estado, nodo_aparente):
		return
	var anclaje := _anclajes.get(nodo_aparente) as Interactuable3D
	if anclaje != null:
		anclaje.habilitado = false
	_actualizar_marcas()
	var fase := int(_estado.get("fase_topologica", 0))
	_actualizar_minotauro(SuenoMinotauro.nodo_real(nodo_aparente, fase))


func _cruzar_umbral(_actor: Node, nodo_real: String) -> void:
	if not SuenoMinotauro.cruzar(_estado, nodo_real):
		return
	_actualizar_repliegue(true)
	_actualizar_marcas()
	_actualizar_minotauro(nodo_real)


func _actualizar_marcas() -> void:
	if _raiz_marcas == null:
		return
	for hijo in _raiz_marcas.get_children():
		hijo.free()
	_marcas_visibles = 0
	var marcas: Array = _estado.get("marcas", [])
	var anterior := Vector3.ZERO
	var hay_anterior := false
	for indice in range(marcas.size()):
		var lectura := SuenoMinotauro.leer_marca(_estado, indice)
		if lectura.is_empty():
			continue
		var aparente := String(lectura.get("aparece_en", ""))
		var posicion: Vector3 = SuenoMinotauro.posicion(aparente) + Vector3(0.0, 0.14, 0.0)
		_crear_caja(
			_raiz_marcas,
			"MarcaVisible%02d" % indice,
			Vector3(1.15, 0.07, 0.22),
			posicion,
			COLOR_ARIADNA,
		)
		if hay_anterior:
			_crear_tramo_visual(
				_raiz_marcas,
				"Hilo%02d" % indice,
				anterior,
				posicion,
				0.08,
				0.06,
				COLOR_ARIADNA,
			)
		anterior = posicion
		hay_anterior = true
		_marcas_visibles += 1


func _actualizar_repliegue(animar: bool) -> void:
	var fase := int(_estado.get("fase_topologica", 0))
	var indice := 0
	for real_crudo in _alas.keys():
		var real := String(real_crudo)
		var ala := _alas[real] as Node3D
		if ala == null:
			continue
		var aparente := SuenoMinotauro.nodo_aparente(real, fase)
		var destino: Vector3 = SuenoMinotauro.posicion(aparente)
		var signo := -1.0 if indice % 2 == 0 else 1.0
		destino += Vector3(signo * 2.9, 3.0, 0.0)
		if SuenoMinotauro.transformacion_actual(_estado) == "escala_imposible":
			destino.y += 2.4 if indice % 2 == 0 else -0.8
		var giro := Vector3(0.0, float((fase * 61 + indice * 29) % 180) - 90.0, 0.0)
		if not animar or reduccion_movimiento:
			ala.position = destino
			ala.rotation_degrees = giro
		else:
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(ala, "position", destino, 0.85)
			tween.tween_property(ala, "rotation_degrees", giro, 0.85)
		indice += 1


func _actualizar_minotauro(nodo_real: String) -> void:
	if _minotauro == null:
		return
	_ultima_respuesta = SuenoMinotauro.responder_minotauro(_estado, nodo_real)
	var presencia := String(_ultima_respuesta.get("presencia", SuenoMinotauro.PRESENCIAS[0]))
	var bloqueo := String(_ultima_respuesta.get("bloqueo", ""))
	var objetivo_real := bloqueo
	if objetivo_real.is_empty():
		var por_presencia := {
			"lejano": SuenoMinotauro.ARCHIVO_RETORNO,
			"respiracion": SuenoMinotauro.CRUCE_SUR,
			"cruce": SuenoMinotauro.ARCHIVO_ESTE,
			"cerca": SuenoMinotauro.CENTRO,
		}
		objetivo_real = String(por_presencia.get(presencia, SuenoMinotauro.ARCHIVO_RETORNO))
	var fase := int(_estado.get("fase_topologica", 0))
	var aparente := SuenoMinotauro.nodo_aparente(objetivo_real, fase)
	_minotauro.position = SuenoMinotauro.posicion(aparente)
	var escalas := {"lejano": 0.72, "respiracion": 0.84, "cruce": 1.0, "cerca": 1.16}
	var escala := float(escalas.get(presencia, 0.72))
	_minotauro.scale = Vector3.ONE * escala
	if _luz_minotauro != null:
		_luz_minotauro.light_energy = 0.35 + escala * 0.35


func _crear_tramo_visual(
	padre: Node3D,
	nombre: String,
	desde: Vector3,
	hasta: Vector3,
	ancho: float,
	alto: float,
	color: Color,
) -> MeshInstance3D:
	var distancia: float = desde.distance_to(hasta)
	var centro: Vector3 = desde.lerp(hasta, 0.5)
	centro.y = maxf(desde.y, hasta.y) + alto * 0.5
	var nodo := _crear_caja(
		padre,
		nombre,
		Vector3(ancho, alto, distancia),
		centro,
		color,
	)
	nodo.look_at(Vector3(hasta.x, centro.y, hasta.z), Vector3.UP)
	return nodo


func _crear_caja(
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
	nodo.material_override = _material(color)
	padre.add_child(nodo)
	return nodo


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	return material


func _material_emisivo(color: Color) -> StandardMaterial3D:
	var material := _material(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.8
	return material
