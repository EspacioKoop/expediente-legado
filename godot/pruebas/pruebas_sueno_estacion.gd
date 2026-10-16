extends SceneTree

var _pasadas = 0
var _fallos = 0


func _initialize() -> void:
	_probar_estado_nuevo()
	_probar_orden_determinista()
	_probar_disponibles_sin_bloqueos()
	_probar_ir_a_y_volver()
	_probar_bloqueo_narrativo()
	_probar_bloqueo_progreso_con_contexto()
	_probar_bloqueo_seguridad_retorno()
	_probar_levantar_bloqueo()
	_probar_levantar_bloqueos_tipo()
	_probar_serializar_deserializar()
	_probar_borde_destino_invalido()
	_probar_borde_contexto_faltante()
	_probar_retorno_seguro_actualizacion()
	_probar_visitados_acumulan()
	print("Pruebas Sueño Estación: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO SueñoEstacion: " + nombre)


func _probar_estado_nuevo() -> void:
	var estado = SuenoEstacion.estado_nuevo(42)
	_comprobar(estado.has("destino_actual"), "estado_nuevo tiene destino_actual")
	_comprobar(estado.has("destino_anterior"), "estado_nuevo tiene destino_anterior")
	_comprobar(estado.has("visitados"), "estado_nuevo tiene visitados")
	_comprobar(estado.has("bloqueos"), "estado_nuevo tiene bloqueos")
	_comprobar(estado.has("orden_presentacion"), "estado_nuevo tiene orden_presentacion")
	_comprobar(estado.has("retorno_seguro"), "estado_nuevo tiene retorno_seguro")
	_comprobar(estado.has("veces_entrada"), "estado_nuevo tiene veces_entrada")
	_comprobar(estado["destino_actual"] == "", "destino_actual empieza vacío")
	_comprobar(estado["destino_anterior"] == "", "destino_anterior empieza vacío")
	_comprobar(estado["visitados"].size() == 0, "visitados empieza vacío")
	_comprobar(estado["bloqueos"].size() == 0, "bloqueos empieza vacío")
	_comprobar(estado["retorno_seguro"] == true, "retorno_seguro empieza true")
	_comprobar(estado["veces_entrada"] == 0, "veces_entrada empieza 0")
	_comprobar(estado["orden_presentacion"].size() == 3, "orden_presentacion tiene 3 destinos")
	# Verificar que contiene los tres destinos esperados
	var tiene_casa = false
	var tiene_infancia = false
	var tiene_juicio = false
	for d in estado["orden_presentacion"]:
		if d == "casa":
			tiene_casa = true
		if d == "infancia":
			tiene_infancia = true
		if d == "juicio":
			tiene_juicio = true
	_comprobar(
		tiene_casa and tiene_infancia and tiene_juicio,
		"orden_presentacion contiene casa, infancia, juicio"
	)


func _probar_orden_determinista() -> void:
	var estado1 = SuenoEstacion.estado_nuevo(12345)
	var estado2 = SuenoEstacion.estado_nuevo(12345)
	var estado3 = SuenoEstacion.estado_nuevo(54321)
	_comprobar(
		estado1["orden_presentacion"] == estado2["orden_presentacion"],
		"misma semilla da mismo orden"
	)
	# Semilla distinta *puede* dar orden distinto (no garantizado, pero probable)
	# Lo importante es que sea determinista, no que sea diferente


func _probar_disponibles_sin_bloqueos() -> void:
	var estado = SuenoEstacion.estado_nuevo(999)
	var disp = SuenoEstacion.disponibles(estado)
	_comprobar(disp.size() == 3, "sin bloqueos hay 3 disponibles")
	_comprobar(SuenoEstacion.disponible(estado, "casa"), "casa disponible")
	_comprobar(SuenoEstacion.disponible(estado, "infancia"), "infancia disponible")
	_comprobar(SuenoEstacion.disponible(estado, "juicio"), "juicio disponible")
	_comprobar(
		not SuenoEstacion.disponible(estado, "inexistente"), "destino inexistente no disponible"
	)


