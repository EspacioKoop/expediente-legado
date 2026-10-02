## Adaptador runtime puro del Enjambre (#2120).
##
## Delega la lógica de ticks y creación al coordinador en `JuicioCombateArquetipoHost`.
## Mantiene el estado de las unidades y expone los resultados del enjambre sin
## tocar el host ni emitir desenlaces.
class_name JuicioCombateEnjambreRuntime
extends RefCounted

## Referencias a la política de arquetipos para constantes de estado y telegraph.
const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")

## Unidades activas del enjambre.
var unidades: Array = []

## Presupuesto de ataques simultáneos permitido para este runtime.
var presupuesto: int = ARQUETIPOS.ENJAMBRE_PRESUPUESTO_ATAQUES


## Inicializa el enjambre usando el host.
func crear(raiz: int, cantidad: int = 2) -> void:
	unidades = JuicioCombateArquetipoHost.nuevo_enjambre(raiz, cantidad)


## Avanza un tick del enjambre delegando al coordinador.
## Devuelve los resultados del tick y la lista de atacantes activos.
func tick(delta: float) -> Dictionary:
	var paso := JuicioCombateArquetipoHost.avanzar_enjambre(unidades, delta, presupuesto)
	unidades = paso.get("unidades", [])
	return {
		"resultados": paso.get("resultados", []),
		"atacantes_activos": paso.get("atacantes_activos", 0)
	}


## Expone qué índices del enjambre muestran el telegraph de ataque corto.
func get_telegraphs() -> Array:
	var indices := []
	for i in range(unidades.size()):
		var unidad := unidades[i]
		if String(unidad.get("estado", "")) == ARQUETIPOS.TELEGRAFIAR:
			indices.append(i)
	return indices


## Devuelve los índices de las unidades que siguen vivas (determinación > 0).
func get_vivos() -> Array:
	var vivos := []
	for i in range(unidades.size()):
		if int(unidades[i].get("determinacion", 0)) > 0:
			vivos.append(i)
	return vivos


## Elimina explícitamente unidades derrotadas basándose en índices.
func eliminar_unidades(indices: Array) -> void:
	var nuevas_unidades := []
	for i in range(unidades.size()):
		if not indices.has(i):
			nuevas_unidades.append(unidades[i])
	unidades = nuevas_unidades
