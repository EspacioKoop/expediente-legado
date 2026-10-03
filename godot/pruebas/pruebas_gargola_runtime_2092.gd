## Regresión del ciclo compuesto de Gárgola (#2194).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const RUNTIME = preload("res://guion/juicio_combate_gargola_runtime_2092.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_guardia()
	_probar_aperturas()
	_probar_condiciones_de_linea()
	_probar_ciclo_de_carga()
	_probar_copia_y_determinismo()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_guardia() -> void:
	var estado := RUNTIME.nuevo(2194)
	_comprobar(estado["modo"] == RUNTIME.MODO_BLOQUEADOR, "nace bloqueador")
	var paso := RUNTIME.avanzar(estado, 0.0, 5.0, 0.3)
	_comprobar(paso["guardia_frontal"], "nace con guardia frontal")
	_comprobar(paso["telegraph"] == "guardia", "expone la guardia al host")
	_comprobar(not paso["inicio_carga"] and not paso["abrir_ventana"], "guardia no emite eventos")
	paso = RUNTIME.avanzar(estado, ARQUETIPOS.BLOQUEADOR_GUARDIA_MAX - 0.01, 5.0, 1.0)
	_comprobar(paso["modo"] == RUNTIME.MODO_BLOQUEADOR, "no carga antes de apertura")
	_comprobar(paso["guardia_frontal"], "mantiene guardia hasta apertura real")
	paso = RUNTIME.avanzar(paso["estado"], 0.02, 5.0, 1.0)
	_comprobar(
		paso["modo"] == RUNTIME.MODO_EMBESTIDOR, "apertura temporal también inicia embestida"
	)
	_comprobar(
		paso["estado"]["bloqueador"]["estado"] == ARQUETIPOS.APERTURA,
		"transición nace de apertura real"
	)


func _probar_aperturas() -> void:
	for romper in [false, true]:
		var paso := RUNTIME.avanzar(RUNTIME.nuevo(2194), 0.2, 5.0, 0.3, not romper, romper)
		_comprobar(paso["modo"] == RUNTIME.MODO_EMBESTIDOR, "flanqueo y ruptura abren la guardia")
		_comprobar(not paso["guardia_frontal"], "apertura apaga guardia")
		_comprobar(paso["telegraph"] == "carga_lineal", "avisa la carga antes de golpear")
		_comprobar(not paso["inicio_carga"], "transición inicial todavía no carga")
		var unidad: Dictionary = paso["estado"]["embestidor"]
		_comprobar(unidad["estado"] == ARQUETIPOS.TELEGRAFIAR, "empieza por telegraph")
		_comprobar(
			is_equal_approx(unidad["temporizador"], ARQUETIPOS.EMBESTIDOR_TELEGRAFO),
			"no consume delta dos veces"
		)


func _probar_condiciones_de_linea() -> void:
	for contexto in [[1.0, true], [12.0, true], [5.0, false]]:
		var paso := RUNTIME.avanzar(
			RUNTIME.nuevo(2194), 0.0, contexto[0], 0.3, true, false, contexto[1]
		)
		_comprobar(
			paso["modo"] == RUNTIME.MODO_EMBESTIDOR, "apertura conserva modo aunque no pueda cargar"
		)
		_comprobar(paso["telegraph"] == "", "distancia o línea inválida no inventa telegraph")
		_comprobar(not paso["inicio_carga"], "sin línea válida no hay carga")
		_comprobar(
			paso["estado"]["embestidor"]["estado"] == ARQUETIPOS.REPOSICIONAR,
			"delega reposición en embestidor"
		)


func _probar_ciclo_de_carga() -> void:
	for choque in [false, true]:
		var paso := RUNTIME.avanzar(RUNTIME.nuevo(2194), 0.0, 5.0, 0.3, true)
		paso = RUNTIME.avanzar(paso["estado"], 0.1, 5.0, -1.2)
		_comprobar(
			is_equal_approx(paso["estado"]["embestidor"]["rumbo_bloqueado"], 0.3),
			"telegraph no persigue al jugador"
		)
		_comprobar(not paso["inicio_carga"], "telegraph no anticipa impacto")
		paso = RUNTIME.avanzar(paso["estado"], ARQUETIPOS.EMBESTIDOR_TELEGRAFO, 5.0, -1.2)
		_comprobar(paso["inicio_carga"], "entrar en CARGAR emite evento")
		_comprobar(paso["estado"]["embestidor"]["estado"] == ARQUETIPOS.CARGAR, "carga real activa")
		paso = RUNTIME.avanzar(paso["estado"], 0.01, 5.0, 2.0)
		_comprobar(not paso["inicio_carga"], "carga sostenida no duplica evento")
		_comprobar(
			is_equal_approx(paso["estado"]["embestidor"]["rumbo_bloqueado"], 0.3),
			"carga conserva rumbo congelado"
		)
		var delta := 0.01 if choque else ARQUETIPOS.EMBESTIDOR_CARGA
		paso = RUNTIME.avanzar(paso["estado"], delta, 5.0, 2.0, false, false, true, choque)
		_comprobar(paso["abrir_ventana"], "choque o fin de carga abre ventana")
		_comprobar(
			paso["estado"]["embestidor"]["estado"] == ARQUETIPOS.RECUPERAR, "entra en recuperación"
		)
		_comprobar(not paso["guardia_frontal"], "no rebloquea en el tick de apertura")
		paso = RUNTIME.avanzar(
			paso["estado"],
			ARQUETIPOS.EMBESTIDOR_RECUPERACION - 0.01,
			5.0,
			0.0,
			true,
			true,
			true,
			true
		)
		_comprobar(
			paso["modo"] == RUNTIME.MODO_EMBESTIDOR and not paso["guardia_frontal"],
			"ni flanqueo ni ruptura ni choque interrumpen recuperación"
		)
		_comprobar(
			not paso["abrir_ventana"] and not paso["inicio_carga"],
			"recuperación sostenida no duplica eventos"
		)
		paso = RUNTIME.avanzar(paso["estado"], 0.02, 5.0, 0.0)
		_comprobar(
			paso["modo"] == RUNTIME.MODO_BLOQUEADOR and paso["guardia_frontal"],
			"solo al terminar recuperación vuelve guardia"
		)
		_comprobar(
			not paso["inicio_carga"] and not paso["abrir_ventana"],
			"retorno a guardia no emite impacto"
		)
		_comprobar(
			paso["estado"]["bloqueador"]["estado"] == ARQUETIPOS.GUARDIA,
			"restaura política bloqueador"
		)


func _probar_copia_y_determinismo() -> void:
	var estado := RUNTIME.nuevo(2194, 2)
	var original := estado.duplicate(true)
	var a := RUNTIME.avanzar(estado, 0.1, 5.0, 0.3, true)
	var b := RUNTIME.avanzar(estado, 0.1, 5.0, 0.3, true)
	_comprobar(a == b, "misma entrada produce salida completa idéntica")
	_comprobar(estado == original, "no muta entrada ni subestados")
	a["estado"]["embestidor"]["rumbo_bloqueado"] = 2.0
	_comprobar(estado == original, "salida no comparte diccionarios con entrada")
	_comprobar(
		is_equal_approx(b["estado"]["embestidor"]["rumbo_bloqueado"], 0.3),
		"salidas de ticks separados son independientes"
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error(mensaje)
