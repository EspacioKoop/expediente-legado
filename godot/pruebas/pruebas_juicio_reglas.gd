class_name PruebasJuicioReglas
extends RefCounted


static func todo(comprobar: Callable) -> void:
	comprobar.call(
		"reglas: expediente reduce determinación rival",
		JuicioCombateReglas.determinacion_rival(3),
		5,
	)
	comprobar.call(
		"reglas: determinación rival conserva suelo",
		JuicioCombateReglas.determinacion_rival(99),
		4,
	)
	comprobar.call(
		"reglas: ataque fuera de alcance falla",
		JuicioCombateReglas.resultado_ataque_rival(2.0, 0.0),
		"falla",
	)
	comprobar.call(
		"reglas: esquiva evita impacto",
		JuicioCombateReglas.resultado_ataque_rival(1.0, 0.1),
		"esquiva",
	)

	var control := {"tags": ["control_espacio"]}
	var neutralizar := {"tags": ["neutralizar"]}
	var telegrafo := {"tags": ["telegraph"]}
	var riesgo := {"tags": ["riesgo"]}
	comprobar.call(
		"reglas: control de espacio alarga Asamblea",
		JuicioCombateReglas.duracion_doctrina("comunismo", control)
			> JuicioCombateReglas.DURACION_DOCTRINA,
		true,
	)
	comprobar.call(
		"reglas: neutralizar alarga recarga rival",
		JuicioCombateReglas.recarga_mesa(neutralizar) > JuicioCombateReglas.RECARGA_RIVAL,
		true,
	)
	comprobar.call(
		"reglas: telegraph amplía Comisión",
		JuicioCombateReglas.duracion_telegrafo(true, telegrafo)
			> JuicioCombateReglas.duracion_telegrafo(true, {}),
		true,
	)
	comprobar.call(
		"reglas: riesgo alarga Externalizar",
		JuicioCombateReglas.duracion_doctrina("neoliberal", riesgo)
			> JuicioCombateReglas.DURACION_DOCTRINA,
		true,
	)
	comprobar.call(
		"reglas: Asamblea interrumpe una intención pendiente",
		JuicioCombateReglas.asamblea_interrumpe("comunismo", true),
		true,
	)
	comprobar.call(
		"reglas: Externalizar duplica daño",
		JuicioCombateReglas.dano_externalizado(2, "neoliberal"),
		4,
	)
	comprobar.call(
		"reglas: interrupción ritual exige golpe fuerte y ataque pendiente",
		JuicioCombateReglas.interrumpe_ataque(
			true, true, {"interrumpe_telegrafo_fuerte": true}
		),
		true,
	)
	comprobar.call(
		"reglas: retorno ritual respeta su límite",
		JuicioCombateReglas.determinacion_retorno(
			{"retornos_rival": 1, "determinacion_retorno": 2}, 1
		),
		0,
	)
	comprobar.call(
		"compatibilidad: JuicioCombate3D delega reglas",
		JuicioCombate3D.duracion_doctrina("comunismo", control),
		JuicioCombateReglas.duracion_doctrina("comunismo", control),
	)
