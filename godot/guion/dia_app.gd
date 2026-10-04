## El día: la pantalla que lo hila.
##
## Monta el espacio de la fase actual, escucha sus salidas y avanza la jornada.
## No sabe qué hay en ninguna sala —eso es `EspaciosCatalogo`— ni qué significa
## avanzar —eso es `Jornada`—: aquí solo se pega una cosa con la otra.
extends Node3D

signal combate_real_terminado(objetivo_id: String, gano: bool, consecuencia: Dictionary)

const SELLO_FIRMA_SIN_PRISA := "firma-sin-prisa"
const SELLO_REINCORPORACION := "reincorporacion-administrativa"
const SELLO_DESPERTAR_REGLAMENTARIO := "despertar-reglamentario"
const DIA_ESPACIOS_APP = preload("res://guion/dia_espacios_app.gd")
const DIA_TRANSICION_APP = preload("res://guion/dia_transicion_app.gd")
const DIA_EXPEDIENTE_APP = preload("res://guion/dia_expediente_app.gd")

var partida := Partida.new()
var contenido := Contenido.new()
var jornada: Dictionary = {}

var _caminante: CharacterBody3D
var _mundo: Node3D
var _rotulo: Label
var _nomina: Label

## #1761: el helper posee el destino de un tránsito que quedó a medias por
## fallo de guardado. DiaApp conserva los wrappers porque son contrato de la
## cadena dia_* y de numerosos controladores.
var _guardado := DiaGuardadoApp.new()
var _presentacion := DiaPresentacionApp.new()
var _borrar: Button
var _borrar_confirmando := false
var _pantalla: CanvasLayer
## Los rótulos del día. Se guarda para poder apagarlos mientras se pone la
## entrada de la vuelta.
var _hud: CanvasLayer
## La entrada de la vuelta mientras se está poniendo (#68). Fuera de ella es
## nula: el reproductor se descarta al terminar en vez de quedarse escuchando.
var _ciclo_laboral := DiaCicloLaboralApp.new()
## Compatibilidad para la cadena de herencia dia_* y las herramientas de captura.
## El estado real pertenece a DiaCicloLaboralApp.
var _entrada: Node3D:
	get:
		return _ciclo_laboral.entrada

## El sitio montado ahora mismo, tal como se construyó. Las cinemáticas que
## ruedan dentro de él (#395) lo leen en vez de volver a pedirlo: en el sueño
## pedirlo otra vez apuntaría la sala en el mapa por segunda vez.
var _espacio_actual: Dictionary = {}
var _ambiente: Environment
var _sol: DirectionalLight3D
var _voz: AudioStreamPlayer
var _pisada: AudioStreamPlayer3D
## Si lo que se lee ahora mismo es algo que dijo alguien. Lo que dice un
## compañero es de la oficina y del momento: llevárselo a la calle o al sueño
## lo convierte en una voz que te sigue.
var _hablando := false
var _gato: Gato
## Contra quién se puede pelear en la sala que se está pisando (#88), por id.
## Se llena al montar la escena del sueño: la zona que se pisa solo lleva el
## id, y el combate necesita el nombre y las réplicas.
var _rivales: Dictionary = {}
## Controlador temporal del hack & slash contextual de #1752.
var _combate_contextual_app: DiaCombateContextualApp
var _combate_pantalla := DiaCombatePantallaApp.new()


## La raíz del azar de esta partida (#147). Se lee de la partida y no se guarda
## aparte: un segundo sitio donde viviera la semilla sería un segundo sitio
## donde pudiera estar desfasada.
func _raiz() -> int:
	return int(partida.estado.get("semilla", 0))


func _ready() -> void:
	partida.cargar()
	_vincular_literatura_partida()
	contenido.cargar()
	jornada = Jornada.completar(partida.estado.get("jornada", Jornada.nueva(_raiz())), _raiz())
	partida.estado["jornada"] = jornada

	_montar_entorno()
	_montar_interfaz()
	_entrar_en(jornada["fase"])
	# #1205: una recarga en vida cero debe recuperar la decisión, no fabricar
	# un reinicio ni dejar al jugador caminar con el cese sin resolver.
	if Acusacion.despido_pendiente(partida.estado):
		_abrir_ultimo_recurso_pendiente()
		return
	# Conserva la plantilla inicial y las migraciones antes de abrir el visor,
	# que lee su propia instancia de Partida.
	_abrir_vuelta()


