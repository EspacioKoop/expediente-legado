## Regresión headless de postura/stagger (#2462).
extends SceneTree

const POSTURA = preload("res://guion/juicio_combate_postura.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_varios_ligeros()
	_probar_contexto_acelera()
	_probar_unico_evento()
	_probar_antistunlock()
	_probar_fin_stagger()
	_probar_valores_invalidos()
	_probar_determinismo()
	print("combate_postura_2462: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_varios_ligeros() -> void:
	var estado: Dictionary = POSTURA.nuevo()
	for indice in range(3):
		var paso: Dictionary = POSTURA.impactar(estado, 1.0)
		estado = paso["estado"]
		_comprobar(
			not bool(paso["stagger_iniciado"]),
			"ligero %d no cruza umbral antes de tiempo" % indice,
		)

	var cuarto: Dictionary = POSTURA.impactar(estado, 1.0)
	_comprobar(bool(cuarto["stagger_iniciado"]), "cuatro ligeros alcanzan stagger")
	_comprobar(POSTURA.en_stagger(cuarto["estado"]), "stagger queda activo")


func _probar_contexto_acelera() -> void:
	var normal: Dictionary = POSTURA.impactar(POSTURA.nuevo(), 2.0)
	_comprobar(
		not bool(normal["stagger_iniciado"]),
		"fuerte normal no cruza por sí solo el umbral",
	)

	var apertura: Dictionary = POSTURA.impactar(POSTURA.nuevo(), 2.0, 2.0)
	_comprobar(
		bool(apertura["stagger_iniciado"]),
		"apertura contextual duplica presión y alcanza stagger",
	)


func _probar_unico_evento() -> void:
	var estado: Dictionary = POSTURA.impactar(POSTURA.nuevo(), POSTURA.UMBRAL)["estado"]
	var repetido: Dictionary = POSTURA.impactar(estado, POSTURA.UMBRAL)
	_comprobar(
		not bool(repetido["stagger_iniciado"]),
		"golpe durante stagger no vuelve a emitir inicio",
	)


func _probar_antistunlock() -> void:
	var estado: Dictionary = POSTURA.impactar(POSTURA.nuevo(), POSTURA.UMBRAL)["estado"]
	var golpe: Dictionary = POSTURA.impactar(estado, 99.0, 99.0)
	_comprobar(
		is_zero_approx(float(golpe["postura_aplicada"])),
		"durante stagger se ignora presión adicional",
	)
	_comprobar(
		is_equal_approx(
			float(golpe["estado"]["stagger_restante"]),
			float(estado["stagger_restante"]),
		),
		"golpe durante stagger no prolonga la ventana",
	)


func _probar_fin_stagger() -> void:
	var estado: Dictionary = POSTURA.impactar(POSTURA.nuevo(), POSTURA.UMBRAL)["estado"]
	estado = POSTURA.avanzar(estado, POSTURA.STAGGER_SEGUNDOS)
	_comprobar(not POSTURA.en_stagger(estado), "stagger termina al consumir su duración")
	_comprobar(is_zero_approx(float(estado["postura"])), "postura vuelve estable tras stagger")

	var nuevo_golpe: Dictionary = POSTURA.impactar(estado, 1.0)
	_comprobar(
		is_equal_approx(float(nuevo_golpe["estado"]["postura"]), 1.0),
		"tras stagger vuelve a acumular postura normalmente",
	)


func _probar_valores_invalidos() -> void:
	var negativo: Dictionary = POSTURA.impactar(POSTURA.nuevo(), -10.0)
	_comprobar(
		is_zero_approx(float(negativo["estado"]["postura"])),
		"peso negativo no reduce ni altera postura",
	)

	var multiplicador: Dictionary = POSTURA.impactar(POSTURA.nuevo(), 2.0, -3.0)
	_comprobar(
		is_zero_approx(float(multiplicador["estado"]["postura"])),
		"multiplicador negativo se recorta a cero",
	)

	var estado_stagger: Dictionary = POSTURA.impactar(POSTURA.nuevo(), POSTURA.UMBRAL)["estado"]
	var delta_negativo: Dictionary = POSTURA.avanzar(estado_stagger, -1.0)
	_comprobar(
		is_equal_approx(
			float(delta_negativo["stagger_restante"]),
			POSTURA.STAGGER_SEGUNDOS,
		),
		"delta negativo no aumenta ni consume stagger",
	)


func _probar_determinismo() -> void:
	var a: Dictionary = POSTURA.impactar(POSTURA.nuevo(), 1.5, 1.5)
	var b: Dictionary = POSTURA.impactar(POSTURA.nuevo(), 1.5, 1.5)
	_comprobar(a == b, "mismo estado e impacto producen misma salida")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2462 postura: " + mensaje)
