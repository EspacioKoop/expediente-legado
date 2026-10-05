## Receta declarativa de feedback de impacto (#2473).
class_name JuicioCombateImpactoFeedback
extends RefCounted

const LIGERO := "ligero"
const FUERTE := "fuerte"
const FINISHER := "finisher"
const STAGGER := "stagger"
const BLOQUEADO := "bloqueado"

const HITSTOP_MAX := 0.10
const SHAKE_MAX := 1.0
const REACCION_MAX := 0.45


static func receta(tipo: String, reduccion_movimiento: bool = false) -> Dictionary:
	var salida := _base(tipo)
	if reduccion_movimiento:
		salida["shake"] = 0.0
		salida["desplazamiento_reaccion"] = 0.0
		salida["flash"] = false
		salida["senal_estatica"] = true
	return _capar(salida)


static func _base(tipo: String) -> Dictionary:
	match tipo:
		LIGERO:
			return _crear(0.025, 0.20, 0.10, 8, true)
		FUERTE:
			return _crear(0.050, 0.45, 0.22, 16, true)
		FINISHER:
			return _crear(0.085, 0.85, 0.40, 28, true)
		STAGGER:
			return _crear(0.060, 0.55, 0.28, 20, true)
		BLOQUEADO:
			return _crear(0.018, 0.16, 0.0, 5, false)
		_:
			return _crear(0.0, 0.0, 0.0, 0, false)


static func _crear(
	hitstop: float,
	shake: float,
	reaccion: float,
	particulas: int,
	flash: bool,
) -> Dictionary:
	return {
		"hitstop": hitstop,
		"shake": shake,
		"desplazamiento_reaccion": reaccion,
		"particulas": particulas,
		"flash": flash,
		"senal_estatica": false,
	}


static func _capar(valor: Dictionary) -> Dictionary:
	return {
		"hitstop": clampf(float(valor.get("hitstop", 0.0)), 0.0, HITSTOP_MAX),
		"shake": clampf(float(valor.get("shake", 0.0)), 0.0, SHAKE_MAX),
		"desplazamiento_reaccion": clampf(
			float(valor.get("desplazamiento_reaccion", 0.0)),
			0.0,
			REACCION_MAX,
		),
		"particulas": maxi(0, int(valor.get("particulas", 0))),
		"flash": bool(valor.get("flash", false)),
		"senal_estatica": bool(valor.get("senal_estatica", false)),
	}
