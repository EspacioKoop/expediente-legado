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
| [AGENTS.md](AGENTS.md) | Flujo obligatorio para agentes y trampas conocidas |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Ramas, PR, pruebas y revisión |
| [Auditoría de paridad SIGA](docs/paridad-expedientes.md) | Qué comportamiento del legado existe ya en Godot y qué falta |
| [Milestones](https://github.com/EspacioKoop/expediente-legado/milestones) | Qué está comprometido para una versión |
| [Releases](https://github.com/EspacioKoop/expediente-legado/releases) | Qué se ha publicado |

Este repositorio adopta las [Normas Platino](https://github.com/EspacioKoop/normas_platino): **reserva antes de editar, rama propia, PR obligatorio, CI y autorización humana de integración**. El silencio no caduca una reserva y `PR_READY` no equivale a permiso para mergear.

## Estado actual — 2026-09-22

La referencia es siempre `main`, no una rama antigua ni un comentario histórico. El segundo playtest humano de la alpha #237 / PR #394 falló el gate de experiencia aunque CI y export fueran verdes. Desde entonces el proyecto ha cambiado de escala: además del saneamiento P0 se han integrado sistemas de vida cotidiana, tiempo, audio, huellas persistentes, capas culturales transversales y una revisión importante de SIGA/OS98.

Esto **no sustituye el siguiente playthrough humano**. Una CI verde demuestra contratos automatizados; no demuestra por sí sola legibilidad visual, tacto con mando, recorrido end-to-end ni calidad de una exportación.

### Núcleo de recorrido y presentación

- **Oficina y SIGA-98:** #1141 corrige problemas observados a 1080p; la ventana de referencia del proyecto es **1920×1080**. #1091 confirma una salida física de la oficina y #1089 mantiene una salida de rescate independiente del foco.
- **Cámara y controles:** el núcleo de #396 está implementado y protegido por pruebas runtime (#1095/#1097), pero #396 y #113 siguen siendo gates humanos de sensación, foco y mando físico.
- **HUD y legibilidad:** #397 continúa abierto como gate de jerarquía visual; tipografía empaquetada y coherencia básica están protegidas por #780/#1126.
- **Personajes:** se han añadido mejoras de proporción, nombres, movimiento y atención (#1083/#1087/#1112/#1113) y el renderer del port pasó a **Forward+** con sombras, SSAO y SSIL (#1121). #275/#134 siguen necesitando validación visual humana.

### SIGA, decisiones y sistemas persistentes

- **Investigación:** relaciones, metadatos, anexos, feedback, historial y profundidad documental ya tienen verticales integrados; #431/#513 siguen siendo los gates de evidencia/playtest antes de considerar cerrada la profundidad SIGA.
- **Decisiones:** el historial y los aplazamientos acumulativos se ampliaron en #1159; las consecuencias políticas siguen separadas de hechos objetivos del expediente.
- **Meticulosidad:** #961 ya afecta microdetalles opcionales (#1169), sueño (#1155) y audio adaptativo (#1187), sin convertir atención en una barra de progreso obligatoria.
- **Huellas ambientales:** #959 tiene ya un primer vertical persistente (#1122) y desgaste documental (#1186).

### Mundo 1998 y vida cotidiana

- **Comercio de barrio:** Quiosco Avenida, El Trastero, interiores y reventa física tienen verticales integrados (#1127/#1132/#1134/#1088), con evidencia visual automatizada en #1136.
- **Casa y objetos:** recuerdos, decals y merchandising propios (#1142–#1146) amplían la densidad de 1998; #1151 añade evidencia conjunta para varias verticales cotidianas.
- **Tiempo y ambiente:** reloj persistente e iluminación horaria (#1135/#1138) ya existen. El audio adaptativo progresa por capas y contexto (#1128/#1130/#1133/#1137/#1139/#1187), pero #966/#119 siguen abiertos como paraguas/gate de mezcla.
- **Vecindario y trayecto:** vecinos y portal se materializan en #1144; #277 continúa como gate de lectura del trayecto.

### OS98, portátil y contenido cultural

- **OS98:** programas del escritorio tienen iconos e identidad propia en expansión: Catálogo, Calculadora, Bloc de notas y Correo ya cuentan con cortes específicos (#1149/#1150/#1152/#1190/#1192).
- **Portátil Color 98:** apagado físico/afterglow, paletas y cierre visual se integraron en #1177/#1185/#1188 sin alterar ROMs CGB.
- **Mitologías:** el corpus común entra en runtime (#1157), con verticales recientes para Mari, Yggdrasil y Popol Wuj (#1164–#1166). #1171/#1174 siguen desarrollando la capa jungiana/mitológica transversal.
- **Religión:** se mantiene separada de Tarot y mitología. JALI 98, VITRAL 98 y SARNATH 98 ya prueban el patrón cultural/ROM (#1158/#1163/#1168/#1170), y #934 tiene un primer corte de práctica/cultura material (#1147).
- **Ideologías:** doctrinas heredadas ya llegan al Juicio 3D (#1115), a cierres de expediente (#1124) y a prensa/radio (#1148). #915–#925 siguen siendo el marco transversal.
- **Literatura:** #1176 definió el contrato de conocimiento/posesión/insight/ritual; #1178 creó el primer corte ejecutable y #1194 alineó el legado con el contrato transversal. La expansión continúa en #1179–#1184.

### Deuda técnica activa

El crecimiento transversal ha cargado especialmente `juicio_combate_3d.gd`. #1191 sigue la modularización; #1193, #1195 y #1196 ya extrajeron reglas puras, adaptador jungiano y capa simbólica. No volver a concentrar lógica de sistemas culturales en un único script.

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