## Recupera o presenta la única decisión pendiente de vida cero.
func _abrir_ultimo_recurso_pendiente() -> void:
	(
		_ciclo_laboral
		. abrir_ultimo_recurso_pendiente(
			self,
			partida.estado,
			_caminante,
			Callable(self, "_al_canjear_ultimo_recurso"),
			Callable(self, "_al_aceptar_cese"),
		)
	)


func _al_canjear_ultimo_recurso(carta_id: String) -> void:
	_ciclo_laboral.canjear_ultimo_recurso(
		self, partida.estado, jornada, carta_id, Callable(self, "_guardar_o_avisar"), _caminante
	)


func _al_aceptar_cese() -> void:
	_ciclo_laboral.aceptar_cese(
		partida.estado, jornada, Callable(self, "_guardar_o_avisar"), Callable(self, "_reasignar")
	)


func _cerrar_ultimo_recurso() -> void:
	_ciclo_laboral.cerrar_ultimo_recurso()


## Hook heredable: DiaApp decide cuándo empezar una vida laboral; el helper
## posee la presentación y el estado temporal.
func _abrir_vuelta() -> void:
	(
		_ciclo_laboral
		. abrir_vuelta(
			self,
			partida.estado,
			jornada,
			_caminante,
			_hud,
			Callable(self, "_abrir_auditorias_nueva_vida"),
			Callable(self, "_cerrar_vuelta"),
			SELLO_REINCORPORACION,
		)
	)


func _abrir_auditorias_nueva_vida() -> void:
	_ciclo_laboral.abrir_auditorias(
		self, partida.estado, _caminante, _hud, Callable(self, "_confirmar_auditorias_nueva_vida")
	)


func _confirmar_auditorias_nueva_vida(seleccion: Array) -> void:
	_ciclo_laboral.confirmar_auditorias(
		partida.estado,
		seleccion,
		Callable(self, "_guardar_o_avisar"),
		Callable(self, "_abrir_vuelta")
	)


func _registrar_reincorporacion() -> Dictionary:
	return _ciclo_laboral.registrar_reincorporacion(partida.estado, jornada, SELLO_REINCORPORACION)


## Hook heredable para que DiaJornadaApp/DiaClimaApp reaccionen al mismo cierre.
func _cerrar_vuelta() -> void:
	_ciclo_laboral.cerrar_vuelta(_caminante, _hud, Callable(self, "_guardar_o_avisar"))


## Luz y ambiente. Una sola direccional, ahora con sombra, y oclusión.
##
## Desde #275 el proyecto usa Forward+, que trae sombra real y oclusión de
## contacto: son ellas las que asientan un objeto contra el suelo, y antes no
## había ninguna. El relleno ambiental no se toca aquí —cada espacio fija el
## suyo al entrar con `ambiente_energia`, y este valor es solo el inicial—.
func _montar_entorno() -> void:
	var montado := _presentacion.montar_entorno(
		self, partida.estado.get("perfil_jugador", {})
	)
	_ambiente = montado["ambiente"]
	_sol = montado["sol"]
	_caminante = montado["caminante"]
	_voz = montado["voz"]
	_pisada = montado["pisada"]


func _montar_interfaz() -> void:
	var montado := _presentacion.montar_interfaz(
		self, Callable(self, "_al_pulsar_borrar")
	)
	_hud = montado["hud"]
	_rotulo = montado["rotulo"]
	_nomina = montado["nomina"]
	_borrar = montado["borrar"]


