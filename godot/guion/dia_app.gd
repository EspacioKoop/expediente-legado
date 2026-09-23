## El día: la pantalla que lo hila.
##
## Monta el espacio de la fase actual, escucha sus salidas y avanza la jornada.
## No sabe qué hay en ninguna sala —eso es `EspaciosCatalogo`— ni qué significa
## avanzar —eso es `Jornada`—: aquí solo se pega una cosa con la otra.
extends Node3D

## Lo que se anda entre paso y paso. Una zancada de persona son unos setenta
## centímetros.
const METROS_POR_ZANCADA := 0.72
const SELLO_FIRMA_SIN_PRISA := "firma-sin-prisa"
const SELLO_REINCORPORACION := "reincorporacion-administrativa"
const SELLO_DESPERTAR_REGLAMENTARIO := "despertar-reglamentario"

var partida := Partida.new()
var contenido := Contenido.new()
## Las decisiones políticas de la partida, que son las cargas de habilidad de
## los combates oníricos (#88). Sin cargarlas, `cargas()` no sabe cuántas
## historias hay y las devuelve todas a cero.
var historias := Historias.new()
var jornada: Dictionary = {}

var _caminante: CharacterBody3D
var _mundo: Node3D
var _rotulo: Label
var _nomina: Label

## El destino al que no se llegó a entrar porque no se pudo guardar. Mientras
## haya uno, pisar cualquier salida REINTENTA el guardado en vez de volver a
## fichar: la nómina y la noche ya están cobradas en memoria, y cobrarlas dos
## veces sería peor que no haberlas escrito.
var _transito_pendiente := ""
var _borrar: Button
var _borrar_confirmando := false
var _pantalla: CanvasLayer
## Los rótulos del día. Se guarda para poder apagarlos mientras se pone la
## entrada de la vuelta.
var _hud: CanvasLayer
## La entrada de la vuelta mientras se está poniendo (#68). Fuera de ella es
## nula: el reproductor se descarta al terminar en vez de quedarse escuchando.
var _entrada: Node3D
var _ultimo_recurso: UltimoRecursoApp
var _auditorias_nueva_vida: AuditoriasNuevaVidaApp

## El sitio montado ahora mismo, tal como se construyó. Las cinemáticas que
## ruedan dentro de él (#395) lo leen en vez de volver a pedirlo: en el sueño
## pedirlo otra vez apuntaría la sala en el mapa por segunda vez.
var _espacio_actual: Dictionary = {}
var _ambiente: Environment
var _sol: DirectionalLight3D
var _voz: AudioStreamPlayer
var _pisada: AudioStreamPlayer3D
var _desde_paso := 0.0
## Si lo que se lee ahora mismo es algo que dijo alguien. Lo que dice un
## compañero es de la oficina y del momento: llevárselo a la calle o al sueño
## lo convierte en una voz que te sigue.
var _hablando := false
var _gato: Gato
## Contra quién se puede pelear en la sala que se está pisando (#88), por id.
## Se llena al montar la escena del sueño: la zona que se pisa solo lleva el
## id, y el combate necesita el nombre y las réplicas.
var _rivales: Dictionary = {}


## La raíz del azar de esta partida (#147). Se lee de la partida y no se guarda
## aparte: un segundo sitio donde viviera la semilla sería un segundo sitio
## donde pudiera estar desfasada.
func _raiz() -> int:
	return int(partida.estado.get("semilla", 0))


func _ready() -> void:
	partida.cargar()
	contenido.cargar()
	historias.cargar()
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
	if not Acusacion.despido_pendiente(partida.estado):
		return
	if is_instance_valid(_ultimo_recurso):
		_ultimo_recurso.actualizar(partida.estado)
		return
	if is_instance_valid(_caminante):
		_caminante.set_physics_process(false)
	_ultimo_recurso = UltimoRecursoApp.new()
	_ultimo_recurso.name = "UltimoRecurso"
	_ultimo_recurso.canje_solicitado.connect(_al_canjear_ultimo_recurso)
	_ultimo_recurso.cese_solicitado.connect(_al_aceptar_cese)
	add_child(_ultimo_recurso)
	_ultimo_recurso.abrir(partida.estado)


