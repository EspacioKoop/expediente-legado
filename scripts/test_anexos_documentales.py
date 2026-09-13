from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "anexos_documentales.gd"


def fuente() -> str:
    return CAPA.read_text(encoding="utf-8")


def test_el_contrato_es_opcional_y_no_toca_pistas() -> None:
    texto = fuente()
    assert 'if not registro.has("anexos"):' in texto
    assert 'return resultado' in texto
    assert "pistas_descubiertas" not in texto
    assert "Acusacion" not in texto


def test_valida_ids_unicos_y_tipos_permitidos() -> None:
    texto = fuente()
    assert 'const TIPOS_VALIDOS := ["texto", "sello", "imagen", "metadato"]' in texto
    assert 'errores_salida.append("id_duplicado:%s" % anexo_id)' in texto
    assert 'errores_salida.append("tipo_invalido:%s" % tipo)' in texto


def test_exige_titulo_y_contenido_o_recurso() -> None:
    texto = fuente()
    assert 'anexo.get("titulo", anexo.get("etiqueta", ""))' in texto
    assert 'var contenido := String(anexo.get("contenido", ""))' in texto
    assert 'var recurso := String(anexo.get("recurso", ""))' in texto
    assert 'if contenido.is_empty() and recurso.is_empty():' in texto


def test_no_modifica_casos_json_ni_visor() -> None:
    texto = fuente()
    assert "casos.json" not in texto
    assert "visor" not in texto.lower()
