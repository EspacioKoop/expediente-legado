from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "visor_metadatos_app.gd"
ANEXOS = ROOT / "godot" / "guion" / "visor_anexos_app.gd"
PRONOSTICOS = ROOT / "godot" / "guion" / "visor_pronosticos_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "visor.tscn"


def fuente() -> str:
    return CAPA.read_text(encoding="utf-8")


def test_la_escena_activa_la_capa_sobre_anotaciones() -> None:
    texto = fuente()
    escena = ESCENA.read_text(encoding="utf-8")
    anexos = ANEXOS.read_text(encoding="utf-8")
    pronosticos = PRONOSTICOS.read_text(encoding="utf-8")
    assert 'res://guion/visor_pronosticos_app.gd' in escena
    assert 'extends "res://guion/visor_anexos_app.gd"' in pronosticos
    assert 'extends "res://guion/visor_metadatos_app.gd"' in anexos
    assert 'extends "res://guion/visor_anotaciones_app.gd"' in texto


def test_solo_presenta_metadatos_existentes_del_registro() -> None:
    texto = fuente()
    assert 'registro.get("folio", "")' in texto
    assert 'registro.get("tipo", "")' in texto
    assert 'registro.get("fecha", "")' in texto
    assert 'return " · ".join(partes)' in texto


def test_no_descubre_pistas_ni_toca_reglas_de_resolucion() -> None:
    texto = fuente()
    assert "descubiertas.append" not in texto
    assert "_buscar_relacion" not in texto
    assert "Acusacion" not in texto
    assert "partida.estado" not in texto


def test_refresca_al_cambiar_de_documento_o_caso() -> None:
    texto = fuente()
    assert texto.count("_actualizar_metadatos()") >= 3
    assert "super._al_elegir_documento(indice)" in texto
    assert "super._al_elegir_caso(indice)" in texto
