#!/usr/bin/env python3
"""
Script de auditoría de audio para issue #2740
Inventario de audio roto y referencias inexistentes

Este script analiza:
1. Todos los archivos de audio existentes en godot/assets/audio/
2. Todas las referencias a audio en archivos .gd
3. Identifica:
   - Archivos de audio que no están referenciados (potencialmente muertos)
   - Referencias a archivos de audio que no existen (rotas)
   - Uso de AudioStreamPlayer y AudioStreamPlayer3D
   - Patrones de carga (load, preload, ResourceLoader)
"""

import os
import re
import json
from pathlib import Path
from dataclasses import dataclass, field
from typing import Dict, List, Set, Tuple, Optional


@dataclass
class AudioFile:
    """Representa un archivo de audio en el proyecto"""
    path: str  # Ruta relativa desde godot/assets/audio
    full_path: str
    size: int
    extension: str


@dataclass
class AudioReference:
    """Representa una referencia a audio en el código"""
    file_path: str  # Archivo .gd donde se referencia
    reference: str  # La referencia (puede ser nombre de archivo o ruta)
    line: Optional[int] = None
    context: Optional[str] = None  # load, preload, CATALOGO, etc.


@dataclass
class AuditResult:
    """Resultado completo de la auditoría"""
    total_files: int = 0
    total_references: int = 0
    unreferenced_files: List[str] = field(default_factory=list)
    broken_references: List[Tuple[str, str]] = field(default_factory=list)  # (archivo_gd, referencia)
    audio_players: Dict[str, List[int]] = field(default_factory=dict)  # archivo: lineas
    load_patterns: Dict[str, List[int]] = field(default_factory=dict)  # patron: lineas
    summary: Dict = field(default_factory=dict)


