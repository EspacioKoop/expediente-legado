## Regresión standalone del adaptador del bloqueador onírico (#1771).
##
##     godot4 --headless --path godot --script pruebas/pruebas_bloqueador_onirico_1771.gd
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")

## Valores del duelo real: si cambian en el host, la simulación debe seguirlos.
const ALCANCE_RIVAL := JuicioCombateReglas.ALCANCE_RIVAL
const VELOCIDAD_JUGADOR := JuicioCombate3D.VELOCIDAD_JUGADOR
const RECARGA_LIGERA := JuicioCombate3D.RECARGA_LIGERA
const PASO := 1.0 / 60.0

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_eleccion()
	_probar_flanco()
	_probar_golpes()
	_probar_giro()
	_probar_rotura_abre_ventana()
	_probar_guardia_no_es_indefinida()
	_probar_rodear_a_velocidad_de_juego_flanquea()
	print("bloqueador_onirico_1771: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_eleccion() -> void:
	var sueno := CombateContextual.PLANO_SUENO
	var realidad := CombateContextual.PLANO_REALIDAD
	_comprobar(HOST.elegir("figura-a", 7, realidad), "", "la realidad conserva el duelo clásico")
	_comprobar(HOST.elegir("", 7, sueno), "", "una figura sin id no recibe arquetipo")
	_comprobar(
		HOST.elegir("figura-a", 7, sueno), HOST.elegir("figura-a", 7, sueno), "elección estable"
	)
	var con_arquetipo := 0
	for indice in range(40):
		var tipo := HOST.elegir("figura-%d" % indice, 7, sueno)
		_comprobar(tipo.is_empty() or HOST.soportado(tipo), true, "solo arquetipos con cuerpo")
		if not tipo.is_empty():
			con_arquetipo += 1
	_comprobar(con_arquetipo > 0 and con_arquetipo < 40, true, "mezcla clásicos y arquetipos")
	_comprobar(HOST.soportado(ARQUETIPOS.BLOQUEADOR), true, "el bloqueador conserva cuerpo")
	_comprobar(HOST.soportado(ARQUETIPOS.HOSTIGADOR), true, "el hostigador ya tiene cuerpo")
	_comprobar(HOST.soportado(ARQUETIPOS.ENJAMBRE), false, "el enjambre aún no tiene cuerpo")


func _probar_flanco() -> void:
	# Rotación 0 mira hacia +Z, igual que atan2(x, z) en el host.
	var rival := Vector3.ZERO
	_comprobar(HOST.flanqueado(rival, 0.0, Vector3(0, 0, 1.4)), false, "de frente no flanquea")
	_comprobar(HOST.flanqueado(rival, 0.0, Vector3(0.6, 0, 1.2)), false, "dentro del arco frontal")
	_comprobar(HOST.flanqueado(rival, 0.0, Vector3(1.4, 0, 0)), true, "de lado flanquea")
	_comprobar(HOST.flanqueado(rival, 0.0, Vector3(0, 0, -1.4)), true, "por la espalda flanquea")
	_comprobar(HOST.flanqueado(rival, 0.0, rival), false, "sin distancia no hay flanco")
	_comprobar(
		HOST.flanqueado(rival, 0.0, Vector3(0, 3.0, 1.4)), false, "la altura no cuenta como flanco"
	)


func _probar_golpes() -> void:
	var guardia := ARQUETIPOS.nuevo(ARQUETIPOS.BLOQUEADOR, 1)
	_comprobar(
		HOST.golpe(guardia, false, false), {"bloqueado": true, "rompe_guardia": false}, "ligero"
	)
	_comprobar(
		HOST.golpe(guardia, false, true), {"bloqueado": true, "rompe_guardia": true}, "fuerte"
	)
	_comprobar(HOST.golpe(guardia, true, false)["bloqueado"], false, "el flanco entra")

	var apertura := guardia.duplicate(true)
	apertura["estado"] = ARQUETIPOS.APERTURA
	_comprobar(HOST.golpe(apertura, false, false)["bloqueado"], false, "la apertura no bloquea")
	_comprobar(HOST.permite_iniciar_ataque(apertura), false, "la apertura es ventana real")
	_comprobar(HOST.permite_iniciar_ataque(guardia), true, "en guardia puede atacar")

	var clasico := {}
	_comprobar(HOST.golpe(clasico, false, true)["bloqueado"], false, "sin arquetipo no bloquea")
	_comprobar(HOST.permite_iniciar_ataque(clasico), true, "sin arquetipo ataca como siempre")


func _probar_giro() -> void:
	var guardia := ARQUETIPOS.nuevo(ARQUETIPOS.BLOQUEADOR, 1)
	var lateral := Vector3(1.4, 0, 0)
	var girado := HOST.girar(guardia, 0.0, Vector3.ZERO, lateral, 0.1)
	_comprobar(is_equal_approx(girado, HOST.GIRO_GUARDIA * 0.1), true, "gira a ritmo limitado")
	var ya_mira := HOST.girar(guardia, PI / 2.0, Vector3.ZERO, lateral, 0.1)
	_comprobar(is_equal_approx(ya_mira, PI / 2.0), true, "no se pasa del objetivo")
	# El camino corto cruza ±PI en vez de dar la vuelta entera.
	var cruce := HOST.girar(guardia, PI - 0.05, Vector3.ZERO, Vector3(-0.1, 0, -1.4), 0.1)
	_comprobar(cruce > PI - 0.05, true, "gira por el camino corto")

	var apertura := guardia.duplicate(true)
	apertura["estado"] = ARQUETIPOS.APERTURA
	_comprobar(HOST.girar(apertura, 0.3, Vector3.ZERO, lateral, 0.1), 0.3, "en apertura no sigue")
	_comprobar(HOST.girar({}, 0.3, Vector3.ZERO, lateral, 0.1), 0.3, "sin arquetipo no gira")


func _probar_rotura_abre_ventana() -> void:
	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.BLOQUEADOR, 1)
	var frente := Vector3(0, 0, ALCANCE_RIVAL)
	var impacto := HOST.golpe(unidad, false, true)
	var contexto := HOST.contexto(Vector3.ZERO, 0.0, frente, bool(impacto["rompe_guardia"]))
	var paso := ARQUETIPOS.avanzar(unidad, PASO, contexto)
	_comprobar(paso["unidad"]["estado"], ARQUETIPOS.APERTURA, "el golpe fuerte abre la guardia")
	_comprobar(paso["ventana_respuesta"], true, "y deja ventana de respuesta")
	_comprobar(
		HOST.golpe(paso["unidad"], false, false)["bloqueado"], false, "el siguiente golpe entra"
	)


