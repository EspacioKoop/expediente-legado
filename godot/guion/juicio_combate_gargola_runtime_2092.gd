## Adaptador mecanico de la Gargola de Umbral (#2177 / #2092).
##
## Compone BLOQUEADOR y EMBESTIDOR sin crear una tercera politica. El diccionario
## `estado` es opaco para el host: fuera de el solo se proyectan las senales
## necesarias para presentacion/wiring.
class_name JuicioCombateGargolaRuntime2092
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const EMBESTIDOR = preload("res://guion/juicio_combate_embestidor_3d.gd")

const MODO_BLOQUEADOR := "bloqueador"
const MODO_EMBESTIDOR := "embestidor"


static func nuevo(raiz: int, indice: int = 0) -> Dictionary:
	return {
		"_raiz": raiz,
		"_indice": indice,
		"modo": MODO_BLOQUEADOR,
		"bloqueador": ARQUETIPOS.nuevo(ARQUETIPOS.BLOQUEADOR, raiz, indice),
		"embestidor": ARQUETIPOS.nuevo(ARQUETIPOS.EMBESTIDOR, raiz, indice),
	}


static func avanzar(
	estado: Dictionary,
	delta: float,
	distancia: float,
	rumbo_objetivo: float,
	flanqueado: bool = false,
	guardia_rota: bool = false,
	linea_libre: bool = true,
	choque: bool = false,
) -> Dictionary:
	var copia := estado.duplicate(true)
	if copia.is_empty():
		copia = nuevo(0)

	if String(copia.get("modo", MODO_BLOQUEADOR)) == MODO_EMBESTIDOR:
		return _avanzar_embestidor(
			copia,
			delta,
			distancia,
			rumbo_objetivo,
			linea_libre,
			choque,
		)

	var bloqueador: Dictionary = copia.get("bloqueador", {})
	var paso_bloqueador := ARQUETIPOS.avanzar(
		bloqueador,
		delta,
		{"flanqueado": flanqueado, "guardia_rota": guardia_rota},
	)
	bloqueador = paso_bloqueador.get("unidad", bloqueador)
	copia["bloqueador"] = bloqueador

	# La unica puerta a EMBESTIDOR es una apertura real de BLOQUEADOR.
	# Se inicializa el telegraph con delta 0 para no consumir dos veces el mismo tick.
	if String(bloqueador.get("estado", "")) == ARQUETIPOS.APERTURA:
		copia["modo"] = MODO_EMBESTIDOR
		return _avanzar_embestidor(
			copia,
			0.0,
			distancia,
			rumbo_objetivo,
			linea_libre,
			false,
		)

	return _salida(
		copia,
		MODO_BLOQUEADOR,
		String(paso_bloqueador.get("telegraph", "")),
		String(bloqueador.get("estado", "")) == ARQUETIPOS.GUARDIA,
		false,
		false,
	)


static func _avanzar_embestidor(
	estado: Dictionary,
	delta: float,
	distancia: float,
	rumbo_objetivo: float,
	linea_libre: bool,
	choque: bool,
) -> Dictionary:
	var embestidor: Dictionary = estado.get("embestidor", {})
	var estado_anterior := String(embestidor.get("estado", ""))
	var distancia_segura := maxf(0.0, distancia)
	var posicion_rival := Vector3.ZERO
	var posicion_jugador := Vector3(
		sin(rumbo_objetivo) * distancia_segura,
		0.0,
		cos(rumbo_objetivo) * distancia_segura,
	)
	var paso := EMBESTIDOR.avanzar(
		embestidor,
		delta,
		posicion_rival,
		posicion_jugador,
		linea_libre,
		choque,
	)
	embestidor = paso.get("unidad", embestidor)
	estado["embestidor"] = embestidor
	var estado_nuevo := String(embestidor.get("estado", ""))

	# Solo se recupera la guardia cuando RECUPERAR ha terminado por la politica
	# EMBESTIDOR. Nunca hay re-bloqueo en el tick que abre la ventana.
	if estado_anterior == ARQUETIPOS.RECUPERAR and estado_nuevo == ARQUETIPOS.REPOSICIONAR:
		var raiz := int(estado.get("_raiz", 0))
		var indice := int(estado.get("_indice", 0))
		estado["bloqueador"] = ARQUETIPOS.nuevo(ARQUETIPOS.BLOQUEADOR, raiz, indice)
		estado["modo"] = MODO_BLOQUEADOR
		return _salida(estado, MODO_BLOQUEADOR, "guardia", true, false, false)

	return _salida(
		estado,
		MODO_EMBESTIDOR,
		String(paso.get("telegraph", "")),
		false,
		bool(paso.get("inicio_carga", false)),
		bool(paso.get("abrir_ventana", false)),
	)


static func _salida(
	estado: Dictionary,
	modo: String,
	telegraph: String,
	guardia_frontal: bool,
	inicio_carga: bool,
	abrir_ventana: bool,
) -> Dictionary:
	return {
		"estado": estado,
		"modo": modo,
		"telegraph": telegraph,
		"guardia_frontal": guardia_frontal,
		"inicio_carga": inicio_carga,
		"abrir_ventana": abrir_ventana,
	}
