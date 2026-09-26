extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_gate_y_semilla()
	_probar_vigilia_deliberada()
	_probar_grafo_y_causalidad()
	_probar_accesibilidad_y_reproduccion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_gate_y_semilla() -> void:
	var jornada := {"dia": 8}
	_comprobar(not SuenoYggdrasil.puede_entrar(jornada), "sin semilla Yggdrasil no entra")
	_comprobar(
		not SuenoYggdrasil.registrar_semilla(jornada, 1, true),
		"una inspección no basta",
	)
	_comprobar(
		not SuenoYggdrasil.registrar_semilla(jornada, 2, false),
		"sin reconocer conexión no activa",
	)
	_comprobar(
		SuenoYggdrasil.registrar_semilla(jornada, 2, true),
		"interacción completa registra semilla",
	)
	_comprobar(SuenoYggdrasil.puede_entrar(jornada), "la semilla común habilita la familia")
	_comprobar(
		SemillasOniricas.familias_activas(jornada),
		["yggdrasil"],
		"Yggdrasil participa en catálogo común",
	)
	var entrada: Dictionary = (
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_yggdrasil"]
	)
	_comprobar(entrada["fuentes"], ["poster:yggdrasil_98"], "la procedencia es estable")
	_comprobar(entrada["intensidad"], 2, "intensidad declarada conservada")
	jornada["dia"] = 9
	_comprobar(not SuenoYggdrasil.puede_entrar(jornada), "la semilla no cruza de jornada")


func _probar_vigilia_deliberada() -> void:
	var jornada := {"dia": 3}
	var poster := YggdrasilVigilia.new()
	get_root().add_child(poster)
	poster.configurar(jornada)
	_comprobar(not poster.esta_activada(), "el póster presente no activa solo")
	poster.examinar()
	_comprobar(poster.inspecciones(), 1, "primera inspección cuenta")
	_comprobar(not poster.esta_activada(), "primera inspección no activa")
	poster.examinar()
	_comprobar(poster.inspecciones(), 2, "segunda inspección completa lectura")
	_comprobar(not poster.conexion_reconocida(), "observar nodos no equivale a seguir conexión")
	_comprobar(not poster.esta_activada(), "dos inspecciones aún no activan")
	poster.examinar()
	_comprobar(poster.conexion_reconocida(), "tercera interacción sigue la conexión")
	_comprobar(poster.esta_activada(), "seguir conexión activa semilla")
	var intensidad := int(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_yggdrasil"]["intensidad"]
	)
	poster.examinar()
	_comprobar(
		SemillasOniricas.obtener_semillas(jornada)["semilla_onirica_yggdrasil"]["intensidad"],
		intensidad,
		"misma fuente es idempotente",
	)
	poster.queue_free()


