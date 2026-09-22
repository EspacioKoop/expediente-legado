class_name PruebasJuicioReglas
extends RefCounted


static func todo(comprobar: Callable) -> void:
	_caso(
		comprobar,
		"reglas: expediente reduce determinación rival",
		JuicioCombateReglas.determinacion_rival(3),
		5,
	)
	_caso(
		comprobar,
		"reglas: determinación rival conserva suelo",
		JuicioCombateReglas.determinacion_rival(99),
		4,
	)
	_caso(
		comprobar,
		"reglas: ataque fuera de alcance falla",
		JuicioCombateReglas.resultado_ataque_rival(2.0, 0.0),
		"falla",
	)
	_caso(
		comprobar,
		"reglas: esquiva evita impacto",
		JuicioCombateReglas.resultado_ataque_rival(1.0, 0.1),
		"esquiva",
	)

	var control := {"tags": ["control_espacio"]}
	var neutralizar := {"tags": ["neutralizar"]}
	var telegrafo := {"tags": ["telegraph"]}
	var riesgo := {"tags": ["riesgo"]}
	_caso(
		comprobar,
		"reglas: control de espacio alarga Asamblea",
		(
			JuicioCombateReglas.duracion_doctrina("comunismo", control)
			> JuicioCombateReglas.DURACION_DOCTRINA
		),
		true,
	)
	_caso(
		comprobar,
		"reglas: neutralizar alarga recarga rival",
		JuicioCombateReglas.recarga_mesa(neutralizar) > JuicioCombateReglas.RECARGA_RIVAL,
		true,
	)
	_caso(
		comprobar,
		"reglas: telegraph amplía Comisión",
		(
			JuicioCombateReglas.duracion_telegrafo(true, telegrafo)
			> JuicioCombateReglas.duracion_telegrafo(true, {})
		),
		true,
	)
	_caso(
		comprobar,
		"reglas: riesgo alarga Externalizar",
		(
			JuicioCombateReglas.duracion_doctrina("neoliberal", riesgo)
			> JuicioCombateReglas.DURACION_DOCTRINA
		),
		true,
	)
	_caso(
		comprobar,
		"reglas: Asamblea interrumpe una intención pendiente",
		JuicioCombateReglas.asamblea_interrumpe("comunismo", true),
		true,
	)
	_caso(
		comprobar,
		"reglas: Externalizar duplica daño",
		JuicioCombateReglas.dano_externalizado(2, "neoliberal"),
		4,
	)
	_caso(
		comprobar,
		"reglas: interrupción ritual exige golpe fuerte y ataque pendiente",
		JuicioCombateReglas.interrumpe_ataque(true, true, {"interrumpe_telegrafo_fuerte": true}),
		true,
	)
	_caso(
		comprobar,
		"reglas: retorno ritual respeta su límite",
		JuicioCombateReglas.determinacion_retorno(
			{"retornos_rival": 1, "determinacion_retorno": 2}, 1
		),
		0,
	)
	_caso(
		comprobar,
		"compatibilidad: JuicioCombate3D delega reglas",
		JuicioCombate3D.duracion_doctrina("comunismo", control),
		JuicioCombateReglas.duracion_doctrina("comunismo", control),
	)


static func _caso(comprobar: Callable, nombre: String, obtenido, esperado) -> void:
	comprobar.call(nombre, obtenido, esperado)
