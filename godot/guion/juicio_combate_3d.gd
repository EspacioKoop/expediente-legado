class_name JuicioCombate3D
extends Node3D

signal terminado(gano: bool)

## Lo más que se sostiene el gesto final antes de cerrar el Juicio.
const PAUSA_FINAL_MAX := 2.5

const REGLAS = preload("res://guion/juicio_combate_reglas.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")
const HUD = preload("res://guion/juicio_combate_hud.gd")
const ARENA = preload("res://guion/juicio_combate_arena_3d.gd")
const JUNGIANO = preload("res://guion/juicio_combate_jungiano.gd")
const SIMBOLICO = preload("res://guion/juicio_combate_simbolico.gd")
const RIVAL = preload("res://guion/juicio_combate_rival.gd")
const DOCTRINA = preload("res://guion/juicio_combate_doctrina.gd")
const JUGADOR = preload("res://guion/juicio_combate_jugador.gd")
const ESTADO_TEMPORAL = preload("res://guion/juicio_combate_estado_temporal.gd")
const AMBIENTAL_1772 = preload("res://guion/juicio_combate_ambiental_1772.gd")
const EMPUJAR_1772 = preload("res://guion/juicio_combate_ambiental_empujar_1772.gd")
const VOLCAR_1772 = preload("res://guion/juicio_combate_ambiental_volcar_1772.gd")
const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const ARQUETIPO_HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")
const HOSTIGADOR_3D = preload("res://guion/juicio_combate_hostigador_3d.gd")
const BLOQUEADOR_3D = preload("res://guion/juicio_combate_bloqueador_3d.gd")
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

## La ficha del jugador, para que pelee con su cuerpo. Vacía: el de serie.
var perfil_jugador: Dictionary = {}
var reduccion_movimiento := false
## Opt-in explícito: solo los hosts de combate contextual lo activan.
var interaccion_ambiental_habilitada := false
## Arquetipo onírico (#1771) que ya eligió el host contextual. Vacío, o uno
## que este duelo no sabe representar, deja el rival clásico.
var arquetipo_onirico := ""

var _ambiental_1772: Dictionary = {}
var _empujar_1772: Dictionary = {}
var _volcar_1772: Dictionary = {}
var _arquetipo: Dictionary = {}
var _guardia_rota := false
var _escudo_guardia: MeshInstance3D
var _linea_hostigador: MeshInstance3D
var _raiz := 0

var _acusado: Dictionary = {}
var _bono_documental := 0
var _determinacion_jugador := DETERMINACION_BASE
var _determinacion_rival := DETERMINACION_BASE
var _acabado := false
var _estado_temporal := ESTADO_TEMPORAL.new()
var _recarga_jugador: float:
	get:
		return _estado_temporal.recarga_jugador
	set(valor):
		_estado_temporal.recarga_jugador = valor
var _esquiva: float:
	get:
		return _estado_temporal.esquiva
	set(valor):
		_estado_temporal.esquiva = valor
var _enredo: float:
	get:
		return _estado_temporal.enredo
	set(valor):
		_estado_temporal.enredo = valor
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
var _comision_pendiente := false
var _compromisos_religion: Array = []
var _rival_inicio_agresion := false
var _tregua_religion_restante := 0.0

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
	_raiz = raiz
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
	_montar_arquetipo()
	if interaccion_ambiental_habilitada:
		_ambiental_1772 = AMBIENTAL_1772.montar(self)
		_empujar_1772 = EMPUJAR_1772.montar(self)
		_volcar_1772 = VOLCAR_1772.montar(self)
	_montar_hud()
	_actualizar_hud()


func _process(delta: float) -> void:
	if _acabado:
		return
	_descontar_temporizadores(delta)
	_descontar_tregua_religion(delta)
	_avanzar_ambiental_1772(delta)
	_mover_jugador(delta)
	_avanzar_arquetipo(delta)
	_mover_rival(delta)
	_actualizar_camara()

	# Acción secundaria semántica y remapeable. Fuera de este host, inventario
	# conserva su significado normal; aquí no sustituye a ningún ataque.
	if interaccion_ambiental_habilitada and Input.is_action_just_pressed("inventario"):
		usar_entorno_ambiental_1772()
	if Input.is_action_just_pressed("interactuar"):
		_atacar(1, ALCANCE_LIGERO, RECARGA_LIGERA, false)
	if Input.is_action_just_pressed("saltar"):
		_atacar(2, ALCANCE_FUERTE, _recarga_fuerte, true)
	if Input.is_action_just_pressed("agacharse"):
		_esquivar()


