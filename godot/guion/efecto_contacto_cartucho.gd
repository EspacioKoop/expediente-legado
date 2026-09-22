## Ruido visual de contacto de cartucho para la Portátil Color 98 (#1055).
##
## Es un único frame de presentación determinista. No recibe ROM, framebuffer
## nativo, SRAM ni referencias al emulador.
class_name EfectoContactoCartucho
extends ColorRect

const FRAMES_VISIBLES := 1

const SHADER_RUIDO := """
shader_type canvas_item;

void fragment() {
    float x = floor(FRAGCOORD.x);
    float y = floor(FRAGCOORD.y);
    float patron = mod(x * 17.0 + y * 31.0 + mod(y, 3.0) * 7.0, 23.0);
    float mascara = step(11.0, patron);
    vec3 oscuro = vec3(0.07, 0.09, 0.08);
    vec3 claro = vec3(0.72, 0.78, 0.69);
    COLOR = vec4(mix(oscuro, claro, mascara), 0.46);
}
"""

var _frames_restantes := FRAMES_VISIBLES


func iniciar() -> void:
	name = "RuidoContactoCartucho"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var shader := Shader.new()
	shader.code = SHADER_RUIDO
	var material_ruido := ShaderMaterial.new()
	material_ruido.shader = shader
	material = material_ruido
	set_process(true)


func _process(_delta: float) -> void:
	_frames_restantes -= 1
	if _frames_restantes <= 0:
		queue_free()
