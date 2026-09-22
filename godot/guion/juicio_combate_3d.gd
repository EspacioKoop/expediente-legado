class_name JuicioCombate3D
extends Node3D

signal terminado(gano: bool)

const REGLAS = preload("res://guion/juicio_combate_reglas.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")
const HUD = preload("res://guion/juicio_combate_hud.gd")
const ARENA = preload("res://guion/juicio_combate_arena_3d.gd")
const DETERMINACION_BASE := REGLAS.DETERMINACION_BASE
const DETERMINACION_MINIMA_RIVAL := REGLAS.DETERMINACION_MINIMA_RIVAL
const VELOCIDAD_JUGADOR := 4.8
const VELOCIDAD_RIVAL := 2.5
const RADIO_ARENA := 5.0
const ALCANCE_LIGERO := 1.75
const ALCANCE_FUERTE := 2.15
const ALCANCE_RIVAL := REGLAS.ALCANCE_RIVAL
const RECARGA_LIGERA := 0.28
const RECARGA_FUERTE := 0.58
const RECARGA_RIVAL := REGLAS.RECARGA_RIVAL
const TELEGRAFO_RIVAL := REGLAS.TELEGRAFO_RIVAL
const DURACION_DOCTRINA := REGLAS.DURACION_DOCTRINA
const BONUS_TELEGRAFO_COMISION := REGLAS.BONUS_TELEGRAFO_COMISION
const DISTANCIA_MESA := 3.0

var reduccion_movimiento := false

var _acusado: Dictionary = {}
var _bono_documental := 0
var _determinacion_jugador := DETERMINACION_BASE
var _determinacion_rival := DETERMINACION_BASE
var _acabado := false
var _recarga_jugador := 0.0
var _recarga_rival := 0.0
var _esquiva := 0.0
var _enredo := 0.0
var _telegrafo_rival := 0.0
var _telegrafo_rival_total := TELEGRAFO_RIVAL
var _ataque_rival_pendiente := false
var _arcano: Dictionary = {}
var _mito_id := ""
var _ritual: Dictionary = {}
var _contraataque := 0
var _retornos_rival := 0
var _radio_arena := RADIO_ARENA
var _velocidad_rival := VELOCIDAD_RIVAL
var _recarga_fuerte := RECARGA_FUERTE
var _cargas_doctrina: Dictionary = {}
var _doctrina_activa := ""
var _doctrina_tiempo := 0.0
var _comision_pendiente := false

var _jugador: CharacterBody3D
var _rival: CharacterBody3D
var _figura_jugador: Node3D
var _figura_rival: Node3D
var _camara: Camera3D
var _aviso_ataque: MeshInstance3D
var _barra_jugador: ProgressBar
var _barra_rival: ProgressBar
var _etiqueta_ritual: Label
var _etiqueta_ataque: Label
var _botones_doctrina: HBoxContainer
var _barra_momentum: ProgressBar
var _boton_finisher: Button
var _etiqueta_jungiana: Label
var _dano_combo_pendiente := 0
var _curacion_arquetipo_acumulada := 0.0
var _invulnerabilidad_jungiana := 0.0
var _sacudida_camara := 0.0
var _aviso_jungiano_restante := 0.0
var _azar := RandomNumberGenerator.new()


static func determinacion_rival(bono_documental: int) -> int:
	return REGLAS.determinacion_rival(bono_documental)


static func resultado_ataque_rival(distancia: float, esquiva_restante: float) -> String:
	return REGLAS.resultado_ataque_rival(distancia, esquiva_restante)


static func interrumpe_ataque(fuerte: bool, ataque_pendiente: bool, ritual: Dictionary) -> bool:
	return REGLAS.interrumpe_ataque(fuerte, ataque_pendiente, ritual)


static func modificadores_doctrina_ritual(eje: String, ritual: Dictionary) -> Dictionary:
	return REGLAS.modificadores_doctrina_ritual(eje, ritual)


static func duracion_doctrina(eje: String, ritual: Dictionary) -> float:
	return REGLAS.duracion_doctrina(eje, ritual)


static func duracion_telegrafo(comision: bool, ritual: Dictionary) -> float:
	return REGLAS.duracion_telegrafo(comision, ritual)