## Avanza los runtimes ambientales temporales desde el mismo tick.
func _avanzar_ambiental_1772(delta: float) -> void:
	if not _empujar_1772.is_empty():
		EMPUJAR_1772.avanzar(_empujar_1772, delta)
	if not _volcar_1772.is_empty():
		VOLCAR_1772.avanzar(_volcar_1772, delta)


## Prioridad determinista: ACTIVAR → EMPUJAR → VOLCAR.
func usar_entorno_ambiental_1772() -> bool:
	if not interaccion_ambiental_habilitada or _acabado:
		return false
	if _jugador == null or not is_instance_valid(_jugador):
		return false
	var posicion := _jugador.global_position
	var resultado := {}
	var continuar := true
	if not _ambiental_1772.is_empty():
		resultado = AMBIENTAL_1772.activar(_ambiental_1772, posicion, true)
		continuar = (
			not bool(resultado.get("ok", false))
			and String(resultado.get("motivo", "")) in ["fuera_de_alcance", "ya_activado"]
		)
	if continuar and not _empujar_1772.is_empty():
		resultado = EMPUJAR_1772.empujar(_empujar_1772, posicion, true)
		continuar = (
			not bool(resultado.get("ok", false))
			and (
				String(resultado.get("motivo", ""))
				in ["fuera_de_alcance", "sin_usos", "en_recarga"]
			)
		)
	if continuar and not _volcar_1772.is_empty():
		resultado = VOLCAR_1772.volcar(_volcar_1772, posicion, true)
	return bool(resultado.get("ok", false))


func estado_entorno_ambiental_1772() -> Dictionary:
	if _ambiental_1772.is_empty():
		return {}
	var estado: Variant = _ambiental_1772.get("estado", {})
	return (estado as Dictionary).duplicate(true) if estado is Dictionary else {}


## Los campos siguen siendo propios del nodo porque pruebas y
## `JuicioFeedbackRitual` los leen por nombre; aquí solo se aplican los
## cierres que la regla pura declara expirados.
func _descontar_temporizadores(delta: float) -> void:
	var expirados := _estado_temporal.descontar(delta)
	if expirados.has("aviso_jungiano") and _etiqueta_jungiana != null:
		_etiqueta_jungiana.visible = false
	if expirados.has("doctrina"):
		_cerrar_doctrina()


func _descontar_tregua_religion(delta: float) -> void:
	if _tregua_religion_restante <= 0.0:
		return
	var anterior := _tregua_religion_restante
	_tregua_religion_restante = maxf(0.0, _tregua_religion_restante - delta)
	if anterior > 0.0 and _tregua_religion_restante <= 0.0:
		_actualizar_hud()


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
			_estado_temporal.doctrina = float(plan["doctrina_tiempo"])
		DOCTRINA.ACCION_MESA:
			_aplicar_mesa_dialogo()
		DOCTRINA.ACCION_COMISION:
			_activar_comision()

	Sonido.sonar(self, "marcar")
	_actualizar_hud()
	_pintar_doctrinas()
	return true


func abandonar() -> void:
	# Quien se va no espera a ver el gesto.
	_terminar(false, true)


func _aplicar_mesa_dialogo() -> void:
	if _ataque_rival_pendiente:
		_cancelar_ataque_rival()
	_estado_temporal.recarga_rival = maxf(_estado_temporal.recarga_rival, recarga_mesa(_ritual))
	if _jugador == null or _rival == null:
		return
	var destino := RIVAL.posicion_mesa(_jugador.position, _rival.position, DISTANCIA_MESA)
	_rival.position = _limitar(destino)


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
	_estado_temporal.doctrina = float(estado["doctrina_tiempo"])
	_telegrafo_rival = float(estado["telegrafo_restante"])
	_telegrafo_rival_total = float(estado["telegrafo_total"])


