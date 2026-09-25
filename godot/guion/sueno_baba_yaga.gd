## Vertical standalone del sueño de Baba Yaga (#652).
##
## No representa a Baba Yaga como boss. La mecánica está en el bosque y la
## cabaña: elementos cotidianos cambian de posición solo al cruzar un umbral o
## cuando quedan fuera de campo. Las marcas del jugador permanecen en el mundo
## y permiten deducir qué se movió sin ensayo exhaustivo ni azar.
class_name SuenoBabaYaga
extends Node3D

const ID_MITO := "baba_yaga"
const CLAVE_SEMILLA := "semilla_onirica_baba_yaga"
const FUENTE_VIGILIA := "libro:cuentos_eslavos_98"
const LECTURAS_MINIMAS := 2

const OBJETO_ARBOL := "arbol_tabique"
const OBJETO_VALLA := "valla_archivo"
const OBJETO_ARCHIVADOR := "archivador_hito"
const OBJETO_CABANA := "cabana_ancla"
const OBJETOS_MARCA := [OBJETO_ARBOL, OBJETO_VALLA, OBJETO_ARCHIVADOR, OBJETO_CABANA]

const EVENTO_UMBRAL := "cruzar_umbral"
const EVENTO_FUERA_CAMPO := "perder_de_vista"

const POSICIONES_ARBOL := [
	Vector3(-4.8, 0.0, -2.8),
	Vector3(-2.8, 0.0, -4.2),
	Vector3(-5.2, 0.0, 0.8),
	Vector3(-3.4, 0.0, 3.0),
]
const POSICIONES_VALLA := [
	Vector3(2.8, 0.0, -2.8),
	Vector3(4.4, 0.0, -0.4),
	Vector3(1.8, 0.0, 2.8),
	Vector3(3.8, 0.0, 3.4),
]
const POSICIONES_ARCHIVADOR := [
	Vector3(-0.8, 0.0, 2.8),
	Vector3(1.0, 0.0, 3.8),
	Vector3(-1.8, 0.0, 4.1),
]
const POSICIONES_CABANA := [
	Vector3(0.0, 0.0, -1.0),
	Vector3(1.4, 0.0, -0.2),
	Vector3(0.2, 0.0, 1.0),
	Vector3(-1.4, 0.0, -0.1),
]
const PUNTOS_HORIZONTE_CABANA := [
	Vector3(6.4, 5.5, 4.8),
	Vector3(6.4, 5.5, -5.8),
	Vector3(-6.4, 5.5, -5.8),
	Vector3(-6.4, 5.5, 4.8),
]
const DURACION_TRAMO_HORIZONTE := 0.18

const COLOR_SUELO := Color(0.13, 0.15, 0.13)
const COLOR_BOSQUE := Color(0.19, 0.27, 0.18)
const COLOR_MADERA := Color(0.32, 0.23, 0.15)
const COLOR_ARCHIVO := Color(0.28, 0.31, 0.30)
const COLOR_CABANA := Color(0.42, 0.31, 0.20)
const COLOR_INTERIOR := Color(0.54, 0.43, 0.27)
const COLOR_MARCA := Color(0.72, 0.62, 0.30)
const COLOR_RETORNO := Color(0.28, 0.50, 0.37)
const COLOR_COMPARACION := Color(0.72, 0.78, 0.67)
const PASOS_RASTRO := 5
const INTERIORES_CABANA := [
	"CocinaSIGA98",
	"ArchivoInvertido",
	"BosqueInterior",
	"SalaUmbral",
]
const POSICIONES_TECHO_FASE := [
	Vector3.ZERO,
	Vector3(0.35, -0.30, 0.18),
	Vector3(-0.55, -0.72, 0.42),
	Vector3(0.20, -0.18, -0.38),
]
const ROTACIONES_TECHO_FASE := [
	Vector3.ZERO,
	Vector3(0.0, 0.0, 4.0),
	Vector3(7.0, 0.0, -6.0),
	Vector3(-4.0, 0.0, 3.0),
]
const POSICIONES_PLANO_FASE := [
	Vector3.ZERO,
	Vector3(0.25, 0.0, -0.30),
	Vector3(0.70, -0.12, -0.65),
	Vector3(-0.20, 0.08, -0.18),
]
const ROTACIONES_PLANO_FASE := [
	Vector3.ZERO,
	Vector3(0.0, -8.0, 0.0),
	Vector3(-10.0, -18.0, 6.0),
	Vector3(5.0, 10.0, -4.0),
]
const POSICIONES_FONDO_FASE := [
	Vector3.ZERO,
	Vector3(-0.18, 0.0, 0.22),
	Vector3(0.28, 0.0, -0.30),
	Vector3(0.10, 0.0, 0.16),
]
const POSICIONES_HABITACION_FASE := BabaYagaHabitacionGiratoria.POSICIONES_FASE
const ROTACIONES_HABITACION_FASE := BabaYagaHabitacionGiratoria.ROTACIONES_FASE
const ESTADOS_HABITACION_EXTERIOR := BabaYagaHabitacionGiratoria.ESTADOS_EXTERIOR
const DURACION_GIRO_HABITACION := BabaYagaHabitacionGiratoria.DURACION_GIRO

