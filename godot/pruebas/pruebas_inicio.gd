extends SceneTree

const Inicio := preload("res://guion/inicio_app.gd")

var _fallos := 0
var _pasadas := 0
var _ruta := ""


class InicioPrueba:
	extends "res://guion/inicio_app.gd"
	var entradas := 0
	var personajes := 0
	var ventanillas := 0
	var ajustes := 0
	var salidas := 0

	func _entrar() -> void:
		entradas += 1

	func _abrir_personaje() -> void:
		personajes += 1

	func _abrir_ventanilla() -> void:
		ventanillas += 1

	func _abrir_ajustes() -> void:
		ajustes += 1

	func _salir_del_juego() -> void:
		salidas += 1


class PartidaFallida:
	extends Partida
	var falla := true

	func guardar(destino: String = RUTA) -> bool:
		if falla:
			return false
		return super.guardar(destino)


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_ruta = "user://inicio-prueba-%d.json" % Time.get_ticks_usec()
	var inicio := InicioPrueba.new()
	inicio.ruta = _ruta
	root.add_child(inicio)
	var fondo := inicio.get_node_or_null("FondoInicio")
	_comprobar(
		fondo is TextureRect and fondo.texture != null, "inicio pinta el diorama 3D como fondo"
	)
	_comprobar(
		inicio._diorama is InicioDiorama3D and inicio._diorama.obtener_textura() == fondo.texture,
		"el fondo es la textura en vivo del diorama, no una lámina estática"
	)
	_comprobar(
		inicio.find_child("MarcoInicio", true, false) == null,
		"#830: ya no hay bloque OS98 centrado como superficie principal"
	)
	var marca := inicio.find_child("MarcaInicio", true, false)
	_comprobar(marca is TextureRect and marca.texture != null, "cabecera usa marca visual propia")
	var estado := inicio.find_child("EstadoInicio", true, false)
	_comprobar(estado != null, "el aviso de estado sigue presente sobre el diorama")
	_comprobar(
		inicio._continuar.custom_minimum_size.y >= 36.0,
		"acciones tienen presencia visual suficiente"
	)
	_comprobar(inicio._continuar.disabled, "sin guardado no permite continuar")
	_comprobar(inicio._cargar.disabled, "sin guardado no permite cargar")
	_comprobar(not FileAccess.file_exists(_ruta), "abrir menú no crea partida")
	_comprobar(inicio._extras != null, "#830: el nivel principal ofrece una entrada Extras")
	_comprobar(
		inicio._ventanilla.get_parent() == inicio._extras.get_parent(),
		"#567: ventanilla es una acción principal y no queda escondida en Extras"
	)
	_comprobar(
		inicio._extras.focus_neighbor_top == inicio._extras.get_path_to(inicio._ventanilla),
		"#98: el recorrido de mando llega a Extras desde Ventanilla de forma explícita"
	)
	_comprobar(
		inicio._extras.focus_neighbor_bottom == inicio._extras.get_path_to(inicio._ajustes),
		"#98: el recorrido principal continúa de Extras a Ajustes"
	)
	_comprobar(
		not inicio._extras_contenedor.visible,
		"Extras empieza recogido para mantener limpia la jerarquía principal"
	)
	inicio._extras.pressed.emit()
	_comprobar(
		inicio._extras_contenedor.visible,
		"Extras despliega los accesos secundarios sin cambiar de escena"
	)
	_comprobar(
		inicio._personaje.visible and inicio._portatil.visible,
		"Personaje y portátil siguen accesibles dentro de Extras"
	)
	_comprobar(
		inicio._portatil.focus_neighbor_bottom == inicio._portatil.get_path_to(inicio._ajustes),
		"#98: el mando puede salir de Extras hacia Ajustes sin depender de heurística"
	)
	inicio._extras.pressed.emit()
	_comprobar(not inicio._extras_contenedor.visible, "Extras puede volver a recogerse")
	inicio._ventanilla.pressed.emit()
	_comprobar(inicio.ventanillas == 1, "ventanilla es accesible desde inicio")
	inicio._ajustes.pressed.emit()
	_comprobar(inicio.ajustes == 1, "ajustes son accesibles desde inicio")
	inicio._salir.pressed.emit()
	_comprobar(inicio.salidas == 1, "salir es accesible desde inicio")
	inicio._salir.grab_focus()
	_comprobar(
		inicio._diorama.get("_zona_actual") == "salir",
		"enfocar una opción deriva el encuadre del diorama"
	)
	inicio._diorama._procesar_attract(InicioDiorama3D.SEGUNDOS_INACTIVIDAD_ATTRACT + 0.1)
	_comprobar(
		inicio._diorama.get("_attract_activo"),
		"#830: la inactividad prolongada activa el attract mode ligero"
	)
	var primer_tableau: Dictionary = InicioDiorama3D.TABLEAUX_ATTRACT[0]
	_comprobar(
		inicio._diorama.get("_zona_actual") == String(primer_tableau.get("zona", "")),
		"#888: attract mode aplica el encuadre del primer tableau simbólico"
	)
	_comprobar(
		String(primer_tableau.get("id", "")) == "balanza",
		"#888: los tableaux tienen IDs internos estables sin añadir texto a la UI"
	)
	_comprobar(
		not is_equal_approx(float(inicio._diorama.get("_fov_objetivo")), InicioDiorama3D.FOV_BASE),
		"#888: el tableau puede variar sutilmente el FOV sin crear otra escena"
	)
	_comprobar(
		float(inicio._diorama.get("_multiplicador_luz_attract")) < 1.0,
		"#888: el tableau modula la luz como composición y no como iconografía"
	)
	_comprobar(inicio._salir.has_focus(), "attract mode no roba el foco de navegación")
	inicio._diorama._registrar_actividad()
	_comprobar(
		not inicio._diorama.get("_attract_activo"), "cualquier actividad abandona attract mode"
	)
	_comprobar(
		inicio._diorama.get("_zona_actual") == "salir",
		"salir de attract mode restaura el encuadre elegido por el jugador"
	)
	_comprobar(
		is_equal_approx(float(inicio._diorama.get("_fov_objetivo")), InicioDiorama3D.FOV_BASE),
		"salir de attract mode restaura el FOV objetivo normal"
	)
	_comprobar(
		is_equal_approx(float(inicio._diorama.get("_multiplicador_luz_attract")), 1.0),
		"salir de attract mode restaura la iluminación normal"
	)
	var taza := inicio._diorama.find_child("TazaPuesto", true, false) as MeshInstance3D
	var papel := inicio._diorama.find_child("PapelBandeja", true, false) as Node3D
	var vapor := inicio._diorama.find_child("VaporTaza", true, false) as MeshInstance3D
	_comprobar(taza != null, "#830: la composición del escritorio incluye taza reutilizada")
	_comprobar(papel != null, "#830: la bandeja mantiene papel visible en la composición")
	_comprobar(vapor != null and vapor.visible, "#830: la taza aporta vapor ambiental sutil")
	inicio._diorama.configurar_reduccion_movimiento(true)
	inicio._diorama._procesar_attract(InicioDiorama3D.SEGUNDOS_INACTIVIDAD_ATTRACT + 1.0)
	_comprobar(
		not inicio._diorama.get("_attract_activo"),
		"reducir movimiento impide arrancar attract mode"
	)
	_comprobar(
		inicio._diorama.get("_exterior").get("_reduccion_movimiento"),
		"reducir movimiento también congela la ventana exterior del diorama"
	)
	inicio._diorama.configurar_activo(false)
	_comprobar(
		not inicio._diorama.is_processing(),
		"#830: el diorama puede suspender su proceso bajo overlays"
	)
	_comprobar(
		inicio._diorama.get("_viewport").render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"#830: suspender el diorama detiene su viewport principal"
	)
	_comprobar(
		(
			inicio._diorama.get("_exterior").get("_viewport").render_target_update_mode
			== SubViewport.UPDATE_DISABLED
		),
		"#830: suspender el diorama detiene también el viewport exterior"
	)
	inicio._diorama.configurar_activo(true)
	_comprobar(inicio._diorama.is_processing(), "reactivar el diorama restaura su proceso")
	_comprobar(
		inicio._diorama.get("_viewport").render_target_update_mode == SubViewport.UPDATE_ALWAYS,
		"reactivar el diorama restaura el render en vivo"
	)
	_comprobar(
		vapor != null and not vapor.visible, "reducir movimiento elimina el vapor no esencial"
	)
	_comprobar(
		papel != null and is_zero_approx(papel.rotation.y),
		"reducir movimiento devuelve el papel a una pose estable"
	)
	inicio.free()

	var anterior := Partida.new()
	anterior.estado = Partida.nueva()
	anterior.estado.jornada.dinero = 135
	anterior.estado.jornada.fase = "casa"
	_comprobar(anterior.guardar(_ruta), "prepara guardado aislado")
	var original := FileAccess.get_file_as_string(_ruta)
	inicio = InicioPrueba.new()
	inicio.ruta = _ruta
	root.add_child(inicio)
	_comprobar(not inicio._continuar.disabled, "ofrece continuar")
	_comprobar(not inicio._cargar.disabled, "ofrece cargar la ranura guardada")
	_comprobar(FileAccess.get_file_as_string(_ruta) == original, "menú no modifica guardado")
	inicio._nueva.pressed.emit()
	_comprobar(inicio._confirmacion.visible, "nueva requiere confirmación")
	inicio._confirmacion.hide()
	inicio._confirmacion.canceled.emit()
	_comprobar(FileAccess.get_file_as_string(_ruta) == original, "cancelar conserva bytes")
	_comprobar(inicio.entradas == 0, "cancelar no entra al mundo")
	inicio._cargar.pressed.emit()
	_comprobar(inicio.entradas == 1, "cargar entra usando la ranura canónica")
	inicio._continuar.pressed.emit()
	_comprobar(inicio.entradas == 2, "continuar entra")
	_comprobar(FileAccess.get_file_as_string(_ruta) == original, "continuar conserva bytes")
	inicio.free()

	inicio = InicioPrueba.new()
	inicio.ruta = _ruta
	var fallida := PartidaFallida.new()
	inicio.partida = fallida
	root.add_child(inicio)
	inicio._empezar()
	_comprobar(inicio.entradas == 0, "fallo de guardado impide entrar")
	_comprobar(inicio.personajes == 0, "fallo de guardado impide abrir el creador")
	_comprobar(inicio._reinicio_pendiente, "permite reintentar estado pendiente")
	_comprobar(inicio._continuar.disabled, "no ofrece continuar sin guardado nuevo")
	_comprobar(FileAccess.get_file_as_string(_ruta + ".roto") == original, "respalda original")
	var semilla: int = fallida.estado.semilla
	fallida.falla = false
	inicio._pedir_nueva()
	_comprobar(inicio.entradas == 0, "reintentar guardado aún no entra al mundo")
	_comprobar(inicio.personajes == 1, "reintentar guardado abre el creador una vez")
	_comprobar(fallida.estado.semilla == semilla, "reintento conserva semilla")
	var nueva := Partida.new()
	nueva.cargar(_ruta)
	_comprobar(nueva.estado.jornada.dia == 1, "nueva empieza día uno")
	_comprobar(nueva.estado.jornada.dinero == Jornada.nueva().dinero, "dinero canónico")
	_comprobar(nueva.estado.jornada.fase == "archivo", "nueva empieza en archivo")
	_comprobar(nueva.estado.cinematicas_vistas.is_empty(), "entrada sin vistas anteriores")
	_comprobar(
		not PerfilJugador.esta_configurado(nueva.estado.perfil_jugador),
		"nueva queda pendiente de completar la ficha"
	)
	inicio.free()
	for sufijo in ["", ".roto", ".nuevo"]:
		if FileAccess.file_exists(_ruta + sufijo):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_ruta + sufijo))
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