func _probar_ir_a_y_volver() -> void:
	var estado = SuenoEstacion.estado_nuevo(111)
	_comprobar(SuenoEstacion.ir_a(estado, "casa") == true, "ir_a casa devuelve true")
	_comprobar(estado["destino_actual"] == "casa", "destino_actual es casa")
	_comprobar(estado["destino_anterior"] == "", "destino_anterior vacío tras primera entrada")
	_comprobar(estado["visitados"].has("casa"), "casa en visitados")
	_comprobar(estado["veces_entrada"] == 1, "veces_entrada es 1")

	var vuelto = SuenoEstacion.volver(estado)
	_comprobar(vuelto == "casa", "volver devuelve casa")
	_comprobar(estado["destino_actual"] == "", "destino_actual limpio tras volver")
	_comprobar(estado["destino_anterior"] == "casa", "destino_anterior es casa")
	_comprobar(SuenoEstacion.retorno_seguro(estado) == true, "retorno seguro tras volver")

	# Segunda entrada
	_comprobar(SuenoEstacion.ir_a(estado, "infancia") == true, "ir_a infancia devuelve true")
	_comprobar(estado["destino_actual"] == "infancia", "destino_actual es infancia")
	_comprobar(estado["destino_anterior"] == "casa", "destino_anterior es casa")
	_comprobar(estado["visitados"].has("infancia"), "infancia en visitados")
	_comprobar(estado["visitados"].size() == 2, "visitados tiene 2 entradas")
	_comprobar(estado["veces_entrada"] == 2, "veces_entrada es 2")

	vuelto = SuenoEstacion.volver(estado)
	_comprobar(vuelto == "infancia", "volver devuelve infancia")

	# Volver sin estar en destino
	vuelto = SuenoEstacion.volver(estado)
	_comprobar(vuelto == "", "volver sin destino actual devuelve vacío")


func _probar_bloqueo_narrativo() -> void:
	var estado = SuenoEstacion.estado_nuevo(222)
	# Bloquear "casa" por narrativo
	_comprobar(
		(
			SuenoEstacion.bloquear(
				estado, "casa", SuenoEstacion.BLOQUEO_NARRATIVO, "historia pendiente"
			)
			== true
		),
		"bloquear narrativo devuelve true"
	)

	var disp = SuenoEstacion.disponibles(estado)
	_comprobar(disp.size() == 2, "un bloqueo narrativo deja 2 disponibles")
	_comprobar(not disp.has("casa"), "casa no está en disponibles")
	_comprobar(disp.has("infancia"), "infancia sigue disponible")
	_comprobar(disp.has("juicio"), "juicio sigue disponible")

	_comprobar(SuenoEstacion.ir_a(estado, "casa") == false, "ir_a casa bloqueada devuelve false")
	_comprobar(estado["destino_actual"] == "", "destino_actual no cambia al ir a bloqueado")

	# Levantar bloqueo
	_comprobar(
		SuenoEstacion.levantar_bloqueo(estado, "casa", 0) == true, "levantar_bloqueo devuelve true"
	)
	disp = SuenoEstacion.disponibles(estado)
	_comprobar(disp.size() == 3, "tras levantar hay 3 disponibles")
	_comprobar(disp.has("casa"), "casa vuelve a estar disponible")