var _fase_umbral := 0
var _fase_fuera_campo := 0
var _marcas: Dictionary = {}
var _ultima_comparacion: Dictionary = {}
var _tween_cabana: Tween
var _montado := false


static func puede_entrar(estado: Dictionary) -> bool:
	if estado.has("dia"):
		return SemillasOniricas.familias_activas(estado).has(ID_MITO)
	return bool(estado.get(CLAVE_SEMILLA, false))


static func registrar_semilla(
	estado: Dictionary,
	lecturas: int,
	libro_abierto: bool,
	comparo_versiones: bool,
	fuente: String = FUENTE_VIGILIA,
	intensidad: int = 2,
) -> bool:
	if lecturas < LECTURAS_MINIMAS or not libro_abierto or not comparo_versiones:
		return false
	if estado.has("dia"):
		return SemillasOniricas.activar_semilla_onirica(estado, ID_MITO, fuente, intensidad)
	estado[CLAVE_SEMILLA] = true
	return true


static func plan_transicion(reduccion_movimiento: bool) -> Dictionary:
	return {
		"modo": "corte_fundido" if reduccion_movimiento else "fundido_desplazamiento",
		"duracion": 0.0 if reduccion_movimiento else 0.24,
		"animar_geometria": not reduccion_movimiento,
		"mover_camara": false,
		"desplazar_jugador": false,
		"flash": false,
	}


func _ready() -> void:
	preparar()


func preparar() -> void:
	if _montado:
		return
	_montado = true
	_montar_bosque()
	_montar_cabana()
	_montar_acabado_ambiental()
	_montar_retorno()
	_montar_marcas()
	_montar_lectura_comparacion()
	_montar_controles()
	_montar_luz_y_camara()
	_aplicar_estado_visual()


func posiciones_actuales() -> Dictionary:
	return {
		OBJETO_ARBOL: POSICIONES_ARBOL[_fase_umbral % POSICIONES_ARBOL.size()],
		OBJETO_VALLA: POSICIONES_VALLA[_fase_umbral % POSICIONES_VALLA.size()],
		OBJETO_ARCHIVADOR: POSICIONES_ARCHIVADOR[_fase_fuera_campo % POSICIONES_ARCHIVADOR.size()],
		OBJETO_CABANA: POSICIONES_CABANA[_fase_umbral % POSICIONES_CABANA.size()],
	}


func marcas_persistentes() -> Dictionary:
	return _marcas.duplicate(true)


func ultima_comparacion() -> Dictionary:
	return _ultima_comparacion.duplicate(true)


func interior_actual() -> String:
	return INTERIORES_CABANA[_fase_umbral % INTERIORES_CABANA.size()]


func fase_ambiental_actual() -> int:
	return _fase_umbral % POSICIONES_TECHO_FASE.size()


func plan_transito_cabana(origen: Vector3, reduccion_movimiento: bool) -> Dictionary:
	var fase := _fase_umbral % POSICIONES_CABANA.size()
	return {
		"aplicado": true,
		"modo": "corte_fundido" if reduccion_movimiento else "arco_horizonte",
		"animar": not reduccion_movimiento,
		"origen": origen,
		"horizonte": PUNTOS_HORIZONTE_CABANA[fase],
		"destino": POSICIONES_CABANA[fase],
		"duracion": 0.0 if reduccion_movimiento else DURACION_TRAMO_HORIZONTE * 2.0,
		"desplazar_jugador": false,
		"mover_camara": false,
	}