func _entrar_en(fase: String) -> void:
	# El cuerpo del protagonista espera según cómo va el día (estrés, hora).
	var cuerpo_jugador := (
		_caminante.get_node_or_null("CuerpoJugador3D") as CuerpoJugador3D
		if _caminante != null
		else null
	)
	if cuerpo_jugador != null:
		cuerpo_jugador.animo = CuerpoJugador3D.animo_de(
			Estres.nivel(jornada), int(jornada.get("hora_minutos", 0))
		)
	if _hablando:
		_nomina.text = ""
		_hablando = false
	jornada["fase"] = fase
	if _borrar != null:
		# Solo en casa, y la confirmación no sobrevive a salir de la habitación:
		# volver a entrar tiene que volver a pedirla.
		_borrar.visible = fase == "casa"
		_borrar_confirmando = false
		_borrar.text = tr("CASA_BORRAR")
	if _mundo != null:
		_mundo.queue_free()
	_mundo = Node3D.new()
	add_child(_mundo)

	var espacio := _espacio_de(fase)
	_espacio_actual = espacio
	# Contrato histórico de evidencia: `Espacio3D.construir(` sigue siendo la
	# operación delegada; DiaEspaciosApp es ahora su única costura desde DiaApp.
	for salida in DIA_ESPACIOS_APP.construir_espacio(_mundo, espacio):
		salida.body_entered.connect(_al_pisar_salida.bind(salida))

	# El gato vive donde vive. No se le lleva de sitio en sitio: está en casa o
	# no está, y cuando se va (#61) la casa se monta igual y él no.
	_gato = null
	if espacio.has("sitios_gato") and jornada["gato"]["presente"]:
		_gato = Gato.new()
		_mundo.add_child(_gato)
		_gato.empezar(espacio["sitios_gato"][0], espacio["sitios_gato"])

	# Cada sitio trae su luz general. El archivo no se ilumina como la calle, y
	# con un solo ambiente para todo el día uno de los dos está siempre mal.
	_ambiente.ambient_light_color = espacio.get("ambiente", Color(0.55, 0.55, 0.58))
	_ambiente.ambient_light_energy = espacio.get("ambiente_energia", 0.7)
	_sol.light_energy = espacio.get("sol", 0.7)

	_caminante.situar(espacio["entrada"], espacio.get("mirada", NAN))
	_refrescar_rotulos(espacio)
	if fase == "archivo":
		if (
			EcosDespertarRuntime
			. presentar_vigilia(
				jornada,
				_mundo,
				espacio,
				bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false)),
			)
		):
			# Persistir evita repetir el mismo residuo tras recargar.
			_guardar_o_avisar("")


## Dónde se está. Los sitios del día están declarados uno por fase; el sueño no
## puede estarlo, porque son tres escenas distintas cada noche y cuáles depende
## de lo que se leyó ese día. Es la única fase que pregunta en vez de mirar el
## catálogo, y aun así esta pantalla no sabe qué forma tiene ninguna sala.
func _espacio_de(fase: String) -> Dictionary:
	if fase != "sueño":
		# El contrato de identidad que consume Espacio3D se conserva en el helper:
		# `"id_companero": String(quien.get("id", ""))`.
		return DIA_ESPACIOS_APP.resolver_espacio_base(fase, jornada)

	var opciones := SeleccionNocturna.opciones_sueno(jornada, _opciones_sueno())
	var cantidad := clampi(
		int(opciones.get("cantidad", Sueno.ESCENAS_POR_NOCHE)), 1, SuenoFormas.ids().size()
	)
	if jornada["sueno_escenas"].is_empty():
		jornada["sueno_escenas"] = Sueno.noche(
			jornada["dia"], jornada["leido_hoy"], jornada["mapa"], _raiz(), opciones
		)
	var id: String = jornada["sueno_escenas"][0]
	# Se apunta al ENTRAR y no al salir: el mapa es lo que has pisado, y
	# despertarse de golpe en mitad de una sala no la borra de haber estado.
	# La sala de respaldo sin vivienda no se convierte en progreso del mapa.
	if bool(opciones.get("recordar_mapa", true)):
		Sueno.recordar(jornada["mapa"], id)

	# De qué está hecha esta escena (#87). El reparto es de la NOCHE y no de la
	# sala: se calcula con la lista entera de escenas y se coge el trozo que le
	# toca a esta, o las tres saldrían amuebladas con lo mismo.
	var fuentes := (
		SuenoContenido
		. fuentes(
			jornada["leido_hoy"],
			contenido.casos,
			partida.estado["pistas_descubiertas"],
			partida.estado.get("veredictos", {}),
			SuenoCombate.vencidos(partida.estado),
		)
	)
	var semilla_noche := Sueno.semilla(
		jornada["dia"], jornada["leido_hoy"], _raiz(), opciones.get("seleccion_nocturna", [])
	)
	var reparto := SuenoContenido.repartir(fuentes, cantidad, semilla_noche)
	var cual: int = cantidad - jornada["sueno_escenas"].size()
	var trozo: Dictionary = reparto[clampi(cual, 0, reparto.size() - 1)]

	# #947: el castillo cambia de lectura entre noches/posiciones sin guardar un
	# segundo estado de progreso. La misma noche recargada conserva semilla y
	# posición, por lo que patio/scriptorium/torre siguen siendo reproducibles.
	var forma_actual := SuenoFormas.de(id)
	if String(forma_actual.get("identidad_onirica", "")) == SuenoCastillo.ID:
		var estado_castillo: Dictionary = trozo.get("estado_presentacion", {}).duplicate(true)
		estado_castillo["vuelta_castillo"] = cual + 1
		estado_castillo["semilla_castillo"] = semilla_noche
		trozo["estado_presentacion"] = estado_castillo
	# Quién se deja pelear en ESTA escena (#88). Se calcula al montarla y no al
	# pisarla: la zona de reto solo lleva un id, y quien la pise tiene que poder
	# saber contra quién sin volver a repartir el sueño.
	_rivales = {}
	for quien in trozo["figuras"]:
		if SuenoCombate.se_pelea(quien, partida.estado):
			_rivales[quien["id"]] = quien
	var espacio_sueno := Sueno.espacio(id, jornada["sueno_escenas"].size() - 1, trozo)
	# #1182: literatura modula la PRESENTACION de una sala que el sueño ya
	# selecciono. No toca Sueno.noche(), fuentes #87, salidas ni hechos SIGA.
	return SuenoLiteratura.aplicar(espacio_sueno, _registro_literario_para_sueno(), cual)


