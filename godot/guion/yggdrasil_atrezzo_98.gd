## Atrezzo doméstico de Yggdrasil (#653).
##
## Este recorte es solo dressing visual: no añade colisión, interacción ni
## siembra onírica. La activación deliberada sigue perteneciendo al póster de
## YggdrasilVigilia, de modo que ver el bonsái no altera el estado de partida.
class_name YggdrasilAtrezzo98
extends RefCounted

const TEXTURA_BONSAI: Texture2D = preload(
	"res://assets/texturas/yggdrasil_ai_98/bonsai_yggdrasil_98.webp"
)
const NOMBRE := "AtrezzoYggdrasilCasa"
const POSICION := Vector3(3.72, 0.55, 2.15)
const ALTURA := 0.82


static func montar_casa(mundo: Node3D) -> Node3D:
	if mundo == null:
		return null
	var existente := mundo.get_node_or_null(NOMBRE) as Node3D
	if existente != null:
		return existente

	var raiz := Node3D.new()
	raiz.name = NOMBRE
	mundo.add_child(raiz)

	var sprite := Sprite3D.new()
	sprite.name = "BonsaiYggdrasil98"
	sprite.texture = TEXTURA_BONSAI
	sprite.position = POSICION
	sprite.pixel_size = ALTURA / maxf(float(TEXTURA_BONSAI.get_height()), 1.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.16
	sprite.shaded = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.set_meta("atrezzo_yggdrasil_98", true)
	raiz.add_child(sprite)
	return raiz
