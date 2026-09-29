extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar()


func _probar() -> void:
	var dia_uno := {\n\t\t"dia": 1, "fase": "archivo", "hora_minutos": 9 * 60, "acciones": 4, "dinero": 80\n\t}
	var plan_a := LlamadasInternas.plan(dia_uno)
	var plan_b := LlamadasInternas.plan(dia_uno.duplicate(true))
	_comprobar(plan_a == plan_b, "el plan es determinista")
	_comprobar(plan_a.size() == 2, "un día puede tener dos llamadas")
	_comprobar(LlamadasInternas.plan({"dia": 2}).size() == 1, "otro día tiene una llamada")
	_comprobar(LlamadasInternas.plan({"dia": 3}).size() == 2, "nunca supera dos llamadas")

	var tipos := {}
	for dia in 3:
		for llamada in LlamadasInternas.plan({"dia": dia + 1}):
			tipos[String(llamada["tipo"])] = true
	_comprobar(tipos.size() == 3, "las tres variantes entran en la rotación")

	var jornada := {
		"dia": 3,
		"fase": "archivo",
		"hora_minutos": 9 * 60,
		"acciones": 3,
		"dinero": 55,
		"cerrados_hoy": 0,
	}
	var plan := LlamadasInternas.plan(jornada)
	jornada["hora_minutos"] = int(plan[0]["desde"])
	var siguiente := LlamadasInternas.siguiente(jornada)
	_comprobar(\n\t\tString(siguiente.get("id", "")) == String(plan[0]["id"]), "activa la llamada de su ventana"\n\t)
	_comprobar(LlamadasInternas.iniciar(jornada, siguiente), "la llamada arranca una sola vez")
	_comprobar(not LlamadasInternas.iniciar(jornada, siguiente), "no duplica una llamada activa")
	var resultado := LlamadasInternas.resolver(jornada, siguiente, "atender")
	_comprobar(bool(resultado.get("ok", false)), "atender resuelve")
	_comprobar(String(resultado.get("resultado", "")) == "atendida", "registra decisión ambiental")
	_comprobar(LlamadasInternas.siguiente(jornada).is_empty(), "no repite la misma llamada")

	_comprobar(int(jornada["acciones"]) == 3, "no gasta acciones")
	_comprobar(int(jornada["dinero"]) == 55, "no toca dinero")
	_comprobar(int(jornada["cerrados_hoy"]) == 0, "no altera expedientes")

	var perdida := {
		"dia": 5,
		"fase": "archivo",
		"hora_minutos": 18 * 60,
		"acciones": 2,
	}
	_comprobar(\n\t\tLlamadasInternas.siguiente(perdida).is_empty(), "una ventana pasada no deja objetivo oculto"\n\t)
	var estado: Dictionary = LlamadasInternas.estado(perdida)
	_comprobar(\n\t\tnot (estado["resueltas"] as Dictionary).is_empty(), "las llamadas pasadas quedan ignoradas"\n\t)

	var fuera := {"dia": 3, "fase": "casa", "hora_minutos": int(plan[0]["desde"])}
	_comprobar(LlamadasInternas.siguiente(fuera).is_empty(), "fuera de oficina no suena")

	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO LlamadasInternas1769: " + nombre)