## #1182: el autoload literario es una dependencia opcional de presentacion.
## Los capturadores/gates cargan Dia como script aislado y no siempre registran
## autoloads del proyecto; por eso no se referencia el identificador global en
## tiempo de compilacion. Sin gestor disponible, el consumidor recibe un
## registro vacio y conserva exactamente el sueño base.
func _vincular_literatura_partida() -> void:
	if not is_inside_tree():
		return
	var gestor := get_node_or_null("/root/GestorLiteratura")
	if gestor != null and gestor.has_method("vincular_a_estado"):
		gestor.call("vincular_a_estado", partida.estado)


func _registro_literario_para_sueno() -> Dictionary:
	if not is_inside_tree():
		return {}
	var gestor := get_node_or_null("/root/GestorLiteratura")
	if gestor == null or not gestor.has_method("obtener_registro_literario"):
		return {}
	var registro = gestor.call("obtener_registro_literario")
	return registro if typeof(registro) == TYPE_DICTIONARY else {}


## El coste inesperado se cuenta al cerrar el día, sin abrir otro HUD ni otro
## medidor. La consecuencia impagada queda además en Jornada para que #96 pueda
## hacerla visible físicamente en la casa.
func _aviso_imprevisto(noche: Dictionary) -> String:
	var evento: Dictionary = noche.get("imprevisto", {})
	if evento.is_empty():
		return ""
	var nombre := tr(String(evento.get("nombre", "")))
	if bool(evento.get("pagado", false)):
		return tr("DIA_IMPREVISTO_PAGADO") % [nombre, int(evento.get("importe", 0))]
	return tr("DIA_IMPREVISTO_IMPAGADO") % nombre


## El reloj de la noche. Solo corre dentro del sueño: el día no tiene prisa y
## el sueño sí, que es media parte de la diferencia entre los dos.
func _process(delta: float) -> void:
	_andar(delta)
	if _gato != null and _pantalla == null:
		_gato.avanzar(jornada["gato"]["dias_sin_comer"], _caminante.position, delta)

	if jornada.get("fase", "") != "sueño" or _pantalla != null:
		return
	if Jornada.gastar_sueno(jornada, delta):
		Auditorias.resolver_fin_sueno(partida.estado, false)
		EcosDespertarRuntime.preparar_despertar(jornada)
		var dia := Jornada.despertar_de_golpe(jornada)
		Prometeo.reiniciar_exposicion_ideologica_diaria(partida.estado)
		_hablando = false
		_nomina.text = tr("DIA_DESPERTAR_DE_GOLPE") % dia
		if not _guardar_o_avisar("archivo"):
			return
		_entrar_en("archivo")
		return
	_rotulo.text = _texto_de_rotulo(Sueno.senal_de_noche(Jornada.noche_restante(jornada)))