func _probar_bloqueo_progreso_con_contexto() -> void:
	var estado = SuenoEstacion.estado_nuevo(333)
	# Bloquear "juicio" por progreso con condición día >= 5
	_comprobar(
		(
			SuenoEstacion.bloquear(
				estado, "juicio", SuenoEstacion.BLOQUEO_PROGRESO, "falta dia", {"dia_minimo": 5}
			)
			== true
		),
		"bloquear progreso con dia_minimo"
	)

	# Contexto día 3: bloqueo activo
	var disp_dia3 = SuenoEstacion.disponibles(estado, {"dia": 3})
	_comprobar(disp_dia3.size() == 2, "dia 3: 2 disponibles")
	_comprobar(not disp_dia3.has("juicio"), "juicio bloqueado en dia 3")

	# Contexto día 5: bloqueo resuelto
	var disp_dia5 = SuenoEstacion.disponibles(estado, {"dia": 5})
	_comprobar(disp_dia5.size() == 3, "dia 5: 3 disponibles")
	_comprobar(disp_dia5.has("juicio"), "juicio disponible en dia 5")

	# Contexto día 10: bloqueo resuelto
	var disp_dia10 = SuenoEstacion.disponibles(estado, {"dia": 10})
	_comprobar(disp_dia10.size() == 3, "dia 10: 3 disponibles")

	# Contexto sin día: bloqueo activo por seguridad
	var disp_sin = SuenoEstacion.disponibles(estado, {})
	_comprobar(disp_sin.size() == 2, "sin contexto: 2 disponibles")
	_comprobar(not disp_sin.has("juicio"), "juicio bloqueado sin contexto")


func _probar_bloqueo_seguridad_retorno() -> void:
	var estado = SuenoEstacion.estado_nuevo(444)
	# Bloquear "infancia" por seguridad
	_comprobar(
		(
			SuenoEstacion.bloquear(
				estado, "infancia", SuenoEstacion.BLOQUEO_SEGURIDAD, "zona inestable"
			)
			== true
		),
		"bloquear seguridad devuelve true"
	)

	# Entrar a infancia (bloqueo no impide ir_a, solo disponibles)
	_comprobar(
		SuenoEstacion.ir_a(estado, "infancia") == true,
		"ir_a infancia con bloqueo seguridad devuelve true"
	)
	_comprobar(estado["destino_actual"] == "infancia", "destino_actual es infancia")

	# Retorno NO seguro mientras esté en destino con bloqueo seguridad
	_comprobar(
		SuenoEstacion.retorno_seguro(estado) == false,
		"retorno NO seguro en infancia con bloqueo seguridad"
	)

	# Volver
	SuenoEstacion.volver(estado)
	_comprobar(
		SuenoEstacion.retorno_seguro(estado) == true, "retorno seguro tras volver de infancia"
	)

	# Entrar a casa (sin bloqueo)
	_comprobar(SuenoEstacion.ir_a(estado, "casa") == true, "ir_a casa devuelve true")
	_comprobar(SuenoEstacion.retorno_seguro(estado) == true, "retorno seguro en casa sin bloqueo")


func _probar_levantar_bloqueo() -> void:
	var estado = SuenoEstacion.estado_nuevo(555)
	SuenoEstacion.bloquear(estado, "casa", SuenoEstacion.BLOQUEO_NARRATIVO, "motivo1")
	SuenoEstacion.bloquear(
		estado, "casa", SuenoEstacion.BLOQUEO_PROGRESO, "motivo2", {"dia_minimo": 3}
	)

	# Levantar índice inexistente
	_comprobar(
		SuenoEstacion.levantar_bloqueo(estado, "casa", 5) == false,
		"levantar índice fuera de rango devuelve false"
	)
	_comprobar(
		SuenoEstacion.levantar_bloqueo(estado, "inexistente", 0) == false,
		"levantar destino inexistente devuelve false"
	)

	# Levantar primer bloqueo
	_comprobar(
		SuenoEstacion.levantar_bloqueo(estado, "casa", 0) == true,
		"levantar primer bloqueo devuelve true"
	)
	var info = SuenoEstacion.info_bloqueos(estado, "casa")
	_comprobar(info.size() == 2, "info_bloqueos devuelve 2 (uno inactivo)")
	_comprobar(info[0]["activo"] == false, "primer bloqueo inactivo")
	_comprobar(info[1]["activo"] == true, "segundo bloqueo activo")

	# Levantar segundo
	_comprobar(
		SuenoEstacion.levantar_bloqueo(estado, "casa", 1) == true,
		"levantar segundo bloqueo devuelve true"
	)
	info = SuenoEstacion.info_bloqueos(estado, "casa")
	_comprobar(info[0]["activo"] == false, "primer sigue inactivo")
	_comprobar(info[1]["activo"] == false, "segundo inactivo")

	# Disponibles vuelve a tener casa
	var disp = SuenoEstacion.disponibles(estado)
	_comprobar(disp.has("casa"), "casa disponible tras levantar todos")