func _al_canjear_ultimo_recurso(carta_id: String) -> void:
	var resultado := Acusacion.canjear_carta_por_vida(partida.estado, carta_id)
	if String(resultado.get("resultado", "")) != "canje":
		if is_instance_valid(_ultimo_recurso):
			_ultimo_recurso.actualizar(partida.estado)
		return

	# Una derrota de Hastur deja su combate interrumpido mientras existe la
	# frontera. Si el canje salva la misma vuelta, se rearma ese mismo intento.
	ClimaxHastur.reanudar_tras_ultimo_recurso(partida.estado, jornada)
	var guardado := _guardar_o_avisar("")
	_cerrar_ultimo_recurso()
	if not guardado:
		if is_instance_valid(_caminante):
			_caminante.set_physics_process(true)
		return

	var climax := get_node_or_null("ClimaxHasturOwnerController")
	if climax != null and climax.has_method("_reanudar_si_procede"):
		climax.call_deferred("_reanudar_si_procede")
	elif is_instance_valid(_caminante):
		_caminante.set_physics_process(true)


func _al_aceptar_cese() -> void:
	var resultado := Acusacion.aceptar_cese(partida.estado, jornada)
	if not bool(resultado.get("despido", false)):
		if is_instance_valid(_ultimo_recurso):
			_ultimo_recurso.actualizar(partida.estado)
		return
	_guardar_o_avisar("")
	_cerrar_ultimo_recurso()
	_reasignar()


func _cerrar_ultimo_recurso() -> void:
	if is_instance_valid(_ultimo_recurso):
		_ultimo_recurso.queue_free()
	_ultimo_recurso = null


## La entrada de una vida laboral (#68).
##
## Se pone ENCIMA de la oficina ya montada y no antes de montarla: así al
## terminar no hay ningún fotograma en negro esperando a que se construya el
## archivo, y saltarla deja al jugador exactamente donde estaría.
##
## Solo abre una vuelta —día uno, en el archivo y con la jornada entera por
## delante—, que es lo que distingue empezar de volver a cargar una partida a
## medias. Una entrada que se repita cada vez que se abre el juego dejaría de
## ser una entrada.
##
## Ocurre al arrancar y también a media sesión: cuando firmar cuesta la última
## vida, `_cerrar_expediente` vuelve a llamar aquí por `_reasignar`. Esa es la
## razón de que la condición mire la jornada y no una bandera de "ya
## arrancamos" — lo que abre una entrada es que la vida laboral esté por
## estrenar, venga de donde venga.
func _abrir_vuelta() -> void:
	if jornada["fase"] != "archivo" or jornada["dia"] != 1:
		return
	if jornada["acciones"] != Jornada.ACCIONES_POR_DIA:
		return
	if int(jornada.get("vuelta", 1)) > 1 and Auditorias.seleccion_pendiente(partida.estado):
		_abrir_auditorias_nueva_vida()
		return

	_registrar_reincorporacion()

	# El cuerpo se queda quieto mientras dura: la cinemática se salta con
	# cualquier tecla, y sin esto esa misma tecla sería también un paso.
	_caminante.set_physics_process(false)

	# Y los rótulos del día se apagan. No es limpieza: la oficina ya está
	# montada detrás, así que sin esto la frase de un compañero se lee ENCIMA de
	# la pantalla de arranque —alguien te habla antes de que hayas entrado, en la
	# cinemática cuyo remate es que no hay nadie más—.
	_hud.visible = false

	_entrada = load("res://escenas/cinematica.tscn").instantiate()
	add_child(_entrada)
	_entrada.terminada.connect(_cerrar_vuelta)
	var vistas := Cinematica.vistas_de(partida.estado, EntradaCinematica.ID)
	_entrada.reproducir(EntradaCinematica.planos_de(vistas), EntradaCinematica.ID, partida.estado)


