extends SceneTree

const Recogible := preload("res://guion/recogible_3d.gd")

var _pasadas := 0
var _fallos := 0
var _activaciones := 0
var _recogidas := 0
var _actor_recibido: Node = null
var _objeto_recibido: Dictionary = {}


func _initialize() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_recogida_valida()
	_probar_duplicado()
	_probar_id_invalido()
	_probar_deshabilitado()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_recogida_valida() -> void:
	_reiniciar_senales()
	var estado := Inventario.nuevo()
	var recogible = Recogible.new()
	var datos := {
		"id": "llave_archivo",
		"nombre": "llave del archivo",
		"vendible": true,
		"precio": 120,
		"origen": "escenario",
		"categoria": "llave",
	}
	recogible.configurar(estado, datos)
	recogible.activado.connect(_al_activar)
	recogible.recogido.connect(_al_recoger)
	root.add_child(recogible)

	_comprobar(recogible.verbo == recogible.Verbo.COGER, "declara el verbo COGER")
	_comprobar(recogible.texto_accion() == "Coger llave del archivo", "expone el prompt contextual")
	_comprobar(
		recogible.find_children("*", "CollisionShape3D", true, false).size() == 1,
		"crea un volumen de interacción si el prop no trae uno"
	)
	_comprobar(recogible.interactuar(root), "acepta una recogida válida")
	_comprobar(Inventario.contiene(estado, "llave_archivo"), "añade el objeto al inventario")
	_comprobar(estado[Inventario.CARRIED].size() == 1, "solo añade una entrada")
	var guardado: Dictionary = estado[Inventario.CARRIED][0]
	_comprobar(String(guardado.get("nombre", "")) == "llave del archivo", "conserva el nombre")
	_comprobar(String(guardado.get("categoria", "")) == "llave", "conserva metadatos adicionales")
	_comprobar(_activaciones == 1, "emite la activación genérica una vez")
	_comprobar(_recogidas == 1, "emite la señal de recogida una vez")
	_comprobar(_actor_recibido == root, "propaga el actor que recoge")
	_comprobar(recogible.is_queued_for_deletion(), "retira el prop tras recogerlo")


func _probar_duplicado() -> void:
	_reiniciar_senales()
	var estado := Inventario.nuevo()
	_comprobar(
		Inventario.recoger(estado, {"id": "documento", "nombre": "documento previo"}),
		"prepara un objeto ya poseído"
	)
	var recogible = Recogible.new()
	recogible.configurar(estado, {"id": "documento", "nombre": "otro documento"})
	recogible.activado.connect(_al_activar)
	root.add_child(recogible)

	_comprobar(not recogible.interactuar(root), "rechaza un id duplicado")
	_comprobar(_activaciones == 0, "un duplicado no emite activación")
	_comprobar(estado[Inventario.CARRIED].size() == 1, "un duplicado no altera el inventario")
	_comprobar(not recogible.is_queued_for_deletion(), "un duplicado permanece en el mundo")
	recogible.queue_free()


func _probar_id_invalido() -> void:
	_reiniciar_senales()
	var estado := Inventario.nuevo()
	var recogible = Recogible.new()
	recogible.configurar(estado, {"nombre": "objeto sin id"})
	recogible.activado.connect(_al_activar)
	root.add_child(recogible)

	_comprobar(not recogible.interactuar(root), "rechaza un objeto sin id")
	_comprobar(_activaciones == 0, "un id inválido no emite activación")
	_comprobar(not recogible.is_queued_for_deletion(), "un objeto inválido permanece en el mundo")
	recogible.queue_free()


func _probar_deshabilitado() -> void:
	_reiniciar_senales()
	var estado := Inventario.nuevo()
	var recogible = Recogible.new()
	recogible.configurar(estado, {"id": "cinta", "nombre": "cinta VHS"})
	recogible.habilitado = false
	recogible.activado.connect(_al_activar)
	root.add_child(recogible)

	_comprobar(not recogible.interactuar(root), "respeta el estado deshabilitado")
	_comprobar(estado[Inventario.CARRIED].is_empty(), "deshabilitado no modifica el inventario")
	_comprobar(_activaciones == 0, "deshabilitado no emite activación")
	_comprobar(not recogible.is_queued_for_deletion(), "deshabilitado permanece en el mundo")
	recogible.queue_free()


func _al_activar(actor: Node) -> void:
	_activaciones += 1
	_actor_recibido = actor


func _al_recoger(objeto: Dictionary, actor: Node) -> void:
	_recogidas += 1
	_objeto_recibido = objeto
	_actor_recibido = actor


func _reiniciar_senales() -> void:
	_activaciones = 0
	_recogidas = 0
	_actor_recibido = null
	_objeto_recibido = {}


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Recogible3D: " + nombre)
