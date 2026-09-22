class_name PruebasJuicioSimbolico
extends RefCounted


static func todo(comprobar: Callable) -> void:
	var base := JuicioCombateSimbolico.configuracion_ritual({}, 5.0, 2.5, 0.58)
	_caso(comprobar, "simbólico: conserva radio base", base["radio_arena"], 5.0)
	_caso(comprobar, "simbólico: conserva velocidad base", base["velocidad_rival"], 2.5)
	_caso(comprobar, "simbólico: conserva recarga base", base["recarga_fuerte"], 0.58)

	var ritual := {
		"radio_arena": 4.0,
		"velocidad_rival_mul": 0.8,
		"recarga_fuerte": 0.72,
	}
	var modificada := JuicioCombateSimbolico.configuracion_ritual(ritual, 5.0, 2.5, 0.58)
	_caso(comprobar, "simbólico: ritual cambia radio", modificada["radio_arena"], 4.0)
	_caso(comprobar, "simbólico: ritual escala velocidad", modificada["velocidad_rival"], 2.0)
	_caso(comprobar, "simbólico: ritual cambia recarga", modificada["recarga_fuerte"], 0.72)
	_caso(
		comprobar,
		"simbólico: prioriza id del acusado",
		JuicioCombateSimbolico.clave_acusado({"id": "x", "nombre": "Nombre"}),
		"x",
	)
	_caso(
		comprobar,
		"simbólico: usa nombre si falta id",
		JuicioCombateSimbolico.clave_acusado({"nombre": "Nombre"}),
		"Nombre",
	)


static func _caso(comprobar: Callable, nombre: String, obtenido, esperado) -> void:
	comprobar.call(nombre, obtenido, esperado)
