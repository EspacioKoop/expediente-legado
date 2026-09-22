# SARNATH 98

Tercera micro-ROM cultural de #932, original para Game Boy / Game Boy Color.

## Base documentada

Fuentes principales:

- UNESCO World Heritage — **Ancient Buddhist Site of Sarnath**:
  https://whc.unesco.org/en/list/927/
- UNESCO Decision **48 COM 8B.17**:
  https://whc.unesco.org/en/decisions/9171
- UNESCO — mapas de la propiedad inscrita:
  https://whc.unesco.org/en/list/927/maps/

UNESCO inscribió Sarnath en 2026 como propiedad serial compuesta por dos partes: **Chaukhandi Stupa** y los **Archaeological Remains of Sarnath**. El sitio conserva restos arquitectónicos y arqueológicos de diferentes periodos y continúa siendo un lugar de memoria y peregrinación budista.

La misma documentación advierte que la geografía sagrada histórica más amplia ha sido alterada. Por eso SARNATH 98 **no reproduce un mapa real ni afirma reconstruir una ruta histórica**.

## Mecánica

La ROM abstrae orientación y memoria espacial.

Cada ronda:

1. muestra brevemente una secuencia de rumbos;
2. el jugador pulsa A para ocultarla;
3. debe repetirla con la cruceta.

Hay tres rutas deterministas:

- ronda 1: arriba → derecha → arriba;
- ronda 2: izquierda → arriba → derecha → abajo;
- ronda 3: arriba → arriba → derecha → abajo → izquierda.

Un error devuelve la ronda actual al modo de observación; no borra las rondas ya resueltas.

## Handshake

WRAM $C100:

- arranque: 0x00;
- comprar/insertar/iniciar: 0x00;
- rondas 1 o 2 completas: 0x00;
- tercera ruta completa: 0xA5;
- reinicio: 0x00.

## Representación

Se registra exposición cultural vinculada al budismo por la procedencia histórica y viva de Sarnath, no por identidad o convicción del jugador.

La ROM evita:

- puntos de karma, mérito o iluminación;
- meditación, recitación o peregrinación simuladas como prueba de habilidad;
- imágenes del Buda u objetos devocionales como pickups;
- afirmar que las secuencias son rutas históricas;
- inventar doctrina.

El diseño ampliado vive en docs/religion-rom-sarnath-932.md.