func estado_habitacion_actual() -> Dictionary:
	return BabaYagaHabitacionGiratoria.estado_para_fase(_fase_umbral)


func plan_giro_habitacion(origen: Dictionary, reduccion_movimiento: bool) -> Dictionary:
	var habitacion := (
		get_node_or_null("AcabadoAmbiental/HabitacionGiratoria") as BabaYagaHabitacionGiratoria
	)
	if habitacion == null:
		return {"aplicado": false}
	return habitacion.plan_giro(origen, _fase_umbral, reduccion_movimiento)


func dejar_marca(nombre: String, objetivo: String) -> bool:
	preparar()
	var id := nombre.strip_edges()
	if id.is_empty() or not OBJETOS_MARCA.has(objetivo) or _marcas.has(id):
		return false
	var posiciones := posiciones_actuales()
	_marcas[id] = {
		"objetivo": objetivo,
		"posicion": posiciones[objetivo],
	}
	_ultima_comparacion = {}
	_sincronizar_marcas_visual()
	_sincronizar_comparacion_visual()
	return true


func comparar_marca(nombre: String) -> Dictionary:
	if not _marcas.has(nombre):
		_ultima_comparacion = {"ok": false, "movido": false}
		_sincronizar_comparacion_visual()
		return _ultima_comparacion.duplicate(true)
	var marca: Dictionary = _marcas[nombre]
	var objetivo := String(marca.get("objetivo", ""))
	var origen: Vector3 = marca.get("posicion", Vector3.ZERO)
	var actual: Vector3 = posiciones_actuales().get(objetivo, origen)
	_ultima_comparacion = {
		"ok": true,
		"objetivo": objetivo,
		"origen": origen,
		"actual": actual,
		"movido": not origen.is_equal_approx(actual),
		"distancia": origen.distance_to(actual),
	}
	_sincronizar_comparacion_visual()
	return _ultima_comparacion.duplicate(true)


## Regla espacial:
## - cruzar el umbral mueve árbol, valla y cabaña a su siguiente estado;
## - perder de vista solo mueve el archivador si el consumidor confirma que el
##   objeto quedó fuera de campo.
## No existe temporizador, RNG ni movimiento espontáneo.
func aplicar_evento(
	evento: String,
	fuera_de_campo: bool = false,
	reduccion_movimiento: bool = false,
) -> Dictionary:
	preparar()
	var cambiado := false
	var origen_cabana: Vector3 = posiciones_actuales()[OBJETO_CABANA]
	var origen_habitacion := estado_habitacion_actual()
	var transito_cabana := {"aplicado": false}
	var giro_habitacion := {"aplicado": false}
	if evento == EVENTO_UMBRAL:
		_fase_umbral = (_fase_umbral + 1) % POSICIONES_CABANA.size()
		cambiado = true
	elif evento == EVENTO_FUERA_CAMPO and fuera_de_campo:
		_fase_fuera_campo = (_fase_fuera_campo + 1) % POSICIONES_ARCHIVADOR.size()
		cambiado = true

	if cambiado:
		_ultima_comparacion = {}
		_aplicar_estado_visual()
		if evento == EVENTO_UMBRAL:
			transito_cabana = _aplicar_transito_cabana(origen_cabana, reduccion_movimiento)
			giro_habitacion = _aplicar_giro_habitacion(origen_habitacion, reduccion_movimiento)
		_sincronizar_comparacion_visual()

	var salida := plan_transicion(reduccion_movimiento)
	(
		salida
		. merge(
			{
				"ok": cambiado,
				"evento": evento,
				"posiciones": posiciones_actuales(),
				"marcas": marcas_persistentes(),
				"cabana_visible": cabana_visible(),
				"retorno_disponible": ruta_retorno_disponible(),
				"interior_cabana": interior_actual(),
				"fase_ambiental": fase_ambiental_actual(),
				"transito_cabana": transito_cabana,
				"giro_habitacion": giro_habitacion,
			},
			true,
		)
	)
	return salida


func cabana_visible() -> bool:
	var cabana := get_node_or_null("CabanaAncla")
	return cabana != null and cabana.visible


func ruta_retorno_disponible() -> bool:
	return get_node_or_null("RetornoSeguro") != null


