extends CharacterBody3D

# Player controller integrating Jungian systems
@onready var gestor_arquetipos = GestorArquetipos
@onready var gestor_momentum = GestorMomentum
@onready var gestor_combos = GestorCombos

var velocidad = 8.0
var salto_impulso = 12.0
var ultimo_ataque = 0.0

func _physics_process(delta: float) -> void:
    _handle_movement(delta)
    _handle_input()

func _handle_movement(delta: float) -> void:
    var direction = Vector3.ZERO
    if Input.is_action_pressed("move_right"):
        direction.x += 1
    if Input.is_action_pressed("move_left"):
        direction.x -= 1
    if Input.is_action_pressed("move_forward"):
        direction.z -= 1
    if Input.is_action_pressed("move_back"):
        direction.z += 1
    direction = direction.normalized()
    velocity = direction * velocidad
    if not is_on_floor():
        velocity.y += get_gravity().y * delta
    else if Input.is_action_just_pressed("jump"):
        velocity.y = salto_impulso
    move_and_slide()

func _handle_input() -> void:
    if Input.is_action_just_pressed("attack"):
        _atacar()
    if Input.is_action_just_pressed("heavy_attack"):
        _atacar_pesado()
    if Input.is_action_just_pressed("dodge"):
        _esquivar()

func _atacar() -> void:
    gestor_momentum.registrar_golpe()
    gestor_combos.registrar_entrada("ataque_ligero")
    # Apply archetype effects
    var efectos = gestor_arquetipos.obtener_efectos_activos()
    if efectos.has("bonus_crit"):
        # apply crit chance
        pass
    print("Ataque ligero, momentum:", gestor_momentum.momentum_actual)

func _atacar_pesado() -> void:
    gestor_momentum.registrar_golpe(es_critico=True)
    gestor_combos.registrar_entrada("ataque_pesado")
    print("Ataque pesado, momentum:", gestor_momentum.momentum_actual)

func _esquivar() -> void:
    gestor_combos.registrar_entrada("esquivar")
    # check for combo
    # dodge logic
    print("Esquivar")

# Expose debug
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("debug_insight"):
        gestor_arquetipos.ganar_insight(50)
        print("Insight +50, total:", gestor_arquetipos.insight_total)
