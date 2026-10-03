## Contrato ejecutable del adaptador multi-cuerpo (#2157).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const RUNTIME = preload("res://guion/juicio_combate_enjambre_runtime.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_presupuesto_y_ciclo()
	_probar_transiciones()
	_probar_derrotados()
	_probar_copia_y_determinismo()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _grupo() -> Array:
	var unidades := HOST.nuevo_enjambre(2157, 3)
	for unidad in unidades:
		unidad["cooldown"] = 0.0
	return unidades


func _probar_presupuesto_y_ciclo() -> void:
	for presupuesto in [1, 2, 999]:
		var unidades := _grupo()
		var maximo := HOST.presupuesto_enjambre(presupuesto)
		var paso := RUNTIME.tick(unidades, 0.01, presupuesto)
		_comprobar(paso["atacantes_activos"] == maximo, "consume los huecos en el mismo tick")
		_comprobar(paso["inicio_ataque"].is_empty(), "avisar todavía no aplica un ataque")
		_comprobar(paso["abrir_ventana"].is_empty(), "avisar no abre recuperación")
		unidades = paso["unidades"]
		var presupuesto_correcto := true
		var transiciones_correctas := true
		var ataques := 0
		var ventanas := 0
		for _tick in range(400):
			paso = RUNTIME.tick(unidades, 0.02, presupuesto)
			var nuevas: Array = paso["unidades"]
			var activos := ARQUETIPOS.cuenta_presupuesto(nuevas)
			presupuesto_correcto = (
				presupuesto_correcto
				and activos <= maximo
				and activos == int(paso["atacantes_activos"])
			)
			for indice in range(unidades.size()):
				var antes: String = unidades[indice]["estado"]
				var despues: String = nuevas[indice]["estado"]
				var entra_ataque := despues == ARQUETIPOS.ATACAR and antes != despues
				var entra_ventana := despues == ARQUETIPOS.RECUPERAR and antes != despues
				transiciones_correctas = (
					transiciones_correctas
					and paso["inicio_ataque"].has(indice) == entra_ataque
					and paso["abrir_ventana"].has(indice) == entra_ventana
				)
			ataques += paso["inicio_ataque"].size()
			ventanas += paso["abrir_ventana"].size()
			unidades = nuevas
		_comprobar(presupuesto_correcto, "el ciclo completo respeta el presupuesto compartido")
		_comprobar(transiciones_correctas, "eventos coinciden exclusivamente con transiciones")
		_comprobar(ataques > 0 and ventanas > 0, "el ciclo incluye ataques y recuperación")


func _probar_transiciones() -> void:
	var unidades := _grupo()
	unidades[0]["estado"] = ARQUETIPOS.TELEGRAFIAR
	unidades[0]["temporizador"] = 0.0
	unidades[1]["estado"] = ARQUETIPOS.ATACAR
	unidades[1]["temporizador"] = 0.0
	var paso := RUNTIME.tick(unidades, 0.01, 2)
	_comprobar(paso["inicio_ataque"] == [0], "solo la entrada a ATACAR dispara impacto")
	_comprobar(paso["abrir_ventana"] == [1], "solo la entrada a RECUPERAR abre ventana")
	_comprobar(paso["atacantes_activos"] == 2, "el tercer cuerpo usa el hueco liberado")
	_comprobar(paso["unidades"][2]["estado"] == ARQUETIPOS.TELEGRAFIAR, "avisa al ganar turno")
	paso = RUNTIME.tick(paso["unidades"], 0.01, 2)
	_comprobar(paso["inicio_ataque"].is_empty(), "mantener ATACAR no duplica impacto")
	_comprobar(paso["abrir_ventana"].is_empty(), "mantener RECUPERAR no duplica ventana")


func _probar_derrotados() -> void:
	for indice_muerto in range(3):
		for determinacion in [0, -1]:
			var unidades := _grupo()
			unidades[indice_muerto]["estado"] = ARQUETIPOS.ATACAR
			unidades[indice_muerto]["temporizador"] = 0.0
			unidades[indice_muerto]["determinacion"] = determinacion
			var muerto: Dictionary = unidades[indice_muerto].duplicate(true)
			var paso := RUNTIME.tick(unidades, 0.01, 2)
			_comprobar(paso["unidades"].size() == 3, "conserva índices actor/unidad")
			_comprobar(paso["resultados"].size() == 3, "conserva índices de resultados")
			_comprobar(paso["atacantes_activos"] == 2, "derrotado no ocupa presupuesto")
			_comprobar(paso["resultados"][indice_muerto] == {}, "derrotado no emite intención")
			paso = RUNTIME.tick(paso["unidades"], ARQUETIPOS.ENJAMBRE_TELEGRAFO, 2)
			var indices_vivos := []
			for indice in range(3):
				if indice != indice_muerto:
					indices_vivos.append(indice)
			_comprobar(
				paso["inicio_ataque"] == indices_vivos, "hermanas avanzan con índices originales"
			)
			_comprobar(paso["abrir_ventana"].is_empty(), "derrotado no emite recuperación")
			_comprobar(paso["unidades"][indice_muerto] == muerto, "derrotado no revive ni avanza")
	var todas := _grupo()
	for unidad in todas:
		unidad["determinacion"] = 0
	var final := RUNTIME.tick(todas, 10.0, 2)
	_comprobar(final["atacantes_activos"] == 0, "grupo derrotado no consume presupuesto")
	_comprobar(final["inicio_ataque"].is_empty(), "grupo derrotado no ataca")
	_comprobar(final["abrir_ventana"].is_empty(), "grupo derrotado no abre ventanas")
	var vacio := RUNTIME.tick([], 0.01, 2)
	_comprobar(
		vacio["unidades"].is_empty() and vacio["resultados"].is_empty(), "grupo vacío es válido"
	)


func _probar_copia_y_determinismo() -> void:
	var unidades := _grupo()
	var original := unidades.duplicate(true)
	var a := RUNTIME.tick(unidades, 0.01, 2)
	var b := RUNTIME.tick(unidades, 0.01, 2)
	_comprobar(a == b, "misma entrada produce misma salida completa")
	_comprobar(unidades == original, "tick no modifica la entrada")
	a["unidades"][0]["determinacion"] = 0
	_comprobar(unidades == original, "resultado independiente de la entrada")
	_comprobar(
		b["unidades"][0]["determinacion"] == 1, "resultados de ticks separados son independientes"
	)


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error(mensaje)