static func recarga_mesa(ritual: Dictionary) -> float:
	return REGLAS.recarga_mesa(ritual)


static func asamblea_interrumpe(eje_activo: String, ataque_pendiente: bool) -> bool:
	return REGLAS.asamblea_interrumpe(eje_activo, ataque_pendiente)


static func dano_externalizado(dano_base: int, eje_activo: String) -> int:
	return REGLAS.dano_externalizado(dano_base, eje_activo)


static func determinacion_retorno(ritual: Dictionary, retornos_usados: int) -> int:
	return REGLAS.determinacion_retorno(ritual, retornos_usados)


func configurar(
	acusado: Dictionary, bono_documental: int, reducir_movimiento: bool, raiz: int = 0
) -> void:
	_acusado = acusado.duplicate(true)
	_bono_documental = bono_documental
	reduccion_movimiento = reducir_movimiento
	_determinacion_rival = determinacion_rival(_bono_documental)
	_azar.seed = (
		Azar
		. derivar_texto(
			raiz,
			"combate",
			"juicio_combate_3d:%s" % String(_acusado.get("id", "")),
			[bono_documental],
		)
	)


func _ready() -> void:
	_preparar_sistemas_jungianos()
	_resolver_capa_simbolica()
	_montar_arena()
	_montar_hud()
	_actualizar_hud()


func _process(delta: float) -> void:
	if _acabado:
		return
	_recarga_jugador = maxf(0.0, _recarga_jugador - delta)
	_recarga_rival = maxf(0.0, _recarga_rival - delta)
	_esquiva = maxf(0.0, _esquiva - delta)
	_enredo = maxf(0.0, _enredo - delta)
	_invulnerabilidad_jungiana = maxf(0.0, _invulnerabilidad_jungiana - delta)
	_sacudida_camara = maxf(0.0, _sacudida_camara - delta)
	if _aviso_jungiano_restante > 0.0:
		_aviso_jungiano_restante = maxf(0.0, _aviso_jungiano_restante - delta)
		if is_zero_approx(_aviso_jungiano_restante) and _etiqueta_jungiana != null:
			_etiqueta_jungiana.visible = false
	if _doctrina_tiempo > 0.0:
		_doctrina_tiempo = maxf(0.0, _doctrina_tiempo - delta)
		if is_zero_approx(_doctrina_tiempo):
			_cerrar_doctrina()
	_mover_jugador(delta)
	_mover_rival(delta)
	_actualizar_camara()

	if Input.is_action_just_pressed("interactuar"):
		_atacar(1, ALCANCE_LIGERO, RECARGA_LIGERA, false)
	if Input.is_action_just_pressed("saltar"):
		_atacar(2, ALCANCE_FUERTE, _recarga_fuerte, true)
	if Input.is_action_just_pressed("agacharse"):
		_esquivar()


func activar_doctrina(eje: String) -> bool:
	if _acabado or not Historias.HABILIDADES.has(eje):
		return false
	if int(_cargas_doctrina.get(eje, 0)) <= 0:
		return false
	if not _doctrina_activa.is_empty() or _comision_pendiente:
		return false

	_cargas_doctrina[eje] = int(_cargas_doctrina[eje]) - 1
	match eje:
		"comunismo", "neoliberal":
			_doctrina_activa = eje
			_doctrina_tiempo = duracion_doctrina(eje, _ritual)
		"centrista":
			_aplicar_mesa_dialogo()
		"socialdemocrata":
			_activar_comision()

	Sonido.sonar(self, "marcar")
	_actualizar_hud()
	_pintar_doctrinas()
	return true


func abandonar() -> void:
	_terminar(false)


func _aplicar_mesa_dialogo() -> void:
	if _ataque_rival_pendiente:
		_cancelar_ataque_rival()
	_recarga_rival = maxf(_recarga_rival, recarga_mesa(_ritual))
	if _jugador == null or _rival == null:
		return
	var separacion := _rival.position - _jugador.position
	separacion.y = 0.0
	if separacion.length_squared() < 0.001:
		separacion = Vector3(0.0, 0.0, -1.0)
	_rival.position = _limitar(_jugador.position + separacion.normalized() * DISTANCIA_MESA)


