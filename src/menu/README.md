# `menu/`

Los menús de la pantalla. Ocupan las columnas fuera del tablero:

| Zona | Celdas | Qué muestra |
|---|---|---|
| Barra de herramientas | x 21 a 24, y 15 | La herramienta elegida (`toolBar`) |
| Zona interactiva | x 21 a 24, y 0 a 14 | El panel de la herramienta elegida (máquinas, info, o nada) |
| Información del nivel | x 0 a 4, y 1 a 14 | Reservada (todavía vacía) |

| Archivo | Qué tiene |
|---|---|
| `menuManager.wlk` | `menuManager`: el que conoce a todos los menús y les reenvía los eventos. También `emptyMenu`. Las zonas de la pantalla son `Zone`, que está en `src/board.wlk` |
| `placeMenu.wlk` | El panel de la herramienta **place**: las máquinas para elegir, con páginas y un marco sobre la elegida |
| `editMenu.wlk` | El panel de la herramienta **edit**: los settings de la máquina elegida, agrupados por categoría |
| `toolBar.wlk` | La barra que muestra qué herramienta está elegida |
| `levelInfoMenu.wlk` | La información del nivel, en la zona de la izquierda: nombre, objetivos y si se ganó |
| `menuText.wlk` | `MenuText`: un texto de los menús. Lo usan `editMenu` y `levelInfoMenu` |

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
- `resetPage()`: vuelve a la primera página, y redibuja si el panel se está viendo. Se usa al cambiar el catálogo (`machineManager.changeCatalog`): si el nuevo tiene menos páginas, la página actual podría no existir.
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

## `levelInfoMenu.wlk`

Muestra la información del nivel en la zona `levelInfoZone` (x 0 a 4, y 1 a 14), centrada en la parte azul (columna 1.5). **No decide nada**: le avisa `levelManager` (ver [`levels/README.md`](../levels/README.md)).

| Fila (y) | Qué muestra |
|---|---|
| 13 | El nombre del nivel, en mayúsculas y en amarillo, sobre una cinta roja como el título del juego |
| 12 | Una ayuda (`showHint(texto)`): en el modo libre, `L: volver`. En los tutoriales, el botón **T SALTEAR TUTORIAL** (`assets/menu/key_skip.png`), que también se clickea: `isSkipButton(pos)` dice si un click cayó en él. Se borra al cargar otro nivel |
| 11 | `OBJETIVO`, en gris, arriba de una tarjeta de papel (como las hojas del recetario) que llega hasta el último objetivo. No aparece si el nivel no tiene objetivos con texto, como el modo libre |
| 10 a 8 | Uno por objetivo (`level.shownGoals()`), como máximo 3: la imagen del plato a la izquierda, su texto en marrón y una barra de progreso que se llena por décimos (`goal.progressTenths()`) |
| 7.5 | El paso del tutorial (`tutorial.stepLabel()`, por ejemplo `PASO 2 DE 8`), en gris, arriba de un globo de diálogo |
| 7 hacia abajo | El mensaje del tutorial, en marrón dentro del globo: como máximo 6 líneas, separadas por 0.55 filas para que se lean como un párrafo. El globo tiene el alto justo para las líneas. Vacío en los niveles sin tutorial |
| 3.65 hacia arriba | Las teclas del mensaje del tutorial, afuera del globo (en amarillo no se leen sobre el papel), la primera arriba: imágenes `assets/menu/key_<nombre>.png` con el estilo de las teclas del fondo (por ejemplo `place`: Z COLOCAR). Se van cuando cambia el mensaje |
| 4.6 y 3.7 | Al ganar: `¡Nivel completo!` y la tecla N (SIGUIENTE), o `¡Fin del juego!` y la tecla 0 (REINICIAR) si no hay otro nivel. Las teclas son imágenes (`assets/menu/key_next.png` y `key_restart.png`, las genera `makeKeyHints.py`) con el estilo de las teclas del fondo |
| 3.5 hacia abajo | Nada: el fondo (`background.gif`) tiene dibujadas las teclas F, M, Espacio y 1 2 3 |

| Método | Lo llama | Qué hace |
|---|---|---|
| `show(nivel)` | `levelManager.load` | Borra todo lo que había y dibuja el nombre, el título y los objetivos |
| `updateProgress(nivel)` | `levelManager`, al entregar algo y al apagar la simulación | Reemplaza sólo los objetivos (`progressMessage()` y `progressBars()` devuelven lo que se ve) |
| `showCompleted(hayOtro)` | `levelManager.finishLevel` | Agrega el mensaje y la tecla para seguir (`completedMessage()` devuelve lo que dicen) |
| `showTutorialMessage(paso, lineas, teclas)` | `levelManager`, al cargar un nivel y con cada aviso al tutorial | Reemplaza el globo, el paso, el mensaje y sus teclas (`tutorialStepLabel()`, `tutorialMessage()` y `tutorialMessageKeys()` devuelven lo que se ve) |