func _probar_levantar_bloqueos_tipo() -> void:
	var estado = SuenoEstacion.estado_nuevo(666)
	SuenoEstacion.bloquear(estado, "juicio", SuenoEstacion.BLOQUEO_NARRATIVO, "n1")
	SuenoEstacion.bloquear(
		estado, "juicio", SuenoEstacion.BLOQUEO_PROGRESO, "p1", {"dia_minimo": 2}
	)
	SuenoEstacion.bloquear(estado, "juicio", SuenoEstacion.BLOQUEO_SEGURIDAD, "s1")
	SuenoEstacion.bloquear(estado, "casa", SuenoEstacion.BLOQUEO_NARRATIVO, "n2")

	var levantados = SuenoEstacion.levantar_bloqueos_tipo(
		estado, "juicio", SuenoEstacion.BLOQUEO_NARRATIVO
	)
	_comprobar(levantados == 1, "levantar_bloqueos_tipo narrativo devuelve 1")

	levantados = SuenoEstacion.levantar_bloqueos_tipo(
		estado, "juicio", SuenoEstacion.BLOQUEO_PROGRESO
	)
	_comprobar(levantados == 1, "levantar_bloqueos_tipo progreso devuelve 1")

	levantados = SuenoEstacion.levantar_bloqueos_tipo(
		estado, "juicio", SuenoEstacion.BLOQUEO_SEGURIDAD
	)
	_comprobar(levantados == 1, "levantar_bloqueos_tipo seguridad devuelve 1")

	# Casa no afectada
	var info_juicio = SuenoEstacion.info_bloqueos(estado, "juicio")
	_comprobar(info_juicio[0]["activo"] == false, "juicio narrativo inactivo")
	_comprobar(info_juicio[1]["activo"] == false, "juicio progreso inactivo")
	_comprobar(info_juicio[2]["activo"] == false, "juicio seguridad inactivo")

	var info_casa = SuenoEstacion.info_bloqueos(estado, "casa")
	_comprobar(info_casa[0]["activo"] == true, "casa narrativo sigue activo")

	# Destino inexistente
	_comprobar(
		(
			SuenoEstacion.levantar_bloqueos_tipo(
				estado, "inexistente", SuenoEstacion.BLOQUEO_NARRATIVO
			)
			== 0
		),
		"destino inexistente devuelve 0"
	)


