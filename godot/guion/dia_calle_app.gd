## Corrección visual del trayecto (#277).
##
## La calle no puede construirse como una habitación: la declaración antigua
## reutilizaba el rectángulo interior de Espacio3D y acababa con techo y cuatro
## muros perimetrales, de modo que el exterior se leía como un pasillo.
##
## Esta capa mantiene el contrato de Jornada y recompone únicamente la geometría
## de `trayecto`: planta vacía para no levantar envolvente interior, calzada/aceras
## como bultos bajos, fachadas discontinuas y un único escaparate de televisores
## 3D. Las seis superficies `Pantalla` dispersas desaparecen.
extends "res://guion/dia_onboarding_app.gd"

const VENTANILLA := preload("res://escenas/ventanilla.tscn")

var _ventanas_vivas: CalleVentanasVivas = null
var _viento: VientoAmbiental = null
var _religion_mundo_934: ReligionMundo9343D = null
var _encuentro_real_1889: DiaEncuentroReal1889App = null


func _espacio_de(fase: String) -> Dictionary:
	var espacio: Dictionary = super._espacio_de(fase)
	if fase != "trayecto":
		return espacio

	# Una planta vacía evita que Espacio3D trate la calle como una habitación:
	# no hay techo ni muros automáticos. El suelo y las fachadas se declaran
	# explícitamente debajo, igual que cualquier otro volumen del catálogo.
	espacio.erase("suelo")
	espacio["planta"] = []
	espacio.erase("pantallas")
	espacio["bultos"] = _bultos_calle()
	espacio["ventanas"] = _ventanas_calle()
	return espacio


func _entrar_en(fase: String) -> void:
	super._entrar_en(fase)
	_soltar_capas_calle()
	if fase == "trayecto":
		_montar_persiana_calle()
		TraficoVialCC0.montar(_mundo)
		CochesPsxCC0.montar(_mundo)
		MobiliarioUrbanoCC0.montar(_mundo)
		var calle := CalleIdentidad.montar(_mundo)
		CalleFachadasVivas.montar(calle)
		CalleLocalesComerciales3D.montar(self, calle)
		Bit98Dressing.montar(calle)
		ComercioBarrio3D.montar(self, calle)
		DesvioRefugio3D.montar(calle, jornada)
		_montar_religion_mundo_934()
		_montar_encuentro_real_1889()
		var ventanilla := calle.find_child("EntrarVentanillaReclamaciones", true, false)
		if (
			ventanilla != null
			and not ventanilla.activado.is_connected(_abrir_ventanilla_reclamaciones)
		):
			ventanilla.activado.connect(_abrir_ventanilla_reclamaciones)
		# Diferido a propósito: los árboles CC0 y otros vestidos del trayecto los
		# monta su propio controlador después de esta llamada, y el viento tiene
		# que encontrarlos ya puestos.
		_montar_animacion_ambiental.call_deferred(calle)


## Da de alta lo que se mueve solo en el trayecto. Todo cuelga del mismo
## animador para que compartan presupuesto: si mañana el barrio gana peatones,
## compiten por el cupo en vez de sumarse a él.
func _montar_animacion_ambiental(calle: Node3D) -> void:
	if calle == null or not is_instance_valid(calle) or not calle.is_inside_tree():
		return
	if _mundo == null or _ventanas_vivas != null:
		return
	# El animador lo sirve la capa del sueño, que es el ancestro común: el cupo
	# de piezas es del día entero, no de la calle.
	var animador := animador_ambiental()
	# El desfase de cada pieza sale del día: dos partidas distintas no tienen
	# por qué encontrarse el mismo piso encendido.
	animador.semilla = int(jornada.get("dia", 1))

	_ventanas_vivas = CalleVentanasVivas.new()
	_ventanas_vivas.name = "VentanasVivasCalle"
	add_child(_ventanas_vivas)
	_ventanas_vivas.adoptar(calle, animador)

	_viento = VientoAmbiental.new()
	_viento.name = "VientoCalle"
	add_child(_viento)
	_viento.adoptar(_mundo, animador)
	# `Clima.estado` es una función del día, no un estado aparte: preguntarlo
	# aquí no duplica ninguna fuente de verdad.
	_viento.fijar_clima(Clima.estado(int(jornada.get("dia", 1))))


## Las piezas de la calle mueren con la fase; el animador que las reparte vive
## por encima y lo limpia la capa del sueño.
func _soltar_capas_calle() -> void:
	for capa in [_ventanas_vivas, _viento, _religion_mundo_934, _encuentro_real_1889]:
		if capa != null and is_instance_valid(capa):
			capa.queue_free()
	_ventanas_vivas = null
	_viento = null
	_religion_mundo_934 = null
	_encuentro_real_1889 = null


