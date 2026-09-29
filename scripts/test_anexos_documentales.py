from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "anexos_documentales.gd"


def sin_comentarios(texto: str) -> str:
    """Código sin líneas de comentario: una prohibición no debe saltar por la doc."""
    return "\n".join(l for l in texto.splitlines() if not l.lstrip().startswith("#"))


def fuente() -> str:
    return CAPA.read_text(encoding="utf-8")


class AnexosDocumentalesTest(unittest.TestCase):
    def test_el_contrato_es_opcional_y_no_toca_pistas(self) -> None:
        texto = fuente()
        assert 'if not registro.has("anexos"):' in texto
        assert 'return resultado' in texto
        assert "pistas_descubiertas" not in texto
        assert "Acusacion" not in texto

    def test_valida_ids_unicos_y_tipos_permitidos(self) -> None:
        texto = fuente()
        assert 'const TIPOS_VALIDOS := ["texto", "sello", "imagen", "metadato"]' in texto
        assert 'errores_salida.append("id_duplicado:%s" % anexo_id)' in texto
        assert 'errores_salida.append("tipo_invalido:%s" % tipo)' in texto

    def test_exige_titulo_y_contenido_o_recurso(self) -> None:
        texto = fuente()
        assert 'anexo.get("titulo", anexo.get("etiqueta", ""))' in texto
        assert 'var contenido := String(anexo.get("contenido", ""))' in texto
        assert 'var recurso := String(anexo.get("recurso", ""))' in texto
        assert 'if contenido.is_empty() and recurso.is_empty():' in texto

    def test_rechaza_registro_de_catalogo_inexistente(self) -> None:
        texto = fuente()
        assert "static func errores_catalogo" in texto
        assert 'resultado.append("registro_inexistente:%s" % id)' in texto
        assert "static func ids_registro" in texto

    def test_recurso_debe_ser_local_existir_y_declarar_procedencia(self) -> None:
        texto = fuente()
        assert 'recurso.begins_with("res://")' in texto
        assert "FileAccess.file_exists(recurso)" in texto
        assert 'errores_salida.append("recurso_no_local:%s" % anexo_id)' in texto
        assert 'errores_salida.append("recurso_inexistente:%s" % anexo_id)' in texto
        assert 'anexo.get("procedencia", "")' in texto
        assert 'anexo.get("licencia", "")' in texto

    def test_no_modifica_casos_json_ni_visor(self) -> None:
        texto = fuente()
        assert "casos.json" not in texto
        assert "visor" not in sin_comentarios(texto).lower()


if __name__ == "__main__":
    unittest.main()