class AudioAuditor:
    """Clase principal para auditar el audio del proyecto"""
    
    def __init__(self, project_root: str = "godot"):
        self.project_root = project_root
        self.audio_root = os.path.join(project_root, "assets", "audio")
        self.audio_files: Dict[str, AudioFile] = {}
        self.references: List[AudioReference] = []
        self.scan_results: AuditResult = AuditResult()
    
    def scan_audio_files(self) -> None:
        """Escanea todos los archivos de audio en el proyecto"""
        if not os.path.exists(self.audio_root):
            print(f"⚠ Advertencia: {self.audio_root} no existe")
            return
        
        for root, dirs, files in os.walk(self.audio_root):
            for file in files:
                if file.lower().endswith((".ogg", ".wav", ".mp3")):
                    full_path = os.path.join(root, file)
                    rel_path = os.path.relpath(full_path, self.audio_root)
                    size = os.path.getsize(full_path)
                    extension = os.path.splitext(file)[1].lower()
                    
                    self.audio_files[rel_path] = AudioFile(
                        path=rel_path,
                        full_path=full_path,
                        size=size,
                        extension=extension
                    )
        
        self.scan_results.total_files = len(self.audio_files)
    
    def scan_gdscript_files(self) -> None:
        """Escanea todos los archivos .gd en busca de referencias de audio"""
        gdscript_root = self.project_root
        
        for root, dirs, files in os.walk(gdscript_root):
            # Saltar directorios de pruebas y debug
            if any(skip in root for skip in ['pruebas', 'debug', '.git']):
                continue
            
            for file in files:
                if file.endswith('.gd'):
                    file_path = os.path.join(root, file)
                    self._scan_gd_file(file_path)
        
        self.scan_results.total_references = len(self.references)
    
    def _scan_gd_file(self, file_path: str) -> None:
        """Escanea un archivo .gd en busca de referencias de audio"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
                content = ''.join(lines)
            
            # Buscar AudioStreamPlayer
            audio_player_matches = re.finditer(
                r'AudioStreamPlayer(?:3D|2D)?\b',
                content
            )
            for match in audio_player_matches:
                line_num = content[:match.start()].count('\n') + 1
                if file_path not in self.scan_results.audio_players:
                    self.scan_results.audio_players[file_path] = []
                if line_num not in self.scan_results.audio_players[file_path]:
                    self.scan_results.audio_players[file_path].append(line_num)
            
            # Buscar patrones de carga
            load_patterns = [
                (r'load\(', 'load'),
                (r'preload\(', 'preload'),
                (r'ResourceLoader\.load\(', 'ResourceLoader.load'),
            ]
            
            for pattern, name in load_patterns:
                matches = re.finditer(pattern, content)
                for match in matches:
                    line_num = content[:match.start()].count('\n') + 1
                    if name not in self.scan_results.load_patterns:
                        self.scan_results.load_patterns[name] = []
                    if line_num not in self.scan_results.load_patterns[name]:
                        self.scan_results.load_patterns[name].append(line_num)
            
            # Para sonido.gd, extraer referencias de CATALOGO, FAMILIAS, etc.
            if 'sonido.gd' in file_path:
                self._extract_sonido_gd_references(file_path, content)
                return
            
            # Para musica.gd, extraer referencias
            if 'musica.gd' in file_path:
                self._extract_musica_gd_references(file_path, content)
                return
            
            # Para otros archivos, buscar referencias a archivos de audio
            audio_ref_patterns = [
                (r'["\'](assets/audio/[^"\']+\.(?:ogg|wav|mp3))["\']', 'full_path'),
                (r'["\']([a-zA-Z0-9_\-]+/)*[a-zA-Z0-9_\-]+\.(?:ogg|wav|mp3)["\']', 'filename'),
            ]
            
            for pattern, ref_type in audio_ref_patterns:
                matches = re.finditer(pattern, content)
                for match in matches:
                    ref = match.group(1)
                    line_num = content[:match.start()].count('\n') + 1
                    
                    # Determinar contexto
                    context = self._determine_context(content, match.start())
                    
                    self.references.append(AudioReference(
                        file_path=file_path,
                        reference=ref,
                        line=line_num,
                        context=context
                    ))
                    
        except Exception as e:
            print(f"⚠ Error leyendo {file_path}: {e}")
    
    def _extract_sonido_gd_references(self, file_path: str, content: str) -> None:
        """Extrae todas las referencias de audio de sonido.gd específicamente"""
        
        # Extraer de PASOS array
        pasos_match = re.search(r'const PASOS := \[(.*?)\]', content, re.DOTALL)
        if pasos_match:
            pasos_content = pasos_match.group(1)
            for match in re.finditer(r'"([^"]+\.ogg)"', pasos_content):
                self.references.append(AudioReference(
                    file_path=file_path,
                    reference=match.group(1),
                    line=None,
                    context='PASOS'
                ))
        
        # Extraer de PASOS_POR_SUELO
        pasos_suelo_match = re.search(r'const PASOS_POR_SUELO := \{(.*?)\n\}', content, re.DOTALL)
        if pasos_suelo_match:
            pasos_suelo_content = pasos_suelo_match.group(1)
            for match in re.finditer(r'"([^"]+\.ogg)"', pasos_suelo_content):
                self.references.append(AudioReference(
                    file_path=file_path,
                    reference=match.group(1),
                    line=None,
                    context='PASOS_POR_SUELO'
                ))
        
        # Extraer de CATALOGO
        catalogo_match = re.search(r'const CATALOGO := \{(.*?)\n\}', content, re.DOTALL)
        if catalogo_match:
            catalogo_content = catalogo_match.group(1)
            for match in re.finditer(r'"([^"]+\.ogg)"', catalogo_content):
                self.references.append(AudioReference(
                    file_path=file_path,
                    reference=match.group(1),
                    line=None,
                    context='CATALOGO'
                ))
        
        # Extraer de FAMILIAS
        familias_match = re.search(r'const FAMILIAS := \{(.*?)\n\}', content, re.DOTALL)
        if familias_match:
            familias_content = familias_match.group(1)
            for match in re.finditer(r'"([^"]+\.ogg)"', familias_content):
                self.references.append(AudioReference(
                    file_path=file_path,
                    reference=match.group(1),
                    line=None,
                    context='FAMILIAS'
                ))
        
        # Extraer de FAMILIAS_RESPALDO
        respaldo_match = re.search(r'const FAMILIAS_RESPALDO := \{(.*?)\n\}', content, re.DOTALL)
        if respaldo_match:
            respaldo_content = respaldo_match.group(1)
            for match in re.finditer(r'"([^"]+\.ogg)"', respaldo_content):
                self.references.append(AudioReference(
                    file_path=file_path,
                    reference=match.group(1),
                    line=None,
                    context='FAMILIAS_RESPALDO'
                ))
        
        # Extraer IMPACTO_CAREO
        impacto_match = re.search(r'const IMPACTO_CAREO := "([^"]+)"', content)
        if impacto_match:
            self.references.append(AudioReference(
                file_path=file_path,
                reference=impacto_match.group(1),
                line=None,
                context='IMPACTO_CAREO'
            ))
    
    def _extract_musica_gd_references(self, file_path: str, content: str) -> None:
        """Extrae todas las referencias de audio de musica.gd específicamente"""
        
        # Extraer RUTA
        ruta_match = re.search(r'const RUTA := "([^"]+)"', content)
        if ruta_match:
            ruta = ruta_match.group(1)
            # Verificar si el directorio existe
            dir_path = os.path.join(self.project_root, ruta.replace('res://', ''))
            if not os.path.exists(dir_path):
                self.references.append(AudioReference(
                    file_path=file_path,
                    reference=ruta,
                    line=None,
                    context='RUTA_MISSING'
                ))
            else:
                self.references.append(AudioReference(
                    file_path=file_path,
                    reference=ruta,
                    line=None,
                    context='RUTA'
                ))
        
        # Extraer CATALOGO - incluir valores vacíos también
        catalogo_match = re.search(r'const CATALOGO := \{(.*?)\n\}', content, re.DOTALL)
        if catalogo_match:
            catalogo_content = catalogo_match.group(1)
            for match in re.finditer(r'"([^"]*)"', catalogo_content):
                value = match.group(1)
                self.references.append(AudioReference(
                    file_path=file_path,
                    reference=value if value else '(empty)',
                    line=None,
                    context='CATALOGO'
                ))
        
        # Extraer INICIO_BUCLE_POR_FICHERO
        bucle_match = re.search(r'const INICIO_BUCLE_POR_FICHERO := \{(.*?)\n\}', content, re.DOTALL)
        if bucle_match:
            bucle_content = bucle_match.group(1)
            for match in re.finditer(r'"([^"]+\.ogg)"', bucle_content):
                self.references.append(AudioReference(
                    file_path=file_path,
                    reference=match.group(1),
                    line=None,
                    context='INICIO_BUCLE_POR_FICHERO'
                ))
    
    def _determine_context(self, content: str, position: int) -> str:
        """Determina el contexto de una referencia (load, preload, CATALOGO, etc.)"""
        # Buscar hacia atrás para encontrar la palabra clave
        before = content[:position]
        
        # Buscar en los últimos 200 caracteres
        context_window = before[-200:]
        
        if 'load(' in context_window or 'preload(' in context_window:
            return 'load/preload'
        elif 'CATALOGO' in context_window or 'FAMILIAS' in context_window:
            return 'CATALOGO/FAMILIAS'
        elif 'stream(' in context_window:
            return 'stream()'
        else:
            return 'string_literal'
    
    def find_unreferenced_files(self) -> List[str]:
        """Encuentra archivos de audio que no están referenciados"""
        referenced = set()
        
        for ref in self.references:
            if ref.reference is None:
                continue
            # Normalizar la referencia
            ref_path = ref.reference
            if ref_path.startswith('assets/audio/'):
                ref_path = ref_path[len('assets/audio/'):]
            referenced.add(ref_path)
        
        unreferenced = []
        for file_path, audio_file in self.audio_files.items():
            if audio_file.path not in referenced:
                unreferenced.append(audio_file.path)
        
        return sorted(unreferenced)
    
    def find_broken_references(self) -> List[Tuple[str, str, int]]:
        """Encuentra referencias a archivos que no existen"""
        broken = []
        
        for ref in self.references:
            if ref.reference is None:
                continue
            ref_path = ref.reference
            
            # Saltar referencias especiales
            if ref_path in ['(empty)', 'careo', 'final']:
                # Estas son claves de CATALOGO, no archivos
                continue
            if ref_path.startswith('res://'):
                # Ruta completa, verificar si existe
                full_path = os.path.join(self.project_root, ref_path.replace('res://', ''))
                if not os.path.exists(full_path):
                    broken.append((ref.file_path, ref.reference, ref.line or 0))
                continue
            
            # Probar diferentes interpretaciones
            possible_paths = [
                os.path.join(self.audio_root, ref_path),
                os.path.join(self.audio_root, ref_path.replace('assets/audio/', '')),
                os.path.join(self.project_root, ref_path),
            ]
            
            exists = any(os.path.exists(p) for p in possible_paths)
            
            if not exists:
                # Verificar si es una referencia a chip/ (que sí existe)
                if 'chip/' in ref_path:
                    chip_path = os.path.join(self.audio_root, ref_path)
                    if not os.path.exists(chip_path):
                        broken.append((ref.file_path, ref.reference, ref.line or 0))
                else:
                    broken.append((ref.file_path, ref.reference, ref.line or 0))
        
        # También buscar en archivos .gd referencias a rutas de audio que no existen
        for root, dirs, files in os.walk(self.project_root):
            for file in files:
                if file.endswith('.gd'):
                    filepath = os.path.join(root, file)
                    try:
                        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                            content = f.read()
                            # Buscar strings que parezcan rutas de audio
                            for match in re.finditer(r'["\'](assets/audio/[^"\']+\.ogg)["\']', content):
                                audio_path = match.group(1)
                                full_path = os.path.join(self.project_root, audio_path)
                                if not os.path.exists(full_path):
                                    line_num = content[:match.start()].count('\n') + 1
                                    broken.append((filepath, audio_path, line_num))
                    except:
                        pass
        
        return broken
    
    def find_duplicate_files(self) -> List[Tuple[str, List[str]]]:
        """Encuentra archivos con el mismo nombre en diferentes rutas"""
        name_map: Dict[str, List[str]] = {}
        
        for file_path, audio_file in self.audio_files.items():
            name = os.path.basename(audio_file.path)
            if name not in name_map:
                name_map[name] = []
            name_map[name].append(file_path)
        
        duplicates = []
        for name, paths in name_map.items():
            if len(paths) > 1:
                duplicates.append((name, sorted(paths)))
        
        return sorted(duplicates, key=lambda x: x[0])
    
    def run(self) -> AuditResult:
        """Ejecuta la auditoría completa"""
        print("🔍 Iniciando auditoría de audio...")
        print("=" * 80)
        
        # Escanear archivos de audio
        print("\n📁 Escaneando archivos de audio...")
        self.scan_audio_files()
        print(f"   ✓ Encontrados {self.scan_results.total_files} archivos de audio")
        
        # Escanear archivos GDScript
        print("\n📄 Escaneando archivos GDScript...")
        self.scan_gdscript_files()
        print(f"   ✓ Encontradas {self.scan_results.total_references} referencias")
        
        # Analizar resultados
        print("\n🔬 Analizando resultados...")
        
        self.scan_results.unreferenced_files = self.find_unreferenced_files()
        print(f"   ✓ Archivos sin referencia: {len(self.scan_results.unreferenced_files)}")
        
        broken = self.find_broken_references()
        self.scan_results.broken_references = [(f, r) for f, r, _ in broken]
        print(f"   ✓ Referencias rotas: {len(self.scan_results.broken_references)}")
        
        duplicates = self.find_duplicate_files()
        print(f"   ✓ Archivos duplicados: {len(duplicates)}")
        
        # Buscar referencias a música (que no existe en disco)
        music_refs = self.find_music_references()
        print(f"   ✓ Referencias a música: {len(music_refs)}")
        
        # Generar resumen
        self._generate_summary(duplicates)
        
        print("\n✅ Auditoría completada")
        return self.scan_results
    
    def find_music_references(self) -> List[Tuple[str, str]]:
        """Busca referencias a archivos de música que no existen"""
        music_refs = []
        
        for root, dirs, files in os.walk(self.project_root):
            for file in files:
                if file.endswith('.gd'):
                    filepath = os.path.join(root, file)
                    try:
                        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                            content = f.read()
                            # Buscar referencias a assets/audio/musica/
                            for match in re.finditer(r'["\'](assets/audio/musica/[^"\']+)["\']', content):
                                ref = match.group(1)
                                music_refs.append((filepath, ref))
                            # Buscar en CATALOGO de música
                            for match in re.finditer(r'"([^"]+)"', content):
                                ref = match.group(1)
                                if ref.endswith('.ogg') and 'musica' in ref.lower():
                                    music_refs.append((filepath, ref))
                    except:
                        pass
        
        return music_refs
    
    def _generate_summary(self, duplicates: List[Tuple[str, List[str]]]) -> None:
        """Genera un resumen detallado"""
        self.scan_results.summary = {
            'audio_files': {
                'total': self.scan_results.total_files,
                'by_extension': self._count_by_extension(),
                'total_size': self._total_size(),
            },
            'references': {
                'total': self.scan_results.total_references,
                'audio_players': len(self.scan_results.audio_players),
                'load_patterns': {k: len(v) for k, v in self.scan_results.load_patterns.items()},
            },
            'issues': {
                'unreferenced': len(self.scan_results.unreferenced_files),
                'broken': len(self.scan_results.broken_references),
                'duplicates': len(duplicates),
            }
        }
    
    def _count_by_extension(self) -> Dict[str, int]:
        """Cuenta archivos por extensión"""
        counts: Dict[str, int] = {}
        for audio_file in self.audio_files.values():
            ext = audio_file.extension
            counts[ext] = counts.get(ext, 0) + 1
        return counts
    
    def _total_size(self) -> int:
        """Calcula el tamaño total de todos los archivos"""
        return sum(audio_file.size for audio_file in self.audio_files.values())
    
    def generate_report(self, output_file: str = "scripts/auditoria_audio_2740.json") -> None:
        """Genera un informe en formato JSON"""
        report = {
            'metadata': {
                'issue': '#2740',
                'title': 'Inventario de audio roto y referencias inexistentes',
                'generated_at': '2026-10-27',
            },
            'summary': self.scan_results.summary,
            'audio_files': [
                {
                    'path': path,
                    'size': info.size,
                    'extension': info.extension
                }
                for path, info in sorted(self.audio_files.items())
            ],
            'unreferenced_files': self.scan_results.unreferenced_files,
            'broken_references': [
                {'file': f, 'reference': r}
                for f, r in self.scan_results.broken_references
            ],
            'audio_players': {
                file: lines
                for file, lines in self.scan_results.audio_players.items()
            },
            'references': [
                {
                    'file': ref.file_path,
                    'reference': ref.reference,
                    'line': ref.line,
                    'context': ref.context
                }
                for ref in self.references
            ]
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\n📊 Informe generado: {output_file}")
    
    def generate_human_report(self, output_file: str = "scripts/auditoria_audio_2740.md") -> None:
        """Genera un informe legible para humanos"""
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("# Auditoría de Audio - Issue #2740\n\n")
            f.write("## Resumen\n\n")
            f.write(f"- **Total archivos de audio**: {self.scan_results.total_files}\n")
            f.write(f"- **Total referencias en código**: {self.scan_results.total_references}\n")
            f.write(f"- **Archivos sin referencia**: {len(self.scan_results.unreferenced_files)}\n")
            f.write(f"- **Referencias rotas**: {len(self.scan_results.broken_references)}\n")
            f.write(f"- **Archivos con AudioStreamPlayer**: {len(self.scan_results.audio_players)}\n\n")
            
            if self.scan_results.unreferenced_files:
                f.write("## Archivos de audio sin referencia\n\n")
                f.write("Estos archivos existen pero no se usan en ningún archivo .gd:\n\n")
                for file_path in self.scan_results.unreferenced_files:
                    f.write(f"- `assets/audio/{file_path}`\n")
                f.write("\n")
            
            if self.scan_results.broken_references:
                f.write("## Referencias rotas\n\n")
                f.write("Estas referencias en el código apuntan a archivos que no existen:\n\n")
                for file_path, reference in self.scan_results.broken_references:
                    f.write(f"- `{file_path}` referencia `{reference}`\n")
                f.write("\n")
            
            f.write("## Archivos con AudioStreamPlayer\n\n")
            for file_path, lines in sorted(self.scan_results.audio_players.items()):
                f.write(f"- `{file_path}` (líneas: {', '.join(map(str, lines))})\n")
        
        print(f"\n📄 Informe humano generado: {output_file}")


def main():
    """Función principal"""
    auditor = AudioAuditor()
    results = auditor.run()
    
    # Generar informes
    auditor.generate_report()
    auditor.generate_human_report()
    
    # Mostrar resultados en consola
    print("\n" + "=" * 80)
    print("RESULTADOS DE LA AUDITORÍA")
    print("=" * 80)
    
    print(f"\n📊 Total archivos de audio: {results.total_files}")
    print(f"📊 Total referencias: {results.total_references}")
    
    if results.unreferenced_files:
        print(f"\n⚠️  Archivos SIN referencia ({len(results.unreferenced_files)}):")
        for file in results.unreferenced_files[:10]:
            print(f"   - {file}")
        if len(results.unreferenced_files) > 10:
            print(f"   ... y {len(results.unreferenced_files) - 10} más")
    
    if results.broken_references:
        print(f"\n❌ Referencias ROTAS ({len(results.broken_references)}):")
        for file, ref in results.broken_references[:10]:
            print(f"   - {file}: '{ref}'")
        if len(results.broken_references) > 10:
            print(f"   ... y {len(results.broken_references) - 10} más")
    
    if not results.unreferenced_files and not results.broken_references:
        print("\n✅ No se encontraron problemas de referencias")
    
    print("\n" + "=" * 80)


if __name__ == "__main__":
    main()