func _cerrar_doctrina() -> void:
	if _doctrina_activa.is_empty():
		return
	_doctrina_activa = ""
	_estado_temporal.doctrina = 0.0
	_actualizar_hud()
	_pintar_doctrinas()


func _mover_jugador(delta: float) -> void:
	var entrada := Vector2(
		Input.get_axis("mover_izquierda", "mover_derecha"),
		Input.get_axis("mover_adelante", "mover_atras")
	)
	var paso := JUGADOR.plan_movimiento(
		_jugador.position, entrada, VELOCIDAD_JUGADOR, _esquiva > 0.0, _radio_arena, delta
	)
	_jugador.position = paso["posicion"]
	JuicioCombateEscenografia3D.andar(_figura_jugador, entrada.length() > 0.1)
	if bool(paso["orientar"]):
		_jugador.rotation.y = float(paso["rotacion_y"])


func _mover_rival(delta: float) -> void:
	if _ataque_rival_pendiente:
		_actualizar_telegrafo_rival(delta)
		return
	if String(_arquetipo.get("tipo", "")) == ARQUETIPOS.HOSTIGADOR:
		var host := HOSTIGADOR_3D.mover(
			_jugador.position, _rival.position, _rival.rotation.y, _arquetipo, _radio_arena, delta
		)
		_rival.position = host["posicion"]
		_rival.rotation.y = float(host["rotacion_y"])
		JuicioCombateEscenografia3D.andar(_figura_rival, bool(host["andando"]))
		return
	# La apertura del bloqueador es la ventana del jugador: quieto y sin atacar,
	# para que se lea sin texto que ahora se le puede golpear.
	if not ARQUETIPO_HOST.permite_iniciar_ataque(_arquetipo):
		JuicioCombateEscenografia3D.andar(_figura_rival, false)
		return

	var paso := (
		RIVAL
		. plan_movimiento(
			_jugador.position,
			_rival.position,
			_estado_temporal.recarga_rival,
			_velocidad_rival,
			_enredo,
			_ritual,
			delta,
		)
	)
	JuicioCombateEscenografia3D.andar(_figura_rival, bool(paso["mover"]))
	if bool(paso["mover"]):
		var desplazamiento: Vector3 = paso["desplazamiento"]
		_rival.position = _limitar(_rival.position + desplazamiento)
		# Con arquetipo, la orientación es la guardia y ya la gira la política.
		if _arquetipo.is_empty():
			_rival.rotation.y = float(paso["rotacion_y"])
	elif bool(paso["iniciar_ataque"]):
		_iniciar_ataque_rival()


func _iniciar_ataque_rival() -> void:
	if _ataque_rival_pendiente or _acabado or _tregua_religion_restante > 0.0:
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
		_estado_temporal.doctrina = _telegrafo_rival_total
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

	var hacia := _jugador.position - _rival.position
	hacia.y = 0.0
	var resolucion := RIVAL.resolver_ataque(hacia.length(), _esquiva)
	_estado_temporal.recarga_rival = float(resolucion["recarga"])
	_aplicar_impacto_rival(String(resolucion["resultado"]))


## Punto común para el ataque cuerpo a cuerpo y la línea del hostigador. Así
## esquiva, invulnerabilidad, doctrinas y derrota conservan una sola regla.
func _aplicar_impacto_rival(resultado: String) -> void:
	var efecto := (
		RIVAL
		. resolver_impacto_en_jugador(
			resultado,
			_determinacion_jugador,
			_estado_temporal.invulnerabilidad_jungiana,
			_doctrina_activa,
		)
	)
	match String(efecto["desenlace"]):
		"esquiva":
			Sonido.sonar(self, "pulsar")
			_registrar_esquiva_ritual()
		"negado":
			Sonido.sonar(self, "pulsar")
			JuicioCombateEscenografia3D.gesto(_figura_jugador, "negar")
			_mostrar_aviso_jungiano("SELF · IMPACTO NEGADO", 0.8)
		"impacto":
			Sonido.sonar(self, "error")
			_determinacion_jugador = int(efecto["determinacion_jugador"])
			JUNGIANO.registrar_dano_recibido(self)
			if bool(efecto["cerrar_externalizar"]):
				_cerrar_doctrina()
			_reaccion(_figura_jugador, -0.18)
			JuicioCombateEscenografia3D.gesto(_figura_jugador, "encajar")
			_actualizar_hud()
			if bool(efecto["derrota"]):
				_terminar(false)

	if bool(efecto["cerrar_comision"]):
		_cerrar_doctrina()


