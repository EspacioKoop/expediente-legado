## Regresión standalone del bloqueador onírico (#1771) cableado al duelo real
## de JuicioCombate3D y al host contextual del sueño.
##
##     godot4 --headless --path godot --script pruebas/pruebas_bloqueador_host_1771.gd
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const PASO := 1.0 / 60.0
const RAIZ := 7

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	await _probar_duelo_clasico_intacto()
	await _probar_arquetipo_sin_cuerpo_no_se_monta()
	await _probar_frente_bloquea()
	await _probar_fuerte_rompe_y_abre()
	await _probar_flanco_entra()
	await _probar_apertura_quieta_y_sin_ataque()
	await _probar_espalda_no_deja_guardia_abierta_para_siempre()
	await _probar_reduccion_movimiento_no_cambia_reglas()
	await _probar_host_contextual_solo_sueno()
	# Sonidos, gestos y tweens de reacción son efímeros del SceneTree.
	await create_timer(0.5).timeout
	await process_frame
	print("bloqueador_host_1771: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_duelo_clasico_intacto() -> void:
	var juicio := await _nuevo("")
	_comprobar(juicio._arquetipo.is_empty(), true, "sin arquetipo no hay política")
	_comprobar(juicio._escudo_guardia == null, true, "sin arquetipo no hay guardia visible")
	var antes := juicio._determinacion_rival
	_golpe(juicio, false)
	_comprobar(juicio._determinacion_rival, antes - 1, "el golpe frontal clásico hace daño")
	juicio.free()


func _probar_arquetipo_sin_cuerpo_no_se_monta() -> void:
	var juicio := await _nuevo(ARQUETIPOS.HOSTIGADOR)
	_comprobar(juicio._arquetipo.is_empty(), true, "el hostigador aún no tiene cuerpo")
	var antes := juicio._determinacion_rival
	_golpe(juicio, false)
	_comprobar(juicio._determinacion_rival, antes - 1, "y el duelo sigue siendo el clásico")
	juicio.free()


func _probar_frente_bloquea() -> void:
	var juicio := await _nuevo(ARQUETIPOS.BLOQUEADOR)
	_comprobar(_estado(juicio), ARQUETIPOS.GUARDIA, "el bloqueador empieza en guardia")
	_comprobar(juicio._escudo_guardia.visible, true, "la guardia se ve sin texto")
	var antes := juicio._determinacion_rival
	_golpe(juicio, false)
	_comprobar(juicio._determinacion_rival, antes, "de frente el golpe ligero no entra")
	_comprobar(juicio._guardia_rota, false, "el ligero no rompe la guardia")
	juicio._avanzar_arquetipo(PASO)
	_comprobar(_estado(juicio), ARQUETIPOS.GUARDIA, "y la guardia se mantiene")
	juicio.free()


func _probar_fuerte_rompe_y_abre() -> void:
	var juicio := await _nuevo(ARQUETIPOS.BLOQUEADOR)
	var antes := juicio._determinacion_rival
	_golpe(juicio, true)
	_comprobar(juicio._determinacion_rival, antes, "el fuerte de frente tampoco hace daño")
	juicio._avanzar_arquetipo(PASO)
	_comprobar(_estado(juicio), ARQUETIPOS.APERTURA, "pero rompe la guardia y la abre")
	_comprobar(juicio._escudo_guardia.visible, false, "la apertura retira la guardia")
	_golpe(juicio, false)
	_comprobar(juicio._determinacion_rival, antes - 1, "en la apertura el ligero entra")
	juicio.free()


func _probar_flanco_entra() -> void:
	var juicio := await _nuevo(ARQUETIPOS.BLOQUEADOR)
	# El rival mira a +Z desde (0, 0, -1): a su lado queda fuera del arco frontal.
	juicio._jugador.position = Vector3(1.0, 0.0, -1.0)
	var antes := juicio._determinacion_rival
	_golpe(juicio, false)
	_comprobar(juicio._determinacion_rival, antes - 1, "por el flanco el golpe entra")
	juicio._avanzar_arquetipo(PASO)
	_comprobar(_estado(juicio), ARQUETIPOS.APERTURA, "y el flanco abre la guardia")
	juicio.free()


func _probar_apertura_quieta_y_sin_ataque() -> void:
	var juicio := await _nuevo(ARQUETIPOS.BLOQUEADOR)
	juicio._arquetipo["estado"] = ARQUETIPOS.APERTURA
	juicio._arquetipo["temporizador"] = ARQUETIPOS.BLOQUEADOR_APERTURA
	juicio._estado_temporal.recarga_rival = 0.0

	juicio._jugador.position = Vector3(0.0, 0.0, 3.0)
	var posicion := juicio._rival.position
	juicio._mover_rival(PASO)
	_comprobar(juicio._rival.position, posicion, "en apertura no persigue")

	juicio._jugador.position = Vector3.ZERO
	juicio._mover_rival(PASO)
	_comprobar(juicio._ataque_rival_pendiente, false, "en apertura no empieza ataque")

	juicio._arquetipo["estado"] = ARQUETIPOS.GUARDIA
	juicio._mover_rival(PASO)
	_comprobar(juicio._ataque_rival_pendiente, true, "en guardia sí ataca: no es un muro pasivo")
	juicio.free()


## Plantarse a la espalda da ventanas, pero la figura acaba girando y vuelve a
## proteger el frente: ni guardia infinita ni apertura infinita.
func _probar_espalda_no_deja_guardia_abierta_para_siempre() -> void:
	var juicio := await _nuevo(ARQUETIPOS.BLOQUEADOR)
	juicio._jugador.position = Vector3(0.0, 0.0, -2.0)
	var aperturas := 0
	var recupera_frente := false
	var anterior := _estado(juicio)
	var tiempo := 0.0
	while tiempo < 6.0:
		juicio._avanzar_arquetipo(PASO)
		var estado := _estado(juicio)
		if estado == ARQUETIPOS.APERTURA and anterior != ARQUETIPOS.APERTURA:
			aperturas += 1
		var flanco := HOST.flanqueado(
			juicio._rival.position, juicio._rival.rotation.y, juicio._jugador.position
		)
		if aperturas > 0 and estado == ARQUETIPOS.GUARDIA and not flanco:
			recupera_frente = true
		anterior = estado
		tiempo += PASO
	_comprobar(aperturas > 0, true, "la espalda abre la guardia")
	_comprobar(recupera_frente, true, "y la figura acaba girando para cubrir el frente")
	juicio.free()


func _probar_reduccion_movimiento_no_cambia_reglas() -> void:
	var animado := await _nuevo(ARQUETIPOS.BLOQUEADOR, false)
	var reducido := await _nuevo(ARQUETIPOS.BLOQUEADOR, true)
	var iguales := true
	var tiempo := 0.0
	while tiempo < 3.0:
		animado._avanzar_arquetipo(PASO)
		reducido._avanzar_arquetipo(PASO)
		if _estado(animado) != _estado(reducido):
			iguales = false
		if animado._escudo_guardia.visible != reducido._escudo_guardia.visible:
			iguales = false
		tiempo += PASO
	_comprobar(iguales, true, "reduccion_movimiento conserva estados y telegraph de guardia")
	animado.free()
	reducido.free()


func _probar_host_contextual_solo_sueno() -> void:
	var id := ""
	for indice in range(40):
		var candidato := "figura-host-%d" % indice
		if HOST.elegir(candidato, RAIZ, CombateContextual.PLANO_SUENO) == ARQUETIPOS.BLOQUEADOR:
			id = candidato
			break
	_comprobar(id.is_empty(), false, "hay figuras oníricas con bloqueador")

	var sueno := _abrir_contextual(id, CombateContextual.PLANO_SUENO)
	var combate: JuicioCombate3D = sueno._combate
	_comprobar(combate.arquetipo_onirico, ARQUETIPOS.BLOQUEADOR, "el sueño pasa el arquetipo")
	_comprobar(_estado(combate), ARQUETIPOS.GUARDIA, "y el duelo monta la guardia")
	sueno.free()

	var realidad := _abrir_contextual(id, CombateContextual.PLANO_REALIDAD)
	combate = realidad._combate
	_comprobar(combate.arquetipo_onirico, "", "la misma figura en la realidad es clásica")
	_comprobar(combate._arquetipo.is_empty(), true, "sin política en la realidad")
	realidad.free()
	await process_frame


func _abrir_contextual(id: String, plano: String) -> DiaCombateContextualApp:
	var app := DiaCombateContextualApp.new()
	get_root().add_child(app)
	var caminante := CharacterBody3D.new()
	var mundo := Node3D.new()
	var hud := CanvasLayer.new()
	for nodo in [caminante, mundo, hud]:
		app.add_child(nodo)
	var abierto := (
		app
		. abrir(
			{"id": id, "nombre": "FIGURA"},
			{"permitido": true, "plano": plano},
			null,
			caminante,
			mundo,
			hud,
			Environment.new(),
			Partida.new(),
			{},
			RAIZ,
		)
	)
	_comprobar(abierto, true, "el host contextual abre el duelo (%s)" % plano)
	app._combate.set_process(false)
	return app


func _nuevo(arquetipo: String, reducir: bool = true) -> JuicioCombate3D:
	var juicio := JuicioCombate3D.new()
	juicio.configurar({"id": "prueba_1771", "nombre": "PRUEBA #1771"}, 0, reducir, RAIZ)
	juicio.arquetipo_onirico = arquetipo
	get_root().add_child(juicio)
	# Los pasos los da la prueba; el _process real movería al rival entre medias.
	juicio.set_process(false)
	await process_frame
	juicio._jugador.position = Vector3.ZERO
	juicio._rival.position = Vector3(0.0, 0.0, -1.0)
	juicio._rival.rotation.y = 0.0
	return juicio


func _golpe(juicio: JuicioCombate3D, fuerte: bool) -> void:
	juicio._recarga_jugador = 0.0
	if fuerte:
		juicio._atacar(2, JuicioCombate3D.ALCANCE_FUERTE, JuicioCombate3D.RECARGA_FUERTE, true)
	else:
		juicio._atacar(1, JuicioCombate3D.ALCANCE_LIGERO, JuicioCombate3D.RECARGA_LIGERA, false)


func _estado(juicio: JuicioCombate3D) -> String:
	return String(juicio._arquetipo.get("estado", ""))


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #1771 host: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