## #934: el tablón y la mesa se materializan en el recorrido real sin crear
## otra autoridad. La calle solo monta la presentación y persiste cuando el
## componente confirma que ReligionEventos aceptó un hecho nuevo.
func _montar_religion_mundo_934() -> void:
	if _mundo == null or _religion_mundo_934 != null:
		return
	var registro := ReligionEventos.asegurar_en_estado(partida.estado)
	var vertical := ReligionMundo9343D.new()
	vertical.name = "ReligionMundo934Recorrido"
	# El conjunto queda sobre la acera izquierda, paralelo a la fachada y fuera
	# del eje principal de paso. Sus mallas no añaden colisión de mundo.
	vertical.position = Vector3(-4.35, 0.0, 7.4)
	vertical.rotation_degrees.y = 90.0
	_mundo.add_child(vertical)
	(
		vertical
		. configurar(
			registro,
			int(jornada.get("dia", 1)),
			bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false)),
			maxi(1, int(jornada.get("vuelta", 1))),
		)
	)
	vertical.exposicion_registrada.connect(_al_registro_religion_934)
	vertical.practica_registrada.connect(_al_registro_religion_934)
	_religion_mundo_934 = vertical


func _al_registro_religion_934(_id_evento: String) -> void:
	_guardar_o_avisar("")


## #1889: un unico encuentro real y opt-in valida la frontera contextual sin
## convertir el trayecto en un espacio donde se pueda atacar libremente.
func _montar_encuentro_real_1889() -> void:
	if _mundo == null or _encuentro_real_1889 != null:
		return
	var encuentro := DiaEncuentroReal1889App.new()
	encuentro.name = "EncuentroReal1889Recorrido"
	# Fuera del eje principal y del conjunto de #934: se puede ignorar y seguir.
	encuentro.position = Vector3(4.65, 0.0, 4.2)
	_mundo.add_child(encuentro)
	encuentro.configurar(jornada)
	encuentro.combate_solicitado.connect(_abrir_encuentro_real_1889)
	if not combate_real_terminado.is_connected(_resolver_encuentro_real_1889):
		combate_real_terminado.connect(_resolver_encuentro_real_1889)
	_encuentro_real_1889 = encuentro


func _abrir_encuentro_real_1889(objetivo: Dictionary) -> void:
	if _encuentro_real_1889 == null:
		return
	var abierto := abrir_combate_real(objetivo)
	_encuentro_real_1889.marcar_combate_abierto(abierto)


func _resolver_encuentro_real_1889(
	objetivo_id: String, gano: bool, consecuencia: Dictionary
) -> void:
	if _encuentro_real_1889 == null:
		return
	if not _encuentro_real_1889.resolver_resultado(objetivo_id, gano, consecuencia):
		return
	_nomina.text = tr("ENCUENTRO_REAL_1889_VICTORIA" if gano else "ENCUENTRO_REAL_1889_DERROTA")


## El Coliseo de #43 se juega en su propia pantalla; desde la calle se abre
## encima del día, con la misma partida, y al salir se vuelve a andar.
func abrir_ventanilla_reclamaciones() -> void:
	_abrir_ventanilla_reclamaciones(null)


func _abrir_ventanilla_reclamaciones(_actor: Node) -> void:
	if _pantalla != null:
		return
	# Lo pendiente del día queda escrito antes: la Ventanilla guarda por su cuenta.
	if not _guardar_o_avisar(""):
		return
	_caminante.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pantalla = CanvasLayer.new()
	_pantalla.name = "PantallaVentanilla"
	add_child(_pantalla)
	var ventanilla = VENTANILLA.instantiate()
	ventanilla.partida_externa = partida
	ventanilla.cerrada.connect(_cerrar_ventanilla_reclamaciones)
	_pantalla.add_child(ventanilla)


func _cerrar_ventanilla_reclamaciones() -> void:
	if _pantalla == null:
		return
	_pantalla.queue_free()
	_pantalla = null
	_caminante.set_physics_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _montar_persiana_calle() -> void:
	if _mundo == null or _mundo.get_node_or_null("PersianaCalleInteractuable") != null:
		return
	var persiana := PersianaCalleInteractiva3D.new()
	persiana.name = "PersianaCalleInteractuable"
	# Se superpone a la ventana doméstica existente de la fachada derecha. Su
	# posición queda lejos del portal final para no competir con la transición.
	persiana.position = Vector3(5.28, 1.22, -10.0)
	_mundo.add_child(persiana)
	persiana.configurar()