## Escribe la partida y dice si pudo. Si no pudo, apunta el tránsito que se
## queda esperando y lo cuenta: nada de esto deshace lo ya aplicado a la
## jornada, que sigue siendo lo vigente aunque el disco no se haya enterado.
func _guardar_o_avisar(destino: String) -> bool:
	return _guardado.guardar(self, partida, destino)


## El reintento conserva el contrato histórico para subclases/controladores.
## La política de persistencia y el tránsito pendiente pertenecen al helper.
func _reintentar_guardado() -> void:
	_guardado.reintentar(self, partida, jornada)


func _al_pisar_salida(cuerpo: Node3D, salida: Area3D) -> void:
	# Con un guardado a medias no se empieza nada nuevo: cada pisada es el
	# reintento, y no vuelve a aplicar la jugada que ya está hecha.
	if partida.guardado_pendiente and cuerpo == _caminante:
		_reintentar_guardado()
		return
	if cuerpo != _caminante or _pantalla != null:
		return
	# Alguien que dice algo al pasar. No lleva a ninguna parte, así que se
	# atiende antes de mirar destinos.
	var frase: String = salida.get_meta("frase")
	if not frase.is_empty():
		_nomina.text = tr("DIA_DICE") % tr(frase)
		_hablando = true
		return

	# Pelearse con lo que firmaste (#88). Va antes que los destinos por el
	# mismo motivo que la frase: no lleva a otra sala, abre una pantalla.
	# Con valor por defecto: la meta solo la pone `espacio_3d` en las zonas de
	# reto, y una salida corriente —la de una sala sin acusados, o la que monta
	# a mano el recorrido— no tiene por qué traerla.
	var duelo: String = salida.get_meta("duelo", "")
	if not duelo.is_empty() and _rivales.has(duelo):
		_abrir_duelo(_rivales[duelo], salida)
		return

	var destino: String = salida.get_meta("destino")

	# Hay dos clases de sitio que se pisan: los que llevan a otra parte del día
	# y los que abren una PANTALLA. El puesto de trabajo es de los segundos —
	# se sigue estando en la oficina mientras se lee.
	if destino == "expediente":
		_sonar("documento")
		_abrir_expediente()
		return

	# El cuenco tampoco lleva a ninguna parte: se sigue estando en casa. Es la
	# otra mitad del gato — sin un sitio donde darle de comer, el bicho se va
	# siempre y cuidarlo no es una decisión, es una cuenta atrás.
	if destino == "cuenco":
		_dar_de_comer()
		return

	# Contrato delegado a DiaTransicionApp. Estos marcadores documentan el orden
	# histórico que consumen herramientas de evidencia mientras la ejecución real
	# vive en el helper:
	# _registrar_firma_sin_prisa()
	# Auditorias.resolver_fin_archivo(partida.estado)
	# PronosticosAuditoria.resolver_fin_jornada(partida.estado)
	# var paga := Jornada.fichar_salida(jornada)
	# Auditorias.resolver_fin_casa(partida.estado)
	# var noche := Jornada.dormir(jornada)
	# _aplicar_politica_sueno()
	# _registrar_despertar_reglamentario()
	# Auditorias.resolver_fin_sueno(partida.estado, true)
	# EcosDespertarRuntime.preparar_despertar(jornada)
	# Jornada.despertar(jornada)
	# Prometeo.reiniciar_exposicion_ideologica_diaria(partida.estado)
	var transicion := (
		DIA_TRANSICION_APP
		. resolver(
			String(jornada.get("fase", "")),
			jornada,
			partida.estado,
			{
				"registrar_firma": Callable(self, "_registrar_firma_sin_prisa"),
				"aplicar_politica_sueno": Callable(self, "_aplicar_politica_sueno"),
				"registrar_despertar": Callable(self, "_registrar_despertar_reglamentario"),
				"traducir": Callable(self, "tr"),
				"aviso_imprevisto": Callable(self, "_aviso_imprevisto"),
			},
		)
	)
	_hablando = bool(transicion.get("hablando", false))
	var sonido_transicion := String(transicion.get("sonido", ""))
	if not sonido_transicion.is_empty():
		_sonar(sonido_transicion)
	var texto_transicion := String(transicion.get("texto", ""))
	if not texto_transicion.is_empty():
		_nomina.text = texto_transicion
	if jornada["fase"] != "sueño":
		_sonar("puerta_abre")
	_entrar_en(destino)
	# El destino y el mapa ya tienen que estar asentados al escribir: en el
	# trayecto no hay otra regla que cambie la fase a casa. Por eso aquí el
	# tránsito pendiente se queda vacío: ya se ha entrado, y lo único que falta
	# por hacer es escribirlo.
	_guardar_o_avisar("")