## La segunda vida laboral y siguientes ya son una reincorporación administrativa.
##
## Se deriva del contador de vuelta existente: no hace falta una bandera paralela
## y recargar el día 1 sigue siendo idempotente. El guardado ocurre al cerrar la
## misma entrada de vuelta.
func _abrir_auditorias_nueva_vida() -> void:
	if is_instance_valid(_auditorias_nueva_vida):
		return
	if is_instance_valid(_caminante):
		_caminante.set_physics_process(false)
	if is_instance_valid(_hud):
		_hud.visible = false
	_auditorias_nueva_vida = AuditoriasNuevaVidaApp.new()
	_auditorias_nueva_vida.name = "AuditoriasNuevaVida"
	_auditorias_nueva_vida.seleccion_confirmada.connect(_confirmar_auditorias_nueva_vida)
	add_child(_auditorias_nueva_vida)
	_auditorias_nueva_vida.abrir(partida.estado)


func _confirmar_auditorias_nueva_vida(seleccion: Array) -> void:
	var anterior := Dictionary(partida.estado.get(Auditorias.CLAVE_ESTADO, {})).duplicate(true)
	if not Auditorias.resolver_seleccion(partida.estado, seleccion):
		return
	if not _guardar_o_avisar(""):
		partida.estado[Auditorias.CLAVE_ESTADO] = anterior
		return
	if is_instance_valid(_auditorias_nueva_vida):
		_auditorias_nueva_vida.queue_free()
	_auditorias_nueva_vida = null
	_abrir_vuelta()


func _registrar_reincorporacion() -> Dictionary:
	if int(jornada.get("vuelta", 1)) <= 1:
		return {"resultado": "no-cumplido", "id": SELLO_REINCORPORACION}
	return Sellos.registrar_sello(partida.estado, SELLO_REINCORPORACION)


## Al acabar la entrada se guarda, y no por costumbre: lo que hay que conservar
## es que se ha visto. Sin este guardado la cuenta se pierde al cerrar el juego
## y la entrada volvería a durar lo mismo para siempre, que es justo lo que el
## acortado de #67 vino a evitar.
func _cerrar_vuelta() -> void:
	if _entrada == null:
		return
	_entrada.queue_free()
	_entrada = null
	_caminante.set_physics_process(true)
	_hud.visible = true
	_guardar_o_avisar("")


## Luz y ambiente. Una sola direccional, ahora con sombra, y oclusión.
##
## Desde #275 el proyecto usa Forward+, que trae sombra real y oclusión de
## contacto: son ellas las que asientan un objeto contra el suelo, y antes no
## había ninguna. El relleno ambiental no se toca aquí —cada espacio fija el
## suyo al entrar con `ambiente_energia`, y este valor es solo el inicial—.
func _montar_entorno() -> void:
	var entorno := WorldEnvironment.new()
	var ajustes := Environment.new()
	_ambiente = ajustes
	ajustes.background_mode = Environment.BG_COLOR
	ajustes.background_color = Color(0.05, 0.05, 0.06)
	ajustes.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ajustes.ambient_light_color = Color(0.55, 0.55, 0.58)
	# El relleno real lo fija cada espacio al entrar; este es solo el inicial.
	ajustes.ambient_light_energy = 0.7
	# Oclusión ambiental y su equivalente para luz indirecta. Las dos son de
	# Forward+ y son lo que asienta un objeto contra el suelo y contra el muro
	# cuando la sombra proyectada no llega.
	ajustes.ssao_enabled = true
	ajustes.ssao_radius = 0.8
	ajustes.ssao_intensity = 2.0
	ajustes.ssil_enabled = true
	ajustes.ssil_intensity = 0.7
	entorno.environment = ajustes
	add_child(entorno)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_energy = 0.7
	sol.shadow_enabled = true
	sol.shadow_bias = 0.03
	sol.shadow_normal_bias = 1.4
	add_child(sol)
	_sol = sol

	_caminante = load("res://escenas/caminante.tscn").instantiate()
	# #701: el cuerpo visible usa la ficha de ESTA partida, ya cargada aquí.
	var cuerpo_jugador := _caminante.get_node_or_null("CuerpoJugador3D") as CuerpoJugador3D
	if cuerpo_jugador != null:
		cuerpo_jugador.perfil = partida.estado.get("perfil_jugador", {})
	add_child(_caminante)

	# Dos voces: lo que pasa (una puerta, la nómina) y lo que haces tú (andar).
	# La segunda va pegada al cuerpo, que es de donde salen los pasos.
	_voz = AudioStreamPlayer.new()
	add_child(_voz)
	_pisada = AudioStreamPlayer3D.new()
	_pisada.unit_size = 3.0
	_caminante.add_child(_pisada)