func _probar_serializar_deserializar() -> void:
	var estado_original = SuenoEstacion.estado_nuevo(777)
	SuenoEstacion.ir_a(estado_original, "casa")
	SuenoEstacion.volver(estado_original)
	SuenoEstacion.ir_a(estado_original, "infancia")
	SuenoEstacion.bloquear(
		estado_original, "juicio", SuenoEstacion.BLOQUEO_NARRATIVO, "bloqueado por lore"
	)
	SuenoEstacion.bloquear(
		estado_original,
		"casa",
		SuenoEstacion.BLOQUEO_PROGRESO,
		"falta item",
		{"requiere": "llave_maestra", "valor": true}
	)

	var serializado = SuenoEstacion.serializar(estado_original)
	_comprobar(serializado.has("destino_actual"), "serializar tiene destino_actual")
	_comprobar(serializado.has("destino_anterior"), "serializar tiene destino_anterior")
	_comprobar(serializado.has("visitados"), "serializar tiene visitados")
	_comprobar(serializado.has("bloqueos"), "serializar tiene bloqueos")
	_comprobar(serializado.has("orden_presentacion"), "serializar tiene orden_presentacion")
	_comprobar(serializado.has("veces_entrada"), "serializar tiene veces_entrada")

	var estado_restaurado = SuenoEstacion.deserializar(serializado, 777)
	_comprobar(
		estado_restaurado["destino_actual"] == estado_original["destino_actual"],
		"destino_actual restaurado"
	)
	_comprobar(
		estado_restaurado["destino_anterior"] == estado_original["destino_anterior"],
		"destino_anterior restaurado"
	)
	_comprobar(
		estado_restaurado["visitados"] == estado_original["visitados"], "visitados restaurado"
	)
	_comprobar(
		estado_restaurado["veces_entrada"] == estado_original["veces_entrada"],
		"veces_entrada restaurado"
	)
	_comprobar(
		estado_restaurado["orden_presentacion"] == estado_original["orden_presentacion"],
		"orden_presentacion restaurado"
	)

	# Verificar bloqueos restaurados
	var bloqueos_orig = estado_original["bloqueos"]
	var bloqueos_rest = estado_restaurado["bloqueos"]
	_comprobar(bloqueos_rest.has("juicio"), "bloqueos juicio restaurado")
	_comprobar(bloqueos_rest.has("casa"), "bloqueos casa restaurado")
	_comprobar(
		bloqueos_rest["juicio"].size() == bloqueos_orig["juicio"].size(),
		"juicio mismo num bloqueos"
	)
	_comprobar(
		bloqueos_rest["casa"].size() == bloqueos_orig["casa"].size(), "casa mismo num bloqueos"
	)
	_comprobar(bloqueos_rest["juicio"][0]["tipo"] == "narrativo", "tipo bloqueo juicio narrativo")
	_comprobar(bloqueos_rest["casa"][0]["tipo"] == "progreso", "tipo bloqueo casa progreso")
	_comprobar(
		bloqueos_rest["casa"][0]["condicion"]["requiere"] == "llave_maestra",
		"condicion requiere restaurada"
	)
	_comprobar(bloqueos_rest["casa"][0]["condicion"]["valor"] == true, "condicion valor restaurado")

	# Retorno seguro restaurado
	_comprobar(
		estado_restaurado["retorno_seguro"] == estado_original["retorno_seguro"],
		"retorno_seguro restaurado"
	)

	# Datos inválidos -> estado_nuevo
	var estado_defecto = SuenoEstacion.deserializar({}, 888)
	_comprobar(estado_defecto["retorno_seguro"] == true, "deserializar dict vacío da estado nuevo")
	_comprobar(estado_defecto["orden_presentacion"].size() == 3, "estado defecto tiene 3 destinos")


func _probar_borde_destino_invalido() -> void:
	var estado = SuenoEstacion.estado_nuevo(999)
	_comprobar(SuenoEstacion.disponible(estado, "") == false, "destino vacío no disponible")
	_comprobar(SuenoEstacion.disponible(estado, "CASA") == false, "mayúsculas no disponible")
	_comprobar(SuenoEstacion.ir_a(estado, "no_existe") == false, "ir_a inexistente devuelve false")
	_comprobar(
		(
			SuenoEstacion.bloquear(estado, "no_existe", SuenoEstacion.BLOQUEO_NARRATIVO, "test")
			== false
		),
		"bloquear inexistente devuelve false"
	)
	_comprobar(
		SuenoEstacion.levantar_bloqueo(estado, "no_existe", 0) == false,
		"levantar inexistente devuelve false"
	)
	_comprobar(
		(
			SuenoEstacion.levantar_bloqueos_tipo(
				estado, "no_existe", SuenoEstacion.BLOQUEO_NARRATIVO
			)
			== 0
		),
		"levantar tipo inexistente devuelve 0"
	)
	_comprobar(
		SuenoEstacion.info_bloqueos(estado, "no_existe").size() == 0, "info inexistente vacío"
	)

	# Tipo de bloqueo inválido
	_comprobar(
		SuenoEstacion.bloquear(estado, "casa", "invalido", "test") == false,
		"tipo bloqueo inválido devuelve false"
	)