## Un jugador plantado de frente que solo pulsa el ataque ligero acaba
## haciendo daño: la guardia caduca sola aunque nadie la rompa ni rodee.
func _probar_guardia_no_es_indefinida() -> void:
	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.BLOQUEADOR, 1)
	var frente := Vector3(0, 0, ALCANCE_RIVAL)
	var recarga := 0.0
	var bloqueados := 0
	var entran := 0
	var tiempo := 0.0
	while tiempo < 6.0:
		var contexto := HOST.contexto(Vector3.ZERO, 0.0, frente, false)
		unidad = ARQUETIPOS.avanzar(unidad, PASO, contexto)["unidad"]
		recarga = maxf(0.0, recarga - PASO)
		if recarga <= 0.0:
			recarga = RECARGA_LIGERA
			if HOST.golpe(unidad, false, false)["bloqueado"]:
				bloqueados += 1
			else:
				entran += 1
		tiempo += PASO
	_comprobar(bloqueados > 0, true, "de frente la guardia bloquea")
	_comprobar(entran > 0, true, "esperar la apertura basta para hacer daño")


## Rodear de verdad, a la velocidad del jugador y a la distancia de golpe,
## supera el giro de la guardia en menos de dos segundos.
func _probar_rodear_a_velocidad_de_juego_flanquea() -> void:
	var unidad := ARQUETIPOS.nuevo(ARQUETIPOS.BLOQUEADOR, 1)
	# Guardia larga ficticia para medir solo el giro, sin apertura por tiempo.
	unidad["temporizador"] = 99.0
	var rotacion := 0.0
	var angulo := 0.0
	var velocidad_angular := VELOCIDAD_JUGADOR / ALCANCE_RIVAL
	var tiempo := 0.0
	var flanco := false
	while tiempo < 2.0 and not flanco:
		angulo += velocidad_angular * PASO
		var jugador := Vector3(sin(angulo), 0, cos(angulo)) * ALCANCE_RIVAL
		rotacion = HOST.girar(unidad, rotacion, Vector3.ZERO, jugador, PASO)
		flanco = HOST.flanqueado(Vector3.ZERO, rotacion, jugador)
		tiempo += PASO
	_comprobar(flanco, true, "rodear a velocidad de juego alcanza el flanco")
	_comprobar(velocidad_angular > HOST.GIRO_GUARDIA, true, "el jugador gira más rápido")


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #1771: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