func estado_reproducible() -> Dictionary:
	return {
		"fase_umbral": _fase_umbral,
		"fase_fuera_campo": _fase_fuera_campo,
		"marcas": _marcas.duplicate(true),
		"ultima_comparacion": _ultima_comparacion.duplicate(true),
	}


func restaurar_estado(estado: Dictionary) -> void:
	_fase_umbral = posmod(int(estado.get("fase_umbral", 0)), POSICIONES_CABANA.size())
	_fase_fuera_campo = posmod(int(estado.get("fase_fuera_campo", 0)), POSICIONES_ARCHIVADOR.size())
	var marcas = estado.get("marcas", {})
	_marcas = marcas.duplicate(true) if typeof(marcas) == TYPE_DICTIONARY else {}
	var comparacion = estado.get("ultima_comparacion", {})
	_ultima_comparacion = (
		comparacion.duplicate(true) if typeof(comparacion) == TYPE_DICTIONARY else {}
	)
	if _montado:
		_aplicar_estado_visual()
		_sincronizar_marcas_visual()
		_sincronizar_comparacion_visual()


func _montar_bosque() -> void:
	_crear_caja(
		self,
		"SueloBosque",
		Vector3(15.0, 0.25, 12.0),
		Vector3(0.0, -0.14, 0.0),
		COLOR_SUELO,
	)

	var bosque := Node3D.new()
	bosque.name = "BosqueMovil"
	add_child(bosque)

	var arbol := Node3D.new()
	arbol.name = "ArbolTabique"
	bosque.add_child(arbol)
	_crear_caja(
		arbol, "TroncoTabique", Vector3(1.0, 4.2, 0.8), Vector3(0.0, 2.1, 0.0), COLOR_BOSQUE
	)
	_crear_caja(
		arbol, "PanelOficina", Vector3(2.8, 1.5, 0.18), Vector3(0.0, 2.2, 0.0), COLOR_ARCHIVO
	)

	var valla := Node3D.new()
	valla.name = "VallaArchivo"
	bosque.add_child(valla)
	for i in 3:
		_crear_caja(
			valla,
			"Poste%d" % (i + 1),
			Vector3(0.22, 2.2, 0.22),
			Vector3(-1.0 + i, 1.1, 0.0),
			COLOR_MADERA,
		)
	_crear_caja(valla, "Travesano", Vector3(2.5, 0.22, 0.22), Vector3(0.0, 1.2, 0.0), COLOR_MADERA)

	var archivador := Node3D.new()
	archivador.name = "ArchivadorHito"
	bosque.add_child(archivador)
	_crear_caja(
		archivador,
		"Cuerpo",
		Vector3(1.2, 2.1, 1.0),
		Vector3(0.0, 1.05, 0.0),
		COLOR_ARCHIVO,
	)
	_crear_caja(
		archivador,
		"CintaHito",
		Vector3(0.82, 0.18, 0.05),
		Vector3(0.0, 1.5, -0.53),
		COLOR_MARCA,
	)


