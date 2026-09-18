## Vertical jugable autocontenido de los bolos de pasillo (#159).
##
## La física se resuelve con un paso fijo y colisiones circulares en X/Z. Los
## MeshInstance3D son presentación: no hay RigidBody3D cuya resolución dependa
## del framerate. El tanteo y la rotación siguen perteneciendo a Bolos (#170).
class_name BolosPasillo3D
extends Node3D

signal actividad_terminada(resultado: Dictionary)

const CARRIL_ANCHO := 2.4
const CARRIL_ANCHO_ESTRECHO := 1.72
const CARRIL_LARGO := 8.0
const PASO_FIJO := 1.0 / 120.0
const ROZAMIENTO := 1.2
const RADIO_BOLA := 0.16
const RADIO_BOLO := 0.17
const VELOCIDAD_MINIMA := 3.0
const VELOCIDAD_MAXIMA := 8.0
const VELOCIDAD_REPOSO := 0.12
const TIEMPO_MAXIMO_TIRO := 4.0
const LIMITE_PASOS_PRUEBA := 2400
const POSICION_BOLA := Vector3(0.0, 0.20, 3.25)
const LANZADORES := ["jugador", "prudente", "agresiva", "absurda"]
const PLAN_COMPANEROS := [[4, 3], [7, 2], [0, 1]]
const VARIANTE_ESTRECHO := "estrecho"
const VARIANTE_MESA := "mesa"
const VARIANTE_REBOTE := "rebote"
const VARIANTE_ABSURDO := "absurdo"
const VARIANTE_NOCTURNO := "nocturno"
const VARIANTES := [
	VARIANTE_ESTRECHO,
	VARIANTE_MESA,
	VARIANTE_REBOTE,
	VARIANTE_ABSURDO,
	VARIANTE_NOCTURNO,
]
const BOLO_ABSURDO := Vector3(1.02, 0.28, -2.16)
## Fuera del ancho jugable: presencia social, nunca obstáculos de la física.
const POSICIONES_COMPANEROS := [
	Vector3(-1.72, 0.0, 1.85),
	Vector3(1.72, 0.0, 0.35),
	Vector3(-1.72, 0.0, -1.15),
]
const COLORES_COMPANEROS := [
	Color(0.48, 0.60, 0.70),
	Color(0.66, 0.48, 0.52),
	Color(0.52, 0.62, 0.46),
]
const POSICIONES_BOLOS := [
	Vector3(0.00, 0.28, -2.10),
	Vector3(-0.22, 0.28, -2.52),
	Vector3(0.22, 0.28, -2.52),
	Vector3(-0.44, 0.28, -2.94),
	Vector3(0.00, 0.28, -2.94),
	Vector3(0.44, 0.28, -2.94),
	Vector3(-0.66, 0.28, -3.36),
	Vector3(-0.22, 0.28, -3.36),
	Vector3(0.22, 0.28, -3.36),
	Vector3(0.66, 0.28, -3.36),
]

var estado: Dictionary = {}
var variante := VARIANTE_ESTRECHO
var _posiciones_bolos: Array = []
var _obstaculo_variante: Dictionary = {}
var _bolos_en_pie: Array[bool] = []
var _nodos_bolos: Array[Node3D] = []
var _companeros_visual: Array[Node3D] = []
var _idles_companeros: Array[CompaneroIdle3D] = []
var _bola: MeshInstance3D
var _bola_posicion := POSICION_BOLA
var _bola_velocidad := Vector3.ZERO
var _acumulador := 0.0
var _tiempo_tiro := 0.0
var _tiro_activo := false
var _cargando := false
var _potencia := 0.0
var _apuntado := 0.0
var _finalizada := false


func _ready() -> void:
	PreferenciasSiga.aplicar(PreferenciasSiga.cargar())
	_preparar_variante()
	_montar_presentacion()
	reiniciar()


func configurar_variante(nueva: String) -> void:
	variante = nueva if VARIANTES.has(nueva) else VARIANTE_ESTRECHO
	_preparar_variante()


static func ancho_de(nombre: String) -> float:
	return CARRIL_ANCHO_ESTRECHO if nombre == VARIANTE_ESTRECHO else CARRIL_ANCHO


static func posiciones_de(nombre: String) -> Array:
	var posiciones: Array = POSICIONES_BOLOS.duplicate()
	if nombre == VARIANTE_ABSURDO:
		posiciones[posiciones.size() - 1] = BOLO_ABSURDO
	return posiciones


