## Corte vertical standalone del sueño de la Hidra (#439).
##
## La escena separa deliberadamente dos capas:
## - lógica reproducible: cortar síntomas prolifera hasta límites duros y revela
##   una pista progresiva hacia un nodo común;
## - presentación 3D: cabezas y habitaciones regeneradas se montan con primitivas
##   sin colisión. La arquitectura nueva nunca invade el corredor seguro.
##
## No hay combate, daño ni ventanas de timing: las tres acciones públicas son
## deliberadas (`accion_sintoma`, `observar_conexiones`, `accion_nodo_comun`).
class_name SuenoHidra
extends Node3D

signal estado_cambiado(estado: Dictionary)
signal hidra_resuelta

const SEMILLA := "semilla_onirica_hidra"
const CABEZAS_INICIALES := 3
const MAX_CABEZAS := 9
const CORTES_POR_REGENERACION := 2
const MAX_REGENERACIONES := 2
const PISTA_NODO_LEGIBLE := 2
const ANCHO_CORREDOR_SEGURO := 3.0
const POSICION_RAIZ := Vector3(0.0, 0.8, -2.0)

## Anclas visuales fijas: la seed solo rota el punto de inicio. Así la misma
## partida produce la misma proliferación incluso después de guardar/cargar.
const ANCLAS_CABEZAS := [
	Vector3(-4.5, 0.0, -4.0),
	Vector3(4.5, 0.0, -4.0),
	Vector3(-5.5, 0.0, 1.0),
	Vector3(5.5, 0.0, 1.0),
	Vector3(-6.0, 0.0, 6.0),
	Vector3(6.0, 0.0, 6.0),
	Vector3(-4.5, 0.0, 10.0),
	Vector3(4.5, 0.0, 10.0),
	Vector3(0.0, 0.0, 12.0),
]

## Las salas nacen a ambos lados del eje Z. Solo son malla: no contienen
## CollisionShape3D/StaticBody3D y por tanto no pueden cerrar la ruta jugable.
const ANCLAS_REGENERACION := [
	Vector3(-6.0, 0.0, 3.0),
	Vector3(6.0, 0.0, 7.0),
]

var _estado: Dictionary = {}
var _habilitada := false
var _reduccion_movimiento := false
var _cabezas_3d: Node3D
var _arquitectura_3d: Node3D
var _conexiones_3d: Node3D
var _resolucion_3d: Node3D
var _raiz_visual: MeshInstance3D


func _ready() -> void:
	_asegurar_estructura()
	visible = false


static func habilitada(semillas: Dictionary) -> bool:
	return semillas.has(SEMILLA)


static func estado_nuevo(raiz_seed: int = 0) -> Dictionary:
	return {
		"raiz_seed": raiz_seed,
		"cabezas": CABEZAS_INICIALES,
		"cortes_sintoma": 0,
		"regeneraciones": 0,
		"pista_nivel": 0,
		"resuelta": false,
		"nodo_legible": false,
		"pista": _texto_pista(0),
	}


## Configurar con un diccionario sin la semilla mantiene la familia totalmente
## fuera de escena. `semillas` acepta directamente la salida de
## SemillasOniricas.obtener_semillas(jornada).
func configurar(
	semillas: Dictionary, reduccion_movimiento: bool = false, raiz_seed: int = 0
) -> bool:
	_asegurar_estructura()
	_habilitada = habilitada(semillas)
	_reduccion_movimiento = reduccion_movimiento
	_estado = estado_nuevo(raiz_seed)
	visible = _habilitada
	if _habilitada:
		_sincronizar_visuales()
	else:
		_vaciar(_cabezas_3d)
		_vaciar(_arquitectura_3d)
	return _habilitada


func estado_actual() -> Dictionary:
	return _estado.duplicate(true)


func modo_aparicion() -> String:
	return "fundido_discreto" if _reduccion_movimiento else "crecimiento_escalonado"