func _activar_comision() -> void:
	if not _ataque_rival_pendiente:
		_comision_pendiente = true
		return
	var total_nuevo := duracion_telegrafo(true, _ritual)
	var extra := maxf(0.0, total_nuevo - TELEGRAFO_RIVAL)
	_telegrafo_rival += extra
	_telegrafo_rival_total += extra
	_doctrina_activa = "socialdemocrata"
	_doctrina_tiempo = _telegrafo_rival


func _cerrar_doctrina() -> void:
	if _doctrina_activa.is_empty():
		return
	_doctrina_activa = ""
	_doctrina_tiempo = 0.0
	_actualizar_hud()
	_pintar_doctrinas()


func _mover_jugador(delta: float) -> void:
	var direccion := Vector2(
		Input.get_axis("mover_izquierda", "mover_derecha"),
		Input.get_axis("mover_adelante", "mover_atras")
	)
	if direccion.length_squared() > 1.0:
		direccion = direccion.normalized()
	var multiplicador := 2.25 if _esquiva > 0.0 else 1.0
	_jugador.position += (
		Vector3(direccion.x, 0.0, direccion.y) * VELOCIDAD_JUGADOR * multiplicador * delta
	)
	_jugador.position = _limitar(_jugador.position)
	if direccion.length_squared() > 0.01:
		_jugador.rotation.y = atan2(direccion.x, direccion.y)


func _mover_rival(delta: float) -> void:
	if _ataque_rival_pendiente:
		_actualizar_telegrafo_rival(delta)
		return

	var hacia := _jugador.position - _rival.position
	hacia.y = 0.0
	var distancia := hacia.length()
	if distancia > ALCANCE_RIVAL:
		var direccion := hacia.normalized()
		var velocidad := _velocidad_rival
		if _enredo > 0.0:
			velocidad *= float(_ritual.get("velocidad_enredado_mul", 1.0))
		_rival.position += direccion * velocidad * delta
		_rival.position = _limitar(_rival.position)
		_rival.rotation.y = atan2(direccion.x, direccion.z)
	elif _recarga_rival <= 0.0:
		_iniciar_ataque_rival()


func _iniciar_ataque_rival() -> void:
	if _ataque_rival_pendiente or _acabado:
		return
	_ataque_rival_pendiente = true
	var usar_comision := _comision_pendiente
	_telegrafo_rival_total = duracion_telegrafo(usar_comision, _ritual)
	_telegrafo_rival = _telegrafo_rival_total
	if usar_comision:
		_comision_pendiente = false
		_doctrina_activa = "socialdemocrata"
		_doctrina_tiempo = _telegrafo_rival_total
		_actualizar_hud()
		_pintar_doctrinas()
	if _aviso_ataque != null:
		_aviso_ataque.position = _rival.position + Vector3(0.0, 0.02, 0.0)
		_aviso_ataque.scale = Vector3.ONE
		_aviso_ataque.visible = true
	if _etiqueta_ataque != null:
		_etiqueta_ataque.visible = true
	Sonido.sonar(self, "marcar")


func _actualizar_telegrafo_rival(delta: float) -> void:
	_telegrafo_rival = maxf(0.0, _telegrafo_rival - delta)
	if _aviso_ataque != null:
		_aviso_ataque.position = _rival.position + Vector3(0.0, 0.02, 0.0)
		if not reduccion_movimiento:
			var total := maxf(_telegrafo_rival_total, 0.001)
			var progreso := 1.0 - _telegrafo_rival / total
			var escala := lerpf(0.72, 1.0, progreso)
			_aviso_ataque.scale = Vector3(escala, 1.0, escala)
	if _telegrafo_rival <= 0.0:
		_resolver_ataque_rival()


