# #932 — VITRAL 98: documentación y frontera de representación

## Alcance

Segundo cartucho de la línea de ROMs culturales de #932. La finalidad es demostrar que `ReligionRomVigilia` se reutiliza con otra tradición y otra materialidad sin duplicar emulador, consola ni contrato de exposición.

## Fuentes

### V&A — Stained glass: an introduction

https://www.vam.ac.uk/articles/stained-glass-an-introduction

Datos trasladados al diseño:

- las vidrieras tuvieron un papel destacado en Europa entre 1150 y 1550;
- el vidrio coloreado y pintado se ensamblaba mediante tiras de plomo;
- la luz que atravesaba la ventana alteraba visualmente el espacio;
- el proceso partía de un diseño previo y continuaba con selección/corte del vidrio, pintura y ensamblado.

### V&A — How was it made? Stained glass

https://www.vam.ac.uk/articles/how-was-it-made-stained-glass

El V&A documenta una reproducción de técnicas históricas a partir de un panel procedente del coro de Erfurt Cathedral, Alemania, hacia 1375. El original formaba parte de una escena religiosa.

## Qué se usa y qué no

### Documentado

VITRAL 98 conserva:

1. diseño previo;
2. piezas separadas de vidrio;
3. estructura de plomo como parte de la composición;
4. relación entre vidrio coloreado, luz y arquitectura.

### Invención del juego

Son propias del juego:

- el título VITRAL 98;
- las cuatro piezas;
- las cuatro variantes;
- la solución 2/1/3/2;
- los patrones geométricos;
- audio, pixel-art e indicadores.

No se reconstruye el panel de Erfurt ni se reproduce su escena narrativa.

## Límites de representación

- no aparecen figuras de Cristo, santos ni escenas bíblicas;
- no se usan cruces u objetos devocionales como pickups;
- no hay texto litúrgico;
- completar el puzzle no equivale a práctica religiosa;
- la tradición solo documenta la procedencia cultural del medio;
- la ROM no concede progreso laboral, pistas o dinero.

## Contrato técnico

    jugar VITRAL 98
        ↓
    manipular cuatro piezas
        ↓
    solución 2/1/3/2
        ↓
    WRAM $C100 = $A5
        ↓
    Vitral98Vigilia
        ↓
    ReligionEventos.CANAL_EXPOSICION

El segundo cartucho usa el mismo observer común que JALI 98, demostrando reutilización del contrato sin crear otro sistema religioso paralelo.
