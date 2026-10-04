# Protocolo de Playtest para Doctrinas Ideológicas (#921)

> Documento de referencia para la validación humana de las cuatro doctrinas del Juicio por Combate 3D.
> Versión base: commit 1d9d1dde7f05

---

## 1. Resumen de las cuatro doctrinas

| Doctrina (eje) | Acción | Disparador | Efecto principal | Tag ritual que potencia | Duración base |
|----------------|--------|------------|------------------|-------------------------|---------------|
| **comunismo**  | Asamblea (temporizada) | Carga + telegrafo rival pendiente | Interrumpe iniciativa rival; convierte choque en iniciativa propia | `control_espacio` (+25% duración) | 4.0 s |
| **neoliberal** | Externalizar (temporizada) | Carga | Duplica primer impacto (saliente **y** entrante) | `riesgo` (+25% duración) | 4.0 s |
| **centrista**  | Mesa (instantánea) | Carga + telegrafo rival pendiente | Neutraliza ataque; restablece distancia ≥ 2.95 m | `neutralizar` (+25% recarga rival) | — (instantánea) |
| **socialdemocrata** | Comisión (diferida) | Carga | Espera siguiente intención rival; revela y extiende telegrafo | `telegraph` (+0.25 s extra) | 0.55 s bonus base |

> **Nota:** La duración real se calcula en `JuicioCombateReglas.duracion_doctrina(eje, ritual)` y `duracion_telegrafo(comision, ritual)`. Los tags se declaran en `JuicioSimbolico.ritual_para(id_carta, arquetipo)`.

---

## 2. Matriz de prueba (Test Matrix)

### 2.1. Cobertura funcional por doctrina

| ID | Doctrina | Escenario | Entrada (carga, ritual, estado) | Comportamiento esperado | Criterio de pase |
|----|----------|-----------|----------------------------------|--------------------------|------------------|
| T-01 | comunismo | Activación básica | `comunismo: 1`, ritual sin tags, rival telegrafiando | Se activa, consume 1 carga, `_doctrina_activa == "comunismo"`, temporizador ≈ 4.0 s | ✅ Activa + consume carga + temporizador ≈ 4.0 |
| T-02 | comunismo | Interrumpe ataque | T-01 + jugador ataca mientras doctrina activa | `asamblea_interrumpe == true`, ataque rival cancelado, `_determinacion_rival == 7` (daño ligero normal) | ✅ Interrumpe + daño base |
| T-03 | comunismo | Tag `control_espacio` | `comunismo: 1`, ritual **Laberinto** (la-luna/minotauro) | Duración = 4.0 × 1.25 = 5.0 s | ✅ Duración ≈ 5.0 s |
| T-04 | comunismo | Sin carga | `comunismo: 0`, rival telegrafiando | `activar_doctrina == false` | ✅ Rechaza activación |
| T-05 | comunismo | Fuera de ventana | `comunismo: 1`, **sin** telegrafo rival pendiente | `activar_doctrina == false` (bloqueada por `bloqueada()`) | ✅ Rechaza activación |
| T-06 | neoliberal | Activación básica | `neoliberal: 1`, ritual sin tags | Se activa, consume 1 carga, temporizador ≈ 4.0 s | ✅ Activa + consume + 4.0 s |
| T-07 | neoliberal | Duplica daño saliente | T-06 + jugador ataca (golpe ligero) | `_determinacion_rival == 6` (2 × 3 base) | ✅ Daño = 6 |
| T-08 | neoliberal | Duplica daño entrante | `neoliberal: 1`, rival ataca (golpe ligero) | `_determinacion_jugador == 6` | ✅ Daño recibido = 6 |
| T-09 | neoliberal | Tag `riesgo` | `neoliberal: 1`, ritual **Talón** (la-fuerza/aquiles) | Duración = 4.0 × 1.25 = 5.0 s | ✅ Duración ≈ 5.0 s |
| T-10 | neoliberal | Sin carga | `neoliberal: 0` | `activar_doctrina == false` | ✅ Rechaza |
| T-11 | centrista | Activación básica | `centrista: 1`, ritual sin tags, rival telegrafiando | Se activa, consume 1 carga, ataque neutralizado, distancia ≥ 2.95 m, determinaciones 8/8 | ✅ Neutraliza + distancia + 8/8 |
| T-12 | centrista | Tag `neutralizar` | `centrista: 1`, ritual **Robo del Sol** (el-sol/maui_tamanuitera) | `recarga_mesa > 1.15` (≈ 1.44 s) | ✅ Recarga rival ≈ 1.44 s |
| T-13 | centrista | Sin telegrafo rival | `centrista: 1`, sin `_ataque_rival_pendiente` | `activar_doctrina == false` | ✅ Rechaza |
| T-14 | centrista | Sin carga | `centrista: 0` | `activar_doctrina == false` | ✅ Rechaza |
| T-15 | socialdemocrata | Activación básica | `socialdemocrata: 1`, ritual sin tags | Se activa, consume 1 carga, `_comision_pendiente == true` | ✅ Activa + pendiente |
| T-16 | socialdemocrata | Revela telegrafo | T-15 + rival inicia ataque | `_doctrina_activa == "socialdemocrata"`, `_telegrafo_rival > 0.45` | ✅ Revela + extiende |
| T-17 | socialdemocrata | Tag `telegraph` | `socialdemocrata: 1`, ritual **Robo del Sol** | `duracion_telegrafo(true, ritual) > 0.45 + 0.55` (≈ 1.25 s total) | ✅ Ventana ≈ 1.25 s |
| T-18 | socialdemocrata | Termina tras resolución | T-16 + esquiva/resolución ataque | `_doctrina_activa == ""` | ✅ Limpia tras resolver |
| T-19 | socialdemocrata | Sin carga | `socialdemocrata: 0` | `activar_doctrina == false` | ✅ Rechaza |
| T-20 | socialdemocrata | Comisión pasiva (sin activar) | Ritual **Robo del Sol**, **sin** carga socialdemocrata | `duracion_telegrafo(false, ritual) == 0.45` (no activa comisión) | ✅ No inventa comisión |