func _resolver_ataque_rival() -> void:
	_ataque_rival_pendiente = false
	_recarga_rival = RECARGA_RIVAL
	_ocultar_aviso_ataque()

	var comision_activa := _doctrina_activa == "socialdemocrata"
	var externaliza_activa := _doctrina_activa == "neoliberal"
	var hacia := _jugador.position - _rival.position
	hacia.y = 0.0
	match resultado_ataque_rival(hacia.length(), _esquiva):
		"falla":
			pass
		"esquiva":
			Sonido.sonar(self, "pulsar")
			_registrar_esquiva_ritual()
		_:
			if _invulnerabilidad_jungiana > 0.0:
				Sonido.sonar(self, "pulsar")
				_mostrar_aviso_jungiano("SELF · IMPACTO NEGADO", 0.8)
			else:
				Sonido.sonar(self, "error")
				var dano := dano_externalizado(1, _doctrina_activa)
				_determinacion_jugador = maxi(0, _determinacion_jugador - dano)
				var gestor_momentum := _gestor_jungiano("GestorMomentum")
				if gestor_momentum != null:
					gestor_momentum.call("registrar_dano_recibido")
				if externaliza_activa:
					_cerrar_doctrina()
				_reaccion(_figura_jugador, -0.18)
				_actualizar_hud()
				if _determinacion_jugador <= 0:
					_terminar(false)

	if comision_activa:
		_cerrar_doctrina()


func _cancelar_ataque_rival() -> void:
	_ataque_rival_pendiente = false
	_telegrafo_rival = 0.0
	_telegrafo_rival_total = TELEGRAFO_RIVAL
	_recarga_rival = maxf(_recarga_rival, RECARGA_RIVAL * 0.65)
	_ocultar_aviso_ataque()
	if _doctrina_activa == "socialdemocrata":
		_cerrar_doctrina()
	Sonido.sonar(self, "pulsar")


func _ocultar_aviso_ataque() -> void:
	if _aviso_ataque != null:
		_aviso_ataque.visible = false
	if _etiqueta_ataque != null:
		_etiqueta_ataque.visible = false


func _atacar(dano_base: int, alcance: float, recarga: float, fuerte: bool) -> void:
	if _recarga_jugador > 0.0:
		return
	_recarga_jugador = recarga
	var hacia := _rival.position - _jugador.position
	hacia.y = 0.0
	if hacia.length() > 0.01:
		_jugador.rotation.y = atan2(hacia.x, hacia.z)
	if hacia.length() > alcance:
		return

	var efectos_jungianos: Dictionary = {}
	var gestor_arquetipos := _gestor_jungiano("GestorArquetipos")
	if gestor_arquetipos != null:
		var efectos = gestor_arquetipos.call("efectos_combinados")
		if typeof(efectos) == TYPE_DICTIONARY:
			efectos_jungianos = efectos
	var probabilidad_critico := clampf(
		(
			float(efectos_jungianos.get("bonus_crit", 0.0))
			+ float(efectos_jungianos.get("bonus_todo", 0.0))
		),
		0.0,
		0.75
	)
	var es_critico := probabilidad_critico > 0.0 and _azar.randf() < probabilidad_critico
	var gestor_momentum := _gestor_jungiano("GestorMomentum")
	if gestor_momentum != null:
		gestor_momentum.call("registrar_golpe", es_critico)
	var gestor_combos := _gestor_jungiano("GestorCombos")
	if gestor_combos != null:
		gestor_combos.call("registrar_entrada", "ataque_pesado" if fuerte else "ataque_ligero")

	var dano := dano_base + _dano_combo_pendiente
	_dano_combo_pendiente = 0
	if es_critico:
		dano += 1
		_mostrar_aviso_jungiano("CRÍTICO", 0.65)
	if fuerte:
		dano += int(_ritual.get("dano_fuerte_bonus", 0))
	var interrupcion_ritual := interrumpe_ataque(fuerte, _ataque_rival_pendiente, _ritual)
	var interrupcion_asamblea := asamblea_interrumpe(_doctrina_activa, _ataque_rival_pendiente)
	if interrupcion_ritual:
		dano += int(_ritual.get("dano_interrupcion_bonus", 0))
	if interrupcion_ritual or interrupcion_asamblea:
		_cancelar_ataque_rival()
	if interrupcion_asamblea:
		_cerrar_doctrina()
	if _contraataque > 0:
		dano += _contraataque
		_contraataque = 0
	if _doctrina_activa == "neoliberal":
		dano = dano_externalizado(dano, _doctrina_activa)
		_cerrar_doctrina()

	_determinacion_rival = maxi(0, _determinacion_rival - dano)
	_aplicar_curacion_arquetipo(efectos_jungianos)
	if not fuerte:
		var segundos_enredo := float(_ritual.get("enredo_ligero_segundos", 0.0))
		if segundos_enredo > 0.0:
			_enredo = maxf(_enredo, segundos_enredo)
	_reaccion(_figura_rival, 0.25 + float(dano) * 0.08)
	_actualizar_hud()
	if _determinacion_rival <= 0 and not _intentar_retorno_rival():
		_terminar(true)


