#!/usr/bin/env python3
"""Construye un paquete de contexto pequeño y determinista desde una wiki local.

No usa red ni shell. La autoridad sigue siendo el repositorio/issue/Normas Platino;
este script solo reduce ruido documental para agentes.
"""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
import re
import unicodedata


TOKEN_RE = re.compile(r"[a-z0-9áéíóúüñ][a-z0-9áéíóúüñ_.:/-]*", re.IGNORECASE)
HEADING_RE = re.compile(r"^#{1,6}\s+(.+?)\s*$")
MAX_SOURCE_BYTES = 256_000

STOPWORDS = {
    "a", "al", "algo", "and", "ante", "as", "at", "con", "como", "de", "del",
    "desde", "el", "ella", "en", "es", "esta", "este", "for", "from", "ha", "hay",
    "in", "la", "las", "lo", "los", "más", "no", "o", "of", "on", "para", "por",
    "que", "se", "sin", "su", "sus", "the", "to", "un", "una", "unos", "unas",
    "with", "y",
}


@dataclass(frozen=True)
class Page:
    relpath: str
    title: str
    headings: tuple[str, ...]
    text: str
    tokens: Counter[str]


@dataclass(frozen=True)
class RankedPage:
    page: Page
    score: int
    reasons: tuple[str, ...]


def normalize(text: str) -> str:
    return unicodedata.normalize("NFKC", text).lower()


def tokens(text: str) -> list[str]:
    found = []
    for token in TOKEN_RE.findall(normalize(text)):
        clean = token.strip("._:/-")
        if len(clean) < 2 or clean in STOPWORDS:
            continue
        found.append(clean)
    return found


def path_terms(paths: list[str]) -> list[str]:
    terms: list[str] = []
    for raw in paths:
        value = normalize(raw.replace("\\", "/"))
        for part in value.split("/"):
            if not part:
                continue
            stem = part.rsplit(".", 1)[0]
            terms.extend(tokens(stem.replace("_", " ").replace("-", " ")))
    return terms


def read_page(root: Path, path: Path) -> Page | None:
    if path.is_symlink() or not path.is_file() or path.suffix.lower() != ".md":
        return None
    try:
        size = path.stat().st_size
    except OSError:
        return None
    if size <= 0 or size > MAX_SOURCE_BYTES:
        return None

    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return None

    rel = path.relative_to(root).as_posix()
    headings = tuple(
        match.group(1).strip()
        for line in text.splitlines()
        if (match := HEADING_RE.match(line))
    )
    title = headings[0] if headings else Path(rel).stem.replace("-", " ").replace("_", " ")
    return Page(
        relpath=rel,
        title=title,
        headings=headings,
        text=text,
        tokens=Counter(tokens(text)),
    )


def load_pages(root: Path) -> list[Page]:
    root = root.resolve()
    pages: list[Page] = []
    for path in sorted(root.rglob("*.md")):
        try:
            relative_parts = path.relative_to(root).parts
        except ValueError:
            continue
        if any(part.startswith(".") for part in relative_parts):
            continue
        page = read_page(root, path)
        if page is not None:
            pages.append(page)
    return pages


def rank_pages(
    pages: list[Page],
    issue_text: str,
    reserved_paths: list[str],
) -> list[RankedPage]:
    issue_tokens = Counter(tokens(issue_text))
    route_tokens = Counter(path_terms(reserved_paths))
    query = issue_tokens + route_tokens

    ranked: list[RankedPage] = []
    for page in pages:
        title_tokens = set(tokens(page.title))
        heading_tokens = set(tokens(" ".join(page.headings)))
        slug_tokens = set(tokens(page.relpath.replace("/", " ").replace("-", " ").replace("_", " ")))

        score = 0
        title_hits: list[str] = []
        heading_hits: list[str] = []
        body_hits: list[str] = []
        path_hits: list[str] = []

        for term, weight in query.items():
            capped_weight = min(weight, 4)
            if term in title_tokens:
                score += 12 * capped_weight
                title_hits.append(term)
            elif term in heading_tokens:
                score += 8 * capped_weight
                heading_hits.append(term)

            if term in slug_tokens:
                score += 10 * capped_weight
                path_hits.append(term)

            count = min(page.tokens.get(term, 0), 5)
            if count:
                score += count * min(3, capped_weight)
                body_hits.append(term)

        if score <= 0:
            continue

        reasons: list[str] = []
        if path_hits:
            reasons.append("ruta: " + ", ".join(sorted(set(path_hits))[:5]))
        if title_hits:
            reasons.append("título: " + ", ".join(sorted(set(title_hits))[:5]))
        if heading_hits:
            reasons.append("heading: " + ", ".join(sorted(set(heading_hits))[:5]))
        if body_hits:
            reasons.append("contenido: " + ", ".join(sorted(set(body_hits))[:5]))

        ranked.append(RankedPage(page=page, score=score, reasons=tuple(reasons)))

    ranked.sort(key=lambda item: (-item.score, item.page.relpath.casefold()))
    return ranked


