## Prueba headless de la progresión determinista enlace13 -> incoherencia (#539).
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var estado := ContaminacionOs98.nuevo()
	var partida := {"veredictos": {}}
	var contexto := ContaminacionOs98.contexto(partida, estado, 1)

	_comprobar(
		not ContaminacionOs98.memorandum_disponible(partida),
		"antes de cinco cierres el memorándum sigue oculto",
	)
	_comprobar(not contexto["habilitar_enlace13"], "la superficie restringida no se anuncia antes")
	_comprobar(contexto["credenciales"].is_empty(), "una partida nueva no conoce credenciales")
	_comprobar(
		not ContaminacionOs98.registrar_documento(
			partida, estado, ContaminacionOs98.MEMORANDUM_ID
		),
		"no se puede adelantar enlace13 abriendo un id antes del hito",
	)

	for i in range(5):
		partida["veredictos"]["caso_%d" % i] = "firma"
	contexto = ContaminacionOs98.contexto(partida, estado, 2)
	_comprobar(contexto["memorandum_disponible"], "cinco cierres hacen visible el memorándum")
	_comprobar(contexto["habilitar_enlace13"], "la carpeta restringida pasa a ser visible")
	_comprobar(
		contexto["credenciales"].is_empty(),
		"ver el hito no concede la credencial sin leer el memorándum",
	)

	_comprobar(
		ContaminacionOs98.registrar_documento(partida, estado, ContaminacionOs98.MEMORANDUM_ID),
		"leer el memorándum concede enlace13",
	)
	contexto = ContaminacionOs98.contexto(partida, estado, 2)
	_comprobar(contexto["credenciales"].has("enlace13"), "Explorador recibe la credencial")
	_comprobar(contexto["conocimiento"].has("enlace13"), "Web98 recibe el mismo conocimiento")
	_comprobar(
		contexto["fase_contaminacion"] == ContaminacionOs98.FASE_ACCESO_PRIVILEGIADO,
		"la lectura entra en fase de acceso privilegiado",
	)
	_comprobar(
		not ContaminacionOs98.registrar_documento(partida, estado, ContaminacionOs98.MEMORANDUM_ID),
		"releer el memorándum es idempotente",
	)

	_comprobar(
		ContaminacionOs98.registrar_ruta(estado, ContaminacionOs98.RUTA_RESTRINGIDA),
		"el primer acceso restringido queda registrado",
	)
	_comprobar(
		not ContaminacionOs98.registrar_ruta(estado, ContaminacionOs98.RUTA_RESTRINGIDA),
		"repetir la ruta no duplica el hito",
	)

	_comprobar(
		ContaminacionOs98.registrar_documento(partida, estado, ContaminacionOs98.DIAGNOSTICO_ID),
		"leer el diagnóstico activa la primera incoherencia",
	)
	contexto = ContaminacionOs98.contexto(partida, estado, 2)
	_comprobar(
		contexto["fase_contaminacion"] == ContaminacionOs98.FASE_INCOHERENCIAS,
		"el estado avanza de forma determinista a fase 2",
	)
	_comprobar(
		contexto["conocimiento"].has(ContaminacionOs98.CONOCIMIENTO_INCOHERENCIA),
		"Web98 recibe la llave de la caché imposible solo en fase 2",
	)

	var otra_vuelta := ContaminacionOs98.nuevo()
	var contexto_nuevo := ContaminacionOs98.contexto(partida, otra_vuelta, 1)
	_comprobar(
		contexto_nuevo["credenciales"].is_empty()
		and contexto_nuevo["fase_contaminacion"] == ContaminacionOs98.FASE_NORMALIDAD,
		"un estado de vuelta nuevo no hereda contaminación",
	)

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
