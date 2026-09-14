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

La referencia es siempre `main`, no una rama antigua ni un comentario histórico. El **segundo playtest humano** de la alpha #237 / PR #394 falló el gate de experiencia aunque CI y export fueran verdes: el recorrido existía, pero cámara, HUD, identidad espacial, materiales, densidad, animación y puesta en escena todavía hacían que la build se percibiera como prototipo/greybox.

Desde ese playtest se ha integrado un bloque P0 importante. Esto **no equivale a validación humana**: cuando un issue sigue abierto por sensación, lectura visual o mando físico, no se reimplementa a ciegas; se prueba la versión ya integrada y solo se corrige un fallo reproducible.

Estado relevante de `main`:

- **cámara y locomoción 3D**: #405 cubre el núcleo técnico de #396 — ratón y stick derecho, sensibilidad e inversión Y persistentes, deadzone, aceleración/frenado y captura de cursor; #396 queda como gate de sensación con ratón y mando físico;
- **HUD y diálogo**: #406 unifica prioridades de interacción/tutorial/diálogo/modal y convierte a los compañeros en NPC conversables explícitos; #453 retira HUD permanente fuera del archivo. #397/#276 siguen requiriendo un pase visual humano;
- **cinemáticas prioritarias 3D**: #410 sustituye la avalancha inicial 2D por una secuencia sobre la oficina real y #428 hace casa → sueño en el mundo 3D. #395 queda pendiente de captura/vídeo y legibilidad humana, no de volver a montar esas dos transiciones;
- **identidad espacial y materiales**: oficina tiene perfiles materiales reutilizables (#412); casa tiene composición doméstica y materiales propios (#420/#427); el trayecto tiene cielo/profundidad urbana (#429) y fachadas materializadas (#449). #398/#399 siguen abiertos sobre todo por sueño y por la comparación humana sin HUD;
- **densidad e interacción ambiental**: #400 ya tiene verticales en casa (#407), oficina (#423), sueño (#424) y calle (#433); #465 sustituye dos proxies domésticos de alto valor por cama y cuenco reconocibles. Falta validar la densidad transversal desde cámara de juego;
- **personajes**: #445 añade un primer movimiento ambiental mínimo compatible con reducción de movimiento; #134 sigue abierto por validación. #275 continúa siendo un gate visual de rostros y no debe darse por resuelto solo porque exista una malla low-poly;
- **tratamiento PSX**: #470 cerró #115 con comparativas controladas de oficina/sueño y mantuvo `dithering=0.65`; interfaz, HUD y documentos quedan fuera del efecto;
- **SIGA e investigación**: relaciones, marcadores, metadatos, anexos, feedback y contexto de careo ya están integrados (#289/#309/#318/#320/#321/#323/#352/#367); #286 se valida con playtest específico, no añadiendo capas indefinidamente;
- **decisión política**: además de posponer (#339/#369), #477 exige contexto nuevo antes de decidir, evitando resolver la presión narrativa con un simple botón de aplazamiento;
- **sueño por objetivos**: 3 objetivos posibles, 2 requeridos, feedback 0/2 → 2/2 y resolución automática siguen siendo la base (#281/#301/#308/#313), con contenido limitado a hechos/pistas catalogados (#332).

Los extras ya integrados —portátil, emulación GB, minijuegos y verticales opcionales posteriores— **no convierten esa expansión en prioridad**. Mientras el siguiente pase humano P0 no sea satisfactorio, el orden exacto y el punto de control los fija [#181](https://github.com/EspacioKoop/expediente-legado/issues/181).

Siguen siendo gates humanos de recorrido: #271 (partida nueva/continuar), #272 (onboarding), #273/#396 (tacto y cámara), #280/#395 (transiciones en export), #281 (comprensión del sueño), #113 (mando físico/remapeo), #286 (profundidad SIGA), #397/#398/#399 (lectura visual) y #275/#134/#282/#400 (personajes/densidad).

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
