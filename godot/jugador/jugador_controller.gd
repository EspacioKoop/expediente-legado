extends CharacterBody3D

@onready var gestor_arquetipos := get_node_or_null("/root/GestorArquetipos")
@onready var gestor_momentum := get_node_or_null("/root/GestorMomentum")
@onready var gestor_combos := get_node_or_null("/root/GestorCombos")

var velocidad := 8.0
var salto_impulso := 12.0


func _physics_process(delta: float) -> void:
	_mover(delta)
	_leer_combate()


func _mover(delta: float) -> void:
	var direccion := Vector3(
		Input.get_axis("mover_izquierda", "mover_derecha"),
		0.0,
		Input.get_axis("mover_adelante", "mover_atras")
	)
	if direccion.length_squared() > 1.0:
		direccion = direccion.normalized()
	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed("saltar"):
		velocity.y = salto_impulso
	move_and_slide()


func _leer_combate() -> void:
	if Input.is_action_just_pressed("interactuar"):
		_atacar(false)
	if Input.is_action_just_pressed("saltar"):
		_atacar(true)
	if Input.is_action_just_pressed("agacharse") and gestor_combos != null:
		gestor_combos.call("registrar_entrada", "esquivar")


func _atacar(fuerte: bool) -> void:
	var accion := "ataque_pesado" if fuerte else "ataque_ligero"
	if gestor_momentum != null:
		gestor_momentum.call("registrar_golpe", false)
	if gestor_combos != null:
		gestor_combos.call("registrar_entrada", accion)
	if gestor_arquetipos == null:
		return
	var efectos = gestor_arquetipos.call("efectos_combinados")
	if typeof(efectos) == TYPE_DICTIONARY and float(efectos.get("bonus_crit", 0.0)) > 0.0:
		pass