func _montar_cabana() -> void:
	var cabana := Node3D.new()
	cabana.name = "CabanaAncla"
	add_child(cabana)

	_crear_caja(cabana, "Cuerpo", Vector3(3.0, 2.4, 2.6), Vector3(0.0, 2.2, 0.0), COLOR_CABANA)
	_crear_caja(cabana, "Techo", Vector3(3.5, 0.35, 3.1), Vector3(0.0, 3.55, 0.0), COLOR_MADERA)
	_crear_caja(
		cabana, "PataIndustrialA", Vector3(0.45, 1.8, 0.45), Vector3(-0.8, 0.9, 0.0), COLOR_ARCHIVO
	)
	_crear_caja(
		cabana, "PataIndustrialB", Vector3(0.45, 1.8, 0.45), Vector3(0.8, 0.9, 0.0), COLOR_ARCHIVO
	)

	var interior := Node3D.new()
	interior.name = "InteriorImposible"
	cabana.add_child(interior)
	_crear_caja(
		interior,
		"SueloInterior",
		Vector3(5.2, 0.12, 4.6),
		Vector3(0.0, 1.08, 0.0),
		COLOR_INTERIOR,
	)
	_crear_caja(
		interior,
		"MarcoPuerta",
		Vector3(1.25, 2.0, 0.18),
		Vector3(0.0, 2.0, -1.4),
		COLOR_MARCA,
	)

	var estados := Node3D.new()
	estados.name = "EstadosInterior"
	interior.add_child(estados)

	var cocina := Node3D.new()
	cocina.name = "CocinaSIGA98"
	estados.add_child(cocina)
	_crear_caja(
		cocina,
		"Encimera",
		Vector3(2.25, 0.16, 0.62),
		Vector3(1.12, 1.70, 0.78),
		COLOR_ARCHIVO,
	)
	_crear_caja(
		cocina,
		"MuebleBajo",
		Vector3(2.18, 0.92, 0.56),
		Vector3(1.12, 1.22, 0.78),
		COLOR_CABANA,
	)
	_crear_caja(
		cocina,
		"Alacena",
		Vector3(1.72, 0.82, 0.42),
		Vector3(1.25, 2.68, 0.90),
		COLOR_INTERIOR,
	)
	_crear_caja(
		cocina,
		"CocinaElectrica",
		Vector3(0.68, 0.12, 0.48),
		Vector3(0.55, 1.82, 0.73),
		COLOR_MARCA,
	)
	_crear_caja(
		cocina,
		"Mesa",
		Vector3(1.30, 0.12, 1.02),
		Vector3(-1.22, 1.68, 0.48),
		COLOR_MADERA,
	)
	for i in 4:
		var x := -1.68 if i % 2 == 0 else -0.78
		var z := 0.14 if i < 2 else 0.82
		_crear_caja(
			cocina,
			"PataMesa%d" % (i + 1),
			Vector3(0.12, 0.68, 0.12),
			Vector3(x, 1.34, z),
			COLOR_ARCHIVO,
		)

	var archivo := Node3D.new()
	archivo.name = "ArchivoInvertido"
	estados.add_child(archivo)
	for i in 3:
		_crear_caja(
			archivo,
			"Archivador%02d" % (i + 1),
			Vector3(0.82, 1.72, 0.72),
			Vector3(-1.35 + float(i) * 1.35, 1.94, 0.72),
			COLOR_ARCHIVO,
		)
		_crear_caja(
			archivo,
			"Etiqueta%02d" % (i + 1),
			Vector3(0.38, 0.12, 0.05),
			Vector3(-1.35 + float(i) * 1.35, 2.18, 0.34),
			COLOR_MARCA,
		)
	var mesa_invertida := _crear_caja(
		archivo,
		"MesaInvertida",
		Vector3(2.70, 0.12, 1.25),
		Vector3(0.0, 3.30, 0.28),
		COLOR_MADERA,
	)
	mesa_invertida.rotation_degrees.z = 180.0

	var bosque_interior := Node3D.new()
	bosque_interior.name = "BosqueInterior"
	estados.add_child(bosque_interior)
	for i in 5:
		var x_bosque := -2.0 + float(i) * 1.0
		var altura_bosque := 2.4 + float(i % 2) * 0.65
		_crear_caja(
			bosque_interior,
			"TroncoInterior%02d" % (i + 1),
			Vector3(0.24, altura_bosque, 0.24),
			Vector3(x_bosque, 1.10 + altura_bosque * 0.5, 0.82),
			COLOR_BOSQUE,
		)
	_crear_caja(
		bosque_interior,
		"TechoExterior",
		Vector3(4.80, 0.10, 2.80),
		Vector3(0.0, 3.82, 0.50),
		COLOR_SUELO,
	)

	var sala_umbral := Node3D.new()
	sala_umbral.name = "SalaUmbral"
	estados.add_child(sala_umbral)
	for i in 3:
		_crear_caja(
			sala_umbral,
			"Marco%02dA" % (i + 1),
			Vector3(0.14, 2.20, 0.14),
			Vector3(-1.20 + float(i) * 1.20, 2.14, 0.70 + float(i) * 0.22),
			COLOR_MARCA,
		)
		_crear_caja(
			sala_umbral,
			"Marco%02dB" % (i + 1),
			Vector3(0.14, 2.20, 0.14),
			Vector3(-0.55 + float(i) * 1.20, 2.14, 0.70 + float(i) * 0.22),
			COLOR_MARCA,
		)
		_crear_caja(
			sala_umbral,
			"Dintel%02d" % (i + 1),
			Vector3(0.80, 0.14, 0.14),
			Vector3(-0.88 + float(i) * 1.20, 3.20, 0.70 + float(i) * 0.22),
			COLOR_MARCA,
		)