func _montar_interfaz() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	_hud = capa

	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	caja.offset_left = 12
	caja.offset_top = 10
	caja.theme = EstiloSiga.tema()
	capa.add_child(caja)

	_rotulo = Label.new()
	_rotulo.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	_rotulo.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	_rotulo.add_theme_constant_override("outline_size", 4)
	caja.add_child(_rotulo)

	_nomina = Label.new()
	_nomina.add_theme_color_override("font_color", EstiloSiga.BLANCO)
	_nomina.add_theme_color_override("font_outline_color", EstiloSiga.NEGRO)
	_nomina.add_theme_constant_override("outline_size", 4)
	caja.add_child(_nomina)

	# Empezar de cero se pide en CASA y no en la oficina: el sistema no te
	# ofrece borrarte a ti mismo desde dentro. Dos pulsaciones, porque esto se
	# lleva la memoria de todas las vueltas y no hay deshacer dentro del juego.
	_borrar = Button.new()
	_borrar.text = tr("CASA_BORRAR")
	_borrar.visible = false
	_borrar.pressed.connect(_al_pulsar_borrar)
	caja.add_child(_borrar)


func _entrar_en(fase: String) -> void:
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
	for salida in Espacio3D.construir(_mundo, espacio):
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


## Dónde se está. Los sitios del día están declarados uno por fase; el sueño no
## puede estarlo, porque son tres escenas distintas cada noche y cuáles depende
## de lo que se leyó ese día. Es la única fase que pregunta en vez de mirar el
## catálogo, y aun así esta pantalla no sabe qué forma tiene ninguna sala.
func _espacio_de(fase: String) -> Dictionary:
	if fase != "sueño":
		# En copia: el catálogo es una constante, y añadirle la plantilla de
		# esta vuelta encima la dejaría pegada para toda la partida.
		var sitio := EspaciosCatalogo.de_fase(fase).duplicate(true)
		sitio["figuras"] = _plantilla_en(sitio)
		return sitio

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
		var dia := Jornada.despertar_de_golpe(jornada)
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
	if partida.guardar():
		# Sección aparte y deliberadamente distinta de la partida (#535): si
		# esto falla no se cuenta como fallo de guardado de campaña, que es
		# lo que de verdad bloquea el tránsito.
		var escritorio_controller := get_node_or_null("EscritorioSigaController")
		if (
			escritorio_controller != null
			and escritorio_controller.has_method("guardar_estado_aplicaciones")
		):
			escritorio_controller.guardar_estado_aplicaciones()
		return true
	_transito_pendiente = destino
	_hablando = false
	_nomina.text = tr("ARCHIVO_ERROR_GUARDAR")
	return false