## Acción errónea pero permitida: una cabeza desaparece conceptualmente y
## reaparece como 1-2 problemas nuevos. La cantidad total y la arquitectura
## tienen techo duro, por lo que insistir nunca degrada la escena sin límite.
func accion_sintoma() -> Dictionary:
	if not _habilitada:
		return estado_actual()
	_estado = cortar_sintoma(_estado)
	_sincronizar_visuales()
	estado_cambiado.emit(estado_actual())
	return estado_actual()


## Observar no genera cabezas. Hace explícita la conexión compartida y permite
## deducir el nodo común sin probar combinaciones.
func observar_conexiones() -> Dictionary:
	if not _habilitada:
		return estado_actual()
	_estado = observar_conexiones_estado(_estado)
	_sincronizar_visuales()
	estado_cambiado.emit(estado_actual())
	return estado_actual()


## Solo estabiliza cuando la pista ya hace legible la raíz. No existe precisión
## temporal: una vez descubierta, la acción puede realizarse en cualquier momento.
func accion_nodo_comun() -> bool:
	if not _habilitada:
		return false
	var anterior: bool = _estado.get("resuelta", false) == true
	_estado = resolver_nodo_comun(_estado)
	_sincronizar_visuales()
	estado_cambiado.emit(estado_actual())
	if not anterior and _estado.get("resuelta", false) == true:
		hidra_resuelta.emit()
	return _estado.get("resuelta", false) == true


static func cortar_sintoma(estado: Dictionary) -> Dictionary:
	var siguiente := estado.duplicate(true)
	if siguiente.get("resuelta", false) == true:
		return siguiente

	var cortes := int(siguiente.get("cortes_sintoma", 0)) + 1
	var raiz_seed := int(siguiente.get("raiz_seed", 0))
	var nuevas := 1 + posmod(cortes + raiz_seed, 2)
	siguiente["cortes_sintoma"] = cortes
	siguiente["cabezas"] = mini(MAX_CABEZAS, int(siguiente.get("cabezas", 0)) + nuevas)

	if cortes % CORTES_POR_REGENERACION == 0:
		siguiente["regeneraciones"] = mini(
			MAX_REGENERACIONES, int(siguiente.get("regeneraciones", 0)) + 1
		)

	var pista_nivel := mini(3, maxi(int(siguiente.get("pista_nivel", 0)), cortes))
	siguiente["pista_nivel"] = pista_nivel
	siguiente["nodo_legible"] = pista_nivel >= PISTA_NODO_LEGIBLE
	siguiente["pista"] = _texto_pista(pista_nivel)
	return siguiente


static func observar_conexiones_estado(estado: Dictionary) -> Dictionary:
	var siguiente := estado.duplicate(true)
	if siguiente.get("resuelta", false) == true:
		return siguiente
	var pista_nivel := mini(3, int(siguiente.get("pista_nivel", 0)) + 1)
	siguiente["pista_nivel"] = pista_nivel
	siguiente["nodo_legible"] = pista_nivel >= PISTA_NODO_LEGIBLE
	siguiente["pista"] = _texto_pista(pista_nivel)
	return siguiente


static func resolver_nodo_comun(estado: Dictionary) -> Dictionary:
	var siguiente := estado.duplicate(true)
	if siguiente.get("resuelta", false) == true:
		return siguiente
	if int(siguiente.get("pista_nivel", 0)) < PISTA_NODO_LEGIBLE:
		siguiente["pista"] = "La raíz aún no se distingue de los síntomas."
		return siguiente
	siguiente["resuelta"] = true
	siguiente["cabezas"] = 0
	siguiente["pista"] = "Las conexiones colapsan en un único nodo doméstico."
	return siguiente


static func posicion_cabeza(indice: int, raiz_seed: int) -> Vector3:
	if ANCLAS_CABEZAS.is_empty():
		return Vector3.ZERO
	return ANCLAS_CABEZAS[posmod(indice + raiz_seed, ANCLAS_CABEZAS.size())]