func _montar_acabado_ambiental() -> void:
	var acabado := Node3D.new()
	acabado.name = "AcabadoAmbiental"
	add_child(acabado)

	var fondo := Node3D.new()
	fondo.name = "BosqueFondo"
	acabado.add_child(fondo)
	var hitos := [
		Vector3(-6.25, 0.0, -4.6),
		Vector3(-6.55, 0.0, -1.4),
		Vector3(-6.10, 0.0, 2.4),
		Vector3(6.20, 0.0, -4.2),
		Vector3(6.45, 0.0, -0.8),
		Vector3(6.15, 0.0, 2.9),
		Vector3(-3.7, 0.0, -5.25),
		Vector3(3.9, 0.0, -5.15),
	]
	for i in hitos.size():
		var altura := 4.4 + float(i % 3) * 0.55
		_crear_caja(
			fondo,
			"TroncoColumna%02d" % (i + 1),
			Vector3(0.42, altura, 0.42),
			hitos[i] + Vector3(0.0, altura * 0.5, 0.0),
			COLOR_BOSQUE if i % 2 == 0 else COLOR_ARCHIVO,
		)

	var techo := Node3D.new()
	techo.name = "TechoOficinaInvertido"
	acabado.add_child(techo)
	for i in 4:
		var panel := _crear_caja(
			techo,
			"PanelTecho%02d" % (i + 1),
			Vector3(3.15, 0.10, 2.25),
			Vector3(-4.8 + float(i) * 3.2, 5.35, -0.20 + float(i % 2) * 0.34),
			COLOR_ARCHIVO,
		)
		panel.rotation_degrees.z = 180.0
	for i in 3:
		_crear_caja(
			techo,
			"Fluorescente%02d" % (i + 1),
			Vector3(1.85, 0.06, 0.16),
			Vector3(-3.15 + float(i) * 3.15, 5.18, 0.22),
			COLOR_COMPARACION,
		)

	var plano := Node3D.new()
	plano.name = "PlanoAdministrativoPlegado"
	acabado.add_child(plano)
	var hoja_a := _crear_caja(
		plano,
		"HojaA",
		Vector3(2.85, 2.25, 0.08),
		Vector3(-4.95, 1.45, 4.55),
		COLOR_INTERIOR,
	)
	hoja_a.rotation_degrees.y = 24.0
	var hoja_b := _crear_caja(
		plano,
		"HojaB",
		Vector3(2.85, 2.25, 0.08),
		Vector3(-2.55, 1.45, 4.55),
		COLOR_INTERIOR,
	)
	hoja_b.rotation_degrees.y = -24.0
	for i in 3:
		_crear_caja(
			plano,
			"LineaArchivo%02d" % (i + 1),
			Vector3(1.70, 0.05, 0.10),
			Vector3(-4.80 + float(i) * 1.05, 1.25 + float(i) * 0.38, 4.45),
			COLOR_MARCA,
		)

	var habitacion := BabaYagaHabitacionGiratoria.new()
	acabado.add_child(habitacion)
	habitacion.preparar()


func _montar_retorno() -> void:
	_crear_caja(
		self,
		"RetornoSeguro",
		Vector3(2.2, 0.18, 2.2),
		Vector3(0.0, 0.10, 5.2),
		COLOR_RETORNO,
	)
	_crear_caja(
		self,
		"BalizaRetornoIzquierda",
		Vector3(0.18, 1.9, 0.18),
		Vector3(-1.0, 0.95, 5.2),
		COLOR_RETORNO,
	)
	_crear_caja(
		self,
		"BalizaRetornoDerecha",
		Vector3(0.18, 1.9, 0.18),
		Vector3(1.0, 0.95, 5.2),
		COLOR_RETORNO,
	)
	_crear_caja(
		self,
		"DintelRetorno",
		Vector3(2.18, 0.18, 0.18),
		Vector3(0.0, 1.82, 5.2),
		COLOR_RETORNO,
	)


func _montar_marcas() -> void:
	var marcas := Node3D.new()
	marcas.name = "MarcasPersistentes"
	add_child(marcas)
	_sincronizar_marcas_visual()


func _montar_lectura_comparacion() -> void:
	var lectura := Node3D.new()
	lectura.name = "LecturaComparacion"
	add_child(lectura)
	_sincronizar_comparacion_visual()


