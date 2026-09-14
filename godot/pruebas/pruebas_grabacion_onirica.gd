## Test suite for GrabacionOniricaContrato
## Verifies the deterministic evaluation of dream recording takes.
class_name PruebasGrabacionOnirica
extends RefCounted

static func todo(comprobar: Callable) -> void:
    # Ensure the contract script is loaded and the class is registered
    if ClassDB.get_class("GrabacionOniricaContrato") == null:
        var contract_script = load("res://guion/grabacion_onirica_contrato.gd")
        if contract_script == null:
            push_error("Failed to load contract script")
            return
    
    var GrabacionOniricaContrato = ClassDB.get_class("GrabacionOniricaContrato")
    if GrabacionOniricaContrato == null:
        push_error("Class GrabacionOniricaContrato not found in ClassDB")
        return

    # Test 1: Todas las condiciones válidas -> VALIDA
    var datos_validos = {
        "original_identificado": true,
        "frase_completa": true,
        "tiempo_sujeto": 60.0,
        "duracion_total": 100.0,
        "figura_detecto_camara": false,
        "hubo_corte": false
    }
    comprobar.call("Test 1: condiciones válidas -> VALIDA", GrabacionOniricaContrato.evaluar_toma(datos_validos), GrabacionOniricaContrato.ESTADO_GRABACION_VALIDA)
    
    # Test 2: Original no identificado -> CONTAMINADA
    var datos_no_identificado = datos_validos.duplicate()
    datos_no_identificado["original_identificado"] = false
    comprobar.call("Test 2: original no identificado -> CONTAMINADA", GrabacionOniricaContrato.evaluar_toma(datos_no_identificado), GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA)
    
    # Test 3: Frase incompleta -> CONTAMINADA
    var datos_frase_incompleta = datos_validos.duplicate()
    datos_frase_incompleta["frase_completa"] = false
    comprobar.call("Test 3: frase incompleta -> CONTAMINADA", GrabacionOniricaContrato.evaluar_toma(datos_frase_incompleta), GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA)
    
    # Test 4: Sujeto en cuadro <= 50% -> CONTAMINADA
    var datos_sujo_menos_50 = datos_validos.duplicate()
    datos_sujo_menos_50["tiempo_sujeto"] = 40.0  # 40% of 100
    comprobar.call("Test 4: sujeto <= 50% -> CONTAMINADA", GrabacionOniricaContrato.evaluar_toma(datos_sujo_menos_50), GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA)
    
    # Test 5: Figura detectó cámara -> CONTAMINADA
    var datos_figura_detecto = datos_validos.duplicate()
    datos_figura_detecto["figura_detecto_camara"] = true
    comprobar.call("Test 5: figura detectó cámara -> CONTAMINADA", GrabacionOniricaContrato.evaluar_toma(datos_figura_detecto), GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA)
    
    # Test 6: Hubo corte -> CONTAMINADA
    var datos_con_corte = datos_validos.duplicate()
    datos_con_corte["hubo_corte"] = true
    comprobar.call("Test 6: hubo corte -> CONTAMINADA", GrabacionOniricaContrato.evaluar_toma(datos_con_corte), GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA)
    
    # Test 7: Duración total <= 0 -> CONTAMINADA (error)
    var datos_duracion_cero = datos_validos.duplicate()
    datos_duracion_cero["duracion_total"] = 0.0
    comprobar.call("Test 7: duración cero -> CONTAMINADA", GrabacionOniricaContrato.evaluar_toma(datos_duracion_cero), GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA)
    
    # Test 8: Falta una clave requerida -> CONTAMINADA (error)
    var datos_falta_clave = datos_validos.duplicate()
    datos_falta_clave.erase("original_identificado")
    comprobar.call("Test 8: falta clave -> CONTAMINADA", GrabacionOniricaContrato.evaluar_toma(datos_falta_clave), GrabacionOniricaContrato.ESTADO_GRABACION_CONTAMINADA)