## Test suite for GrabacionOniricaContrato
## Verifies the deterministic evaluation of dream recording takes.
extends Node

const TEST_SCENE := preload("res://guion/grabacion_onirica_contrato.gd")

func _ready() -> void:
    var passed := 0
    var failed := 0
    
    # Test 1: Todas las condiciones válidas -> VALIDA
    var datos_validos = {
        "original_identificado": true,
        "frase_completa": true,
        "tiempo_sujeto": 60.0,
        "duracion_total": 100.0,
        "figura_detecto_camara": false,
        "hubo_corte": false
    }
    assert(GrabacionOniricaContrato.evaluar_toma(datos_validos) == GrabacionOniricaContrato.ESTADO_GRABACION_VALIDA, "Test 1 failed: debería ser VALIDA")
    passed += 1
    print("Test 1 passed: condiciones válidas -> VALIDA")
    
    # Test 2: Original no identificado -> CONTAMINADA
    var datos_no_identificado = datos_validos.duplicate()
    datos_no_identificado["original_identificado"] = false
    assert(GrabacionOniricaContrato.evaluar_toma(datos_no_identificado) == GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA, "Test 2 failed: debería ser CONTAMINADA")
    passed += 1
    print("Test 2 passed: original no identificado -> CONTAMINADA")
    
    # Test 3: Frase incompleta -> CONTAMINADA
    var datos_frase_incompleta = datos_validos.duplicate()
    datos_frase_incompleta["frase_completa"] = false
    assert(GrabacionOniricaContrato.evaluar_toma(datos_frase_incompleta) == GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA, "Test 3 failed: debería ser CONTAMINADA")
    passed += 1
    print("Test 3 passed: frase incompleta -> CONTAMINADA")
    
    # Test 4: Sujeto en cuadro <= 50% -> CONTAMINADA
    var datos_sujo_menos_50 = datos_validos.duplicate()
    datos_sujo_menos_50["tiempo_sujeto"] = 40.0  # 40% de 100
    assert(GrabacionOniricaContrato.evaluar_toma(datos_sujo_menos_50) == GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA, "Test 4 failed: debería ser CONTAMINADA")
    passed += 1
    print("Test 4 passed: sujeto <= 50% -> CONTAMINADA")
    
    # Test 5: Figura detectó cámara -> CONTAMINADA
    var datos_figura_detecto = datos_validos.duplicate()
    datos_figura_detecto["figura_detecto_camara"] = true
    assert(GrabacionOniricaContrato.evaluar_toma(datos_figura_detecto) == GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA, "Test 5 failed: debería ser CONTAMINADA")
    passed += 1
    print("Test 5 passed: figura detectó cámara -> CONTAMINADA")
    
    # Test 6: Hubo corte -> CONTAMINADA
    var datos_con_corte = datos_validos.duplicate()
    datos_con_corte["hubo_corte"] = true
    assert(GrabacionOniricaContrato.evaluar_toma(datos_con_corte) == GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA, "Test 6 failed: debería ser CONTAMINADA")
    passed += 1
    print("Test 6 passed: hubo corte -> CONTAMINADA")
    
    # Test 7: Duración total <= 0 -> CONTAMINADA (error)
    var datos_duracion_cero = datos_validos.duplicate()
    datos_duracion_cero["duracion_total"] = 0.0
    # We expect an error push, but the function returns CONTAMINADA
    assert(GrabacionOniricaContrato.evaluar_toma(datos_duracion_cero) == GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA, "Test 7 failed: debería ser CONTAMINADA")
    passed += 1
    print("Test 7 passed: duración cero -> CONTAMINADA")
    
    # Test 8: Falta una clave requerida -> CONTAMINADA (error)
    var datos_falta_clave = datos_validos.duplicate()
    datos_falta_clave.erase("original_identificado")
    assert(GrabacionOniricaContrato.evaluar_toma(datos_falta_clave) == GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA, "Test 8 failed: debería ser CONTAMINADA")
    passed += 1
    print("Test 8 passed: falta clave -> CONTAMINADA")
    
    print("Tests passed: %d, failed: %d" % [passed, failed])
    # Exit with code 0 if no failures, else 1
    get_tree().quit(failed)