## Adaptador mecánico del Constructor demiúrgico (#2089/#2350).
##
## No implementa cosmología, arte, spawn ni daño. Traduce el contexto mínimo al
## arquetipo CONSTRUCTOR y expone sus señales para que un host posterior decida
## cómo materializar un auxiliar usando la autoridad común de combate.
class_name JuicioCombateConstructorDemiurgicoRuntime2089
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")


static func nuevo(raiz: int, indice: int = 0) -> Dictionary:
	return ARQUETIPOS.nuevo(ARQUETIPOS.CONSTRUCTOR, raiz, indice)


static func avanzar(
	unidad: Dictionary,
	delta: float,
	auxiliares_activos: int,
	limite_auxiliares: int = -1,
	reduccion_movimiento: bool = false,
) -> Dictionary:
	var limite := (
		ARQUETIPOS.CONSTRUCTOR_LIMITE_AUXILIARES if limite_auxiliares < 0 else limite_auxiliares
	)
	limite = clampi(limite, 0, ARQUETIPOS.CONSTRUCTOR_LIMITE_AUXILIARES)
	var paso := (
		ARQUETIPOS
		. avanzar(
			unidad,
			delta,
			{
				"auxiliares_activos": maxi(0, auxiliares_activos),
				"limite_auxiliares": limite,
			},
		)
	)
	var intencion := String(paso.get("intencion", ""))
	return {
		"unidad": paso.get("unidad", {}).duplicate(true),
		"intencion": intencion,
		"telegraph": String(paso.get("telegraph", "")),
		"ventana_respuesta": bool(paso.get("ventana_respuesta", false)),
		"crear_auxiliar": intencion == "crear_auxiliar",
		"presentacion": ARQUETIPOS.presentacion(paso, reduccion_movimiento),
	}
