class_name JuicioCombate3D
extends Node3D

signal terminado(gano: bool)

const REGLAS = preload("res://guion/juicio_combate_reglas.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")
const HUD = preload("res://guion/juicio_combate_hud.gd")
const ARENA = preload("res://guion/juicio_combate_arena_3d.gd")
const JUNGIANO = preload("res://guion/juicio_combate_jungiano.gd")
const SIMBOLICO = preload("res://guion/juicio_combate_simbolico.gd")
const RIVAL = preload("res://guion/juicio_combate_rival.gd")
const DOCTRINA = preload("res://guion/juicio_combate_doctrina.gd")
const JUGADOR = preload("res://guion/juicio_combate_jugador.gd")
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
var _compromisos_religion: Array = []
var _rival_inicio_agresion := false

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


## Primer compromiso religioso (#936) que todavía obliga a ceder la
## iniciativa. Vacío si no hay compromisos o si el rival ya atacó primero.
static func compromiso_religion_bloqueante(
	compromisos: Array, rival_inicio_agresion: bool
) -> Dictionary:
	return SIMBOLICO.compromiso_religion_bloqueante(compromisos, rival_inicio_agresion)


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
	var plan := (
		DOCTRINA
		. intentar_activar(
			eje,
			_cargas_doctrina,
			_ritual,
			_acabado,
			Historias.HABILIDADES.has(eje),
			_doctrina_activa,
			_comision_pendiente,
		)
	)
	if not bool(plan["aceptada"]):
		return false

	_cargas_doctrina = plan["cargas"]
	match String(plan["accion"]):
		DOCTRINA.ACCION_TEMPORIZADA:
			_doctrina_activa = String(plan["doctrina_activa"])
			_doctrina_tiempo = float(plan["doctrina_tiempo"])
		DOCTRINA.ACCION_MESA:
			_aplicar_mesa_dialogo()
		DOCTRINA.ACCION_COMISION:
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
	var estado := (
		DOCTRINA
		. plan_comision(
			_ataque_rival_pendiente,
			_telegrafo_rival,
			_telegrafo_rival_total,
			_ritual,
		)
	)
	_comision_pendiente = bool(estado["comision_pendiente"])
	_doctrina_activa = String(estado["doctrina_activa"])
	_doctrina_tiempo = float(estado["doctrina_tiempo"])
	_telegrafo_rival = float(estado["telegrafo_restante"])
	_telegrafo_rival_total = float(estado["telegrafo_total"])


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

	var paso := (
		RIVAL
		. plan_movimiento(
			_jugador.position,
			_rival.position,
			_recarga_rival,
			_velocidad_rival,
			_enredo,
			_ritual,
			delta,
		)
	)
	if bool(paso["mover"]):
		var desplazamiento: Vector3 = paso["desplazamiento"]
		_rival.position = _limitar(_rival.position + desplazamiento)
		_rival.rotation.y = float(paso["rotacion_y"])
	elif bool(paso["iniciar_ataque"]):
		_iniciar_ataque_rival()


func _iniciar_ataque_rival() -> void:
	if _ataque_rival_pendiente or _acabado:
		return
	_ataque_rival_pendiente = true
	_rival_inicio_agresion = true
	var usar_comision := _comision_pendiente
	var telegrafo := RIVAL.iniciar_telegrafo(usar_comision, _ritual)
	_telegrafo_rival_total = float(telegrafo["total"])
	_telegrafo_rival = float(telegrafo["restante"])
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
	_actualizar_hud()


func _actualizar_telegrafo_rival(delta: float) -> void:
	var estado := RIVAL.avanzar_telegrafo(_telegrafo_rival, _telegrafo_rival_total, delta)
	_telegrafo_rival = float(estado["restante"])
	if _aviso_ataque != null:
		_aviso_ataque.position = _rival.position + Vector3(0.0, 0.02, 0.0)
		if not reduccion_movimiento:
			var escala := lerpf(0.72, 1.0, float(estado["progreso"]))
			_aviso_ataque.scale = Vector3(escala, 1.0, escala)
	if bool(estado["resolver"]):
		_resolver_ataque_rival()