static func regeneracion_respeta_corredor(posicion: Vector3) -> bool:
	return absf(posicion.x) >= ANCHO_CORREDOR_SEGURO


static func _texto_pista(nivel: int) -> String:
	match nivel:
		0:
			return "Las cabezas parecen problemas separados."
		1:
			return "Los cuellos repiten el mismo pulso antes de dividirse."
		2:
			return "Varias conexiones convergen bajo la misma raíz central."
		_:
			return "La proliferación cambia de lugar, pero todas las rutas vuelven al mismo nodo."


func _asegurar_estructura() -> void:
	if _cabezas_3d == null:
		_cabezas_3d = Node3D.new()
		_cabezas_3d.name = "CabezasHidra"
		add_child(_cabezas_3d)
	if _arquitectura_3d == null:
		_arquitectura_3d = Node3D.new()
		_arquitectura_3d.name = "RegeneracionArquitectonica"
		add_child(_arquitectura_3d)
	if _conexiones_3d == null:
		_conexiones_3d = Node3D.new()
		_conexiones_3d.name = "ConexionesRaiz"
		add_child(_conexiones_3d)
	if _resolucion_3d == null:
		_resolucion_3d = Node3D.new()
		_resolucion_3d.name = "ResolucionHidra"
		add_child(_resolucion_3d)
	if _raiz_visual == null:
		_raiz_visual = MeshInstance3D.new()
		_raiz_visual.name = "NodoComun"
		var esfera := SphereMesh.new()
		esfera.radius = 0.75
		esfera.height = 1.5
		_raiz_visual.mesh = esfera
		_raiz_visual.position = POSICION_RAIZ
		add_child(_raiz_visual)
	if get_node_or_null("PropBustoHidra") == null:
		var prop := Mitologias435Props.busto_hidra()
		prop.name = "PropBustoHidra"
		prop.position = Vector3(-7.2, 0.0, -7.4)
		prop.rotation_degrees = Vector3(0.0, 26.0, 0.0)
		prop.scale = Vector3.ONE * 0.62
		prop.set_meta("mitologias_435_solo_visual", true)
		add_child(prop)


func _sincronizar_visuales() -> void:
	_asegurar_estructura()
	_vaciar(_cabezas_3d)
	_vaciar(_arquitectura_3d)
	_vaciar(_conexiones_3d)
	_vaciar(_resolucion_3d)

	var resuelta: bool = _estado.get("resuelta", false) == true
	_raiz_visual.visible = _habilitada and not resuelta
	_raiz_visual.scale = Vector3.ONE
	_actualizar_material_raiz(false)
	if resuelta:
		_crear_semilla_final()
		return

	var cantidad := mini(MAX_CABEZAS, int(_estado.get("cabezas", CABEZAS_INICIALES)))
	var raiz_seed := int(_estado.get("raiz_seed", 0))
	for indice in cantidad:
		var ancla := posicion_cabeza(indice, raiz_seed)
		_crear_cabeza(indice, ancla)
		_crear_conexion(indice, ancla)

	var regeneraciones := mini(MAX_REGENERACIONES, int(_estado.get("regeneraciones", 0)))
	for indice in regeneraciones:
		_crear_regeneracion(indice)


func _crear_cabeza(indice: int, ancla: Vector3) -> void:
	var grupo := Node3D.new()
	grupo.name = "Cabeza_%02d" % indice
	grupo.position = ancla
	_cabezas_3d.add_child(grupo)

	var cuello := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.22
	cilindro.bottom_radius = 0.35
	cilindro.height = 2.4
	cuello.mesh = cilindro
	cuello.position = Vector3(0.0, 1.2, 0.0)
	grupo.add_child(cuello)

	var cabeza := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.48
	esfera.height = 0.9
	cabeza.mesh = esfera
	cabeza.position = Vector3(0.0, 2.55, 0.0)
	grupo.add_child(cabeza)

	var material := Mitologias435Materiales.crear("escama_hidra", Color(0.22, 0.34, 0.18))
	cuello.material_override = material
	cabeza.material_override = material