func _bultos_calle() -> Array:
	return [
		# Calzada y dos aceras: la sección transversal ya no es la de un pasillo.
		{
			"pos": Vector3(0, -0.10, 0),
			"tam": Vector3(8.0, 0.20, 34.0),
			"color": Color(0.20, 0.20, 0.22),
			"textura": "asfalto",
		},
		{
			"pos": Vector3(-4.8, 0.02, 0),
			"tam": Vector3(1.6, 0.24, 34.0),
			"color": Color(0.38, 0.37, 0.36),
		},
		{
			"pos": Vector3(4.8, 0.02, 0),
			"tam": Vector3(1.6, 0.24, 34.0),
			"color": Color(0.38, 0.37, 0.36),
		},
		# Fachadas discontinuas, con distintas alturas y retranqueos. Dejan cielo
		# visible entre edificios y rompen la lectura de corredor uniforme. El
		# revoco CC0 ya versionado evita que sigan siendo bloques de color plano.
		{
			"pos": Vector3(-6.3, 4.5, -12.65),
			"tam": Vector3(2.2, 9.0, 9.3),
			"color": Color(0.31, 0.27, 0.25),
			"textura": "gotele",
		},
		{
			"pos": Vector3(-6.7, 5.5, 10.15),
			"tam": Vector3(2.4, 11.0, 12.3),
			"color": Color(0.27, 0.28, 0.31),
			"textura": "gotele",
		},
		# La fachada derecha deja un hueco real en planta baja para Bit 98.
		# El volumen alto conserva el edificio; los dos paños bajos enmarcan el
		# local sin poner un muro opaco detrás de su cristal.
		{
			"pos": Vector3(6.5, 6.5, -10.65),
			"tam": Vector3(2.0, 7.0, 13.3),
			"color": Color(0.30, 0.29, 0.27),
			"textura": "gotele",
		},
		{
			"pos": Vector3(6.5, 1.5, -12.9),
			"tam": Vector3(2.0, 3.0, 8.8),
			"color": Color(0.30, 0.29, 0.27),
			"textura": "gotele",
		},
		{
			"pos": Vector3(6.5, 1.5, -4.25),
			"tam": Vector3(2.0, 3.0, 0.5),
			"color": Color(0.30, 0.29, 0.27),
			"textura": "gotele",
		},
		{
			"pos": Vector3(6.8, 4.0, 10.15),
			"tam": Vector3(2.5, 8.0, 12.3),
			"color": Color(0.26, 0.25, 0.27),
			"textura": "gotele",
		},
		# Plantas altas sobre la tienda de electrodomésticos.
		{
			"pos": Vector3(-6.65, 6.4, -1.5),
			"tam": Vector3(2.4, 6.0, 7.0),
			"color": Color(0.29, 0.27, 0.26),
			"textura": "gotele",
		},
		# Tienda de electrodomésticos: fondo y marco dejan un hueco real entre
		# fachada y cristal, de modo que las televisiones son visibles dentro del
		# escaparate y no un dibujo pegado por fuera.
		{
			"pos": Vector3(-6.65, 1.70, -1.5),
			"tam": Vector3(0.35, 3.40, 7.0),
			"color": Color(0.24, 0.22, 0.21),
			"textura": "gotele",
		},
		{
			"pos": Vector3(-5.58, 0.35, -1.5),
			"tam": Vector3(0.22, 0.70, 7.0),
			"color": Color(0.18, 0.17, 0.18),
			"textura": "metal_pintado",
		},
		{
			"pos": Vector3(-5.58, 2.85, -1.5),
			"tam": Vector3(0.22, 0.55, 7.0),
			"color": Color(0.18, 0.17, 0.18),
			"textura": "metal_pintado",
		},
		{
			"pos": Vector3(-5.58, 1.60, -4.9),
			"tam": Vector3(0.22, 2.0, 0.22),
			"color": Color(0.18, 0.17, 0.18),
			"textura": "metal_pintado",
		},
		{
			"pos": Vector3(-5.58, 1.60, 1.9),
			"tam": Vector3(0.22, 2.0, 0.22),
			"color": Color(0.18, 0.17, 0.18),
			"textura": "metal_pintado",
		},
		# Portal de destino: marco alto y separado del resto de fachadas para que
		# desde el spawn exista una composición clara hacia casa.
		{
			"pos": Vector3(-1.15, 1.55, 15.8),
			"tam": Vector3(0.45, 3.1, 0.55),
			"color": Color(0.42, 0.38, 0.32),
			"textura": "gotele",
		},
		{
			"pos": Vector3(1.15, 1.55, 15.8),
			"tam": Vector3(0.45, 3.1, 0.55),
			"color": Color(0.42, 0.38, 0.32),
			"textura": "gotele",
		},
		{
			"pos": Vector3(0, 2.95, 15.8),
			"tam": Vector3(2.75, 0.35, 0.55),
			"color": Color(0.42, 0.38, 0.32),
			"textura": "gotele",
		},
	]


func _ventanas_calle() -> Array:
	return [
		# El paño del escaparate es cristal translúcido de CalleIdentidad: un
		# cristal opaco tapaba los televisores que la tienda tiene que enseñar.
		# Ventanas domésticas puntuales: repetición irregular, no paneles de TV.
		{
			"pos": Vector3(5.42, 1.85, -10.0),
			"tam": Vector3(0.08, 1.05, 1.35),
			"color": Color(0.13, 0.15, 0.18),
		},
		{
			"pos": Vector3(5.52, 1.55, 6.2),
			"tam": Vector3(0.08, 0.90, 1.15),
			"color": Color(0.16, 0.13, 0.10),
		},
	]
