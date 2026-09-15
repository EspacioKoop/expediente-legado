## Inicio de jornada: dos miradas a la oficina antes de devolver el control.
##
## No avanza el día ni calcula economía: recibe una Jornada ya resuelta y solo
## la representa. Desde #395 rueda en 3D dentro del archivo real —el corcho de
## conceptos y el terminal del puesto propio— en vez de una ficha de
## rectángulos; el marcador persistente y el llamante no cambian.
class_name InicioJornadaCinematica
extends RefCounted

const ID := "inicio-jornada"

## El corcho de conceptos (`Corcho3D.POSICION`) y el terminal SIGA del puesto
## propio (`EspaciosCatalogo.OFICINA`). Se repiten aquí como datos del plano:
## el reproductor no sabe qué es un corcho.
const CORCHO := Vector3(0.0, 1.55, -3.42)
const TERMINAL := Vector3(-4.3, 1.0, -2.1)


## Los datos exactos que se presentan. Separarlos de los planos permite probar
## que la cinemática mira el estado real y no mantiene otro contador paralelo.
static func datos_de(jornada: Dictionary) -> Dictionary:
	return {
		"dia": int(jornada.get("dia", 1)),
		"dinero": int(jornada.get("dinero", 0)),
		"acciones": int(jornada.get("acciones", 0)),
		"gato": bool(jornada.get("gato", {}).get("presente", false)),
	}


## Identidad persistente de una jornada. Incluye la vuelta: el día 1 de una
## reasignación es otro comienzo aunque comparta número con el primer día.
static func marca_de(jornada: Dictionary) -> String:
	return "%d:%d" % [int(jornada.get("vuelta", 1)), int(jornada.get("dia", 1))]


## Dos planos y 3,4 s en la primera vista: lo justo para leer un rótulo sobre
## un sitio que se reconoce. Al repetirse, el reproductor común los acorta; el
## segundo es el remate y conserva el suelo común de #67.
static func planos_de(jornada: Dictionary, vistas: int = 0) -> Array:
	var datos := datos_de(jornada)
	var rodaje := Cinematica.resolver(planos(), {}, vistas)
	# Reutiliza el texto ya traducido del día en vez de duplicarlo en el CSV.
	rodaje[0]["rotulo"] = TranslationServer.translate("DIA_NUEVO") % datos["dia"]
	rodaje[1]["voz"] = (
		TranslationServer.translate("INICIO_JORNADA_ESTADO")
		% [
			datos["dinero"],
			datos["acciones"],
			TranslationServer.translate("INICIO_JORNADA_GATO") if datos["gato"] else "",
		]
	)
	return rodaje


static func planos() -> Array:
	return [
		{
			# El día se lee delante del corcho: lo que se ha ido entendiendo
			# del archivo sigue clavado donde se dejó ayer.
			"tipo": "3d",
			"nombre": "corcho",
			"camara": Vector3(-0.2, 1.9, 3.3),
			"mira": CORCHO,
			"segundos": 1.6,
		},
		{
			# Y el trabajo espera en el puesto propio, con el terminal encendido.
			"tipo": "3d",
			"nombre": "puesto",
			"camara": Vector3(-2.7, 1.5, 0.3),
			"mira": TERMINAL,
			"segundos": 1.8,
		},
	]