## Las conexiones hacen visible que las cabezas comparten una misma causa. La
## geometría es puramente visual y cambia de lectura cuando el nodo ya es legible.
func _crear_conexion(indice: int, ancla: Vector3) -> void:
	var inicio := POSICION_RAIZ
	var fin := ancla + Vector3(0.0, 0.8, 0.0)
	var distancia := inicio.distance_to(fin)
	if distancia <= 0.001:
		return

	var cable := MeshInstance3D.new()
	cable.name = "Conexion_%02d" % indice
	var caja := BoxMesh.new()
	caja.size = Vector3(0.08, 0.08, distancia)
	cable.mesh = caja
	cable.position = inicio.lerp(fin, 0.5)
	_conexiones_3d.add_child(cable)
	cable.look_at(fin, Vector3.UP)

	var material := StandardMaterial3D.new()
	var legible := int(_estado.get("pista_nivel", 0)) >= PISTA_NODO_LEGIBLE
	material.albedo_color = Color(0.68, 0.52, 0.18) if legible else Color(0.24, 0.17, 0.13)
	material.roughness = 0.86
	cable.material_override = material


## Resolver la causa colapsa toda la proliferación en el objeto doméstico que
## sembró el sueño, en vez de dejar una esfera abstracta como estado final.
func _crear_semilla_final() -> void:
	var cartucho := Node3D.new()
	cartucho.name = "SemillaHydraLoopFinal"
	cartucho.position = POSICION_RAIZ + Vector3(0.0, -0.58, 0.0)
	_resolucion_3d.add_child(cartucho)

	var carcasa := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.62, 0.12, 0.4)
	carcasa.mesh = caja
	cartucho.add_child(carcasa)

	var etiqueta := MeshInstance3D.new()
	etiqueta.name = "EtiquetaHydraLoopFinal"
	var plano := QuadMesh.new()
	plano.size = Vector2(0.42, 0.24)
	etiqueta.mesh = plano
	etiqueta.position = Vector3(0.0, 0.065, 0.0)
	etiqueta.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	cartucho.add_child(etiqueta)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.58, 0.28)
	material.roughness = 0.72
	etiqueta.material_override = material


## Cada regeneración añade tres planos/volúmenes visuales que sugieren una sala.
## No se crea cuerpo físico: la mutación espacial es visible pero incapaz de
## bloquear navegación, y las anclas dejan libre el corredor central.
func _crear_regeneracion(indice: int) -> void:
	if indice < 0 or indice >= ANCLAS_REGENERACION.size():
		return
	var ancla: Vector3 = ANCLAS_REGENERACION[indice]
	if not regeneracion_respeta_corredor(ancla):
		return

	var sala := Node3D.new()
	sala.name = "SalaRegenerada_%02d" % indice
	sala.position = ancla
	_arquitectura_3d.add_child(sala)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.26, 0.25, 0.22, 0.72)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 1.0

	_crear_panel(sala, Vector3(3.0, 2.8, 0.18), Vector3(0.0, 1.4, 1.6), material)
	_crear_panel(sala, Vector3(0.18, 2.8, 3.2), Vector3(-1.5, 1.4, 0.0), material)
	_crear_panel(sala, Vector3(3.0, 0.12, 3.2), Vector3(0.0, 2.8, 0.0), material)


func _crear_panel(
	padre: Node3D, tamano: Vector3, posicion_local: Vector3, material: Material
) -> void:
	var visual := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = tamano
	visual.mesh = caja
	visual.position = posicion_local
	visual.material_override = material
	padre.add_child(visual)


func _actualizar_material_raiz(resuelta: bool) -> void:
	if _raiz_visual == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.16, 0.48, 0.25) if resuelta else Color(0.62, 0.16, 0.13)
	material.roughness = 0.65
	_raiz_visual.material_override = material


func _vaciar(contenedor: Node) -> void:
	if contenedor == null:
		return
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()