## El reintento. Solo vuelve a escribir el mismo estado —ni ficha, ni paga, ni
## gasta una acción— y, si esta vez sale, termina el tránsito que quedó a
## medias.
func _reintentar_guardado() -> void:
	var destino := _transito_pendiente
	if not _guardar_o_avisar(destino):
		return
	_transito_pendiente = ""
	_nomina.text = tr("ARCHIVO_GUARDADO_HECHO")
	if destino.is_empty():
		return
	if jornada["fase"] != "sueño":
		_sonar("puerta_abre")
	_entrar_en(destino)


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

	# Cada tránsito es un acto de la jornada, no solo un cambio de sala: al
	# salir de la oficina se ficha y se cobra; al meterse en la cama se paga el
	# día y el gato cuenta una noche más.
	match jornada["fase"]:
		"archivo":
			_registrar_firma_sin_prisa()
			Auditorias.resolver_fin_archivo(partida.estado)
			PronosticosAuditoria.resolver_fin_jornada(partida.estado)
			var paga := Jornada.fichar_salida(jornada)
			_sonar("nomina")
			_hablando = false
			_nomina.text = (
				tr("DIA_NOMINA")
				% [
					jornada["dia"],
					paga["bruto"],
					paga["base"],
					paga["por_expedientes"],
					paga["expedientes"],
					paga["dinero"]
				]
			)
		"casa":
			Auditorias.resolver_fin_casa(partida.estado)
			var noche := Jornada.dormir(jornada)
			_aplicar_politica_sueno()
			_hablando = false
			_nomina.text = (
				tr("DIA_VIVIR")
				% [
					noche["coste"],
					noche["dinero"],
					(
						(tr("DIA_SIN_GATO_AVISO") if noche["gato_se_fue"] else "")
						+ _aviso_imprevisto(noche)
					)
				]
			)
		"sueño":
			# Se sale de la escena que se acaba de recorrer. Si quedan más, la
			# noche sigue en la siguiente y no se despierta: el destino de la
			# salida ya lo decía.
			jornada["sueno_escenas"].pop_front()
			if jornada["sueno_escenas"].is_empty():
				_registrar_despertar_reglamentario()
				Auditorias.resolver_fin_sueno(partida.estado, true)
				var dia := Jornada.despertar(jornada)
				_hablando = false
				_nomina.text = tr("DIA_NUEVO") % dia
		_:
			pass
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


## Los compañeros de esta vida laboral, sentados donde el sitio diga.
##
## La plantilla se sortea por la semilla de la vuelta, que vive en la jornada:
## te reasignan y los de al lado son otros, pero volver a cargar la partida no
## los cambia. Una oficina cuya gente cambia al recargar no es una oficina.
func _plantilla_en(sitio: Dictionary) -> Array:
	var sitios: Array = sitio.get("sitios_companeros", [])
	if sitios.is_empty():
		return []
	var figuras := []
	var quienes := Companeros.plantilla(jornada["plantilla"])
	for i in mini(quienes.size(), sitios.size()):
		var quien: Dictionary = quienes[i]
		(
			figuras
			. append(
				{
					"pos": sitios[i],
					"color": quien["color"],
					"rotulo": tr(quien["nombre"]),
					"frase": Companeros.frase_de(quien, jornada["dia"]),
					"modelo": Companeros.cuerpo_de(quien),
					"retrato": quien.get("retrato", ""),
				}
			)
		)
	return figuras


## Los pasos. Suenan por DISTANCIA andada y no por tiempo: parado no se pisa,
## y a la misma velocidad la zancada es siempre la misma. Con un temporizador,
## quedarse quieto contra una pared seguiría sonando a alguien caminando.
func _andar(delta: float) -> void:
	if _pantalla != null or not _caminante.is_physics_processing():
		return
	var avance := Vector2(_caminante.velocity.x, _caminante.velocity.z).length() * delta
	_desde_paso += avance
	if _desde_paso < METROS_POR_ZANCADA:
		return
	_desde_paso = 0.0
	_pisada.stream = Sonido.paso_sobre(_suelo_pisado())
	_pisada.pitch_scale = randf_range(0.94, 1.06)
	_pisada.play()


## Qué se pisa: el suelo que declara el espacio, salvo que nieve en la calle. El
## sueño no declara suelo y conserva los pasos genéricos.
func _suelo_pisado() -> String:
	if (
		String(jornada.get("fase", "")) == "trayecto"
		and Clima.estado(int(jornada.get("dia", 1))) == Clima.NIEVE
	):
		return Sonido.NIEVE
	return String(_espacio_actual.get("textura_suelo", ""))