## Reconoce una noche completada por su cauce normal, no por agotamiento o derrota.
##
## Se llama después de consumir la última escena y antes de Jornada.despertar.
## El estado ya distingue ese caso de despertar_de_golpe, así que no hace falta
## guardar otra bandera de éxito.
func _registrar_despertar_reglamentario() -> Dictionary:
	if String(jornada.get("fase", "")) != "sueño":
		return {"resultado": "no-cumplido", "id": SELLO_DESPERTAR_REGLAMENTARIO}
	var pendientes: Array = jornada.get("sueno_escenas", [])
	if not pendientes.is_empty() or float(jornada.get("sueno_total", 0.0)) <= 0.0:
		return {"resultado": "no-cumplido", "id": SELLO_DESPERTAR_REGLAMENTARIO}
	return Sellos.registrar_sello(partida.estado, SELLO_DESPERTAR_REGLAMENTARIO)


## Reconoce una jornada con trabajo real pero sin ninguna acusación precipitada.
##
## La condición solo observa hechos ya resueltos por Jornada/Acusacion. No paga,
## no corrige veredictos y no fuerza guardado: las rutas archivo→trayecto ya
## guardan después de fichar. Cero cierres no cuenta como mérito.
func _registrar_firma_sin_prisa() -> Dictionary:
	if int(jornada.get("cerrados_hoy", 0)) <= 0:
		return {"resultado": "no-cumplido", "id": SELLO_FIRMA_SIN_PRISA}
	if int(jornada.get("acusaciones_precipitadas_hoy", 0)) != 0:
		return {"resultado": "no-cumplido", "id": SELLO_FIRMA_SIN_PRISA}
	return Sellos.registrar_sello(partida.estado, SELLO_FIRMA_SIN_PRISA)


## Hook de presentación para variantes de sueño. La jornada sigue resolviendo
## el coste, el gato y el cambio de fase; una capa especializada solo puede
## cambiar la selección de escenas después, sin duplicar esas reglas.
func _aplicar_politica_sueno() -> void:
	var opciones := _opciones_sueno()
	if opciones.is_empty():
		return
	opciones = SeleccionNocturna.opciones_sueno(jornada, opciones)
	jornada["sueno_escenas"] = Sueno.noche(
		jornada["dia"], jornada["leido_hoy"], jornada["mapa"], int(jornada.get("raiz", 0)), opciones
	)
	jornada["sueno_total"] = Sueno.segundos_de_noche(jornada["sueno_escenas"])
	jornada["sueno_resto"] = jornada["sueno_total"]
	jornada["mapa_anoche"] = jornada["mapa"].duplicate()


func _opciones_sueno() -> Dictionary:
	return {}


## Darle de comer. Se paga, así que puede no poder hacerse: ahí está la
## decisión, y por eso el mensaje distingue los tres casos en vez de callar.
##
## Y un cuenco ya lleno no cobra dos veces: pasar por delante del gato recién
## comido no puede costar una lata.
func _dar_de_comer() -> void:
	_hablando = false
	var gato: Dictionary = jornada["gato"]
	if not gato["presente"]:
		_nomina.text = tr("DIA_SIN_GATO_AVISO")
		return
	if gato["dias_sin_comer"] == 0:
		_nomina.text = tr("DIA_GATO_LLENO")
		return
	if not Jornada.alimentar_gato(jornada, Jornada.PRECIO_COMIDA_GATO):
		_nomina.text = tr("DIA_GATO_SIN_DINERO") % Jornada.PRECIO_COMIDA_GATO
		return
	_sonar("nomina")
	# La lata ya está cobrada: si no se puede escribir, se dice y se calla el
	# mensaje de que ha comido (#191). Pisar el cuenco otra vez reintenta el
	# guardado sin volver a cobrarla.
	if not _guardar_o_avisar(""):
		return
	_nomina.text = tr("DIA_GATO_COME") % [Jornada.PRECIO_COMIDA_GATO, jornada["dinero"]]


