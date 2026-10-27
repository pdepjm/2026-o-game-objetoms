# `menu/`

Los menús de la pantalla. Ocupan las columnas fuera del tablero:

| Zona | Celdas | Qué muestra |
|---|---|---|
| Barra de herramientas | x 21 a 24, y 15 | La herramienta elegida (`toolBar`) |
| Zona interactiva | x 21 a 24, y 0 a 14 | El panel de la herramienta elegida (máquinas, info, o nada) |
| Información del nivel | x 0 a 4, y 1 a 14 | Reservada (todavía vacía) |

| Archivo | Qué tiene |
|---|---|
| `menuManager.wlk` | `menuManager`: el que conoce a todos los menús y les reenvía los eventos. También `Zone` y `emptyMenu` |
| `placeMenu.wlk` | El panel de la herramienta **place**: las máquinas para elegir, con páginas y un marco sobre la elegida |
| `editMenu.wlk` | El panel de la herramienta **edit**: los settings de la máquina elegida, agrupados por categoría |
| `toolBar.wlk` | La barra que muestra qué herramienta está elegida |
| `levelInfoMenu.wlk` | Vacío, reservado para la información del nivel |

## `menuManager.wlk`

- **Es el único que conoce los menús.** El resto del juego le avisa lo que pasó y él se lo pasa al menú que corresponde:
  - `toolChanged(herramienta)`: actualiza la barra y cambia el panel de la zona interactiva;
  - `directionChanged()`: actualiza las imágenes de las máquinas del panel (cambian con W/A/S/D);
  - `prevPage()` y `nextPage()`: teclas Q y E;
  - `onClick(posición)`: un click dentro de la zona interactiva.
- **Los paneles** (`placeMenu`, `editMenu` y `emptyMenu`) entienden los mismos mensajes (`show()`, `hide()` y `onClick(posición)`), así el manager no tiene que preguntar cuál es.
- **Qué panel le toca a cada herramienta:** place → `placeMenu`, edit → `editMenu`. Sin herramienta, delete y rotate muestran `emptyMenu` (nada).
- `Zone`: un rectángulo de celdas. `contains(posición)` dice si un click cayó adentro, y `at(dx, dy)` da una posición relativa a su esquina inferior izquierda.

## `placeMenu.wlk`

- Muestra 4 máquinas por página, en 4 slots de arriba hacia abajo. El orden sale de `machineManager` (ver [`machines/README.md`](../machines/README.md)).
- Las páginas se cambian con Q y E. Cada página muestra 4 máquinas; `prev` y `next` avanzan de a una, sin pasarse de la primera ni de la última.
- Al hacer click en un slot elige esa máquina (`machineManager.select`) y mueve el marco (`overlay`) encima.
- `MenuItem`: cada máquina dibujada en el panel. Le pide la imagen a una máquina de muestra (`menuImage(dirección)`), así cada tipo decide qué mostrar (el brazo, por ejemplo, por ahora siempre muestra la misma).
- `overlay`: el marco sobre la máquina elegida. Sólo se dibuja si esa máquina está en la página que se ve.

> **RENDIMIENTO:** las imágenes y la posición del marco se calculan sólo cuando cambia algo (dirección, página o máquina elegida), no en cada frame. `selectedSlot()` es caro porque crea máquinas para comparar nombres: no llamarlo desde algo que se dibuja.

## `toolBar.wlk`

Muestra `tools/<herramienta>_selected.png`, o `tools/default.png` si no hay ninguna elegida. La actualiza `menuManager` cuando cambia la herramienta.

## `editMenu.wlk`

Muestra los settings de la máquina elegida con la herramienta edit (ver [`machines/README.md`](../machines/README.md#configuración-settings)). **No sabe de qué máquina se trata**: le pide `settings()` y dibuja lo que devuelve.

- Se dibuja de arriba hacia abajo, una línea por vez. Por cada categoría: el título en mayúsculas y, por cada setting de esa categoría, su nombre y sus opciones de a 4 por fila (el ancho de la zona):

  ```
  PRODUCCION              ← categoría (una sola vez, aunque tenga varios settings)
  Ingrediente             ← setting
  [lechuga][pan][papa frita][papa]
  [tomate]
  Velocidad               ← otro setting de la misma categoría
  x0.5   x1     x2
  ```

- Un setting con `column()` (no `null`) se dibuja distinto: después de los demás settings de su categoría, en **esa columna**, con su nombre arriba y sus opciones una debajo de la otra. Los settings en columna de una misma categoría quedan uno al lado del otro. Así se ven las tres salidas del brazo inteligente (`ItemSetSetting`):

  ```
  MOVIMIENTO
  Izq.  Recto  Der.       ← un setting por columna (column() = 0, 1 y 2)
  [papa][papa] [papa]
  [lech][lech] [lech]
  ...
  ```

- Las opciones con `image` se dibujan con su imagen (`OptionImage`) y las otras con su `label` (`MenuText`). En columna, siempre con su imagen.
- Click en una opción: se la aplica a su setting (`setting.select(option)`). `OptionSlot` recuerda qué opción de qué setting hay en cada celda.
- Hay una marca (`OptionMarker`) sobre cada opción elegida (`isSelected`) de **cada** setting. Un setting que permite elegir varias (`ItemSetSetting`) muestra varias marcas.
- Se redibuja sólo cuando cambia la máquina elegida; un click sólo mueve las marcas.
- Una máquina sin settings no muestra nada.