func _montar_controles() -> void:
	var controles := Node3D.new()
	controles.name = "ControlesBosque"
	add_child(controles)

	var umbral := _crear_control(
		controles,
		"UmbralBosque",
		"umbral del bosque",
		Vector3(0.0, 1.0, -4.2),
		Vector3(2.4, 2.0, 0.35),
		COLOR_MADERA,
	)
	umbral.activado.connect(_al_cruzar_umbral)

	var observatorio := _crear_control(
		controles,
		"ObservatorioArchivador",
		"punto de observación",
		Vector3(4.7, 0.75, 3.9),
		Vector3(0.8, 1.4, 0.8),
		COLOR_ARCHIVO,
	)
	observatorio.activado.connect(_al_comprobar_archivador)

	var cinta := _crear_control(
		controles,
		"CintaPersistente",
		"cinta para marcar",
		Vector3(-4.2, 0.75, 3.8),
		Vector3(0.8, 1.2, 0.8),
		COLOR_MARCA,
	)
	cinta.activado.connect(_al_usar_cinta)


func _crear_control(
	padre: Node3D,
	nombre: String,
	nombre_objeto: String,
	posicion: Vector3,
	tam: Vector3,
	color: Color,
) -> Interactuable3D:
	var control := Interactuable3D.new()
	control.name = nombre
	control.position = posicion
	control.verbo = Interactuable3D.Verbo.USAR
	control.nombre_objeto = nombre_objeto
	control.sonido = Interactuable3D.SIN_SONIDO
	control.collision_mask = 0
	padre.add_child(control)

	_crear_caja(control, "Indicador", tam * 0.82, Vector3.ZERO, color)
	var forma := BoxShape3D.new()
	forma.size = tam
	var colision := CollisionShape3D.new()
	colision.name = "Colision"
	colision.shape = forma
	control.add_child(colision)
	return control


func _al_cruzar_umbral(_actor: Node) -> void:
	aplicar_evento(EVENTO_UMBRAL, false, _reduccion_movimiento_activa())


func _al_comprobar_archivador(_actor: Node) -> void:
	aplicar_evento(EVENTO_FUERA_CAMPO, true, _reduccion_movimiento_activa())


func _al_usar_cinta(_actor: Node) -> void:
	const MARCA_JUGADOR := "cinta_jugador"
	if not _marcas.has(MARCA_JUGADOR):
		dejar_marca(MARCA_JUGADOR, OBJETO_ARBOL)
		return
	comparar_marca(MARCA_JUGADOR)


func _reduccion_movimiento_activa() -> bool:
	return bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))


func _montar_luz_y_camara() -> void:
	var luz := DirectionalLight3D.new()
	luz.name = "LuzGeneral"
	luz.rotation_degrees = Vector3(-56.0, -24.0, 0.0)
	luz.light_energy = 0.95
	add_child(luz)

	var camara := Camera3D.new()
	camara.name = "CamaraStandalone"
	camara.position = Vector3(0.0, 9.0, 15.5)
	camara.rotation_degrees = Vector3(-28.0, 0.0, 0.0)
	camara.current = true
	add_child(camara)


func _aplicar_estado_visual() -> void:
	if not _montado:
		return
	var posiciones := posiciones_actuales()
	get_node("BosqueMovil/ArbolTabique").position = posiciones[OBJETO_ARBOL]
	get_node("BosqueMovil/VallaArchivo").position = posiciones[OBJETO_VALLA]
	get_node("BosqueMovil/ArchivadorHito").position = posiciones[OBJETO_ARCHIVADOR]
	get_node("CabanaAncla").position = posiciones[OBJETO_CABANA]
	get_node("CabanaAncla").visible = true
	_actualizar_interior_cabana()
	_actualizar_acabado_ambiental()
	get_node("RetornoSeguro").visible = true


func _aplicar_transito_cabana(origen: Vector3, reduccion_movimiento: bool) -> Dictionary:
	var plan := plan_transito_cabana(origen, reduccion_movimiento)
	var cabana := get_node_or_null("CabanaAncla") as Node3D
	if cabana == null:
		return plan
	if _tween_cabana != null and _tween_cabana.is_valid():
		_tween_cabana.kill()
	var destino: Vector3 = plan["destino"]
	if reduccion_movimiento:
		cabana.position = destino
		return plan
	var horizonte: Vector3 = plan["horizonte"]
	cabana.position = origen
	_tween_cabana = create_tween()
	_tween_cabana.set_trans(Tween.TRANS_SINE)
	_tween_cabana.set_ease(Tween.EASE_IN_OUT)
	_tween_cabana.tween_property(cabana, "position", horizonte, DURACION_TRAMO_HORIZONTE)
	_tween_cabana.tween_property(cabana, "position", destino, DURACION_TRAMO_HORIZONTE)
	return plan


