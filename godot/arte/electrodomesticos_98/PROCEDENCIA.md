# Procedencia — electrodomésticos 98

Pack asset-only para el comercio de electrodomésticos del trayecto (#676/#277).

## Archivos

- `frontales_aparatos_98.svg`: frontales y paneles gráficos para CRT, lavadoras, frigorífico, mando y minicadena.
- `embalajes_98.svg`: gráficos de cajas de cartón para CRT, lavadora, frigorífico y minicadena, más pictogramas de manipulación.
- `senaletica_grafica_98.svg`: flechas, cartelas gráficas, sellos y stickers para escaparate/interior.

## Restricciones deliberadas

- Diseños originales del proyecto.
- Sin marcas, logotipos, fotografías ni productos comerciales reales.
- **Sin elementos `<text>`**: el gate visual de #676 detectó que el importador de SVG de Godot podía conservar gráficos pero omitir texto. Todo lo visible aquí está construido con geometría SVG.
- Fondo transparente y grupos con `id` estable para extracción a atlas/decal.
- No contienen precios ni datos de catálogo.
- No modifican escena, gameplay, economía ni progresión.

## Uso previsto

Estos SVG pueden usarse directamente como textura, recortarse a PNG/atlas o servir como decals sobre las geometrías procedurales ya existentes en `CalleLocalesComerciales3D`. Su función es reducir la lectura de “caja gris” de CRT, lavadoras y frigoríficos sin crear modelos propietarios ni otra fuente de verdad.

Refs #676 #277 #399.