func _intentar_retorno_rival() -> bool:
	var determinacion := determinacion_retorno(_ritual, _retornos_rival)
	if determinacion <= 0:
		return false
	_retornos_rival += 1
	_determinacion_rival = determinacion
	_recarga_rival = RECARGA_RIVAL * 0.50
	_reaccion(_figura_rival, -0.30)
	Sonido.sonar(self, "marcar")
	_actualizar_hud()
	return true


func _esquivar() -> void:
	if _esquiva > 0.0:
		return
	var efectos: Dictionary = {}
	var gestor_arquetipos := _gestor_jungiano("GestorArquetipos")
	if gestor_arquetipos != null:
		var activos = gestor_arquetipos.call("efectos_combinados")
		if typeof(activos) == TYPE_DICTIONARY:
			efectos = activos
	var bonus_evasion := float(efectos.get("evasion", 0.0)) + float(efectos.get("bonus_todo", 0.0))
	_esquiva = 0.34 * (1.0 + bonus_evasion)
	var gestor_combos := _gestor_jungiano("GestorCombos")
	if gestor_combos != null:
		gestor_combos.call("registrar_entrada", "esquivar")
	if reduccion_movimiento:
		return
	_reaccion(_figura_jugador, 0.12)


func _registrar_esquiva_ritual() -> void:
	var bono := int(_ritual.get("contraataque_esquiva", 0))
	if bono <= 0:
		return
	_contraataque = maxi(_contraataque, bono)
	_reaccion(_figura_rival, 0.10)
	_actualizar_hud()


func _terminar(gano: bool) -> void:
	if _acabado:
		return
	_acabado = true
	_ataque_rival_pendiente = false
	var gestor_momentum := _gestor_jungiano("GestorMomentum")
	if gestor_momentum != null:
		gestor_momentum.call("salir_combate")
	var gestor_combos := _gestor_jungiano("GestorCombos")
	if gestor_combos != null:
		gestor_combos.call("reiniciar")
	_ocultar_aviso_ataque()
	terminado.emit(gano)


func _limitar(posicion: Vector3) -> Vector3:
	var plano := Vector2(posicion.x, posicion.z)
	if plano.length() > _radio_arena:
		plano = plano.normalized() * _radio_arena
	return Vector3(plano.x, 0.0, plano.y)


func _resolver_capa_simbolica() -> void:
	var estado := _estado_partida_anfitrion()
	if estado.is_empty():
		return
	_cargas_doctrina = Prometeo.cargas_ideologicas(estado, Historias.TOPE_CARGAS)
	var clave := String(_acusado.get("id", _acusado.get("nombre", "acusado")))
	var tarot = estado.get("tarot", [])
	if typeof(tarot) == TYPE_ARRAY:
		_arcano = JuicioSimbolico.arcano_para(tarot, clave)
	var jornada = estado.get("jornada", {})
	if typeof(jornada) == TYPE_DICTIONARY:
		_mito_id = JuicioSimbolico.mito_para(jornada, clave)
	_ritual = JuicioSimbolico.ritual_para(_arcano, _mito_id)
	_aplicar_configuracion_ritual()


func _aplicar_configuracion_ritual() -> void:
	_radio_arena = float(_ritual.get("radio_arena", RADIO_ARENA))
	_velocidad_rival = VELOCIDAD_RIVAL * float(_ritual.get("velocidad_rival_mul", 1.0))
	_recarga_fuerte = float(_ritual.get("recarga_fuerte", RECARGA_FUERTE))


