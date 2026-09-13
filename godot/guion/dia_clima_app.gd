## Presentación del clima diario sobre el trayecto exterior (#143).
## También integra el diálogo diegético ambiental de #276 sin cambiar la raíz
## histórica de la escena ni la cadena de herencia del día.
extends "res://guion/dia_calle_app.gd"

const FONDO_BASE := Color(0.05, 0.05, 0.06)
const TAM_TERMINAL_INTERACTIVO := Vector3(1.0, 1.2, 0.8)

var _clima_nodo: Node3D = null


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	# Un guardado pendiente tiene prioridad absoluta: la capa base sabe cómo
	# reintentarlo sin duplicar efectos de jornada.
	if partida.guardado_pendiente:
		super._al_pisar_salida(cuerpo, salida)
		return
	if cuerpo != _caminante or _pantalla != null:
		super._al_pisar_salida(cuerpo, salida)
		return

	var frase: String = salida.get_meta("frase", "")
	if frase.is_empty():
		super._al_pisar_salida(cuerpo, salida)
		return

	DialogoDiegetico.mostrar(_hud, _mundo, _caminante, salida, tr(frase))


func _espacio_de(fase: String) -> Dictionary:
	var espacio: Dictionary = super._espacio_de(fase)
	if fase == "trayecto":
		espacio["exterior"] = true
	return espacio


func _entrar_en(fase: String) -> void:
	_retirar_clima()
	super._entrar_en(fase)
	if fase == "archivo":
		_montar_terminal_interactivo()
		_montar_archivadores_interactivos(_espacio_de(fase))
	elif fase == "casa":
		CasaUtileria.montar(_mundo)
	# La niebla cambia el fondo global del Environment. Cada entrada restaura el
	# valor base antes de decidir si este espacio recibe tiempo exterior.
	_ambiente.background_color = FONDO_BASE
	var espacio := _espacio_de(fase)
	if not bool(espacio.get("exterior", false)):
		return
	_aplicar_clima(Clima.estado(int(jornada.get("dia", 1))))


## Sustituye únicamente el volumen que antes abría el expediente al pisarlo.
## La lógica de apertura sigue siendo `_abrir_expediente()`: aquí solo cambia
## cómo expresa el jugador la intención, de caminar dentro a mirar y pulsar la
## acción semántica `interactuar`.
func _montar_terminal_interactivo() -> void:
	var zona := _buscar_zona_destino(_mundo, "expediente")
	if zona == null:
		return

	# El trigger antiguo no puede seguir abriendo al caminar ni interceptar el
	# raycast del detector de interacción.
	zona.monitoring = false
	zona.monitorable = false
	zona.collision_layer = 0

	var terminal := Interactuable3D.new()
	terminal.name = "TerminalSIGAInteractuable"
	terminal.position = zona.position
	terminal.verbo = Interactuable3D.Verbo.USAR
	terminal.nombre_objeto = tr(String(zona.get_meta("rotulo", "SALIDA_PUESTO")))
	terminal.activado.connect(_activar_terminal_siga)
	_mundo.add_child(terminal)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = TAM_TERMINAL_INTERACTIVO
	colision.shape = forma
	terminal.add_child(colision)


## Añade intención a los archivadores ya declarados y modelados. No crea un
## inventario ni documentos: el catálogo sigue siendo dueño de qué muebles hay.
func _montar_archivadores_interactivos(espacio: Dictionary) -> void:
	var indice := 0
	for bulto in espacio.get("bultos", []):
		if String(bulto.get("modelo", "")) != "bookcaseClosed":
			continue
		indice += 1
		var archivador := ArchivadorInteractivo3D.new()
		archivador.name = "ArchivadorInteractuable%d" % indice
		archivador.position = bulto["pos"]
		_mundo.add_child(archivador)
		archivador.configurar(bulto["tam"])


func _activar_terminal_siga(_actor: Node) -> void:
	if _pantalla != null:
		return
	_sonar("documento")
	_abrir_expediente()


func _buscar_zona_destino(nodo: Node, destino: String) -> Area3D:
	for hijo in nodo.get_children():
		if hijo is Area3D and String(hijo.get_meta("destino", "")) == destino:
			return hijo
		var encontrada := _buscar_zona_destino(hijo, destino)
		if encontrada != null:
			return encontrada
	return null


func _retirar_clima() -> void:
	if is_instance_valid(_clima_nodo):
		_clima_nodo.queue_free()
	_clima_nodo = null


func _aplicar_clima(estado_clima: String) -> void:
	match estado_clima:
		Clima.NUBLADO:
			_ambiente.ambient_light_energy *= 0.72
			_sol.light_energy *= 0.55
		Clima.LLUVIA:
			_ambiente.ambient_light_energy *= 0.68
			_sol.light_energy *= 0.42
			_montar_precipitacion(false)
		Clima.NIEBLA:
			# La niebla levanta el negro pero mata contraste y alcance visual.
			_ambiente.ambient_light_energy = maxf(_ambiente.ambient_light_energy, 0.62)
			_sol.light_energy *= 0.28
			_ambiente.background_color = Color(0.34, 0.35, 0.38)
		Clima.NIEVE:
			_ambiente.ambient_light_energy *= 0.82
			_sol.light_energy *= 0.65
			_montar_precipitacion(true)
		_:
			pass


func _montar_precipitacion(nieve: bool) -> void:
	_clima_nodo = Node3D.new()
	_clima_nodo.name = "ClimaPrecipitacion"
	_mundo.add_child(_clima_nodo)

	var particulas := GPUParticles3D.new()
	particulas.name = "Nieve" if nieve else "Lluvia"
	particulas.amount = 520 if nieve else 760
	particulas.lifetime = 2.8 if nieve else 1.5
	particulas.preprocess = particulas.lifetime
	particulas.visibility_aabb = AABB(Vector3(-9, -1, -18), Vector3(18, 10, 36))
	particulas.position = Vector3(0, 6.0, 0)
	_clima_nodo.add_child(particulas)

	var proceso := ParticleProcessMaterial.new()
	proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proceso.emission_box_extents = Vector3(7.5, 0.5, 17.0)
	proceso.direction = Vector3(0, -1, 0)
	proceso.spread = 8.0 if nieve else 2.0
	proceso.initial_velocity_min = 1.2 if nieve else 7.0
	proceso.initial_velocity_max = 2.2 if nieve else 10.0
	proceso.gravity = Vector3(0, -0.45 if nieve else -2.2, 0)
	particulas.process_material = proceso

	var malla := QuadMesh.new()
	malla.size = Vector2(0.028, 0.028) if nieve else Vector2(0.018, 0.28)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = (
		Color(0.92, 0.94, 1.0, 0.82) if nieve else Color(0.65, 0.75, 0.88, 0.62)
	)
	malla.material = material
	particulas.draw_pass_1 = malla
