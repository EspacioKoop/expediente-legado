## Pruebas para ConsecuenciasExpedientes (#2742)
##
## Estas pruebas verifican:
## 1. Registro de consecuencias para expedientes
## 2. Persistencia en guardado/carga
## 3. Consulta de consecuencias por expediente y por ámbito
## 4. Integración con el sistema de veredictos existente
extends "res://guion/pruebas.gd"


func prueba_registrar_consecuencias_basico():
	var estado := Partida.nueva()
	var caso_id := "caso@1"
	var sospechoso_id := "sospechoso_1"
	var consecuencias := [{"id": "test_consecuencia_1", "tipo": "visual", "ambito": "oficina"}]

	var resultado := ConsecuenciasExpedientes.registrar(
		estado, caso_id, sospechoso_id, consecuencias
	)

	assert_eq(resultado.get("resultado"), "registrado")
	assert_eq(resultado.get("caso_id"), caso_id)
	assert_eq(resultado.get("sospechoso_id"), sospechoso_id)
	assert_eq(resultado.get("consecuencias_registradas"), 1)

	# Verificar que se guardó
	var consec := ConsecuenciasExpedientes.de_expediente(estado, caso_id)
	assert_eq(consec.size(), 1)
	assert_eq(consec[0].get("id"), "test_consecuencia_1")


func prueba_registrar_consecuencias_del_catalogo():
	var estado := Partida.nueva()
	var caso_id := "caso@1"
	var sospechoso_id := "sospechoso_1"

	# Registrar SIN proveer consecuencias (debe usar el catálogo)
	var resultado := ConsecuenciasExpedientes.registrar(estado, caso_id, sospechoso_id, [])

	assert_eq(resultado.get("resultado"), "registrado")

	# Verificar que se usaron las del catálogo
	var consec := ConsecuenciasExpedientes.de_expediente(estado, caso_id)
	assert_gt(consec.size(), 0, "Debería haber consecuencias del catálogo")


func prueba_obtener_consecuencias_inexistente():
	var estado := Partida.nueva()
	var caso_id := "caso_inexistente"

	var consec := ConsecuenciasExpedientes.de_expediente(estado, caso_id)
	assert_eq(consec.size(), 0)


func prueba_tiene_consecuencias():
	var estado := Partida.nueva()
	var caso_id := "caso@1"
	var sospechoso_id := "sospechoso_1"
	var consecuencias := [{"id": "test_1", "tipo": "visual"}]

	# Antes de registrar
	assert_false(ConsecuenciasExpedientes.tiene_consecuencias(estado, caso_id))

	# Después de registrar
	ConsecuenciasExpedientes.registrar(estado, caso_id, sospechoso_id, consecuencias)
	assert_true(ConsecuenciasExpedientes.tiene_consecuencias(estado, caso_id))


func prueba_todas_las_consecuencias():
	var estado := Partida.nueva()

	# Registrar varios expedientes con consecuencias
	ConsecuenciasExpedientes.registrar(
		estado, "caso@1", "sospechoso_1", [{"id": "c1", "tipo": "visual", "ambito": "oficina"}]
	)
	ConsecuenciasExpedientes.registrar(
		estado, "caso2@2", "sospechoso_2", [{"id": "c2", "tipo": "visual", "ambito": "casa"}]
	)

	var todas := ConsecuenciasExpedientes.todas(estado)
	assert_eq(todas.size(), 2)


func prueba_consecuencias_por_ambito():
	var estado := Partida.nueva()

	# Registrar consecuencias en diferentes ámbitos
	ConsecuenciasExpedientes.registrar(
		estado,
		"caso@1",
		"sospechoso_1",
		[
			{"id": "c1", "tipo": "visual", "ambito": "oficina"},
			{"id": "c2", "tipo": "visual", "ambito": "casa"}
		]
	)

	var oficina := ConsecuenciasExpedientes.por_ambito(estado, "oficina")
	assert_eq(oficina.size(), 1)
	assert_eq(oficina[0].get("id"), "c1")

	var casa := ConsecuenciasExpedientes.por_ambito(estado, "casa")
	assert_eq(casa.size(), 1)
	assert_eq(casa[0].get("id"), "c2")


func prueba_eliminar_consecuencias():
	var estado := Partida.nueva()
	var caso_id := "caso@1"
	var sospechoso_id := "sospechoso_1"
	var consecuencias := [{"id": "test_1", "tipo": "visual"}]

	ConsecuenciasExpedientes.registrar(estado, caso_id, sospechoso_id, consecuencias)
	assert_true(ConsecuenciasExpedientes.tiene_consecuencias(estado, caso_id))

	var eliminado := ConsecuenciasExpedientes.eliminar(estado, caso_id)
	assert_true(eliminado)
	assert_false(ConsecuenciasExpedientes.tiene_consecuencias(estado, caso_id))