- **Sólo se redibuja cuando lo llaman**, nunca en cada frame. Un `MenuText` tiene el texto fijo: para cambiarlo, se saca el visual y se agrega uno nuevo.
- Guarda lo dibujado en listas (el nombre, la tarjeta y el título; los objetivos; el mensaje de nivel completo; el globo, el mensaje y las teclas del tutorial) para reemplazar sólo lo que cambia.
- **El estilo lo dan las imágenes de atrás** (`assets/menu/info/`: la cinta, las tarjetas para 1 a 3 objetivos, las barras de 0 a 10 décimos y los globos para 1 a 6 líneas, que genera `makeLevelInfo.py`) **y las letras**. Las imágenes se agregan antes que los textos, porque se dibujan en ese orden.
- **Sobre el papel (la tarjeta y el globo) los textos se escriben con sprites** (`spriteText.wlk`), porque Wollok dibuja todos sus textos con un contorno oscuro que no se puede sacar, y ahí se ve raro. El nombre del nivel y los textos sobre el azul siguen siendo textos de Wollok (`MenuText`).
- **Las posiciones con decimales son `CellPosition`**, no `game.at`: Wollok redondea a la celda la posición de `game.at` al dibujar, y la imagen quedaría corrida.
- Wollok no corta el texto en varias líneas: con 4 celdas de ancho, los textos tienen que ser cortos. Para el tutorial, el límite está en `tutorialMaxLength()` (16) y `tutorialMaxLines()` (6), y lo revisa un test.
- **Centrado:** Wollok dibuja cada texto centrado en su celda, y la parte azul va de x 0 a 4. Por eso los textos van en la columna 1.5: su centro cae en x = 2.

### `tutorialMarks.wlk`

Los indicadores del tutorial sobre el tablero: `show(celdasObjetivo, celdasSeñaladas)` saca los anteriores y dibuja un recuadro (`tutorial/place.gif`) en cada celda objetivo y una flecha (`tutorial/look.gif`) arriba de la máquina de cada celda señalada (`arrowPosition`: con una de 2x2, arriba de su fila de arriba y centrada entre sus dos columnas). Lo llama `levelManager` con cada aviso al tutorial. Las imágenes se generan con `assets/tutorial/makeMarks.py`.
- `positionOfRow(fila)`: la posición en pantalla de una de sus filas (la usan los tests).

## `recipeBookMenu.wlk`

El libro de recetas: una tapa y una página por plato. Se abre con **F** (también desde la portada), **siempre en la tapa**, y se cierra con la cruz o con **F**. **Las flechas (izquierda y derecha) pasan las páginas**: la tapa está antes de la primera receta. **Mientras está abierto, la simulación queda en pausa** (`simulationEngine.pause()`), y al cerrarlo sigue desde donde estaba. Si estaba apagada, sigue apagada.

- **Cada página es una imagen entera** de 800x500 (`assets/recipes_book/`), dibujada desde la celda (5, 2): ocupa x 5 a 20 e y 2 a 11. El código no dibuja textos: sólo cambia la imagen.
- **La cruz se clickea**: ocupa las 4 celdas de arriba a la derecha de la imagen (x 19 y 20, y 10 y 11), porque Wollok avisa los clicks por celda. Tiene que estar en el mismo lugar en todas las páginas.
- Las flechas para pasar de página están dibujadas en las imágenes: "para avanzar →" en la tapa (`cover.png`), y "← anterior" y "siguiente →" en cada receta (la última no tiene "siguiente"). Si se vuelven a exportar las páginas, hay que dibujarlas.
- Con el libro abierto, **los clicks van al libro y las demás teclas no hacen nada** (ver `userController.whenPlaying`).

| Método | Qué hace |
|---|---|
| `open()` / `close()` / `toggle()` | Abre (en la tapa) y cierra |
| `onClick(pos)` | Un click con el libro abierto: la cruz lo cierra |
| `prevPage()` / `nextPage()` | Las flechas. Desde la primera receta, la izquierda vuelve a la tapa; en la tapa la izquierda, y en la última receta la derecha, no hacen nada. Con el libro cerrado, tampoco |

**Agregar un plato:**

1. Su página en `assets/recipes_book/recipe_<plato>.png`, de 800x500, con la cruz y las flechas en el mismo lugar que las demás.
2. Una línea en `pages`, en el lugar que le toca (el número que tiene dibujado).
3. Un test avisa si una receta del juego no tiene página.