static func obstaculo_de(nombre: String) -> Dictionary:
	if nombre == VARIANTE_MESA:
		return {
			"modo": "bloquea",
			"posicion": Vector3(0.0, 0.30, -1.62),
			"tamano": Vector3(1.16, 0.60, 0.24),
		}
	if nombre == VARIANTE_REBOTE:
		return {
			"modo": "rebota",
			"posicion": Vector3(0.78, 0.42, -1.35),
			"tamano": Vector3(0.20, 0.84, 1.70),
		}
	return {}


static func energia_luz_de(nombre: String) -> float:
	return 0.28 if nombre == VARIANTE_NOCTURNO else 1.0


func _preparar_variante() -> void:
	_posiciones_bolos = posiciones_de(variante)
	_obstaculo_variante = obstaculo_de(variante)


func _physics_process(delta: float) -> void:
	if _finalizada:
		return
	if Input.is_action_just_pressed("cancelar"):
		abandonar()
		return

	if not _tiro_activo and int(estado.get("turno", 0)) == 0:
		var eje := Input.get_axis("mover_izquierda", "mover_derecha")
		_apuntado = clampf(_apuntado + eje * delta * 0.85, -1.0, 1.0)
		if Input.is_action_just_pressed("interactuar"):
			_cargando = true
			_potencia = 0.0
		if _cargando and Input.is_action_pressed("interactuar"):
			_potencia = minf(_potencia + delta * 0.75, 1.0)
		if _cargando and Input.is_action_just_released("interactuar"):
			var fuerza := maxf(_potencia, 0.12)
			_cargando = false
			lanzar(_apuntado, fuerza)

	if not _tiro_activo:
		return
	_acumulador += clampf(delta, 0.0, 0.25)
	while _acumulador >= PASO_FIJO and _tiro_activo:
		_paso_fijo()
		_acumulador -= PASO_FIJO


func reiniciar() -> void:
	estado = Bolos.nueva(LANZADORES)
	_finalizada = false
	_tiro_activo = false
	_cargando = false
	_potencia = 0.0
	_apuntado = 0.0
	_preparar_bola()
	_restaurar_bolos()


func lanzar(apuntado: float, potencia: float) -> bool:
	if _finalizada or _tiro_activo or int(estado.get("turno", 0)) != 0:
		return false
	if potencia <= 0.0:
		return false

	_apuntado = clampf(apuntado, -1.0, 1.0)
	var fuerza := clampf(potencia, 0.0, 1.0)
	var direccion := Vector3(_apuntado * 0.55, 0.0, -1.0).normalized()
	_bola_posicion = POSICION_BOLA
	_bola_velocidad = direccion * lerpf(VELOCIDAD_MINIMA, VELOCIDAD_MAXIMA, fuerza)
	_acumulador = 0.0
	_tiempo_tiro = 0.0
	_tiro_activo = true
	_refrescar_bola()
	return true


func simular_hasta_reposo(max_pasos: int = LIMITE_PASOS_PRUEBA) -> int:
	var pasos := 0
	while _tiro_activo and pasos < maxi(max_pasos, 0):
		_paso_fijo()
		pasos += 1
	if _tiro_activo:
		_resolver_lanzamiento()
	return pasos


func abandonar() -> Dictionary:
	if _finalizada:
		return Bolos.resultado(estado)
	var resultado := Bolos.abandonar(estado)
	_finalizar(resultado)
	return resultado


func resultado_actual() -> Dictionary:
	return Bolos.resultado(estado)


func total_bolos_en_pie() -> int:
	return _bolos_en_pie.count(true)


func lanzamiento_activo() -> bool:
	return _tiro_activo


func _paso_fijo() -> void:
	_tiempo_tiro += PASO_FIJO
	_bola_posicion += _bola_velocidad * PASO_FIJO
	_resolver_obstaculo_variante()
	_detectar_impactos()

	var rapidez := _bola_velocidad.length()
	var nueva_rapidez := maxf(rapidez - ROZAMIENTO * PASO_FIJO, 0.0)
	if nueva_rapidez <= VELOCIDAD_REPOSO:
		_bola_velocidad = Vector3.ZERO
	elif rapidez > 0.0:
		_bola_velocidad = _bola_velocidad.normalized() * nueva_rapidez
	_refrescar_bola()

	var fuera_lateral := absf(_bola_posicion.x) > ancho_de(variante) * 0.5 + RADIO_BOLA
	var fuera_fondo := _bola_posicion.z < -CARRIL_LARGO * 0.5 - RADIO_BOLA
	if (
		_bola_velocidad == Vector3.ZERO
		or fuera_lateral
		or fuera_fondo
		or _tiempo_tiro >= TIEMPO_MAXIMO_TIRO
	):
		_resolver_lanzamiento()