### 2.2. Cruces entre doctrinas (regresión)

| ID | Escenario | Comportamiento esperado |
|----|-----------|--------------------------|
| X-01 | `comunismo` activo, se intenta `centrista` | `bloqueada() == true` → rechaza centrista |
| X-02 | `neoliberal` activo, rival ataca | Externalizar duplica daño entrante; asamblea **no** interrumpe (eje distinto) |
| X-03 | `socialdemocrata` pendiente, se intenta `comunismo` | `bloqueada() == true` (comisión pendiente bloquea) |
| X-04 | Ritual con tag ajeno (ej. `riesgo` en comunismo) | `modificadores_doctrina_ritual` devuelve `{}` → sin efecto cruzado |

### 2.3. Cargas y tope compartido

| ID | Escenario | Comportamiento esperado |
|----|-----------|--------------------------|
| C-01 | 3 decisiones neoliberal + 2 historias centrista, tope 2 | `cargas_ideologicas(estado, 2)` → neoliberal: 2, centrista: 2, otros 0 |
| C-02 | Exposición (prensa/radio) registrada | **No** cuenta para cargas de combate (`cargas_ideologicas` la ignora) |
| C-03 | Ventanilla (Historias) y Juicio leen misma fuente | `Historias.new().cargas(estado) == Prometeo.cargas_ideologicas(estado, tope)` |

---

## 3. Criterios de evaluación (pass/fail)

### 3.1. Criterios obligatorios (bloqueantes)

