## Regresión ejecutada por Godot: no sustituir por heurísticas textuales.
## No monta el mundo 3D completo para evitar depender del renderizador CI.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_fluorescente()
	_probar_render_menu()
	_probar_render_exterior()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_fluorescente() -> void:
	var diorama := InicioDiorama3D.new()
	var luz := OmniLight3D.new()
	diorama._luz_fluorescente = luz
	diorama._energia_base = 0.8
	diorama._tiempo = 10.0
	diorama._siguiente_fallo_fluorescente = 9.0
	diorama._actualizar_fluorescente()
	_comprobar(is_equal_approx(luz.light_energy, 0.12), "el fallo atenúa el fluorescente")
	_comprobar(
		is_equal_approx(diorama._fin_parpadeo, 10.12), "el parpadeo termina tras 120 ms"
	)

	diorama._tiempo = 10.06
	diorama._actualizar_fluorescente()
	_comprobar(is_equal_approx(luz.light_energy, 0.12), "sigue tenue dentro del pulso")
	diorama._tiempo = 10.13
	diorama._actualizar_fluorescente()
	_comprobar(is_equal_approx(luz.light_energy, 0.8), "recupera brillo inmediatamente")
	_comprobar(diorama._fin_parpadeo < 0.0, "sale del estado de parpadeo")
	_comprobar(
		diorama._siguiente_fallo_fluorescente >= 17.13,
		"el intervalo largo empieza DESPUES de la recuperación"
	)
	diorama._tiempo = 10.2
	diorama._actualizar_fluorescente()
	_comprobar(is_equal_approx(luz.light_energy, 0.8), "no hay atenuación permanente")
	luz.free()
	diorama.free()


func _probar_render_menu() -> void:
	var diorama := InicioDiorama3D.new()
	var vista := SubViewport.new()
	diorama._viewport = vista
	diorama._reduccion_movimiento = true
	diorama.configurar_activo(false)
	_comprobar(
		vista.render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"un modal suspende el render del diorama"
	)
	diorama.configurar_activo(true)
	_comprobar(
		vista.render_target_update_mode == SubViewport.UPDATE_ONCE,
		"al volver al menú dibuja un cuadro sin activar UPDATE_ALWAYS"
	)
	vista.render_target_update_mode = SubViewport.UPDATE_DISABLED
	diorama._process(0.016)
	_comprobar(
		vista.render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"no repinta antes de 33 ms"
	)
	diorama._process(0.018)
	_comprobar(
		vista.render_target_update_mode == SubViewport.UPDATE_ONCE,
		"repinta tras un intervalo de 33 ms"
	)
	vista.free()
	diorama.free()


func _probar_render_exterior() -> void:
	var exterior := VentanaExterior3D.new()
	var vista := SubViewport.new()
	exterior._viewport = vista
	exterior._reduccion_movimiento = true
	_comprobar(
		not exterior._render_limitado_menu, "la ventana del juego conserva refresco normal"
	)
	exterior.limitar_refresco_para_menu(true)
	_comprobar(
		vista.render_target_update_mode == SubViewport.UPDATE_ONCE,
		"el menú limita el render de la ventana anidada"
	)
	exterior.configurar_activo(false)
	_comprobar(
		vista.render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"la ventana queda suspendida durante cinemáticas y modales"
	)
	exterior.limitar_refresco_para_menu(false)
	_comprobar(
		vista.render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"cambiar calidad mientras está oculta no reactiva el render"
	)
	exterior.configurar_activo(true)
	_comprobar(
		vista.render_target_update_mode == SubViewport.UPDATE_ALWAYS,
		"fuera del menú recupera el refresco de juego"
	)
	exterior.limitar_refresco_para_menu(true)
	vista.render_target_update_mode = SubViewport.UPDATE_DISABLED
	exterior._process(0.016)
	_comprobar(
		vista.render_target_update_mode == SubViewport.UPDATE_DISABLED,
		"el exterior no repinta en cada frame de 60 Hz"
	)
	exterior._process(0.018)
	_comprobar(
		vista.render_target_update_mode == SubViewport.UPDATE_ONCE,
		"el exterior solo repinta al vencer el intervalo"
	)
	vista.free()
	exterior.free()


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO diorama #2597: %s" % descripcion)
