#!/usr/bin/env python3
"""Pruebas unitarias para las funciones públicas y clases de agent_context_pack.py."""

from collections import Counter
from dataclasses import FrozenInstanceError
from pathlib import Path
import tempfile
import unittest

from scripts.agent_context_pack import (
    MAX_SOURCE_BYTES,
    Page,
    RankedPage,
    path_terms,
    read_page,
    tokens,
)


class TestTokens(unittest.TestCase):
    """Pruebas para la función tokens()."""

    def test_tokens_basico_y_normalizacion(self) -> None:
        text = "Hello, WORLD!_ test-ing 123... a the"
        resultado = tokens(text)
        self.assertEqual(resultado, ["hello", "world", "test-ing", "123"])

    def test_tokens_caracteres_espanol_y_stopwords(self) -> None:
        text = "Información MÁS Canción de un archivo datos"
        resultado = tokens(text)
        self.assertEqual(resultado, ["información", "canción", "archivo", "datos"])

    def test_tokens_puntuacion_bordeadora(self) -> None:
        text = "...-/_codigo_:-..."
        resultado = tokens(text)
        self.assertEqual(resultado, ["codigo"])


class TestPathTerms(unittest.TestCase):
    """Pruebas para la función path_terms()."""

    def test_path_terms_rutas(self) -> None:
        paths = ["src/utils/my_file.py", "docs\\\\guide_v1.md", "README.txt"]
        resultado = path_terms(paths)
        self.assertEqual(
            resultado,
            ["src", "utils", "my", "file", "docs", "guide", "v1", "readme"],
        )


class TestDataclasses(unittest.TestCase):
    """Pruebas para las dataclasses Page y RankedPage."""

    def test_page_dataclass_inmutable(self) -> None:
        page = Page(
            relpath="doc.md",
            title="Título",
            headings=("Título", "Sección"),
            text="# Título\nContenido",
            tokens=Counter({"contenido": 1}),
        )
        self.assertEqual(page.relpath, "doc.md")
        self.assertEqual(page.title, "Título")
        self.assertEqual(page.headings, ("Título", "Sección"))
        self.assertEqual(page.text, "# Título\nContenido")
        self.assertEqual(page.tokens, Counter({"contenido": 1}))

        with self.assertRaises(FrozenInstanceError):
            page.title = "Nuevo Título"  # type: ignore[misc]

    def test_ranked_page_dataclass_inmutable(self) -> None:
        page = Page(
            relpath="doc.md",
            title="Título",
            headings=("Título",),
            text="Texto",
            tokens=Counter({"texto": 1}),
        )
        ranked = RankedPage(page=page, score=15, reasons=("título: título",))
        self.assertEqual(ranked.page, page)
        self.assertEqual(ranked.score, 15)
        self.assertEqual(ranked.reasons, ("título: título",))

        with self.assertRaises(FrozenInstanceError):
            ranked.score = 20  # type: ignore[misc]


class TestReadPage(unittest.TestCase):
    """Pruebas para la función read_page()."""

    def test_read_page_markdown_normal_con_headings(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            md_file = root / "docs" / "introduccion.md"
            md_file.parent.mkdir(parents=True, exist_ok=True)
            contenido = "# Título Principal\n\nTexto de ejemplo.\n\n## Subtítulo\n\nMás texto."
            md_file.write_text(contenido, encoding="utf-8")

            page = read_page(root, md_file)
            self.assertIsNotNone(page)
            assert page is not None
            self.assertEqual(page.relpath, "docs/introduccion.md")
            self.assertEqual(page.title, "Título Principal")
            self.assertEqual(page.headings, ("Título Principal", "Subtítulo"))
            self.assertEqual(page.text, contenido)
            self.assertIn("principal", page.tokens)

    def test_read_page_markdown_sin_headings(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            md_file = root / "mi_primer-documento.md"
            contenido = "Texto plano sin encabezados en el archivo."
            md_file.write_text(contenido, encoding="utf-8")

            page = read_page(root, md_file)
            self.assertIsNotNone(page)
            assert page is not None
            self.assertEqual(page.title, "mi primer documento")
            self.assertEqual(page.headings, ())

    def test_read_page_fichero_vacio(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            md_file = root / "vacio.md"
            md_file.write_text("", encoding="utf-8")

            page = read_page(root, md_file)
            self.assertIsNone(page)

    def test_read_page_fichero_no_utf8(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            md_file = root / "binario.md"
            md_file.write_bytes(bytes([0x80, 0x81, 0xFE, 0xFF]))

            page = read_page(root, md_file)
            self.assertIsNone(page)

    def test_read_page_fichero_no_md(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            txt_file = root / "documento.txt"
            txt_file.write_text("Contenido", encoding="utf-8")

            page = read_page(root, txt_file)
            self.assertIsNone(page)

    def test_read_page_enlace_simbolico(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            real_file = root / "real.md"
            real_file.write_text("# Real", encoding="utf-8")
            symlink = root / "link.md"
            try:
                symlink.symlink_to(real_file)
            except (OSError, NotImplementedError):
                self.skipTest("Symlinks no soportados en el entorno")

            page = read_page(root, symlink)
            self.assertIsNone(page)

    def test_read_page_fichero_demasiado_grande(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            big_file = root / "gigante.md"
            big_file.write_text("a" * (MAX_SOURCE_BYTES + 1), encoding="utf-8")

            page = read_page(root, big_file)
            self.assertIsNone(page)

    @unittest.expectedFailure
    def test_read_page_ruta_fuera_de_raiz(self) -> None:
        """read_page debería devolver None cuando la ruta está fuera de la raíz.

        Fallo conocido: read_page ejecuta path.relative_to(root) sin capturar ValueError,
        provocando una excepción en lugar de devolver None.
        """
        with tempfile.TemporaryDirectory() as tmpdir1, tempfile.TemporaryDirectory() as tmpdir2:
            root = Path(tmpdir1)
            fuera_file = Path(tmpdir2) / "fuera.md"
            fuera_file.write_text("# Fuera", encoding="utf-8")

            page = read_page(root, fuera_file)
            self.assertIsNone(page)


if __name__ == "__main__":
    unittest.main()
