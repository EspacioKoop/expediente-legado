## Adaptador 3D standalone de ENJAMBRE (#2067).
## Monta 2-3 cuerpos deterministas, delega estados al coordinador puro
## y presenta telegraphs sin aplicar daño ni consecuencias.
class_name JuicioCombateEnjambre3D
extends RefCounted

## Posiciones iniciales deterministas para los cuerpos del enjambre.
const POSICIONES_INICIALES := [
	Vector3(-1.5, 0.0, -1.0),
	Vector3(1.5, 0.0, -1.0),
	Vector3(0.0, 0.0, -2.0),
]


## Un cuerpo del enjambre: su nodo 3D y su estado lógico.
class CuerpoEnjambre:
	var nodo: Node3D
	var unidad: Dictionary

	func _init(n: Node3D, u: Dictionary):
		nodo = n
		unidad = u


## Monta la escena del enjambre.
## [param anfitrion] es la raíz donde se cuelgan los cuerpos.
## [param raiz] es la semilla para la generación determinista.
## [param color] es el color del mito para el halo.
## [param cantidad] es el número de cuerpos a montar.
static func montar(anfitrion: Node3D, raiz: int, color: Color, cantidad: int = 2) -> Array:
	var cuerpos := []
	var unidades := JuicioCombateArquetipoHost.nuevo_enjambre(raiz, cantidad)

	for i in range(unidades.size()):
		var nodo := JuicioCombateEscenografia3D.rival_sin_cara(
			anfitrion, "enjambre_%d_%d" % [raiz, i], color
		)
		nodo.position = POSICIONES_INICIALES[i]
		cuerpos.append(CuerpoEnjambre.new(nodo, unidades[i]))

	return cuerpos


## Avanza la lógica del enjambre y actualiza la presentación.
## [param runtime] es el array de CuerpoEnjambre.
## [param delta] es el paso de tiempo.
## [param reduccion_movimiento] si es true, elimina movimiento decorativo.
static func avanzar(runtime: Array, delta: float, reduccion_movimiento: bool = false) -> Dictionary:
	var unidades := []
	for c in runtime:
		unidades.append(c.unidad)

	var paso := JuicioCombateArquetipoHost.avanzar_enjambre(unidades, delta)

	# Actualizar estados y nodos
	for i in range(runtime.size()):
		var cuerpo := runtime[i]
		var resultado := paso.resultados[i]
		var nuevo_estado := paso.unidades[i]

		cuerpo.unidad = nuevo_estado

		# Presentación de telegraphs
		var estado := String(nuevo_estado.get("estado", ""))
		if estado == "TELEGRAFIAR" or estado == "ATACAR":
			_presentar_aviso(cuerpo.nodo, true)
		else:
			_presentar_aviso(cuerpo.nodo, false)

		# Movimiento decorativo (no altera estados/timings)
		if not reduccion_movimiento:
			_aplicar_movimiento_decorativo(cuerpo.nodo, delta)

	return {
		"unidades": paso.unidades,
		"resultados": paso.resultados,
		"atacantes_activos": paso.atacantes_activos
	}


static func _presentar_aviso(nodo: Node3D, visible: bool) -> void:
	var aviso := nodo.get_node_or_null("AvisoGeometrico")
	if aviso == null:
		if not visible:
			return
		# Crear aviso geométrico corto junto al cuerpo
		aviso = Node3D.new()
		aviso.name = "AvisoGeometrico"
		# Un pequeño cubo o esfera flotando sobre la cabeza
		var malla := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.2, 0.2, 0.2)
		malla.mesh = box
		malla.position = Vector3(0.0, 2.0, 0.0)
		aviso.add_child(malla)
		nodo.add_child(aviso)

	if aviso:
		aviso.visible = visible


static func _aplicar_movimiento_decorativo(nodo: Node3D, delta: float) -> void:
	# Oscilación leve para dar vida al enjambre
	var t := Time.get_ticks_msec() / 1000.0
	nodo.position.y = sin(t * 2.0) * 0.1
	nodo.position.x += cos(t * 1.5) * 0.01 * delta