func _resolver_obstaculo_variante() -> void:
	if _obstaculo_variante.is_empty() or _bola_velocidad == Vector3.ZERO:
		return
	var centro: Vector3 = _obstaculo_variante["posicion"]
	var tamano: Vector3 = _obstaculo_variante["tamano"]
	var dentro_x := absf(_bola_posicion.x - centro.x) <= tamano.x * 0.5 + RADIO_BOLA
	var dentro_z := absf(_bola_posicion.z - centro.z) <= tamano.z * 0.5 + RADIO_BOLA
	if not dentro_x or not dentro_z:
		return
	if String(_obstaculo_variante.get("modo", "")) == "rebota":
		var signo := signf(_bola_velocidad.x)
		if is_zero_approx(signo):
			signo = 1.0
		_bola_posicion.x = centro.x - signo * (tamano.x * 0.5 + RADIO_BOLA + 0.01)
		_bola_velocidad.x = -_bola_velocidad.x * 0.85
		if absf(_bola_velocidad.x) < 0.18:
			_bola_velocidad.x = -signo * 0.18
		return
	_bola_velocidad = Vector3.ZERO


func _detectar_impactos() -> void:
	var bola_2d := Vector2(_bola_posicion.x, _bola_posicion.z)
	for indice in _posiciones_bolos.size():
		if not _bolos_en_pie[indice]:
			continue
		var posicion: Vector3 = _posiciones_bolos[indice]
		var bolo_2d := Vector2(posicion.x, posicion.z)
		if bola_2d.distance_to(bolo_2d) > RADIO_BOLA + RADIO_BOLO:
			continue
		_bolos_en_pie[indice] = false
		var desviacion: float = _bola_posicion.x - posicion.x
		if absf(desviacion) < 0.02:
			desviacion = 0.02
		_bola_velocidad.x += clampf(desviacion * 0.8, -0.22, 0.22)
		_bola_velocidad *= 0.86
		_tumbar_bolo(indice, desviacion)


func _resolver_lanzamiento() -> void:
	if not _tiro_activo:
		return
	_tiro_activo = false
	_bola_velocidad = Vector3.ZERO

	var derribados_totales := Bolos.BOLOS_POR_TURNO - total_bolos_en_pie()
	var ya_contabilizados := int(estado.get("derribados_turno", 0))
	var nuevos := maxi(derribados_totales - ya_contabilizados, 0)
	var turno_anterior := int(estado.get("turno", 0))
	Bolos.derribar(estado, nuevos)
	_preparar_bola()

	if int(estado.get("turno", 0)) != turno_anterior:
		_restaurar_bolos()
		if turno_anterior == 0:
			_jugar_companeros()


func _jugar_companeros() -> void:
	for plan in PLAN_COMPANEROS:
		for derribados in plan:
			if estado.get("terminada", false):
				break
			Bolos.derribar(estado, int(derribados))
	if estado.get("terminada", false):
		_finalizar(Bolos.resultado(estado))


func _finalizar(resultado: Dictionary) -> void:
	if _finalizada:
		return
	_finalizada = true
	_tiro_activo = false
	_cargando = false
	actividad_terminada.emit(resultado)


func _preparar_bola() -> void:
	_bola_posicion = POSICION_BOLA
	_bola_velocidad = Vector3.ZERO
	_acumulador = 0.0
	_tiempo_tiro = 0.0
	_refrescar_bola()


func _restaurar_bolos() -> void:
	_bolos_en_pie.clear()
	for indice in _posiciones_bolos.size():
		_bolos_en_pie.append(true)
		if indice >= _nodos_bolos.size():
			continue
		var nodo := _nodos_bolos[indice]
		nodo.position = _posiciones_bolos[indice]
		nodo.rotation_degrees = Vector3.ZERO


func _tumbar_bolo(indice: int, desviacion: float) -> void:
	if indice < 0 or indice >= _nodos_bolos.size():
		return
	var nodo := _nodos_bolos[indice]
	nodo.rotation_degrees = Vector3(72.0, 0.0, clampf(desviacion * 90.0, -24.0, 24.0))
	nodo.position.y = 0.12


