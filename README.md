# SIGA-98 · Expediente Legado

Videojuego de investigación y horror burocrático ambientado alrededor de **SIGA**, un sistema de administración de finales de los 90. El jugador trabaja expedientes, relaciona documentos, atraviesa el ciclo oficina → trayecto → casa → sueño y descubre una segunda capa, **Prometeo**, sin que la investigación se reduzca a una lista automática de respuestas.

El proyecto nació como aplicación web con Spring Boot y se está reescribiendo en **Godot 4** para distribuirlo sin servidor. El backend sigue siendo referencia histórica y ejecutable; `godot/` es el frente principal de desarrollo del juego.

## Cómo orientarse

| Dónde | Qué responde |
| --- | --- |
| [Plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181) | Qué va primero ahora mismo |
| [Registro de reservas #182](https://github.com/EspacioKoop/expediente-legado/issues/182) | Quién está tocando qué |
| [ROADMAP.md](ROADMAP.md) | Fases y dirección hasta la 1.0 |
| [AGENTS.md](AGENTS.md) | Flujo obligatorio para agentes y trampas conocidas |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Ramas, PR, pruebas y revisión |
| [Auditoría de paridad SIGA](docs/paridad-expedientes.md) | Qué comportamiento del legado existe ya en Godot y qué falta |
| [Milestones](https://github.com/EspacioKoop/expediente-legado/milestones) | Qué está comprometido para una versión |
| [Releases](https://github.com/EspacioKoop/expediente-legado/releases) | Qué se ha publicado |

Este repositorio adopta las [Normas Platino](https://github.com/EspacioKoop/normas_platino): **reserva antes de editar, rama propia, PR obligatorio, CI y autorización humana de integración**. El silencio no caduca una reserva y `PR_READY` no equivale a permiso para mergear.

## Estado actual

La referencia es siempre `main`, no una rama antigua ni un comentario histórico. Tras el primer playthrough humano (#9), el trabajo se concentra en preparar una segunda alpha que pueda recorrerse sin conocimiento del código.

Ya están integrados, entre otros:

- **sueño por objetivos**: 3 objetivos posibles, 2 requeridos, feedback desde 0/2, resolución automática e idempotencia (#281, #301, #308, #313);
- **investigación SIGA más profunda**: combinación manual de folios, marcadores, metadatos, feedback explícito y anexos examinables (#286, #289, #309, #318, #320, #321, #323); la auditoría legado → Godot vive en [`docs/paridad-expedientes.md`](docs/paridad-expedientes.md);
- **menú y controles**: menú global, pausa, foco, preferencias y remapeo visual de teclado/mando (#113, #306, #335); queda validación con mando físico y de presentación;
- **interacción 3D común**: detector contextual, terminal SIGA y archivadores reales ya usan el mismo contrato (#283, #307, #341, #345, #348);
- **trayecto exterior**: composición de calle/escaparate y corrección del hook a la fase real `trayecto` (#277, #314, #331, #337);
- **presentación P1**: rostros 3D low-poly (#275/#310), diálogo diegético (#276/#317/#338) y asistente-gato 2D abajo a la derecha (#285/#315);
- **ciclo doméstico**: economía base calibrada (#83), alquiler/impago funcional y pérdida de lo almacenado en casa al quedarse sin vivienda (#84/#85/#333);
- **audio**: `Sonido` para efectos y `Musica` para momentos dramáticos están separados; el ambiente continuo se desarrolla en #119.

Siguen siendo gates humanos, no motivos para reescribir sistemas a ciegas: #271 (partida nueva/continuar), #272 (onboarding), #273 (tacto/volumen de pasos), #280 (cinemáticas en export), #281 (comprensión del sueño) y #113 (mando físico).

La prioridad exacta y el punto de control viven en [#181](https://github.com/EspacioKoop/expediente-legado/issues/181).

## Stack

- **Juego vivo:** Godot 4.7, GDScript, renderer de compatibilidad y pruebas headless.
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
├── docs/                       # decisiones, investigación y auditorías versionadas
├── scripts/                    # verificadores y regresiones auxiliares
├── backend/                    # versión web / fuente histórica
├── dist/                       # empaquetado del standalone web legado
└── godot/                      # juego vivo
    ├── assets/                 # binarios y procedencia
    ├── datos/                  # casos, textos, catálogos
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
- las mecánicas de investigación no deben inventar hechos: relaciones, anexos y recompensas oníricas consumen datos ya catalogados.

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