func _resolver_ataque_rival() -> void:
	_ataque_rival_pendiente = false
	_ocultar_aviso_ataque()

	var comision_activa := _doctrina_activa == "socialdemocrata"
	var externaliza_activa := _doctrina_activa == "neoliberal"
	var hacia := _jugador.position - _rival.position
	hacia.y = 0.0
	var resolucion := RIVAL.resolver_ataque(hacia.length(), _esquiva)
	_recarga_rival = float(resolucion["recarga"])
	match String(resolucion["resultado"]):
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
				JUNGIANO.registrar_dano_recibido(self)
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
	var estado := RIVAL.cancelar_telegrafo(_recarga_rival)
	_telegrafo_rival = float(estado["restante"])
	_telegrafo_rival_total = float(estado["total"])
	_recarga_rival = float(estado["recarga"])
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
	if not compromiso_religion_bloqueante(_compromisos_religion, _rival_inicio_agresion).is_empty():
		return
	_recarga_jugador = recarga
	var hacia := _rival.position - _jugador.position
	hacia.y = 0.0
	if hacia.length() > 0.01:
		_jugador.rotation.y = atan2(hacia.x, hacia.z)
	if hacia.length() > alcance:
		return

	var efectos_jungianos := JUNGIANO.efectos_activos(self)
	var probabilidad_critico := JUNGIANO.probabilidad_critico(efectos_jungianos)
	var es_critico := probabilidad_critico > 0.0 and _azar.randf() < probabilidad_critico
	JUNGIANO.registrar_golpe(self, es_critico, fuerte)

	if es_critico:
		_mostrar_aviso_jungiano("CRÍTICO", 0.65)
	var impacto := (
		JUGADOR
		. resolver_impacto(
			dano_base,
			_dano_combo_pendiente,
			es_critico,
			fuerte,
			_ritual,
			_ataque_rival_pendiente,
			_doctrina_activa,
			_contraataque,
		)
	)
	_dano_combo_pendiente = 0
	if bool(impacto["interrumpir_rival"]):
		_cancelar_ataque_rival()
	if bool(impacto["cerrar_doctrina"]):
		_cerrar_doctrina()
	if bool(impacto["consumir_contraataque"]):
		_contraataque = 0

	var dano := int(impacto["dano"])
	_determinacion_rival = maxi(0, _determinacion_rival - dano)
	_aplicar_curacion_arquetipo(efectos_jungianos)
	var segundos_enredo := float(impacto["enredo_segundos"])
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
	var efectos := JUNGIANO.efectos_activos(self)
	_esquiva = JUGADOR.duracion_esquiva(JUNGIANO.bonus_evasion(efectos))
	JUNGIANO.registrar_esquiva(self)
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
	JUNGIANO.salir_combate(self)
	_ocultar_aviso_ataque()
	terminado.emit(gano)


func _limitar(posicion: Vector3) -> Vector3:
	var plano := Vector2(posicion.x, posicion.z)
	if plano.length() > _radio_arena:
		plano = plano.normalized() * _radio_arena
	return Vector3(plano.x, 0.0, plano.y)


func _resolver_capa_simbolica() -> void:
	var capa := (
		SIMBOLICO
		. resolver(
			self,
			_acusado,
			RADIO_ARENA,
			VELOCIDAD_RIVAL,
			RECARGA_FUERTE,
		)
	)
	if capa.is_empty():
		return
	_cargas_doctrina = capa["cargas_doctrina"]
	_arcano = capa["arcano"]
	_mito_id = String(capa["mito_id"])
	_ritual = capa["ritual"]
	_radio_arena = float(capa["radio_arena"])
	_velocidad_rival = float(capa["velocidad_rival"])
	_recarga_fuerte = float(capa["recarga_fuerte"])
	_compromisos_religion = capa.get("compromisos_religion", [])


func _aplicar_configuracion_ritual() -> void:
	var configuracion := (
		SIMBOLICO
		. configuracion_ritual(
			_ritual,
			RADIO_ARENA,
			VELOCIDAD_RIVAL,
			RECARGA_FUERTE,
		)
	)
	_radio_arena = float(configuracion["radio_arena"])
	_velocidad_rival = float(configuracion["velocidad_rival"])
	_recarga_fuerte = float(configuracion["recarga_fuerte"])


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
	if not (
		HUD
		. actualizar_determinacion(
			_barra_jugador,
			_barra_rival,
			_etiqueta_ritual,
			_determinacion_jugador,
			_determinacion_rival,
			_texto_ritual(),
		)
	):
		return
	_actualizar_hud_jungiano()