func _estado_partida_anfitrion() -> Dictionary:
	var anfitrion := get_parent()
	if anfitrion == null:
		return {}
	var tiene_partida := false
	for bruto in anfitrion.get_property_list():
		if typeof(bruto) == TYPE_DICTIONARY and String(bruto.get("name", "")) == "partida":
			tiene_partida = true
			break
	if not tiene_partida:
		return {}
	var partida_actual = anfitrion.get("partida")
	if partida_actual is Partida:
		return partida_actual.estado
	return {}


func _montar_arena() -> void:
	var nodos := (
		ARENA
		. montar(
			self,
			_acusado,
			_arcano,
			_mito_id,
			_ritual,
			RADIO_ARENA,
			_radio_arena,
		)
	)
	_jugador = nodos["jugador"]
	_rival = nodos["rival"]
	_figura_jugador = nodos["figura_jugador"]
	_figura_rival = nodos["figura_rival"]
	_aviso_ataque = nodos["aviso_ataque"]
	_camara = nodos["camara"]
	_actualizar_camara()


func _montar_hud() -> void:
	var nodos := (
		HUD
		. montar(
			self,
			tr(String(_acusado.get("nombre", ""))),
			determinacion_rival(_bono_documental),
			not _ritual.is_empty() or _hay_cargas_doctrina(),
			{
				"ataque_inminente": tr("VENTANILLA_ATAQUE_INMINENTE"),
				"momentum": tr("JUICIO_JUNGIANO_MOMENTUM"),
				"finisher": tr("JUICIO_JUNGIANO_FINISHER"),
				"finisher_tooltip": tr("JUICIO_JUNGIANO_FINISHER_TOOLTIP"),
			},
			Callable(self, "_ejecutar_finisher_jungiano"),
		)
	)
	_barra_jugador = nodos["barra_jugador"]
	_barra_rival = nodos["barra_rival"]
	_etiqueta_ritual = nodos["etiqueta_ritual"]
	_etiqueta_ataque = nodos["etiqueta_ataque"]
	_botones_doctrina = nodos["botones_doctrina"]
	_barra_momentum = nodos["barra_momentum"]
	_boton_finisher = nodos["boton_finisher"]
	_etiqueta_jungiana = nodos["etiqueta_jungiana"]
	_pintar_doctrinas()


func _actualizar_hud() -> void:
	if _barra_jugador == null or _barra_rival == null:
		return
	_barra_jugador.value = _determinacion_jugador
	_barra_rival.value = _determinacion_rival
	if _etiqueta_ritual != null:
		_etiqueta_ritual.text = _texto_ritual()
	_actualizar_hud_jungiano()


func _texto_ritual() -> String:
	var texto := ""
	if not _ritual.is_empty():
		texto = "RITUAL · %s" % String(_ritual.get("nombre", ""))
	if _contraataque > 0:
		texto += (" · " if not texto.is_empty() else "") + "CONTRA +%d" % _contraataque
	var eje_estado := _doctrina_activa
	if eje_estado.is_empty() and _comision_pendiente:
		eje_estado = "socialdemocrata"
	if not eje_estado.is_empty():
		var habilidad: Dictionary = Historias.HABILIDADES[eje_estado]
		var nombre := tr(String(habilidad["nombre"]))
		texto += (" · " if not texto.is_empty() else "") + nombre
	return texto


func _hay_cargas_doctrina() -> bool:
	for eje in Prometeo.EJES:
		if int(_cargas_doctrina.get(eje, 0)) > 0:
			return true
	return false


func _pintar_doctrinas() -> void:
	if _botones_doctrina == null:
		return
	for hijo in _botones_doctrina.get_children():
		_botones_doctrina.remove_child(hijo)
		hijo.queue_free()

	var bloqueadas := not _doctrina_activa.is_empty() or _comision_pendiente
	for eje in Prometeo.EJES:
		var cantidad := int(_cargas_doctrina.get(eje, 0))
		if cantidad <= 0:
			continue
		var habilidad: Dictionary = Historias.HABILIDADES[eje]
		var boton := Button.new()
		var texto_boton := "%s ×%d" % [tr(String(habilidad["nombre"])), cantidad]
		boton.text = texto_boton
		boton.tooltip_text = tr(String(habilidad["efecto"]))
		boton.disabled = bloqueadas
		boton.pressed.connect(activar_doctrina.bind(eje))
		_botones_doctrina.add_child(boton)
	_botones_doctrina.visible = _botones_doctrina.get_child_count() > 0


