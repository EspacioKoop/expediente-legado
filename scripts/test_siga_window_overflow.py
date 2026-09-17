from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VISUAL = ROOT / "godot" / "guion" / "escritorio_siga_visual.gd"


def fuente() -> str:
    return VISUAL.read_text(encoding="utf-8")


def test_ventanas_os98_recortan_contenido_al_marco() -> None:
    texto = fuente()
    assert "panel.clip_contents = true" in texto


def test_ventana_adopta_minimo_real_del_contenido() -> None:
    texto = fuente()
    for fragmento in (
        "contenido.get_combined_minimum_size()",
        'datos["tamano_minimo"] = minimo_real',
        "panel.size.x = maxf(panel.size.x, minimo_real.x)",
        "panel.size.y = maxf(panel.size.y, minimo_real.y)",
        "_limitar_ventana(panel, minimo_real)",
    ):
        assert fragmento in texto
