## Contrato de grabación onírica: evalúa la validez de una toma según las reglas deterministas.
## No depende de la adquisición de la cámara, UI, puesta en escena o experiencia del Camarógrafo Onírico.
class_name GrabacionOniricaContrato
extends RefCounted

# Resultado de la evaluación
enum EstadoGrabacion { VALIDA, CONTAMINADA }

## Evalúa una toma y devuelve su estado.
## Parámetros:
##   datos: Diccionario con las siguientes claves:
##     - original_identificado: bool (¿el original que deforma está identificado por conocimiento diurno?)
##     - frase_completa: bool (¿la toma captura la frase completa?)
##     - tiempo_sujeto: float (segundos que el sujeto permanece en cuadro)
##     - duracion_total: float (duración total de la toma en segundos, debe ser >0)
##     - figura_detecto_camara: bool (¿la figura détectó la cámara?)
##     - hubo_corte: bool (¿hubo corte o interrupción durante la toma?)
## Retorna:
##   EstadoGrabacion.VALIDA si se cumplen todas las reglas, EstadoGrabacion.CONTAMINADA en caso contrario.
func evaluar_toma(datos: Dictionary) -> EstadoGrabacion:
    # Validar presenza de claves esenciales
    var requeridas = ["original_identificado", "frase_completa", "tiempo_sujeto", "duracion_total", "figura_detecto_camara", "hubo_corte"]
    for clave in requeridas:
        if not datos.has(clave):
            push_error("Falta clave requerida en datos de toma: %s" % clave)
            return EstadoGrabacion.CONTAMINADA
    
    # Extraer valores
    var original_identificado = datos["original_identificado"]
    var frase_completa = datos["frase_completa"]
    var tiempo_sujeto = float(datos["tiempo_sujeto"])
    var duracion_total = float(datos["duracion_total"])
    var figura_detecto_camara = datos["figura_detecto_camara"]
    var hubo_corte = datos["hubo_corte"]
    
    # Validar duracion_total positiva
    if duracion_total <= 0:
        push_error("duracion_total debe ser positiva")
        return EstadoGrabacion.CONTAMINADA
    
    # Calcular porcentaje de sujeto en cuadro
    var sujeto_en_cuadro_porcentaje = (tiempo_sujeto / duracion_total) * 100.0
    
    # Aplicar reglas
    if not original_identificado:
        return EstadoGrabacion.CONTAMINADA
    if not frase_completa:
        return EstadoGrabacion.CONTAMINADA
    if sujeto_en_cuadro_porcentaje <= 50.0:
        return EstadoGrabacion.CONTAMINADA
    if figura_detecto_camara:
        return EstadoGrabacion.CONTAMINADA
    if hubo_corte:
        return EstadoGrabacion.CONTAMINADA
    
    # Todas las reglas satisfechas
    return EstadoGrabacion.VALIDA