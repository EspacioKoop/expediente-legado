## Variante instrumentada del Juicio por Combate para playtest de #912.
##
## Hereda las reglas reales y solo añade contadores en memoria. No escribe en
## Partida/Jornada, no cambia números de balance y nunca se instancia desde el
## runtime normal del juego.
class_name JuicioCombatePlaytest912
extends JuicioCombate3D

var _duracion_playtest := 0.0
var _resultado_playtest := "en_curso"
var _metricas_playtest := {
	"determinacion_perdida": 0,
	"ligeros_conectados": 0,
	"fuertes_conectados": 0,
	"esquivas_utiles": 0,
	"interrupciones": 0,
	"contraataques": 0,
	"retornos": 0,
}


func _process(delta: float) -> void:
	if not _acabado:
		_duracion_playtest += delta
	super._process(delta)


func abandonar() -> void:
	if not _acabado:
		_resultado_playtest = "abandono"
	super.abandonar()


func _resolver_ataque_rival() -> void:
	var hacia := _jugador.position - _rival.position
	hacia.y = 0.0
	var resultado := resultado_ataque_rival(hacia.length(), _esquiva)
	var determinacion_antes := _determinacion_jugador
	super._resolver_ataque_rival()
	if resultado == "esquiva":
		_metricas_playtest["esquivas_utiles"] += 1
	elif resultado == "impacto":
		_metricas_playtest["determinacion_perdida"] += maxi(
			0, determinacion_antes - _determinacion_jugador
		)


func _atacar(dano_base: int, alcance: float, recarga: float, fuerte: bool) -> void:
	var hacia := _rival.position - _jugador.position
	hacia.y = 0.0
	var conectado := not _acabado and _recarga_jugador <= 0.0 and hacia.length() <= alcance
	var interrumpia := conectado and interrumpe_ataque(fuerte, _ataque_rival_pendiente, _ritual)
	var usaba_contra := conectado and _contraataque > 0
	super._atacar(dano_base, alcance, recarga, fuerte)
	if not conectado:
		return
	var clave := "fuertes_conectados" if fuerte else "ligeros_conectados"
	_metricas_playtest[clave] += 1
	if interrumpia:
		_metricas_playtest["interrupciones"] += 1
	if usaba_contra:
		_metricas_playtest["contraataques"] += 1


func _intentar_retorno_rival() -> bool:
	var retornos_antes := _retornos_rival
	var retorno := super._intentar_retorno_rival()
	if retorno and _retornos_rival > retornos_antes:
		_metricas_playtest["retornos"] += 1
	return retorno


func _terminar(gano: bool, inmediato: bool = false) -> void:
	if not _acabado and _resultado_playtest == "en_curso":
		_resultado_playtest = "victoria" if gano else "derrota"
	super._terminar(gano, inmediato)


func resumen_playtest() -> Dictionary:
	var resumen := _metricas_playtest.duplicate(true)
	resumen["duracion_segundos"] = _duracion_playtest
	resumen["resultado"] = _resultado_playtest
	resumen["ritual_id"] = String(_ritual.get("id", "base"))
	if resumen["ritual_id"].is_empty():
		resumen["ritual_id"] = "base"
	resumen["determinacion_jugador_final"] = _determinacion_jugador
	resumen["determinacion_rival_final"] = _determinacion_rival
	return resumen