| Código | Descripción | Verificación |
|--------|-------------|--------------|
| **P-01** | **Activación solo con carga** | Ninguna doctrina se activa si `cargas[eje] <= 0`. |
| **P-02** | **Consumo exacto de 1 carga** | Tras activar, `cargas[eje] == valor_anterior - 1`. |
| **P-03** | **Ventana temporal respetada** | Temporizadas (comunismo, neoliberal): `_estado_temporal.doctrina` baja a 0 y limpia `_doctrina_activa`. Comisión: `_comision_pendiente` → `_doctrina_activa` → limpia tras resolver intención. Mesa: instantánea, sin temporizador. |
| **P-04** | **Identidad funcional conservada** | Asamblea interrumpe, Externalizar duplica, Mesa neutraliza, Comisión revela. Sin efectos colaterales (daño gratis, movimiento decorativo, invulnerabilidad extra). |
| **P-05** | **Tags genéricos, no matriz dura** | `modificadores_doctrina_ritual` consulta `ritual.tags` (array), no `if doctrina == "X" and ritual == "Y"`. Un tag nuevo en un ritual activa su modificador sin tocar código de doctrina. |
| **P-06** | **Exposición ≠ carga** | `registrar_exposicion_ideologica` no incrementa `cargas_ideologicas`. |
| **P-07** | **Tope global aplicado** | `cargas_ideologicas(estado, TOPE)` respeta `TOPE` por eje; sumatorio ≤ 4 × TOPE. |
| **P-08** | **Fuente única de verdad** | Ventanilla (`Historias.cargas`) y Juicio (`JuicioSimbolico.cargas_ideologicas`) devuelven idéntico diccionario. |

### 3.2. Criterios de calidad (no bloqueantes, para iteración)

