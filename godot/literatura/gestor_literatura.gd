extends Node

# Autoload: GestorLiteratura
signal obra_conocida(obra_id)

var obras: Array = []
var obras_conocidas: Array = []
var autores_conocidos: Array = []
# Compatibilidad temporal con consumidores previos. El contrato #1176 no
# incrementa estos contadores al conocer una obra.
var insight_total: int = 0
var momentum_bonus: float = 0.0
var registro_literario: Dictionary = LiteraturaEventos.nuevo()


func _ready() -> void:
	_cargar_catalogo()


func _cargar_catalogo() -> void:
	var archivo := FileAccess.open("res://datos/literatura/obras.json", FileAccess.READ)
	if archivo == null:
		return
	var data = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	if not (data is Dictionary):
		return
	var obras_data = data.get("obras", [])
	obras = obras_data if obras_data is Array else []


func conocer_obra(
	obra_id: String,
	fuente: String = "legacy:gestor_literatura",
	contexto: String = "compatibilidad",
	jornada: int = 0
) -> bool:
	var id := obra_id.strip_edges()
	if id.is_empty():
		return false

	var evento := (
		LiteraturaEventos
		. crear_evento(
			"conocimiento:legacy:%s" % id,
			LiteraturaEventos.CANAL_CONOCIMIENTO,
			id,
			fuente,
			contexto,
			jornada,
			["legacy"],
		)
	)
	if not LiteraturaEventos.registrar(registro_literario, evento):
		return false

	if id not in obras_conocidas:
		obras_conocidas.append(id)
	obra_conocida.emit(id)
	return true


## Productor explicito para interacciones que SI alcanzan el umbral de lectura
## significativa de #1176. A diferencia de conocer_obra(), este metodo puede
## registrar insight porque el llamador aporta progreso y fuente concretos.
func registrar_lectura_significativa(
	obra_id: String, fuente: String, jornada: int = 0, progreso_normalizado: float = 1.0
) -> Dictionary:
	var resultado := (
		LiteraturaLectura
		. registrar_interaccion(
			registro_literario,
			obra_id,
			fuente,
			jornada,
			progreso_normalizado,
		)
	)
	if bool(resultado.get("conocimiento_nuevo", false)) and obra_id not in obras_conocidas:
		obras_conocidas.append(obra_id)
		obra_conocida.emit(obra_id)
	return resultado


## Puente del autoload hacia el consumidor puro de #1183. El consumidor calcula
## coste y modificador; quien invoque este método decide cómo aplicar el coste.
func ejecutar_ritual_cita(
	obra_id: String,
	fuente: String,
	encuentro_id: String,
	jornada: int = 0,
	momentum_actual: float = 0.0
) -> Dictionary:
	return (
		LiteraturaConflicto
		. ejecutar_cita(
			registro_literario,
			obra_id,
			fuente,
			encuentro_id,
			jornada,
			momentum_actual,
		)
	)


func obtener_registro_literario() -> Dictionary:
	return registro_literario.duplicate(true)


## Entrada para observers externos (#1179). Por diseño rechaza conocimiento:
## ningún minijuego o handshake puede sustituir una lectura significativa.
func registrar_evento_externo(evento: Dictionary) -> bool:
	if String(evento.get("canal", "")) == LiteraturaEventos.CANAL_CONOCIMIENTO:
		return false
	return LiteraturaEventos.registrar(registro_literario, evento)


func obtener_insight_total() -> int:
	return insight_total


func obtener_momentum_bonus() -> float:
	return momentum_bonus


func _obtener_efecto_obra(obra_id: String) -> Dictionary:
	if obras.is_empty():
		_cargar_catalogo()
	for obra in obras:
		if obra is Dictionary and String(obra.get("id", "")) == obra_id:
			var efecto = obra.get("efecto", {})
			return efecto if efecto is Dictionary else {}
	return {}


func _arquetipo_desbloqueado(id: String):
	var arquetipo = GestorArquetipos.obtener_arquetipo(id)
	if arquetipo == null or not bool(arquetipo.desbloqueado):
		return null
	return arquetipo


# Compatibilidad para consumidores explícitos de gameplay. Conocer una obra no
# llama estas funciones: el efecto debe activarse desde un ritual/conflicto.
func _aplicar_efecto_especial(_obra_id: String, efecto: String) -> void:
	match efecto:
		"revelacion":
			var persona = _arquetipo_desbloqueado("persona")
			if persona != null:
				GestorArquetipos.ganar_insight(20)
				persona.efecto_combate["evasion_temporal"] = 0.3
		"transformacion":
			var sombra = _arquetipo_desbloqueado("sombra")
			if sombra != null:
				sombra.efecto_combate["bonus_crit"] = (
					float(sombra.efecto_combate.get("bonus_crit", 0.0)) + 0.1
				)
		"no_linealidad":
			if _arquetipo_desbloqueado("self") != null:
				GestorArquetipos.ganar_insight(15)
		"ciclos_temporales":
			GestorMomentum.momentum_actual = min(
				GestorMomentum.momentum_max,
				GestorMomentum.momentum_actual + 15,
			)
		"corriente_conciencia":
			GestorArquetipos.ganar_insight(30)
			GestorMomentum.momentum_actual = max(0, GestorMomentum.momentum_actual - 20)


func _aplicar_cita_especial(_obra_id: String, efecto: String) -> void:
	match efecto:
		"revelacion":
			print("Revelacion: debilidad enemiga expuesta - Anima cura aliados")
			if _arquetipo_desbloqueado("anima") != null:
				pass
		"transformacion":
			print("Transformacion: forma alternativa activada - Sombra desatada")
			if _arquetipo_desbloqueado("sombra") != null:
				GestorMomentum.ejecutar_finisher("super")
		"no_linealidad":
			print("No linealidad: combos desordenados temporalmente - Persona adapta")
		"ciclos_temporales":
			print("Ciclos temporales: momentum regenera rapido")
			GestorMomentum.decay_rate = 2.0
		"corriente_conciencia":
			print("Corriente de conciencia: insight instantaneo")
			GestorArquetipos.ganar_insight(50)