func _refrescar_bola() -> void:
	if is_instance_valid(_bola):
		_bola.position = _bola_posicion


func _montar_presentacion() -> void:
	var suelo := _caja(
		Vector3(0.0, -0.06, -0.15), Vector3(ancho_de(variante), 0.12, CARRIL_LARGO)
	)
	var material_suelo := StandardMaterial3D.new()
	material_suelo.albedo_color = Color(0.20, 0.18, 0.15)
	material_suelo.roughness = 0.92
	suelo.material_override = material_suelo

	var material_bolo := StandardMaterial3D.new()
	material_bolo.albedo_color = Color(0.82, 0.80, 0.72)
	material_bolo.roughness = 0.72
	for indice in _posiciones_bolos.size():
		var nodo := MeshInstance3D.new()
		nodo.name = "Bolo%02d" % (indice + 1)
		var malla := CapsuleMesh.new()
		malla.radius = RADIO_BOLO * 0.68
		malla.height = 0.56
		nodo.mesh = malla
		nodo.material_override = material_bolo
		nodo.position = _posiciones_bolos[indice]
		add_child(nodo)
		_nodos_bolos.append(nodo)

	_bola = MeshInstance3D.new()
	_bola.name = "Bola"
	var malla_bola := SphereMesh.new()
	malla_bola.radius = RADIO_BOLA
	malla_bola.height = RADIO_BOLA * 2.0
	_bola.mesh = malla_bola
	var material_bola := StandardMaterial3D.new()
	material_bola.albedo_color = Color(0.20, 0.26, 0.30)
	material_bola.roughness = 0.76
	_bola.material_override = material_bola
	add_child(_bola)

	_montar_obstaculo_variante()
	_montar_companeros()

	var camara := Camera3D.new()
	camara.name = "Camara"
	camara.position = Vector3(0.0, 4.7, 6.4)
	camara.rotation_degrees = Vector3(-27.0, 0.0, 0.0)
	add_child(camara)

	var luz := DirectionalLight3D.new()
	luz.name = "LuzPasillo"
	luz.rotation_degrees = Vector3(-58.0, -24.0, 0.0)
	luz.light_energy = energia_luz_de(variante)
	luz.shadow_enabled = true
	add_child(luz)


func _montar_obstaculo_variante() -> void:
	if _obstaculo_variante.is_empty():
		return
	var nodo := _caja(_obstaculo_variante["posicion"], _obstaculo_variante["tamano"])
	var modo := String(_obstaculo_variante.get("modo", ""))
	nodo.name = "ArchivadorVariante" if modo == "rebota" else "MesaVariante"
	var material := StandardMaterial3D.new()
	material.albedo_color = (
		Color(0.30, 0.33, 0.35) if modo == "rebota" else Color(0.34, 0.27, 0.20)
	)
	material.roughness = 0.88
	nodo.material_override = material


func _montar_companeros() -> void:
	var preferencias := PreferenciasSiga.cargar()
	var reducir := bool(preferencias.get("reduccion_movimiento", false))
	for indice in POSICIONES_COMPANEROS.size():
		var cuerpo := Node3D.new()
		cuerpo.name = "CompaneroBolos%d" % (indice + 1)
		cuerpo.position = POSICIONES_COMPANEROS[indice]
		# Desde ambos laterales miran hacia el carril, no hacia cámara.
		cuerpo.rotation.y = -PI / 2.0 if cuerpo.position.x < 0.0 else PI / 2.0
		add_child(cuerpo)
		if not Modelos.persona(cuerpo, "persona", COLORES_COMPANEROS[indice]):
			cuerpo.queue_free()
			continue

		var idle := CompaneroIdle3D.new()
		idle.name = "IdleBolos%d" % (indice + 1)
		add_child(idle)
		# Un compañero reutiliza el gesto de espera de #134; los otros respiran.
		# Todos comparten la preferencia de reducción de movimiento del juego.
		var brazos := indice == 0
		(
			idle
			. configurar(
				cuerpo,
				hash("bolos-%s" % LANZADORES[indice + 1]),
				false,
				reducir,
				false,
				brazos,
				false,
			)
		)
		_companeros_visual.append(cuerpo)
		_idles_companeros.append(idle)


func _caja(posicion: Vector3, tamano: Vector3) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	nodo.mesh = malla
	nodo.position = posicion
	add_child(nodo)
	return nodo