func _sonar(nombre: String) -> void:
	var stream := Sonido.stream(nombre)
	if stream != null:
		_voz.stream = stream
		_voz.play()


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
	_caminante.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_pantalla = CanvasLayer.new()
	add_child(_pantalla)
	_pantalla.add_child(load("res://escenas/visor.tscn").instantiate())

	# El botón de volver lo pone el DÍA y no el visor: el visor también se usa
	# suelto, y no tiene por qué saber que hay una oficina alrededor.
	var volver := Button.new()
	volver.theme = EstiloSiga.tema()
	volver.text = tr("PUESTO_LEVANTARSE")
	volver.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	volver.offset_left = -190
	volver.offset_top = 4
	volver.offset_right = -8
	volver.pressed.connect(_cerrar_expediente)
	_pantalla.add_child(volver)

	_hablando = false
	_nomina.text = tr("DIA_EN_EL_PUESTO")


## El duelo onírico, encima de la sala y sin salir de ella.
##
## Mientras está abierto el reloj de la noche se para: perder la noche dentro
## de un menú no sería una decisión del jugador, sería un descuido de quien
## montó la pantalla.
func _abrir_duelo(quien: Dictionary, zona: Area3D) -> void:
	_caminante.set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_pantalla = CanvasLayer.new()
	add_child(_pantalla)
	var duelo := SuenoDuelo.new()
	duelo.figura = quien
	duelo.cargas = historias.cargas(partida.estado)
	duelo.terminado.connect(_cerrar_duelo.bind(quien, zona))
	_pantalla.add_child(duelo)

	_hablando = false
	_nomina.text = ""


func _cerrar_duelo(gano: bool, quien: Dictionary, zona: Area3D) -> void:
	if _pantalla == null:
		return
	_pantalla.queue_free()
	_pantalla = null

	if not gano:
		Auditorias.resolver_fin_sueno(partida.estado, false)
	var final := SuenoCombate.resolver(partida.estado, jornada, quien, gano)
	# El duelo ya está resuelto en memoria, así que se devuelve el control pase
	# lo que pase: encerrar al jugador en una pantalla muerta no salva nada. Si
	# no se pudo escribir, el aviso queda puesto y pisar una salida reintenta.
	_guardar_o_avisar("")

	_caminante.set_physics_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if not final["gano"]:
		# Perder corta la noche: se despierta de golpe, con lo que eso cuesta
		# —el mapa no crece— y ni un castigo más.
		_nomina.text = tr("DIA_DESPERTAR_DE_GOLPE") % final["dia"]
		_entrar_en("archivo")
		return

	# Ganar: deja de estar ahí, y se ha dormido. La vida solo se dice cuando
	# de verdad se ha recuperado alguna; al tope, decirlo sería mentir.
	_rivales.erase(quien.get("id", ""))
	if zona.has_meta("cuerpo"):
		var cuerpo = zona.get_meta("cuerpo")
		if is_instance_valid(cuerpo):
			cuerpo.queue_free()
	zona.queue_free()
	_nomina.text = (
		tr("SUENO_DUELO_VIDA") % final["vida"]
		if final["recuperada"]
		else tr("SUENO_DUELO_SIN_VIDA")
	)


func _cerrar_expediente() -> void:
	if _pantalla == null:
		return
	_pantalla.queue_free()
	_pantalla = null
	_sonar("puerta_cierra")

	# De qué vida laboral se levantó. Se apunta ANTES de releer, porque firmar
	# puede haberla terminado y lo que vuelve del fichero sería ya la
	# siguiente, indistinguible de la de antes.
	var vuelta_antes := int(jornada.get("vuelta", 1))

	partida.cargar()
	jornada = Jornada.completar(partida.estado.get("jornada", Jornada.nueva(_raiz())), _raiz())
	partida.estado["jornada"] = jornada

	_caminante.set_physics_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