func _cancelar_ataque_rival() -> void:
	_ataque_rival_pendiente = false
	var estado := RIVAL.cancelar_telegrafo(_estado_temporal.recarga_rival)
	_telegrafo_rival = float(estado["restante"])
	_telegrafo_rival_total = float(estado["total"])
	_estado_temporal.recarga_rival = float(estado["recarga"])
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
	if _recarga_jugador > 0.0 or _tregua_religion_restante > 0.0:
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
	if _bloquear_golpe(fuerte):
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
	JuicioCombateEscenografia3D.gesto(_figura_jugador, "discutir")
	JuicioCombateEscenografia3D.gesto(_figura_rival, "encajar")
	_actualizar_hud()
	if _determinacion_rival <= 0 and not _intentar_retorno_rival():
		_terminar(true)


func _intentar_retorno_rival() -> bool:
	var plan := RIVAL.retorno(_ritual, _retornos_rival)
	if not bool(plan["acepta"]):
		return false
	_retornos_rival = int(plan["retornos"])
	_determinacion_rival = int(plan["determinacion"])
	_estado_temporal.recarga_rival = float(plan["recarga"])
	_reaccion(_figura_rival, -0.30)
	JuicioCombateEscenografia3D.gesto(_figura_rival, "enfadado")
	Sonido.sonar(self, "marcar")
	_actualizar_hud()
	return true


func _montar_arquetipo() -> void:
	if not ARQUETIPO_HOST.soportado(arquetipo_onirico) or _rival == null:
		return
	_arquetipo = ARQUETIPOS.nuevo(arquetipo_onirico, _raiz)
	if arquetipo_onirico == ARQUETIPOS.BLOQUEADOR:
		_escudo_guardia = BLOQUEADOR_3D.montar_guardia(_rival)
		_pintar_guardia()
	elif arquetipo_onirico == ARQUETIPOS.HOSTIGADOR:
		_linea_hostigador = HOSTIGADOR_3D.montar_linea(self)


func _avanzar_arquetipo(delta: float) -> void:
	if _arquetipo.is_empty():
		return
	if String(_arquetipo.get("tipo", "")) == ARQUETIPOS.HOSTIGADOR:
		var host := HOSTIGADOR_3D.avanzar(_arquetipo, delta, _rival.position, _jugador.position)
		_arquetipo = host["unidad"]
		if bool(host["fijar_rumbo"]):
			_rival.rotation.y = float(_arquetipo.get("rumbo_bloqueado", _rival.rotation.y))
		if bool(host["inicio_agresion"]):
			_rival_inicio_agresion = true
			Sonido.sonar(self, "marcar")
		if bool(host["disparar"]):
			_aplicar_impacto_rival(
				HOSTIGADOR_3D.resultado_disparo(
					_rival.position, _arquetipo, _jugador.position, _esquiva
				)
			)
		if bool(host["abrir_ventana"]):
			JuicioCombateEscenografia3D.gesto(_figura_rival, "encajar")
		HOSTIGADOR_3D.pintar_linea(
			_linea_hostigador, _rival.position, _arquetipo, String(host["telegraph"])
		)
		return
	var contexto := ARQUETIPO_HOST.contexto(
		_rival.position, _rival.rotation.y, _jugador.position, _guardia_rota
	)
	_guardia_rota = false
	_arquetipo = ARQUETIPOS.avanzar(_arquetipo, delta, contexto)["unidad"]
	_rival.rotation.y = ARQUETIPO_HOST.girar(
		_arquetipo, _rival.rotation.y, _rival.position, _jugador.position, delta
	)
	_pintar_guardia()