def _append_with_budget(parts: list[str], chunk: str, max_bytes: int) -> bool:
    current = "".join(parts)
    remaining = max_bytes - len(current.encode("utf-8"))
    if remaining <= 0:
        return False

    encoded = chunk.encode("utf-8")
    if len(encoded) <= remaining:
        parts.append(chunk)
        return True

    marker = "\n\n[… contenido recortado por límite de contexto …]\n"
    marker_bytes = len(marker.encode("utf-8"))
    if remaining <= marker_bytes + 32:
        return False

    target = remaining - marker_bytes
    raw = encoded[:target]
    while raw:
        try:
            text = raw.decode("utf-8")
            break
        except UnicodeDecodeError:
            raw = raw[:-1]
    else:
        return False

    parts.append(text.rstrip() + marker)
    return False


def build_pack(
    ranked: list[RankedPage],
    *,
    max_pages: int,
    max_bytes: int,
    fallback_home: Page | None,
) -> str:
    parts = [
        "# Contexto seleccionado de la wiki\n\n",
        "> Contexto auxiliar. Si contradice el repositorio, el issue, #181/#182 o las Normas Platino, manda la fuente canónica.\n\n",
    ]

    selected = ranked[:max_pages]
    if not selected and fallback_home is not None:
        selected = [RankedPage(fallback_home, 0, ("fallback: Home",))]

    if not selected:
        parts.append("No se encontraron páginas relevantes.\n")
        return "".join(parts)

    inventory = ["## Selección\n\n"]
    for item in selected:
        reason = "; ".join(item.reasons) if item.reasons else "fallback"
        inventory.append(f"- `{item.page.relpath}` — score {item.score}; {reason}\n")
    inventory.append("\n")
    _append_with_budget(parts, "".join(inventory), max_bytes)

    for item in selected:
        reason = "; ".join(item.reasons) if item.reasons else "fallback"
        section = (
            f"## {item.page.relpath}\n\n"
            f"**Motivo de selección:** score {item.score}; {reason}.\n\n"
            f"{item.page.text.strip()}\n\n"
        )
        if not _append_with_budget(parts, section, max_bytes):
            break

    return "".join(parts)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wiki-dir", required=True, type=Path)
    parser.add_argument("--issue-file", required=True, type=Path)
    parser.add_argument("--path", dest="paths", action="append", default=[])
    parser.add_argument("--max-pages", type=int, default=8)
    parser.add_argument("--max-bytes", type=int, default=24_000)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.max_pages < 1:
        raise SystemExit("--max-pages debe ser >= 1")
    if args.max_bytes < 1_024:
        raise SystemExit("--max-bytes debe ser >= 1024")

    wiki_root = args.wiki_dir.resolve()
    if not wiki_root.is_dir():
        raise SystemExit("wiki-dir no existe o no es directorio")

    issue_text = args.issue_file.read_text(encoding="utf-8")
    pages = load_pages(wiki_root)
    ranked = rank_pages(pages, issue_text, args.paths)
    home = next(
        (page for page in pages if page.relpath.casefold() in {"home.md", "readme.md"}),
        None,
    )
    packed = build_pack(
        ranked,
        max_pages=args.max_pages,
        max_bytes=args.max_bytes,
        fallback_home=home,
    )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(packed, encoding="utf-8")
    print(
        f"context-pack: {len(packed.encode('utf-8'))} bytes; "
        f"{min(len(ranked), args.max_pages)} páginas con score"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