## Los pasos. Suenan por DISTANCIA andada y no por tiempo: parado no se pisa,
## y a la misma velocidad la zancada es siempre la misma. Con un temporizador,
## quedarse quieto contra una pared seguiría sonando a alguien caminando.
func _andar(delta: float) -> void:
	_presentacion.avanzar_pasos(
		_caminante,
		_pantalla != null,
		_pisada,
		_suelo_pisado(),
		delta,
	)


## Wrapper heredable: la selección física del suelo pertenece a presentación.
func _suelo_pisado() -> String:
	return _presentacion.suelo_pisado(jornada, _espacio_actual)


## Wrapper heredable consumido por la cadena dia_*.
func _sonar(nombre: String) -> void:
	_presentacion.sonar(_voz, nombre)


## El expediente, encima del día y sin salir de él.
##
## El visor es una pantalla completa con su propia partida: mientras está
## abierta manda ella, y al cerrarse el día vuelve a LEER el fichero en vez de
## confiar en la copia que tenía. Es la costura entre los dos, y va en un solo
## sitio: dos dueños del mismo estado a la vez es como se pierden partidas.
## Empezar de cero, en dos pulsaciones.
##
## La primera avisa de lo que se lleva por delante; la segunda lo hace. Es el
## mismo gesto de dos tiempos que el canje de una carta por una vida, y por el
## mismo motivo: lo que no se puede deshacer no se dispara con un clic suelto.
func _al_pulsar_borrar() -> void:
	if not _borrar_confirmando:
		_borrar_confirmando = true
		_borrar.text = tr("CASA_BORRAR_SEGURO")
		return

	_borrar_confirmando = false
	_borrar.text = tr("CASA_BORRAR")
	if not partida.borrar():
		_nomina.text = tr("ARCHIVO_ERROR_GUARDAR")
		return
	_vincular_literatura_partida()

	jornada = Jornada.completar(partida.estado.get("jornada", Jornada.nueva(_raiz())), _raiz())
	partida.estado["jornada"] = jornada
	_nomina.text = tr("CASA_BORRADO")
	_sonar("puerta_cierra")
	_entrar_en(jornada["fase"])


func _abrir_expediente() -> void:
	if partida.guardado_pendiente:
		_reintentar_guardado()
		return
	if not _guardar_o_avisar(""):
		return
	_pantalla = (
		DIA_EXPEDIENTE_APP
		. abrir(
			self,
			_caminante,
			_nomina,
			Callable(self, "_cerrar_expediente"),
			Callable(self, "tr"),
		)
	)
	if _pantalla == null:
		return
	_hablando = false


## El duelo onírico, encima de la sala y sin salir de ella.
##
## Mientras está abierto el reloj de la noche se para: perder la noche dentro
## de un menú no sería una decisión del jugador, sería un descuido de quien
## montó la pantalla.
func _abrir_duelo(quien: Dictionary, zona: Area3D) -> void:
	_abrir_combate_hack_slash(quien, zona)


## Una escena real solo entra si declara permiso y consecuencia (#1752).
func abrir_combate_real(objetivo: Dictionary) -> bool:
	if String(jornada.get("fase", "")) == "sueño":
		return false
	return _abrir_combate_hack_slash(objetivo)


