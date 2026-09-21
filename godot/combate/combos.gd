extends Node

# Autoload: GestorCombos
signal combo_ejecutado(nombre_combo, efectos)
signal finisher_ejecutado(nombre, efectos, es_super)

var combos_disponibles: Dictionary = {
    "golpe_sombra": {
        "nombre": "Golpe de la Sombra",
        "requisitos": {"momentum_min": 30, "arquetipo": "sombra"},
        "secuencia": ["ataque_ligero", "ataque_ligero", "ataque_pesado"],
        "efectos": {"daño_multiplier": 2.0, "aplicar_sombra": true, "area": 2.0}
    },
    "abrazo_anima": {
        "nombre": "Abrazo del Anima",
        "requisitos": {"momentum_min": 40, "arquetipo": "anima"},
        "secuencia": ["ataque_pesado", "esquivar", "ataque_ligero"],
        "efectos": {"curacion_area": 30, "buff_aliados": {"resistencia": 0.2, "duracion": 10}}
    },
    "danza_persona": {
        "nombre": "Danza de la Persona",
        "requisitos": {"momentum_min": 35, "arquetipo": "persona"},
        "secuencia": ["esquivar", "ataque_ligero", "esquivar", "ataque_pesado"],
        "efectos": {"evasion_temporal": 0.5, "duracion": 5, "contragolpe": true}
    },
    "despertar_self": {
        "nombre": "Despertar del Self",
        "requisitos": {"momentum_min": 100, "arquetipo": "self"},
        "secuencia": ["ataque_pesado", "ataque_pesado", "ataque_pesado", "ataque_pesado"],
        "efectos": {"daño_masivo": 500, "area": 5.0, "stun": 3.0, "buff_permanente": {"stats": 0.1}}
    }
}

var finishers: Dictionary = {
    "sombra_desatada": {
        "nombre": "Desatamiento de la Sombra",
        "costo_momentum": 75,
        "es_super": false,
        "efectos": {"daño_verdadero": 200, "miedo_enemigos": 4.0, "buff_jugador": {"crit": 0.3, "duracion": 15}}
    },
    "furia_divina": {
        "nombre": "Furia del Dios",
        "costo_momentum": 100,
        "es_super": true,
        "efectos": {"daño_divino": 500, "area": 8.0, "curacion_total": true, "invulnerabilidad": 5.0, "buff_permanente": {"todo": 0.15}}
    }
}

var buffer_entradas: Array = []
const MAX_BUFFER: int = 6
const TIEMPO_BUFFER: float = 2.0

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    # Limpiar buffer viejo
    var ahora = Time.get_ticks_msec() / 1000.0
    buffer_entradas = [e for e in buffer_entradas if ahora - e.tiempo < TIEMPO_BUFFER]

func registrar_entrada(accion: String) -> void:
    var ahora = Time.get_ticks_msec() / 1000.0
    buffer_entradas.append({"accion": accion, "tiempo": ahora})
    if buffer_entradas.size() > MAX_BUFFER:
        buffer_entradas.pop_front()
    _verificar_combos()

func _verificar_combos() -> void:
    var secuencia_actual = [e.accion for e in buffer_entradas]
    
    for combo_id, combo in combos_disponibles:
        if _coincide_secuencia(secuencia_actual, combo.secuencia):
            if _cumple_requisitos(combo.requisitos):
                combo_ejecutado.emit(combo.nombre, combo.efectos)
                buffer_entradas.clear()
                return

func _coincide_secuencia(buffer: Array, objetivo: Array) -> bool:
    if buffer.size() < objetivo.size():
        return false
    # Verificar los últimos N elementos
    for i in range(objetivo.size()):
        if buffer[buffer.size() - objetivo.size() + i] != objetivo[i]:
            return false
    return true

func _cumple_requisitos(req: Dictionary) -> bool:
    var momentum = get_node("/root/GestorMomentum")
    var arquetipos = get_node("/root/GestorArquetipos")
    
    if req.has("momentum_min") and momentum.momentum_actual < req.momentum_min:
        return false
    if req.has("arquetipo") and not arquetipos.obtener_arquetipo(req.arquetipo)?.desbloqueado:
        return false
    return true

func ejecutar_finisher(nombre: String) -> bool:
    if not finishers.has(nombre):
        return false
    
    var finisher = finishers[nombre]
    var momentum = get_node("/root/GestorMomentum")
    
    if momentum.momentum_actual >= finisher.costo_momentum:
        momentum.ejecutar_finisher("super" if finisher.es_super else "normal")
        finisher_ejecutado.emit(finisher.nombre, finisher.efectos, finisher.es_super)
        return true
    return false