func _actualizar_interior_cabana() -> void:
	var estados := get_node_or_null("CabanaAncla/InteriorImposible/EstadosInterior")
	if estados == null:
		return
	var seleccionado := interior_actual()
	for estado in estados.get_children():
		if estado is Node3D:
			estado.visible = String(estado.name) == seleccionado


func _actualizar_acabado_ambiental() -> void:
	var techo := get_node_or_null("AcabadoAmbiental/TechoOficinaInvertido") as Node3D
	var plano := get_node_or_null("AcabadoAmbiental/PlanoAdministrativoPlegado") as Node3D
	var fondo := get_node_or_null("AcabadoAmbiental/BosqueFondo") as Node3D
	if techo == null or plano == null or fondo == null:
		return
	var fase := fase_ambiental_actual()
	techo.position = POSICIONES_TECHO_FASE[fase]
	techo.rotation_degrees = ROTACIONES_TECHO_FASE[fase]
	plano.position = POSICIONES_PLANO_FASE[fase]
	plano.rotation_degrees = ROTACIONES_PLANO_FASE[fase]
	fondo.position = POSICIONES_FONDO_FASE[fase]
	_actualizar_habitacion_giratoria()


func _actualizar_habitacion_giratoria() -> void:
	var habitacion := get_node_or_null("AcabadoAmbiental/HabitacionGiratoria") as BabaYagaHabitacionGiratoria
	if habitacion != null:
		habitacion.aplicar_estado(_fase_umbral)


func _aplicar_giro_habitacion(origen: Dictionary, reduccion_movimiento: bool) -> Dictionary:
	var habitacion := get_node_or_null("AcabadoAmbiental/HabitacionGiratoria") as BabaYagaHabitacionGiratoria
	if habitacion == null:
		return {"aplicado": false}
	return habitacion.aplicar_giro(origen, _fase_umbral, reduccion_movimiento)


func _sincronizar_marcas_visual() -> void:
	var contenedor := get_node_or_null("MarcasPersistentes")
	if contenedor == null:
		return
	for hijo in contenedor.get_children():
		hijo.queue_free()
	var ids: Array = _marcas.keys()
	ids.sort()
	for id in ids:
		var marca: Dictionary = _marcas[id]
		var posicion: Vector3 = marca.get("posicion", Vector3.ZERO)
		_crear_caja(
			contenedor,
			"Marca_%s" % String(id).validate_node_name(),
			Vector3(0.55, 0.08, 0.55),
			posicion + Vector3(0.0, 0.06, 0.0),
			COLOR_MARCA,
		)


func _sincronizar_comparacion_visual() -> void:
	var contenedor := get_node_or_null("LecturaComparacion")
	if contenedor == null:
		return
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()
	if (
		not bool(_ultima_comparacion.get("ok", false))
		or not bool(_ultima_comparacion.get("movido", false))
	):
		return
	var origen: Vector3 = _ultima_comparacion.get("origen", Vector3.ZERO)
	var actual: Vector3 = _ultima_comparacion.get("actual", origen)
	_crear_caja(
		contenedor,
		"OrigenMarca",
		Vector3(0.82, 0.08, 0.82),
		origen + Vector3(0.0, 0.08, 0.0),
		COLOR_MARCA,
	)
	_crear_caja(
		contenedor,
		"DestinoActual",
		Vector3(0.32, 0.88, 0.32),
		actual + Vector3(0.0, 0.44, 0.0),
		COLOR_COMPARACION,
	)
	for i in range(1, PASOS_RASTRO):
		var proporcion := float(i) / float(PASOS_RASTRO)
		var paso := origen.lerp(actual, proporcion)
		_crear_caja(
			contenedor,
			"Paso_%02d" % i,
			Vector3(0.18, 0.06, 0.18),
			paso + Vector3(0.0, 0.05, 0.0),
			COLOR_COMPARACION,
		)


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
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.84
	nodo.material_override = material
	padre.add_child(nodo)
	return nodo
