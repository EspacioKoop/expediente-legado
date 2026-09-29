extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	_probar_base_sin_eventos()
	_probar_exposicion_del_cunado()
	_probar_practica_de_correspondencia()
	_probar_frontera_de_conocimiento()
	_probar_conviccion_explicita_conocida()
	_probar_vuelta_actual()
	print("dialogo_religion_933: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _estado(vuelta: int = 1) -> Dictionary:
	return {"jornada": {"vuelta": vuelta}, ReligionEventos.CLAVE_ESTADO: ReligionEventos.nuevo()}


func _registrar(
	estado: Dictionary,
	id_evento: String,
	canal: String,
	vuelta: int,
	publico: bool = false,
	conocido_por: Array = [],
	metadatos: Dictionary = {},
) -> void:
	var registro: Dictionary = estado[ReligionEventos.CLAVE_ESTADO]
	var datos := metadatos.duplicate(true)
	datos["vuelta"] = vuelta
	var evento := (
		ReligionEventos
		. crear_evento(
			id_evento,
			canal,
			"prueba:933",
			"dialogo",
			1,
			"",
			[],
			[],
			publico,
			conocido_por,
			datos,
		)
	)
	ReligionEventos.registrar(registro, evento)


func _probar_base_sin_eventos() -> void:
	var estado := _estado()
	_comprobar(DialogoReligion933.resolver_clave(estado, "cunado"), "", "sin hechos conserva base")
	_comprobar(
		DialogoReligion933.resolver_clave(estado, "correspondencia"),
		"",
		"sin hechos conserva base externa",
	)


func _probar_exposicion_del_cunado() -> void:
	var estado := _estado()
	_registrar(estado, "expo-publica", ReligionEventos.CANAL_EXPOSICION, 1, true)
	_comprobar(
		DialogoReligion933.resolver_clave(estado, "cunado"),
		DialogoReligion933.CLAVE_CUNADO_EXPOSICION,
		"el cuñado reconoce exposición pública",
	)
	_comprobar(
		DialogoReligion933.resolver_clave(estado, "correspondencia"),
		"",
		"la exposición no se convierte en práctica",
	)


func _probar_practica_de_correspondencia() -> void:
	var estado := _estado()
	_registrar(
		estado,
		"practica-compartida",
		ReligionEventos.CANAL_PRACTICA,
		1,
		false,
		["correspondencia"],
	)
	_comprobar(
		DialogoReligion933.resolver_clave(estado, "correspondencia"),
		DialogoReligion933.CLAVE_CORRESPONDENCIA_PRACTICA,
		"correspondencia reacciona a práctica conocida",
	)
	_comprobar(
		DialogoReligion933.resolver_clave(estado, "cunado"),
		"",
		"la práctica no sustituye la exposición del cuñado",
	)


func _probar_frontera_de_conocimiento() -> void:
	var estado := _estado()
	_registrar(
		estado,
		"expo-privada",
		ReligionEventos.CANAL_EXPOSICION,
		1,
		false,
		["correspondencia"],
	)
	_comprobar(
		DialogoReligion933.resolver_clave(estado, "cunado"),
		"",
		"un hecho privado ajeno no se filtra al cuñado",
	)


func _probar_conviccion_explicita_conocida() -> void:
	var estado := _estado()
	_registrar(
		estado,
		"declaracion-publica",
		ReligionEventos.CANAL_CONVICCION,
		1,
		true,
		["cunado", "correspondencia"],
		{"declaracion": ReligionEventos.DECLARACION_DUDA},
	)
	_comprobar(
		DialogoReligion933.resolver_clave(estado, "cunado"),
		DialogoReligion933.CLAVE_CUNADO_CONVICCION,
		"el cuñado reacciona a una declaración explícita conocida",
	)
	_comprobar(
		DialogoReligion933.resolver_clave(estado, "correspondencia"),
		DialogoReligion933.CLAVE_CORRESPONDENCIA_CONVICCION,
		"correspondencia puede reaccionar de forma distinta al mismo hecho",
	)
	_comprobar(
		(
			DialogoReligion933.CLAVE_CUNADO_CONVICCION
			!= DialogoReligion933.CLAVE_CORRESPONDENCIA_CONVICCION
		),
		true,
		"dos NPC no quedan reducidos a una voz única",
	)

	var privada := _estado()
	_registrar(
		privada,
		"declaracion-privada",
		ReligionEventos.CANAL_CONVICCION,
		1,
		false,
		["correspondencia"],
		{"declaracion": ReligionEventos.DECLARACION_AFIRMACION},
	)
	_comprobar(
		DialogoReligion933.resolver_clave(privada, "cunado"),
		"",
		"una declaración privada ajena no se filtra al cuñado",
	)
	_comprobar(
		DialogoReligion933.resolver_clave(privada, "correspondencia"),
		DialogoReligion933.CLAVE_CORRESPONDENCIA_CONVICCION,
		"solo el interlocutor conocedor consume la declaración privada",
	)


func _probar_vuelta_actual() -> void:
	var estado := _estado(2)
	_registrar(estado, "expo-vieja", ReligionEventos.CANAL_EXPOSICION, 1, true)
	_comprobar(
		DialogoReligion933.resolver_clave(estado, "cunado"),
		"",
		"una vida nueva no consume exposición histórica como estado activo",
	)


func _comprobar(actual, esperado, nombre: String) -> void:
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO #933: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
