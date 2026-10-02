## Presentación 3D cultural del Cíclope (#2128).
##
## Capa visual sobre el runtime genérico EMBESTIDOR.
## Consume estados y rumbo para definir poses y gestos sin tocar la mecánica.
class_name JuicioCombateCiclope3D
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")

## Silueta placeholder: Cíclope es una masa pesada y frontal.
const ESCALA_CILUPE := Vector3(1.4, 2.2, 1.2)


static func montar_presentacion(anfitrion: Node3D) -> Node3D:
	var contenedor := Node3D.new()
	contenedor.name = "PresentacionCiclope"

	var cuerpo := MeshInstance3D.new()
	cuerpo.name = "Cuerpo"
	var malla := CapsuleMesh.new()
	malla.radius = 0.7
	malla.height = 2.0
	cuerpo.mesh = malla
	cuerpo.scale = ESCALA_CILUPE

	contenedor.add_child(cuerpo)
	anfitrion.add_child(contenedor)
	return contenedor


static func actualizar_pose(
	presentacion: Node3D,
	unidad: Dictionary,
	delta: float,
) -> void:
	if presentacion == null:
		return

	var estado := String(unidad.get("estado", ""))
	var cuerpo := presentacion.get_node_or_null("Cuerpo") as MeshInstance3D
	if cuerpo == null:
		return

	## Interpolación suave de poses según el estado del runtime EMBESTIDOR
	match estado:
		ARQUETIPOS.TELEGRAFIAR:
			## Postura de telegraph: leve retroceso o tensión frontal
			## Coherente con 'carga_lineal'
			cuerpo.position = cuerpo.position.lerp(Vector3(0.0, 0.0, -0.2), delta * 5.0)
			cuerpo.rotation.x = lerp(cuerpo.rotation.x, deg_to_rad(-10.0), delta * 5.0)

		ARQUETIPOS.CARGAR:
			## Postura de carga: máxima tensión hacia adelante
			cuerpo.position = cuerpo.position.lerp(Vector3(0.0, 0.0, 0.0), delta * 10.0)
			cuerpo.rotation.x = lerp(cuerpo.rotation.x, deg_to_rad(5.0), delta * 10.0)

		ARQUETIPOS.RECUPERAR:
			## Gesto de recuperación: desplome o balanceo tras choque/fallo
			cuerpo.position = cuerpo.position.lerp(Vector3(0.0, -0.1, 0.1), delta * 3.0)
			cuerpo.rotation.x = lerp(cuerpo.rotation.x, deg_to_rad(-20.0), delta * 3.0)

		_:
			## Pose estática / Reposo
			## 'reduccion_movimiento' conserva la lectura al no haber transiciones bruscas
			cuerpo.position = cuerpo.position.lerp(Vector3.ZERO, delta * 2.0)
			cuerpo.rotation = cuerpo.rotation.lerp(Vector3.ZERO, delta * 2.0)
