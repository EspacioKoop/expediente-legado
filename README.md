# SIGA-98 · Expediente Legado

Videojuego de investigación y horror burocrático ambientado alrededor de **SIGA**, un sistema de administración de finales de los 90. El jugador trabaja expedientes, relaciona documentos, atraviesa el ciclo oficina → trayecto → casa → sueño y descubre una segunda capa, **Prometeo**, sin que la investigación se reduzca a una lista automática de respuestas.

El proyecto nació como aplicación web con Spring Boot y se está reescribiendo en **Godot 4** para distribuirlo sin servidor. El backend sigue siendo referencia histórica y ejecutable; `godot/` es el frente principal de desarrollo del juego.

## Cómo orientarse

| Dónde | Qué responde |
| --- | --- |
| [Plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181) | Qué va primero ahora mismo |
| [Registro de reservas #182](https://github.com/EspacioKoop/expediente-legado/issues/182) | Quién está tocando qué |
| [ROADMAP.md](ROADMAP.md) | Fases, gates y dirección hasta la 1.0 |
| [Índice de documentación](docs/README.md) | Qué documento es canónico para cada área |
| [Referencias ludonarrativas](docs/research/referencias-ludonarrativas.md) | Técnicas de investigación/presentación y sus límites de adopción |
| [AGENTS.md](AGENTS.md) | Flujo obligatorio para agentes y trampas conocidas |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Ramas, PR, pruebas y revisión |
| [Auditoría de paridad SIGA](docs/paridad-expedientes.md) | Qué comportamiento del legado existe ya en Godot y qué falta |
| [Milestones](https://github.com/EspacioKoop/expediente-legado/milestones) | Qué está comprometido para una versión |
| [Releases](https://github.com/EspacioKoop/expediente-legado/releases) | Qué se ha publicado |

Este repositorio adopta las [Normas Platino](https://github.com/EspacioKoop/normas_platino): **reserva antes de editar, rama propia, PR obligatorio, CI y autorización humana de integración**. El silencio no caduca una reserva y `PR_READY` no equivale a permiso para mergear.

## Estado actual — 2026-09-26

La referencia sigue siendo `main`. Este corte documenta el estado integrado hasta `6ccfa4317897d70ca9462e7c92aefea41095b2bc`; un PR abierto o una rama adelantada no cuentan como funcionalidad disponible hasta su merge.

El núcleo ya no está en una fase de “port mínimo”. En los últimos cortes se han reforzado la investigación documental, la interfaz diegética de SIGA-98, las consecuencias espaciales del trabajo burocrático, la vida ambiental y la identidad visual/onírica. Aun así, **el siguiente playthrough humano completo sigue siendo el gate principal**: CI verde y evidencia automatizada no sustituyen legibilidad, tacto, ritmo ni continuidad real.

### Recorrido, interfaz y personajes

- **HUD contextual:** #1401 conecta #397 con un HUD de recursos dependiente de fase, evitando mostrar información irrelevante de forma permanente. #397 sigue abierto como gate humano de jerarquía visual y lectura a resolución real.
- **Contraste y menús:** #1367 fija una regla visual más clara para menú general, creador de personaje y superficies OS98, sin dar por cerrada por sí sola la revisión visual global.
- **Protagonista y NPCs:** #1394 convierte al jugador en un avatar Rocketbox seleccionable; #1371 añade captura de movimiento Rocketbox a compañeros compatibles y #1391 da identidad funcional a dependientes de tiendas. #275/#134 continúan requiriendo validación humana de proporción, reconocimiento y presencia.
- **Oficina/cámara/salida:** se mantienen las correcciones y salvaguardas ya integradas para foco, cámara y salida física; #396/#113 siguen siendo gates humanos de sensación y mando.

### SIGA-98, expedientes y trabajo documental

- **Reconstrucciones 3D por fuente:** #1365 y #1369 cubren los diez expedientes actuales con reconstrucciones breves ligadas a documentos leídos. Son representaciones de un punto de vista, no una “verdad canónica secreta”.
- **Terminal SIGA:** #1410 crea un núcleo de terminal ficticio y seguro; #1416 lo conecta al puesto de oficina; #1422 añade archivos temporales/usuarios simulados y #1423 historial navegable. No ejecuta red, procesos ni filesystem reales.
- **Análisis y falsificación de copias:** #1426 añade análisis opcional basado en hechos visibles; #1429 permite intervenir copias temporales de forma determinista y #1431 añade revisión interna narrativa. Este bloque no debe reescribir el documento fuente ni convertir el minijuego en una vía para inventar evidencia.
- **Archivado con consecuencias:** #1435 materializa desorden recuperable al archivar mal y #1436 deriva una demora de búsqueda acotada de ese mismo estado. Las consecuencias son reversibles y no crean una segunda fuente de persistencia.
- **Profundidad de investigación:** #286/#431/#513 siguen siendo los paraguas/gates de calidad. Más herramientas no equivalen automáticamente a un expediente más interesante: el playtest debe comprobar qué aporta realmente a leer, contrastar y decidir.

### Mundo 1998, casa y sistemas persistentes

- **Fauna ambiental:** #1398 introduce animales en calle y sueños; #1404, #1409 y #1412 añaden microgestos, anatomía/acabado y variantes dependientes de hora/clima sin convertirlos en IA sistémica pesada.
- **Huellas de uso:** #1363 extiende huellas persistentes a equipos domésticos y #1420 añade desgaste por tránsito repetido, reutilizando el contrato existente en vez de duplicar estado.
- **Minijuegos acotados:** #1418 convierte el golf en una partida determinista de tres hoyos manteniéndolo como slice autónomo, no como requisito del recorrido principal.
- **Atrezzo cultural:** #1440 integra un bonsái doméstico inspirado en Yggdrasil y la caja ficticia **Yggdrasil's Egg** en la tienda de videojuegos. Ambos son atrezzo: no desbloquean mitología, no alteran economía y no se presentan como fuentes históricas.

### Sueños, mitologías y dirección audiovisual

- **PBR y props oníricos:** #1414, #1417, #1419 y #1425 añaden materiales/props propios y los conectan a las seis familias originales de #435; #1428 completa evidencia visual automatizada para Gilgamesh, Aquiles y Duat sin autoaprobar el criterio artístico.
- **Mari:** #1427 conecta el pack visual de Mari al runtime conservando selección nocturna y lógica climática existentes.
- **Baba Yaga:** #1413, #1415, #1421, #1424, #1430 y #1434 convierten el vertical en un espacio más legible y mutable: interior imposible por fases, escalada ambiental, tránsito por horizonte y una habitación que pasa de interior a exterior. La capa visual permanece separada de navegación y seguridad.
- **Referencias de diseño:** #1433 incorpora el corpus transversal de [referencias ludonarrativas](docs/research/referencias-ludonarrativas.md), con una regla explícita: estudiar técnicas no equivale a copiar contenido ni a declarar una mecánica implementada.

### Gates que siguen mandando

Siguen necesitando persona, hardware o export real, entre otros:

- **#9** — playthrough end-to-end sobre el `main` actual;
- **#396/#113** — cámara, foco y mando físico;
- **#397/#780** — jerarquía visual y legibilidad real;
- **#275/#134** — reconocimiento y proporción de NPCs;
- **#277** — lectura espacial del trayecto;
- **#395/#280** — continuidad y cinemáticas en export;
- **#431/#513/#286** — profundidad de expedientes y utilidad real de documentos/reconstrucciones;
- **#119/#966** — mezcla y audio adaptativo en contexto;
- **#112** — exportación/publicación cuando vuelva a activarse la entrega pública.

## Stack

- **Juego vivo:** Godot 4.7, GDScript, renderer **Forward+**, viewport de referencia **1920×1080** y pruebas headless/runtime.
- **Backend legado:** Spring Boot 3, Java 25, Spring Data JPA, Spring Security y Thymeleaf.
- **Web legado:** Bootstrap 5, Vitest y Playwright.
- **Datos:** JSON/CSV en `godot/datos/`; MySQL 8 en desarrollo web y H2 para el standalone web.
- **Calidad:** suite Godot + recorrido real + arranque, unittest Python de regresión, `gdlint`, `gdformat`, JUnit, Checkstyle, PMD, SpotBugs y Vitest.

## Estructura

```text
.
├── README.md
├── AGENTS.md
├── CONTRIBUTING.md
├── ROADMAP.md
├── docs/                       # decisiones, auditorías, investigación y evidencia
│   └── README.md               # índice canónico de documentación
├── scripts/                    # verificadores y regresiones auxiliares
├── backend/                    # versión web / fuente histórica
├── dist/                       # empaquetado del standalone web legado
└── godot/                      # juego vivo
    ├── assets/                 # binarios y procedencia
    ├── datos/                  # casos, textos y catálogos
    ├── guion/                  # lógica y capas de presentación
    ├── escenas/
    └── pruebas/
```

## Verificar el port a Godot

Usa el motor de la línea declarada en `.godot-version` (actualmente 4.7). Desde la raíz:

```bash
python3 scripts/verificar_godot.py
python3 -m unittest discover -s scripts -p 'test_*.py'
gdlint godot
gdformat --check --diff godot
```

`verificar_godot.py` importa recursos, ejecuta la suite principal, recorre escenas reales y comprueba que el juego arranca con datos temporales. `godot/pruebas/minimo.txt` protege el mínimo de comprobaciones de la suite; reducirlo requiere justificar qué prueba desaparece.

No fijamos aquí un número de comprobaciones: cambia con frecuencia y la fuente de verdad es el workflow del SHA que se quiere integrar.

El CI también ejecuta, desde `backend/`:

```bash
mvn test
mvn checkstyle:check pmd:check spotbugs:check
npm test
```

Una CI verde prueba lo automatizado. **No sustituye** una partida completa, la lectura visual, el mando físico ni el comportamiento de una exportación real.

## Arquitectura del port

El contenido salió del `DataSeeder` y del legado web hacia datos versionados; la lógica se rehace como contratos pequeños y capas de Godot, con regresiones antes de integrarlos en escenas compartidas.

Convenciones importantes:

- las fases de `Jornada` usan nombres canónicos; la calle real es `trayecto`, no `calle`;
- la entrada se expresa mediante acciones semánticas (`interactuar`, `cancelar`, movimiento), no teclas hardcodeadas;
- `Partida` persiste estado, pero no es el bus de comunicación entre pantallas;
- el texto de interfaz/guion vive en `godot/datos/textos.csv`; el catálogo de casos sigue en JSON;
- `Sonido`, `Musica` y el ambiente continuo son responsabilidades separadas;
- el sueño normal progresa por objetivos, no por encontrar una salida física invisible;
- las mecánicas de investigación no deben inventar hechos: relaciones, anexos y recompensas oníricas consumen datos ya catalogados;
- Tarot, mitología, ideología, religión y literatura pueden cruzarse, pero mantienen contratos y fuentes de verdad separados;
- los efectos culturales/contextuales deben activarse por acciones observables, no por afinidades globales implícitas.

## Assets y Git LFS

Texturas, mallas, tipografías, sonido y vídeo que entren como binarios siguen las reglas de `.gitattributes` y `godot/assets/procedencia.json`. Cada asset distribuible debe declarar autor, fuente, licencia compatible y `sha256`.

```bash
git lfs install
git clone https://github.com/EspacioKoop/expediente-legado.git
```

Si ya clonaste sin LFS: `git lfs install && git lfs pull`.

No añadas un puntero LFS mediante una API de contenidos si el objeto binario no ha sido subido al almacén LFS: el repositorio quedaría apuntando a un objeto inexistente.

## Cómo levantar la versión web legado

```bash
cp .env.example .env
docker compose up --build
```

- App: http://localhost:1998
- Adminer: http://localhost:1999

Las credenciales de demostración y desarrollo viven en la configuración del proyecto; no copies secretos reales a documentación, PR, logs ni capturas.

## Build standalone del legado web

```bash
bash dist/empaquetar-alpha.sh
```

Genera paquetes autocontenidos del backend web en `dist/salida/`. Esto es independiente de la exportación del port Godot, cuyo seguimiento vive en los issues de distribución del roadmap.

## Licencia

**MIT** para el código, textos y datos propios del repositorio (ver [`LICENSE`](LICENSE)). El material de terceros bajo `godot/assets/` conserva su licencia individual y debe estar inventariado en `godot/assets/procedencia.json`.