func _probar_grafo_y_causalidad() -> void:
	var sueno := SuenoYggdrasil.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var conexiones := sueno.conexiones_visibles()
	_comprobar(conexiones.size(), 3, "hay tres conexiones visibles")
	_comprobar(
		conexiones[SuenoYggdrasil.NODO_RAIZ], SuenoYggdrasil.NODO_RAMA, "raíz conecta con rama"
	)
	_comprobar(
		conexiones[SuenoYggdrasil.NODO_RAMA], SuenoYggdrasil.NODO_TRONCO, "rama conecta con tronco"
	)
	_comprobar(
		conexiones[SuenoYggdrasil.NODO_TRONCO], SuenoYggdrasil.NODO_RAIZ, "tronco conecta con raíz"
	)
	_comprobar(sueno.get_node_or_null("Conexiones") != null, "el grafo existe en escena")
	_comprobar(
		sueno.get_node("Conexiones").get_child_count(), 3, "cada arista tiene representación física"
	)

	var inicial := sueno.estado_reproducible()
	_comprobar(inicial[SuenoYggdrasil.NODO_RAMA], 0, "rama empieza neutra")
	var luz_rama := sueno.get_node("%s/LuzRemota" % SuenoYggdrasil.NODO_RAMA) as OmniLight3D
	var nucleo_tronco := sueno.get_node("%s/Nucleo" % SuenoYggdrasil.NODO_TRONCO) as MeshInstance3D
	var barrera_raiz := (
		sueno.get_node("%s/BarreraAcceso" % SuenoYggdrasil.NODO_RAIZ) as MeshInstance3D
	)
	var energia_rama_inicial := luz_rama.light_energy
	var altura_tronco_inicial := nucleo_tronco.position.y
	var altura_barrera_inicial := barrera_raiz.position.y
	var desde_raiz := sueno.intervenir(SuenoYggdrasil.NODO_RAIZ)
	_comprobar(desde_raiz["ok"], "intervención válida")
	_comprobar(desde_raiz["origen"], SuenoYggdrasil.NODO_RAIZ, "feedback conserva origen")
	_comprobar(desde_raiz["destino"], SuenoYggdrasil.NODO_RAMA, "efecto ocurre a distancia")
	_comprobar(desde_raiz["accion"], "alimentar", "acción declarada es rastreable")
	_comprobar(desde_raiz["efecto"], "luz", "efecto remoto declarado")
	_comprobar(
		sueno.estado_reproducible()[SuenoYggdrasil.NODO_RAMA], 1, "solo cambia destino remoto"
	)
	_comprobar(
		sueno.estado_reproducible()[SuenoYggdrasil.NODO_RAIZ], 0, "origen no se auto modifica"
	)
	_comprobar(
		luz_rama.light_energy > energia_rama_inicial,
		"alimentar la raíz aumenta físicamente la luz de la rama remota",
	)

	var desde_rama := sueno.intervenir(SuenoYggdrasil.NODO_RAMA)
	_comprobar(
		desde_rama["destino"], SuenoYggdrasil.NODO_TRONCO, "segunda arista también es remota"
	)
	_comprobar(desde_rama["efecto"], "altura", "rama controla altura del tronco")
	_comprobar(
		nucleo_tronco.position.y > altura_tronco_inicial,
		"tensar la rama eleva físicamente el tronco remoto",
	)
	var desde_tronco := sueno.intervenir(SuenoYggdrasil.NODO_TRONCO)
	_comprobar(desde_tronco["destino"], SuenoYggdrasil.NODO_RAIZ, "tercera arista cierra grafo")
	_comprobar(desde_tronco["efecto"], "acceso", "tronco controla acceso de raíz")
	_comprobar(
		barrera_raiz.position.y > altura_barrera_inicial,
		"bloquear el tronco eleva una barrera visual en la raíz remota",
	)
	_comprobar(desde_tronco["retorno_disponible"], "ninguna intervención elimina retorno")

	var invalida := sueno.intervenir("nodo_inexistente")
	_comprobar(not invalida["ok"], "nodo desconocido se rechaza sin mutar")
	_comprobar(invalida["retorno_disponible"], "error tampoco elimina retorno")
	sueno.queue_free()


func _probar_accesibilidad_y_reproduccion() -> void:
	var sueno := SuenoYggdrasil.new()
	get_root().add_child(sueno)
	sueno.preparar()
	var normal := sueno.intervenir(SuenoYggdrasil.NODO_RAIZ, false)
	_comprobar(normal["modo"], "transicion_breve", "presentación normal permite transición breve")
	_comprobar(normal["duracion"], 0.20, "transición normal está acotada")
	_comprobar(normal["feedback_causal"], "siempre hay feedback causal")
	_comprobar(normal["desplazar_sala"], "modo normal puede desplazar estado visual")

	var reducida := sueno.intervenir(SuenoYggdrasil.NODO_RAMA, true)
	_comprobar(reducida["modo"], "corte_fundido", "movimiento reducido usa corte/fundido")
	_comprobar(reducida["duracion"], 0.0, "movimiento reducido no interpola")
	_comprobar(not reducida["desplazar_sala"], "movimiento reducido evita gran desplazamiento")
	_comprobar(reducida["feedback_causal"], "accesibilidad conserva causalidad")
	_comprobar(reducida["retorno_disponible"], "accesibilidad conserva retorno")

	var guardado := sueno.estado_reproducible()
	var copia := SuenoYggdrasil.new()
	get_root().add_child(copia)
	copia.preparar()
	copia.restaurar_estado(guardado)
	_comprobar(copia.estado_reproducible(), guardado, "estado se reproduce exactamente")
	(
		copia
		. restaurar_estado(
			{
				SuenoYggdrasil.NODO_RAIZ: 99,
				SuenoYggdrasil.NODO_TRONCO: -4,
				SuenoYggdrasil.NODO_RAMA: 1,
			}
		)
	)
	_comprobar(
		copia.estado_reproducible()[SuenoYggdrasil.NODO_RAIZ], 2, "restauración acota máximo"
	)
	_comprobar(
		copia.estado_reproducible()[SuenoYggdrasil.NODO_TRONCO], 0, "restauración acota mínimo"
	)
	_comprobar(copia.ruta_retorno_disponible(), "estado extremo mantiene retorno")
	sueno.queue_free()
	copia.queue_free()


func _comprobar(actual, esperado = true, nombre: String = "") -> void:
	if typeof(esperado) == TYPE_STRING and nombre.is_empty():
		nombre = String(esperado)
		esperado = true
	if actual == esperado:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Yggdrasil: %s (actual=%s esperado=%s)" % [nombre, actual, esperado])
