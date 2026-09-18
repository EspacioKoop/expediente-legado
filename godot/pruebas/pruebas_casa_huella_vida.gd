extends SceneTree

const CasaEstadoAmbiental = preload("res://guion/casa_estado_ambiental.gd")
const CasaHuellaVida = preload("res://guion/casa_huella_vida_3d.gd")
const CasaUtileriaScript = preload("res://guion/casa_utileria.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var casa := Node3D.new()
	root.add_child(casa)
	CasaUtileriaScript.montar(casa)

	var estado := {
		"comida_estado": CasaEstadoAmbiental.COMIDA_RECIENTE,
		"alquiler_estado": CasaEstadoAmbiental.ALQUILER_PAGADO,
		"vuelta": 4,
	}
	var firma := CasaHuellaVida.firma(estado)
	var capa := CasaHuellaVida.montar(casa, estado)
	_comprobar(capa != null, "monta la capa vital")
	_comprobar(capa.get_node_or_null("DespensaConComida") != null, "comer deja despensa legible")
	_comprobar(capa.get_node_or_null("ReciboAlquilerPagado") != null, "pagar deja recibo")
	var vueltas := capa.get_node_or_null("VueltasCasa")
	_comprobar(vueltas != null, "las vueltas previas dejan una pila")
	if vueltas != null:
		_comprobar(vueltas.get_child_count() == 3, "vuelta cuatro deja tres carpetas previas")
		_comprobar(
			vueltas.get_node_or_null("CarpetaVuelta01") != null, "la primera vuelta deja carpeta"
		)
		_comprobar(
			vueltas.get_node_or_null("CarpetaVuelta03") != null, "la tercera vuelta deja carpeta"
		)
	_comprobar(CasaHuellaVida.firma(estado) == firma, "la firma es estable")

	var peor := {
		"comida_estado": CasaEstadoAmbiental.COMIDA_FALTA,
		"alquiler_estado": CasaEstadoAmbiental.ALQUILER_IMPAGO,
		"vuelta": 2,
	}
	var reemplazo := CasaHuellaVida.montar(casa, peor)
	_comprobar(reemplazo.get_node_or_null("DespensaEscasa") != null, "no comer cambia la cocina")
	_comprobar(
		reemplazo.get_node_or_null("AvisoAlquilerImpagado") != null,
		"un impago cambia el papel doméstico"
	)
	var vueltas_dos := reemplazo.get_node_or_null("VueltasCasa")
	_comprobar(
		vueltas_dos != null and vueltas_dos.get_child_count() == 1, "vuelta dos deja una carpeta"
	)
	_comprobar(
		casa.find_children(CasaHuellaVida.NOMBRE_RAIZ, "Node3D", false, false).size() == 1,
		"el montaje es idempotente"
	)

	var inicial := {
		"comida_estado": CasaEstadoAmbiental.COMIDA_RECIENTE,
		"alquiler_estado": CasaEstadoAmbiental.ALQUILER_SIN_HISTORIAL,
		"vuelta": 1,
	}
	var limpia := CasaHuellaVida.montar(casa, inicial)
	_comprobar(
		limpia.get_node_or_null("DespensaConComida") != null, "la primera vida puede tener comida"
	)
	_comprobar(
		limpia.get_node_or_null("VueltasCasa") == null, "la primera vida no inventa historial"
	)
	_comprobar(
		limpia.get_node_or_null("ReciboAlquilerPagado") == null,
		"sin vencimientos no inventa recibo"
	)
	_comprobar(
		limpia.get_node_or_null("AvisoAlquilerImpagado") == null,
		"sin vencimientos no inventa aviso"
	)

	casa.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
