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
		var ventanilla := calle.find_child("EntrarVentanillaReclamaciones", true, false)
		if (
			ventanilla != null
			and not ventanilla.activado.is_connected(_abrir_ventanilla_reclamaciones)
		):
			ventanilla.activado.connect(_abrir_ventanilla_reclamaciones)


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