## `startMenu.wlk`

La portada (`startScreen`), los controles (`menuControlsOverlay`, con I: `assets/menu/menu_controls.png`, que genera `makeKeyHints.py` sobre `menu_controls_base.png`) y el fondo del menú. **Enter** empieza a jugar: la primera vez arma el juego (las teclas, los menús, los platitos y el primer nivel). **M** vuelve a la portada y pausa la simulación; **S** en la portada cierra el juego.

- `isPlaying()`: si se está jugando. En la portada y en las instrucciones, las teclas y los clicks del juego no hacen nada (`userController.whenPlaying`); el libro de recetas sí se puede abrir.
- Antes de que `main.wpgm` llame a `show()`, se considera que se está jugando: así los tests, que no pasan por la portada, pueden usar las teclas y los clicks.

CÓMO JUGAR

LA HISTORIA
La IA dominó el mundo y echaron a todos los trabajadores del buffet.
Los ingenieros tenemos hambre y tenemos que seguir comiendo.
Es tu tarea automatizar todos los procesos del buffet.

EL OBJETIVO
El juego tiene distintas tareas. En cada una tenés que preparar una
comida usando las máquinas, sin que nadie las toque: armás la línea
de producción, prendés la simulación y mirás cómo trabaja sola.

CÓMO SE ARMA UNA COMIDA
Los ingredientes salen de un dispenser, viajan por cintas, se procesan
(cortar, cocinar, freír) y se juntan en el ensamblador, que entrega el
plato terminado.
Ejemplo: una hamburguesa necesita pan cortado, lechuga cortada, tomate
cortado y dos carnes cocidas.

LAS MÁQUINAS
- Dispenser: crea ingredientes.
- Cinta: lleva los ingredientes hacia donde apunta.
- Cortadora: corta los ingredientes.
- Horno: cocina los ingredientes.
- Freidora: fríe los ingredientes (próximamente).
- Ensamblador: junta los ingredientes y entrega el plato.

LOS BRAZOS
Hay dos tipos de brazo, y elegir bien cuál usar es parte del desafío.
- Brazo básico: agarra el ingrediente que le llega de un lado y lo
  entrega del lado contrario.
- Brazo inteligente: además sabe cuándo está listo un ingrediente. Lo
  saca del horno justo antes de que se queme. Un brazo básico podría
  sacarlo crudo.

CONTROLES
- Mouse: hacé click en el tablero para usar la herramienta elegida,
  y en el menú de la derecha para elegir una máquina.
- Z: elegir máquinas y colocarlas.
- X: modificar una máquina ya colocada.
- C: rotar una máquina ya colocada.
- V: eliminar una máquina.
- W, A, S, D: elegir hacia dónde mira la máquina antes de colocarla.
- Q y E: cambiar de página en el menú de máquinas.
- F: abrir y cerrar el libro de recetas (las flechas pasan las recetas).
- ESPACIO: prender y apagar la simulación.
- 1, 2 y 3: velocidad de la simulación.
Si apretás de nuevo la herramienta elegida, la deseleccionás.
Con la simulación prendida no se puede colocar, borrar ni rotar:
apagala para seguir construyendo.

LA ENERGÍA
Cada nivel tiene su propia cantidad de energía, y esa energía se
consume usando robots. Cuantos más robots uses, más energía gastás:
pensá bien cuáles hacen falta y cuáles no.

CONSEJOS
- Construí con la simulación apagada y probala cuando esté lista.
- Si un ingrediente se queda trabado, revisá hacia dónde apunta cada máquina.
- Empezá por una línea simple y sumá máquinas de a una.

## `spriteText.wlk`

Escribe textos con una imagen por letra, **sin el contorno** que Wollok les pone a todos sus textos. Lo usa `levelInfoMenu` para lo que va sobre el papel.

- `spriteText.draw(texto, estilo, centroX, centroY)`: escribe el texto centrado en ese punto (en celdas) y devuelve una `SpriteLine`, que sabe sacarse (`hide()`) y decir qué escribió (`description()`, para los tests).
- Los estilos (`textFont`: marrón, 14 px; `labelFont`: gris, 11 px) y las letras están en `spriteFonts.wlk`, **que se genera** con `assets/menu/font/makeFont.py` junto con las imágenes de cada letra. Para cambiar un color o un tamaño, o agregar una letra, se cambia el script y se lo vuelve a correr.
- Una letra que no está se escribe como `?`.
- Cada letra es un visual: usarlo para textos cortos que se redibujan poco, no en cada frame.