func _actualizar_camara() -> void:
	(
		FEEDBACK
		. actualizar_camara(
			_camara,
			_jugador,
			_rival,
			_sacudida_camara,
			reduccion_movimiento,
			_azar,
		)
	)


func _gestor_jungiano(nombre: String) -> Node:
	return get_node_or_null("/root/" + nombre)


func _preparar_sistemas_jungianos() -> void:
	var arquetipos := _gestor_jungiano("GestorArquetipos")
	var momentum := _gestor_jungiano("GestorMomentum")
	var combos := _gestor_jungiano("GestorCombos")
	if arquetipos == null or momentum == null or combos == null:
		return

	momentum.call("reiniciar")
	combos.call("reiniciar")
	var catalogo = arquetipos.get("arquetipos")
	if typeof(catalogo) == TYPE_DICTIONARY:
		for arquetipo_id in catalogo:
			var arquetipo = catalogo[arquetipo_id]
			if arquetipo != null and bool(arquetipo.get("desbloqueado")):
				momentum.call("aplicar_modificador_arquetipo", String(arquetipo_id))
	momentum.set("en_combate", true)

	var cb_arquetipo := Callable(self, "_al_arquetipo_desbloqueado")
	if (
		arquetipos.has_signal("arquetipo_desbloqueado")
		and not arquetipos.is_connected("arquetipo_desbloqueado", cb_arquetipo)
	):
		arquetipos.connect("arquetipo_desbloqueado", cb_arquetipo)
	var cb_momentum := Callable(self, "_al_momentum_cambiado")
	if (
		momentum.has_signal("momentum_cambiado")
		and not momentum.is_connected("momentum_cambiado", cb_momentum)
	):
		momentum.connect("momentum_cambiado", cb_momentum)
	var cb_combo := Callable(self, "_al_combo_ejecutado")
	if (
		combos.has_signal("combo_ejecutado")
		and not combos.is_connected("combo_ejecutado", cb_combo)
	):
		combos.connect("combo_ejecutado", cb_combo)
	var cb_finisher := Callable(self, "_al_finisher_ejecutado")
	if (
		combos.has_signal("finisher_ejecutado")
		and not combos.is_connected("finisher_ejecutado", cb_finisher)
	):
		combos.connect("finisher_ejecutado", cb_finisher)


func _al_arquetipo_desbloqueado(arquetipo_id: String) -> void:
	var momentum := _gestor_jungiano("GestorMomentum")
	if momentum != null:
		momentum.call("aplicar_modificador_arquetipo", arquetipo_id)
	var arquetipos := _gestor_jungiano("GestorArquetipos")
	var nombre := arquetipo_id
	var puntos := 0
	if arquetipos != null:
		var arquetipo = arquetipos.call("obtener_arquetipo", arquetipo_id)
		if arquetipo != null:
			nombre = String(arquetipo.get("nombre"))
		puntos = int(arquetipos.get("puntos_habilidad"))
	_mostrar_aviso_jungiano("ARQUETIPO · %s · HABILIDAD +1 (%d)" % [nombre, puntos], 2.5)
	_actualizar_hud_jungiano()


func _al_momentum_cambiado(_actual: float, _maximo: float) -> void:
	_actualizar_hud_jungiano()


func _al_combo_ejecutado(nombre: String, efectos: Dictionary) -> void:
	if efectos.has("dano_multiplier"):
		_dano_combo_pendiente += maxi(1, int(round(float(efectos["dano_multiplier"]) - 1.0)))
	if efectos.has("dano"):
		_dano_combo_pendiente += maxi(0, int(efectos["dano"]))
	if efectos.has("curacion"):
		_determinacion_jugador = mini(
			DETERMINACION_BASE, _determinacion_jugador + maxi(0, int(efectos["curacion"]))
		)
	if bool(efectos.get("contragolpe", false)):
		_contraataque = maxi(_contraataque, 1)
	if efectos.has("evasion_temporal"):
		_esquiva = maxf(_esquiva, float(efectos.get("duracion", 0.8)))
	var radio := float(efectos.get("area", 1.2))
	_particulas_jungianas(radio, false)
	Sonido.sonar(self, "pulsar")
	_mostrar_aviso_jungiano("COMBO · %s" % nombre, 1.2)