func _bloquear_golpe(fuerte: bool) -> bool:
	if _arquetipo.is_empty():
		return false
	var flanco := ARQUETIPO_HOST.flanqueado(_rival.position, _rival.rotation.y, _jugador.position)
	var guardia := ARQUETIPO_HOST.golpe(_arquetipo, flanco, fuerte)
	if not bool(guardia["bloqueado"]):
		return false
	var rompe := bool(guardia["rompe_guardia"])
	_guardia_rota = _guardia_rota or rompe
	Sonido.sonar(self, "marcar" if rompe else "pulsar")
	JuicioCombateEscenografia3D.gesto(_figura_rival, "encajar" if rompe else "negar")
	_reaccion(_figura_rival, 0.20 if rompe else 0.06)
	return true


func _pintar_guardia() -> void:
	if _escudo_guardia == null:
		return
	_escudo_guardia.visible = String(_arquetipo.get("estado", "")) == ARQUETIPOS.GUARDIA


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
	var plan := JUGADOR.contraataque_tras_esquiva(_ritual, _contraataque)
	if not bool(plan["aplica"]):
		return
	_contraataque = int(plan["contraataque"])
	_reaccion(_figura_rival, 0.10)
	_actualizar_hud()


func _terminar(gano: bool, inmediato: bool = false) -> void:
	if _acabado:
		return
	_acabado = true
	_ataque_rival_pendiente = false
	JUNGIANO.salir_combate(self)
	_ocultar_aviso_ataque()
	var espera := maxf(
		JuicioCombateEscenografia3D.gesto(_figura_jugador, "celebrar" if gano else "nervioso"),
		JuicioCombateEscenografia3D.gesto(_figura_rival, "nervioso" if gano else "aplaudir"),
	)
	# El gesto final se ve antes de cerrar: quien escucha `terminado` libera la
	# escena en ese mismo fotograma (VentanillaApp). El resultado ya es firme
	# (`_acabado`), así que la espera no admite más golpes.
	espera = minf(espera, PAUSA_FINAL_MAX)
	if not inmediato and espera > 0.0 and is_inside_tree():
		await get_tree().create_timer(espera).timeout
	terminado.emit(gano)


func _limitar(posicion: Vector3) -> Vector3:
	return REGLAS.limitar_a_arena(posicion, _radio_arena)


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
	var tregua := SIMBOLICO.tregua_religion_activa(_compromisos_religion)
	_tregua_religion_restante = maxf(0.0, float(tregua.get("duracion", 0.0)))


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
			perfil_jugador,
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
	var tregua_activa := _tregua_religion_restante > 0.0
	var texto_religion := (
		tr("JUICIO_RELIGION_TREGUA") if tregua_activa else tr("JUICIO_RELIGION_COMPROMISO")
	)
	return (
		HUD
		. texto_ritual(
			_ritual,
			_contraataque,
			nombre_doctrina,
			compromiso_activo or tregua_activa,
			texto_religion,
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
			_estado_temporal.sacudida_camara,
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
			_estado_temporal.invulnerabilidad_jungiana,
			efectos,
			es_super,
			DETERMINACION_BASE,
		)
	)
	_determinacion_rival = int(estado["determinacion_rival"])
	_determinacion_jugador = int(estado["determinacion_jugador"])
	_estado_temporal.invulnerabilidad_jungiana = float(estado["invulnerabilidad"])
	_estado_temporal.sacudida_camara = float(estado["sacudida_camara"])
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
	_estado_temporal.aviso_jungiano = maxf(_estado_temporal.aviso_jungiano, duracion)


func _particulas_jungianas(radio: float, es_super: bool) -> void:
	FEEDBACK.particulas_jungianas(self, _rival, radio, es_super)


func _reaccion(figura: Node3D, desplazamiento: float) -> void:
	FEEDBACK.reaccion(self, figura, desplazamiento, reduccion_movimiento)


func _material(color: Color, emision: bool = false) -> StandardMaterial3D:
	return FEEDBACK.material(color, emision)