func _probar_borde_contexto_faltante() -> void:
	var estado = SuenoEstacion.estado_nuevo(1010)
	SuenoEstacion.bloquear(
		estado, "casa", SuenoEstacion.BLOQUEO_PROGRESO, "requiere flag", {"flag": "tiene_llave"}
	)
	SuenoEstacion.bloquear(
		estado,
		"infancia",
		SuenoEstacion.BLOQUEO_PROGRESO,
		"requiere valor",
		{"requiere": "objeto", "valor": "espada"}
	)

	# Contexto vacío: ambos bloqueados
	var disp = SuenoEstacion.disponibles(estado, {})
	_comprobar(disp.size() == 1, "contexto vacío: 1 disponible (juicio)")
	_comprobar(not disp.has("casa"), "casa bloqueada sin flag")
	_comprobar(not disp.has("infancia"), "infancia bloqueada sin objeto")

	# Contexto parcial
	disp = SuenoEstacion.disponibles(estado, {"tiene_llave": true})
	_comprobar(disp.size() == 2, "contexto parcial: 2 disponibles")
	_comprobar(disp.has("casa"), "casa desbloqueada con flag")
	_comprobar(not disp.has("infancia"), "infancia sigue bloqueada")

	# Contexto completo
	disp = SuenoEstacion.disponibles(estado, {"tiene_llave": true, "objeto": "espada"})
	_comprobar(disp.size() == 3, "contexto completo: 3 disponibles")


func _probar_retorno_seguro_actualizacion() -> void:
	var estado = SuenoEstacion.estado_nuevo(2020)
	_comprobar(SuenoEstacion.retorno_seguro(estado) == true, "retorno seguro en estación vacía")

	# Entrar a destino sin bloqueos
	SuenoEstacion.ir_a(estado, "casa")
	_comprobar(SuenoEstacion.retorno_seguro(estado) == true, "retorno seguro en casa sin bloqueos")
	SuenoEstacion.volver(estado)

	# Añadir bloqueo seguridad a casa
	SuenoEstacion.bloquear(estado, "casa", SuenoEstacion.BLOQUEO_SEGURIDAD, "peligro")
	_comprobar(
		SuenoEstacion.retorno_seguro(estado) == true,
		"retorno seguro en estación aunque casa tenga bloqueo seguridad"
	)

	# Entrar a casa
	SuenoEstacion.ir_a(estado, "casa")
	_comprobar(
		SuenoEstacion.retorno_seguro(estado) == false,
		"retorno NO seguro en casa con bloqueo seguridad"
	)

	# Levantar bloqueo seguridad desde dentro
	SuenoEstacion.levantar_bloqueos_tipo(estado, "casa", SuenoEstacion.BLOQUEO_SEGURIDAD)
	_comprobar(
		SuenoEstacion.retorno_seguro(estado) == true,
		"retorno seguro tras levantar bloqueo seguridad desde dentro"
	)

	# Volver
	SuenoEstacion.volver(estado)
	_comprobar(
		SuenoEstacion.retorno_seguro(estado) == true, "retorno seguro en estación tras levantar"
	)


func _probar_visitados_acumulan() -> void:
	var estado = SuenoEstacion.estado_nuevo(3030)
	_comprobar(estado["visitados"].size() == 0, "visitados empieza 0")

	SuenoEstacion.ir_a(estado, "casa")
	SuenoEstacion.volver(estado)
	_comprobar(estado["visitados"].size() == 1, "visitados 1 tras casa")

	SuenoEstacion.ir_a(estado, "infancia")
	SuenoEstacion.volver(estado)
	_comprobar(estado["visitados"].size() == 2, "visitados 2 tras infancia")

	# Volver a casa (ya visitado)
	SuenoEstacion.ir_a(estado, "casa")
	SuenoEstacion.volver(estado)
	_comprobar(estado["visitados"].size() == 2, "visitados sigue 2 tras repetir casa")
	_comprobar(estado["veces_entrada"] == 3, "veces_entrada 3")

	SuenoEstacion.ir_a(estado, "juicio")
	SuenoEstacion.volver(estado)
	_comprobar(estado["visitados"].size() == 3, "visitados 3 tras juicio")
	_comprobar(
		(
			estado["visitados"].has("casa")
			and estado["visitados"].has("infancia")
			and estado["visitados"].has("juicio")
		),
		"visitados tiene los tres"
	)