func _ejecutar_finisher_jungiano() -> void:
	var combos := _gestor_jungiano("GestorCombos")
	if combos == null:
		return
	var finisher_id := String(combos.call("finisher_disponible_actual"))
	if finisher_id.is_empty():
		return
	combos.call("ejecutar_finisher", finisher_id)


func _al_finisher_ejecutado(nombre: String, efectos: Dictionary, es_super: bool) -> void:
	var dano := maxi(0, int(efectos.get("dano", 0)))
	_determinacion_rival = maxi(0, _determinacion_rival - dano)
	if bool(efectos.get("curacion_total", false)):
		_determinacion_jugador = DETERMINACION_BASE
	_invulnerabilidad_jungiana = maxf(
		_invulnerabilidad_jungiana, float(efectos.get("invulnerabilidad", 0.0))
	)
	_sacudida_camara = 0.38 if es_super else 0.24
	_particulas_jungianas(float(efectos.get("area", 2.4)), es_super)
	_reaccion(_figura_rival, 0.62 if es_super else 0.42)
	Sonido.sonar(self, "marcar")
	_mostrar_aviso_jungiano(("SUPER FINISHER · " if es_super else "FINISHER · ") + nombre, 1.8)
	_actualizar_hud()
	if _determinacion_rival <= 0 and not _intentar_retorno_rival():
		_terminar(true)


func _aplicar_curacion_arquetipo(efectos: Dictionary) -> void:
	var tasa := float(efectos.get("curacion", 0.0)) + float(efectos.get("bonus_todo", 0.0))
	if tasa <= 0.0 or _determinacion_jugador >= DETERMINACION_BASE:
		return
	_curacion_arquetipo_acumulada += tasa
	while _curacion_arquetipo_acumulada >= 1.0:
		_curacion_arquetipo_acumulada -= 1.0
		_determinacion_jugador = mini(DETERMINACION_BASE, _determinacion_jugador + 1)


func _actualizar_hud_jungiano() -> void:
	var momentum := _gestor_jungiano("GestorMomentum")
	var combos := _gestor_jungiano("GestorCombos")
	if _barra_momentum != null and momentum != null:
		_barra_momentum.max_value = float(momentum.get("momentum_max"))
		_barra_momentum.value = float(momentum.get("momentum_actual"))
	if _boton_finisher == null:
		return
	if combos == null:
		_boton_finisher.disabled = true
		_boton_finisher.text = tr("JUICIO_JUNGIANO_FINISHER")
		return
	var finisher_id := String(combos.call("finisher_disponible_actual"))
	_boton_finisher.disabled = finisher_id.is_empty() or _acabado
	if finisher_id.is_empty():
		_boton_finisher.text = tr("JUICIO_JUNGIANO_FINISHER")
		return
	var catalogo = combos.get("finishers")
	var es_super := false
	if typeof(catalogo) == TYPE_DICTIONARY and catalogo.has(finisher_id):
		es_super = bool(catalogo[finisher_id].get("es_super", false))
	_boton_finisher.text = (
		tr("JUICIO_JUNGIANO_SUPER_FINISHER") if es_super else tr("JUICIO_JUNGIANO_FINISHER")
	)


func _mostrar_aviso_jungiano(texto: String, duracion: float) -> void:
	if _etiqueta_jungiana == null:
		return
	_etiqueta_jungiana.text = texto
	_etiqueta_jungiana.visible = true
	_aviso_jungiano_restante = maxf(_aviso_jungiano_restante, duracion)


func _particulas_jungianas(radio: float, es_super: bool) -> void:
	FEEDBACK.particulas_jungianas(self, _rival, radio, es_super)


func _reaccion(figura: Node3D, desplazamiento: float) -> void:
	FEEDBACK.reaccion(self, figura, desplazamiento, reduccion_movimiento)


func _material(color: Color, emision: bool = false) -> StandardMaterial3D:
	return FEEDBACK.material(color, emision)
