# Props originales de 1998 — corte #282

Este lote sustituye proxies pequeños por modelos 3D originales y sin marcas reales.
No se importan fotografías, logos, tipografías comerciales ni modelos de terceros.

## Piezas

- teléfono fijo doméstico: base y auricular separados para conservar el estado descolgado;
- lámpara de pie: base metálica, mástil y pantalla textil;
- cuenco de gato: metal mate con apoyo de goma;
- impresora térmica portátil: carcasa propia; LED y tira de papel siguen siendo dinámicos;
- consola portátil: carcasa propia, sin silueta ni iconografía comercial; la pantalla emisiva sigue separada;
- minicadena: cuerpo, cassette, altavoces y mandos físicos; los hotspots existentes siguen siendo los dueños de la interacción.

## Formato y procedencia

Los modelos son fuentes Wavefront OBJ y MTL de texto generadas específicamente para
Expediente Legado a partir del brief del proyecto. No derivan de un asset externo y
viven en `godot/arte/props_originales_98/`, junto al arte fuente propio. Se evita
`godot/assets/` porque ese árbol exige ficha global de procedencia y el registro
`godot/assets/procedencia.json` está reservado por otros frentes activos.

Godot 4 importa OBJ como Mesh independiente y admite su MTL asociado. Las piezas
son estáticas: no necesitan esqueleto, animaciones, UV2 ni materiales PBR. Los
estados que sí cambian (auricular, LEDs, pantalla y papel) permanecen como nodos
separados del runtime.

## Regla de marcas

Los nombres, botones, colores y proporciones son genéricos. No aparecen marcas,
logos, nombres de fabricantes ni nombres de hardware comercial.

## Contrato

El cambio es visual. No cambia economía, inventario, llamadas, radio, emulación,
controles ni persistencia. Las colisiones e `Interactuable3D` existentes se
conservan.

Refs #282 #133 #671 #670 #1054 #124.
