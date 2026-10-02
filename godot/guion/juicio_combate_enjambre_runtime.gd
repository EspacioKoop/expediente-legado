class_name JuicioCombateEnjambreRuntime
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const HOST = preload("res://guion/juicio_combate_arquetipo_host.gd")


## Adaptador puro de tick para el enjambre.
## Delegue en JuicioCombateArquetipoHost.avanzar_enjambre() y expone índices
## de transición de estado para el host.
static func tick(unidades: Array, delta: float, presupuesto: int) -> Dictionary:
	var nuevas := unidades.duplicate(true)
	var vivas := []
	var indices_vivos: Array[int] = []
	for i in range(unidades.size()):
		var unidad = unidades[i]
		if unidad is Dictionary and int(unidad.get("determinacion", 0)) > 0:
			vivas.append(unidad)
			indices_vivos.append(i)

	var paso := HOST.avanzar_enjambre(vivas, delta, presupuesto)
	var nuevas_vivas: Array = paso.get("unidades", [])
	var resultados_vivos: Array = paso.get("resultados", [])
	var resultados: Array = []
	resultados.resize(unidades.size())
	resultados.fill({})

	var inicio_ataque := []
	var abrir_ventana := []
	for local in range(indices_vivos.size()):
		var indice := indices_vivos[local]
		var anterior: Dictionary = unidades[indice]
		var nueva: Dictionary = nuevas_vivas[local]
		nuevas[indice] = nueva
		if local < resultados_vivos.size():
			resultados[indice] = resultados_vivos[local]

		var estado_anterior := String(anterior.get("estado", ""))
		var estado_nuevo := String(nueva.get("estado", ""))
		if estado_nuevo == ARQUETIPOS.ATACAR and estado_anterior != ARQUETIPOS.ATACAR:
			inicio_ataque.append(indice)
		if estado_nuevo == ARQUETIPOS.RECUPERAR and estado_anterior != ARQUETIPOS.RECUPERAR:
			abrir_ventana.append(indice)

	return {
		"unidades": nuevas,
		"resultados": resultados,
		"atacantes_activos": int(paso.get("atacantes_activos", 0)),
		"inicio_ataque": inicio_ataque,
		"abrir_ventana": abrir_ventana,
	}