| Código | Descripción | Observación en playtest |
|--------|-------------|-------------------------|
| **Q-01** | **Legibilidad HUD** | Botones de doctrina aparecen/desaparecen sincronizados con `_pintar_doctrinas`; etiqueta traducida (`tr(habilidad["nombre"])`). |
| **Q-02** | **Feedback temporal** | Barra/indicación de `_estado_temporal.doctrina` visible y coherente (comunismo/neoliberal). |
| **Q-03** | **Señalización de comisión** | UI muestra "Comisión pendiente" mientras `_comision_pendiente == true`; telegrafo extendido visible. |
| **Q-04** | **Audio diferenciado** | Cada doctrina dispara su `Sonido` propio (ver #119 / #1475). |
| **Q-05** | **Accesibilidad inputs** | Activación por acción semántica `doctrina_1..4` (no tecla dura), configurable en `PreferenciasSiga`. |
| **Q-06** | **Ritmo de combate** | Duraciones base (4.0 s, 0.45 s telegrafo) permiten reacción humana sin sentirse "rápido/injusto". |

---

## 4. Procedimiento de playtest humano

### 4.1. Preparación

1. **Entorno**: Godot 4.x (versión en `.godot-version`), rama actualizada a `main` o PR bajo test.
2. **Build**: Ejecutar `bash scripts/preparar_entorno.sh` (compila GDExtension GB/GBC y ROMs).
3. **Lanzar escena de prueba**: `godot/pruebas/issue_921_smoke.tscn` (o escena equivalente con `JuicioCombate3D` expuesto).
4. **Configurar inputs**: Verificar mapeo `doctrina_1..4` en `PreferenciasSiga` (por defecto: 1/2/3/4 o gamepad D-pad).

### 4.2. Sesión estándar (≈ 20 min por doctrina)

#### Fase A — Activación y consumo (5 min)
- Cargar partida con **exactamente 1 carga** de la doctrina bajo test.
- Acercar jugador a rival (distancia ≤ 1.45).
- Esperar telegrafo rival (indicador visual/audio).
- Pulsar acción de doctrina correspondiente.
- **Verificar**: botón se deshabilita, carga baja a 0, doctrina activa en HUD, temporizador/comisión inicia.

#### Fase B — Efecto principal (8 min)
| Doctrina | Acción del tester | Observación clave |
|----------|-------------------|-------------------|
| comunismo | Atacar (golpe ligero) mientras doctrina activa | Rival **no** telegrafía siguiente; determinación rival = 7 |
| neoliberal | Atacar (golpe ligero) y **recibir** ataque rival | Daño saliente = 6, daño entrante = 6 |
| centrista | Esperar telegrafo rival (no atacar) | Ataque cancelado, distancia ≥ 2.95, determinaciones 8/8 |
| socialdemocrata | Esperar telegrafo rival (no atacar) | Telegrafo extendido visible (> 0.45 s), doctrina acompaña intención |

#### Fase C — Expiración y limpieza (3 min)
- Dejar correr temporizador (comunismo/neoliberal) o resolver intención (comisión).
- **Verificar**: `_doctrina_activa == ""`, `_comision_pendiente == false`, HUD limpio, sin residuo de temporizador.

#### Fase D — Casos borde (4 min)
- Repetir Fase A **sin carga** → debe rechazar.
- Repetir Fase A **fuera de ventana** (comunismo/centrista sin telegrafo, socialdemocrata sin intención pendiente) → debe rechazar.
- Probar con ritual **con tag potenciador** (ver matriz T-03, T-09, T-12, T-17) → duración/recarga/telegrafo extendidos.
- Probar ritual **sin tag** → valores base.

### 4.3. Sesión de cruces (≈ 10 min)
- Activar doctrina A, intentar activar B antes de que A expire → debe bloquear (`bloqueada == true`).
- Verificar X-01..X-04 de la matriz.

### 4.4. Registro de resultados

| Campo | Formato |
|-------|---------|
| Doctrina | `comunismo` \| `neoliberal` \| `centrista` \| `socialdemocrata` |
| Test ID | `T-XX` / `X-XX` / `C-XX` |
| Resultado | `PASS` \| `FAIL` \| `PARTIAL` |
| Evidencia | Captura / clip / log (referencia) |
| Notas | Comportamiento inesperado, UX, rendimiento |

> **Plantilla de hoja de prueba** (copiar por sesión):
> ```
> Fecha: ___________  Tester: ___________  Build: ___________
> Doctrina: ___________
> 
> T-01  PASS/FAIL  ___________
> T-02  PASS/FAIL  ___________
> ...
> Q-01  OK/KO     ___________
> ...
> Observaciones generales:
> ____________________________________________________________
> ```

---

## 5. Gates de integración

| Gate | Requisito | Responsable |
|------|-----------|-------------|
| **G-01** | Suite `issue_921_smoke.gd` en verde (CI) | Nivel 3 / CI |
| **G-02** | Playtest humano completo (4 doctrinas + cruces) con **0 FAIL** en P-01..P-08 | Nivel 2 / @eGurucharri |
| **G-03** | Criterios Q-01..Q-06 revisados; incidencias abiertas si KO | Nivel 2 |
| **G-04** | `docs/paridad-ideologias.md` actualizado si cambian reglas | Autor del cambio |

> **No se fusiona a `main` sin G-01 y G-02 en verde.** Ver `CONTRIBUTING.md` § Gates.

---

## 6. Referencias de código (para trazabilidad)

| Archivo | Símbolos clave |
|---------|----------------|
| `godot/guion/juicio_combate_doctrina.gd` | `intentar_activar`, `plan_comision`, `bloqueada`, `eje_estado` |
| `godot/guion/juicio_combate_reglas.gd` | `modificadores_doctrina_ritual`, `duracion_doctrina`, `asamblea_interrumpe`, `dano_externalizado`, `recarga_mesa`, `duracion_telegrafo` |
| `godot/guion/juicio_combate_3d.gd` | `activar_doctrina`, `_cerrar_doctrina`, `_pintar_doctrinas`, `_hay_cargas_doctrina` |
| `godot/guion/juicio_combate_simbolico.gd` | `cargas_ideologicas`, `hay_cargas_doctrina` |
| `godot/guion/prometeo.gd` | `registrar_eleccion_ideologica`, `registrar_exposicion_ideologica`, `cargas_ideologicas` |
| `godot/guion/juicio_simbolico.gd` | `ritual_para` (tags por carta/arquetipo) |
| `godot/pruebas/issue_921_smoke.gd` | Regresión automática completa (T-01..T-20, X-01..X-04, C-01..C-03) |

---

## 7. Historial de versiones

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 1.0 | 2026-10-04 | Qwen Code (worker #2305) | Creación inicial desde base 1d9d1dde7f05 |

---

> **Fin del protocolo.** Para dudas sobre mecánicas, consultar `docs/paridad-ideologias.md` y los tests de `issue_921_smoke.gd`. Para dudas de proceso, `CONTRIBUTING.md` y `AGENTS.md`.