func prueba_contar_expedientes_y_consecuencias():
	var estado := Partida.nueva()

	ConsecuenciasExpedientes.registrar(
		estado, "caso@1", "sospechoso_1", [{"id": "c1_1"}, {"id": "c1_2"}]
	)
	ConsecuenciasExpedientes.registrar(estado, "caso2@2", "sospechoso_2", [{"id": "c2_1"}])

	assert_eq(ConsecuenciasExpedientes.contar_expedientes_con_consecuencias(estado), 2)
	assert_eq(ConsecuenciasExpedientes.contar_consecuencias(estado), 3)


func prueba_tiene_consecuencia_id():
	var estado := Partida.nueva()

	ConsecuenciasExpedientes.registrar(
		estado, "caso@1", "sospechoso_1", [{"id": "consecuencia_especial", "tipo": "visual"}]
	)

	assert_true(ConsecuenciasExpedientes.tiene_consecuencia_id(estado, "consecuencia_especial"))
	assert_false(ConsecuenciasExpedientes.tiene_consecuencia_id(estado, "consecuencia_inexistente"))


func prueba_limpiar_todo():
	var estado := Partida.nueva()

	ConsecuenciasExpedientes.registrar(estado, "caso@1", "sospechoso_1", [{"id": "c1"}])
	ConsecuenciasExpedientes.registrar(estado, "caso2@2", "sospechoso_2", [{"id": "c2"}])

	assert_eq(ConsecuenciasExpedientes.contar_expedientes_con_consecuencias(estado), 2)

	ConsecuenciasExpedientes.limpiar_todo(estado)

	assert_eq(ConsecuenciasExpedientes.contar_expedientes_con_consecuencias(estado), 0)


func prueba_integracion_con_veredictos():
	## Verificar que el sistema de consecuencias funciona junto al de veredictos
	var estado := Partida.nueva()
	var caso_id := "caso@1"
	var sospechoso_id := "sospechoso_1"

	# Primero, registrar veredicto usando Acusacion
	var caso := {"id": caso_id}
	var sospechoso := {"id": sospechoso_id, "nombre": "Test", "desenlace": "", "ataques": []}
	var jornada := {"acciones": 10, "cerrados_hoy": 0}

	var resultado_acusacion := Acusacion.acusar(estado, jornada, caso, sospechoso, [])
	assert_eq(resultado_acusacion.get("resultado"), "cerrado")

	# Verificar que el veredicto se guardó
	assert_true(Acusacion.esta_cerrado(estado, caso_id))

	# Ahora registrar consecuencias
	var consecuencias := [{"id": "consecuencia_veredicto", "tipo": "narrativo"}]
	var resultado_consecuencias := ConsecuenciasExpedientes.registrar(
		estado, caso_id, sospechoso_id, consecuencias
	)
	assert_eq(resultado_consecuencias.get("resultado"), "registrado")

	# Verificar que ambas cosas coexisten
	assert_true(Acusacion.esta_cerrado(estado, caso_id))
	assert_true(ConsecuenciasExpedientes.tiene_consecuencias(estado, caso_id))


func prueba_persistencia_guardado_carga():
	## Prueba de guardado y carga de partida con consecuencias
	var estado := Partida.nueva()

	# Registrar consecuencias
	ConsecuenciasExpedientes.registrar(
		estado,
		"caso@1",
		"sospechoso_1",
		[{"id": "persistente_1", "tipo": "visual", "ambito": "oficina"}]
	)

	# Guardar partida
	var guardado := Partida.guardar(estado)
	assert_true(guardado, "Debería poder guardar la partida")

	# Crear nueva partida y cargar
	var estado_nuevo := Partida.nueva()
	var cargado := Partida.cargar(estado_nuevo)
	assert_true(cargado, "Debería poder cargar la partida")

	# Verificar que las consecuencias se mantuvieron
	assert_true(ConsecuenciasExpedientes.tiene_consecuencias(estado_nuevo, "caso@1"))
	var consec := ConsecuenciasExpedientes.de_expediente(estado_nuevo, "caso@1")
	assert_eq(consec.size(), 1)
	assert_eq(consec[0].get("id"), "persistente_1")


func prueba_catalogo_consecuencias():
	## Verificar que el catálogo tiene consecuencias definidas
	assert_true(ConsecuenciasExpedientes.CATALOGO_CONSECUENCIAS.has("caso@1"))
	assert_true(ConsecuenciasExpedientes.CATALOGO_CONSECUENCIAS.has("caso2@2"))
	assert_true(ConsecuenciasExpedientes.CATALOGO_CONSECUENCIAS.has("caso7@7"))

	# Verificar estructura de las consecuencias
	var caso1_consecuencias := ConsecuenciasExpedientes.CATALOGO_CONSECUENCIAS["caso@1"]
	assert_gt(caso1_consecuencias.size(), 0)

	for consec in caso1_consecuencias:
		assert_true(consec.has("id"))
		assert_true(consec.has("tipo"))
		assert_true(consec.has("descripcion"))
		assert_true(consec.has("ambito"))