func _texto_ritual() -> String:
	var eje_estado := DOCTRINA.eje_estado(_doctrina_activa, _comision_pendiente)
	var nombre_doctrina := ""
	if not eje_estado.is_empty():
		var habilidad: Dictionary = Historias.HABILIDADES[eje_estado]
		nombre_doctrina = tr(String(habilidad["nombre"]))
	var compromiso_activo := not (
		compromiso_religion_bloqueante(_compromisos_religion, _rival_inicio_agresion).is_empty()
	)
	return (
		HUD
		. texto_ritual(
			_ritual,
			_contraataque,
			nombre_doctrina,
			compromiso_activo,
			tr("JUICIO_RELIGION_COMPROMISO"),
		)
	)


func _hay_cargas_doctrina() -> bool:
	return SIMBOLICO.hay_cargas_doctrina(_cargas_doctrina)


func _pintar_doctrinas() -> void:
	(
		HUD
		. pintar_doctrinas(
			_botones_doctrina,
			_cargas_doctrina,
			DOCTRINA.bloqueada(_doctrina_activa, _comision_pendiente),
			Prometeo.EJES,
			Historias.HABILIDADES,
			Callable(self, "tr"),
			Callable(self, "activar_doctrina"),
		)
	)


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
	return JUNGIANO.gestor(self, nombre)


func _preparar_sistemas_jungianos() -> void:
	(
		JUNGIANO
		. preparar(
			self,
			Callable(self, "_al_arquetipo_desbloqueado"),
			Callable(self, "_al_momentum_cambiado"),
			Callable(self, "_al_combo_ejecutado"),
			Callable(self, "_al_finisher_ejecutado"),
		)
	)


func _al_arquetipo_desbloqueado(arquetipo_id: String) -> void:
	JUNGIANO.aplicar_arquetipo(self, arquetipo_id)
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
	var estado := (
		JUNGIANO
		. aplicar_combo(
			_dano_combo_pendiente,
			_determinacion_jugador,
			_contraataque,
			_esquiva,
			efectos,
			DETERMINACION_BASE,
		)
	)
	_dano_combo_pendiente = int(estado["dano_combo_pendiente"])
	_determinacion_jugador = int(estado["determinacion_jugador"])
	_contraataque = int(estado["contraataque"])
	_esquiva = float(estado["esquiva"])
	var radio := float(efectos.get("area", 1.2))
	_particulas_jungianas(radio, false)
	Sonido.sonar(self, "pulsar")
	_mostrar_aviso_jungiano("COMBO · %s" % nombre, 1.2)


func _ejecutar_finisher_jungiano() -> void:
	JUNGIANO.ejecutar_finisher_disponible(self)


func _al_finisher_ejecutado(nombre: String, efectos: Dictionary, es_super: bool) -> void:
	var estado := (
		JUNGIANO
		. aplicar_finisher(
			_determinacion_rival,
			_determinacion_jugador,
			_invulnerabilidad_jungiana,
			efectos,
			es_super,
			DETERMINACION_BASE,
		)
	)
	_determinacion_rival = int(estado["determinacion_rival"])
	_determinacion_jugador = int(estado["determinacion_jugador"])
	_invulnerabilidad_jungiana = float(estado["invulnerabilidad"])
	_sacudida_camara = float(estado["sacudida_camara"])
	_particulas_jungianas(float(efectos.get("area", 2.4)), es_super)
	_reaccion(_figura_rival, 0.62 if es_super else 0.42)
	Sonido.sonar(self, "marcar")
	_mostrar_aviso_jungiano(("SUPER FINISHER · " if es_super else "FINISHER · ") + nombre, 1.8)
	_actualizar_hud()
	if _determinacion_rival <= 0 and not _intentar_retorno_rival():
		_terminar(true)


func _aplicar_curacion_arquetipo(efectos: Dictionary) -> void:
	var estado := (
		JUNGIANO
		. aplicar_curacion_arquetipo(
			_determinacion_jugador,
			_curacion_arquetipo_acumulada,
			efectos,
			DETERMINACION_BASE,
		)
	)
	_determinacion_jugador = int(estado["determinacion_jugador"])
	_curacion_arquetipo_acumulada = float(estado["acumulada"])


func _actualizar_hud_jungiano() -> void:
	(
		HUD
		. actualizar_jungiano(
			_barra_momentum,
			_boton_finisher,
			JUNGIANO.estado_hud(self),
			_acabado,
			tr("JUICIO_JUNGIANO_FINISHER"),
			tr("JUICIO_JUNGIANO_SUPER_FINISHER"),
		)
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
