# Procedencia — merchandising de comercio de barrio

Pack asset-only para #676, creado específicamente para el proyecto.

## Archivos

- `merch_quiosco_98.svg`: prensa, revistas, agenda, cuadernos, sobres, pilas, cassette, dulces, postales, bolígrafos y expositor de tarjetas.
- `merch_trastero_98.svg`: lámparas, radio, despertador, teléfono con cable, ventilador, tostadora, marco, jarrón, caja de cassettes y caja de herramientas.
- `pegatinas_comercio_98.svg`: cartelería y pegatinas genéricas de comercio de barrio.

## Licencia y procedencia

- Diseños originales del proyecto, generados para este repositorio.
- No incluyen marcas, logotipos, fotografías, personajes ni diseños copiados de terceros.
- La estética toma rasgos genéricos de comercios domésticos de finales de los 90: papel impreso, ABS, metal pintado, madera, cassette, telefonía fija y señalética de escaparate.
- No reproducen productos comerciales concretos.

## Uso previsto

Los SVG tienen fondo transparente y cada pieza está aislada en un grupo con `id` estable. Pueden:

1. cargarse como textura completa en Godot;
2. recortarse a PNG/atlas si un material lo necesita;
3. servir de referencia para modelar geometría 3D sencilla;
4. colocarse como decals/planos secundarios dentro de Quiosco Avenida o El Trastero.

No contienen precios ni catálogo canónico. Esos datos siguen viniendo de `ComercioBarrio` en runtime.

Refs #676 #277 #96 #674.