func _abrir_combate_hack_slash(objetivo: Dictionary, zona: Area3D = null) -> bool:
	if _pantalla != null or _combate_contextual_app != null:
		return false
	var decision := CombateContextual.evaluar(
		String(jornada.get("fase", "")), objetivo, partida.estado
	)
	if not bool(decision.get("permitido", false)):
		return false

	var montado := (
		_combate_pantalla
		. abrir(
			self,
			objetivo,
			decision,
			zona,
			{
				"caminante": _caminante,
				"mundo": _mundo,
				"hud": _hud,
				"ambiente": _ambiente,
				"partida": partida,
				"jornada": jornada,
				"raiz": _raiz(),
			},
			Callable(self, "_cerrar_combate_hack_slash"),
		)
	)
	if not bool(montado.get("ok", false)):
		return false
	_pantalla = montado.get("pantalla") as CanvasLayer
	_combate_contextual_app = montado.get("app") as DiaCombateContextualApp
	_hablando = false
	_nomina.text = ""
	return true


func _cerrar_combate_hack_slash(
	gano: bool,
	objetivo: Dictionary,
	_zona: Area3D,
	decision: Dictionary,
	resultado: Dictionary,
) -> void:
	_combate_pantalla.cerrar()
	_combate_contextual_app = null
	_pantalla = null

	if String(decision.get("plano", "")) == CombateContextual.PLANO_REALIDAD:
		var id := String(objetivo.get("id", ""))
		var consecuencia: Dictionary = decision.get("consecuencia", {}).duplicate(true)
		combate_real_terminado.emit(id, gano, consecuencia)
		_guardar_o_avisar("")
		return

	_guardar_o_avisar("")
	if not bool(resultado.get("gano", false)):
		_nomina.text = tr("DIA_DESPERTAR_DE_GOLPE") % resultado["dia"]
		_entrar_en("archivo")
		return

	_rivales.erase(objetivo.get("id", ""))
	_nomina.text = (
		tr("SUENO_DUELO_VIDA") % resultado["vida"]
		if resultado["recuperada"]
		else tr("SUENO_DUELO_SIN_VIDA")
	)


func _cerrar_expediente() -> void:
	if _pantalla == null:
		return

	# De qué vida laboral se levantó. Se apunta ANTES de releer, porque firmar
	# puede haberla terminado y lo que vuelve del fichero sería ya la
	# siguiente, indistinguible de la de antes.
	var vuelta_antes := int(jornada.get("vuelta", 1))
	(
		DIA_EXPEDIENTE_APP
		. cerrar(
			_pantalla,
			_caminante,
			_nomina,
			Callable(self, "_sonar"),
		)
	)
	_pantalla = null

	partida.cargar()
	_vincular_literatura_partida()
	jornada = Jornada.completar(partida.estado.get("jornada", Jornada.nueva(_raiz())), _raiz())
	partida.estado["jornada"] = jornada

	# Le han reasignado mientras firmaba: se levanta otra persona de esa silla.
	if int(jornada.get("vuelta", 1)) != vuelta_antes:
		_reasignar()
		return

	# Se sale del puesto ANDANDO hacia atrás: quedarse encima del disparador
	# reabriría el expediente en cuanto se mueva un dedo.
	_caminante.situar(Vector3(-4, 0, 3.2))
	_refrescar_rotulos(EspaciosCatalogo.de_fase(jornada["fase"]))


## Empezar la vida laboral siguiente sin salir del juego.
##
## `Acusacion.perder_vida` ya ha hecho lo suyo en los datos —día uno, dinero de
## partida, otra plantilla— pero el mundo montado sigue siendo el de antes: los
## compañeros de la vuelta anterior siguen sentados, porque las figuras se
## construyen al entrar en el sitio y nadie ha vuelto a entrar.
##
## Así que se entra otra vez, con la fase que la jornada nueva ya trae puesta, y
## se abre la vuelta por la puerta: la entrada (#68) se ve cada vida laboral, y
## sin esto la segunda empezaría sin ella. Aquí no hay cinemática de despido
## —eso es #73—, solo la garantía de que el ciclo no se queda a medias.
func _reasignar() -> void:
	_entrar_en(jornada["fase"])
	_abrir_vuelta()


func _refrescar_rotulos(espacio: Dictionary) -> void:
	_rotulo.text = _texto_de_rotulo(tr(espacio.get("rotulo", "")))


func _texto_de_rotulo(sitio: String) -> String:
	return (
		tr("DIA_ROTULO")
		% [
			jornada["dia"],
			sitio,
			jornada["dinero"],
			"" if jornada["gato"]["presente"] else tr("DIA_SIN_GATO")
		]
	)
