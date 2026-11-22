# `menu/`

Los menús de la pantalla. Ocupan las columnas fuera del tablero:

| Zona | Celdas | Qué muestra |
|---|---|---|
| Cartel del modo | x 18 a 21, y 12 | COLOCANDO o EDITANDO (`modeBanner`) |
| Zona interactiva | x 18 a 21, y 0 a 11 | El panel del modo: las máquinas para colocar, o los ajustes de la máquina que se edita |
| Botones de abajo a la izquierda | x 0 a 3, y 0 a 3 | Recetario, menú, iniciar/pausa y velocidad, clickeables (`sideButtons`) |
| Información del nivel | x 0 a 4, y 1 a 11 | Reservada (todavía vacía) |

| Archivo | Qué tiene |
|---|---|
| `menuManager.wlk` | `menuManager`: el que conoce a todos los menús y les reenvía los eventos. También `emptyMenu`. Las zonas de la pantalla son `Zone`, que está en `src/board.wlk` |
| `placeMenu.wlk` | El panel de **COLOCANDO**: las máquinas para elegir, con páginas y un marco sobre la elegida, y los botones de dirección |
| `editMenu.wlk` | El panel de **EDITANDO**: los settings de la máquina elegida, agrupados por categoría (con clic, o con las flechas y Enter) |
| `armMenu.wlk` | El panel de **EDITANDO** de los brazos: hacia qué lado del tablero manda cada cosa |
| `levelComplete.wlk` | La comanda que aparece al completar un nivel, con sus botones (siguiente, repetir, menú) |
| `actionsMenu.wlk` | El menú de la máquina elegida: ROTAR, EDITAR y BORRAR, debajo de ella |
| `hud.wlk` | Lo que se ve siempre alrededor del tablero: el cartel COLOCANDO / EDITANDO (`modeBanner`) y los botones de abajo a la izquierda (`sideButtons`, con `speedFrame` en la velocidad elegida) |
| `levelInfoMenu.wlk` | La información del nivel, en la zona de la izquierda: nombre, objetivos y si se ganó |
| `tutorialGuide.wlk` | Lo que el tutorial dibuja sobre el tablero: el cocinero con su globo (`chefGuide`, `bubbleMessages`) y las marcas (`tutorialMarks`) |
| `visuals.wlk` | Lo común a todos los menús: `Picture` (una imagen fija), `CellArea` y `Button` (lo que se clickea), `noButton` y `VisualGroup` (lo dibujado, para sacarlo junto) |
| `texts.wlk` | Los textos: `MenuText` (los de Wollok) y `spriteText` (una imagen por letra, sin contorno) |
| `spriteFonts.wlk`, `bubbleTexts.wlk` | **Generados**: las letras (`assets/menu/font/makeFont.py`) y los mensajes del globo ya escritos (`assets/tutorial/makeBubbleTexts.py`). No se editan a mano |

## `visuals.wlk`: lo común a los menús

Wollok le pide `position()` e `image()` a **cada visual en cada frame**, así que todo lo que se dibuja guarda las dos cosas: la posición es una constante (`CellPosition`, que no crea nada al dibujarse) y la imagen sólo cambia cuando alguien la cambia.

- `Picture(image, position)`: una imagen fija. Sabe mostrarse y sacarse (`show()`, `hide()`). Las subclases cambian la imagen asignándola (`MenuItem`, `CompassTile`, `TutorialMark`, `BookButton`, `modeBanner`...).
- `CellArea(position, width, height, action)`: celdas que se clickean (Wollok avisa el clic por celda). `contains(pos)` y `press()`. `Button` es un `CellArea` con imagen. Los paneles buscan el botón clickeado con `findOrDefault(..., noButton).press()`: no hay `if` por fila.
- `VisualGroup`: lo que dibujó un panel. `add(visual)` lo agrega a la pantalla; `keep(algo)` guarda algo que ya se dibujó solo (un texto de `spriteText`); `clear()` saca todo (cada cosa sabe sacarse con `hide()`).

## `menuManager.wlk`

- **Es el único que conoce los menús.** El resto del juego le avisa lo que pasó y él se lo pasa al menú que corresponde:
  - `modeChanged(modo)`: actualiza el cartel y cambia el panel de la zona interactiva;
  - `directionChanged()`: actualiza las imágenes de las máquinas del panel (cambian con W/A/S/D);
  - `chooseMachine(paso)`: teclas Q y E;
  - `onClick(posición)`: un click dentro de la zona interactiva.
- **Los paneles** (`placeMenu`, `editMenu` y `emptyMenu`) entienden los mismos mensajes (`show()`, `hide()` y `onClick(posición)`), así el manager no tiene que preguntar cuál es.
- **Qué panel le toca a cada modo:** COLOCANDO (`placingMode`) → `placeMenu`, EDITANDO (`editingMode`) → `editMenu`. Antes de empezar a jugar, `emptyMenu` (nada).
- `Zone`: un rectángulo de celdas. `contains(posición)` dice si un click cayó adentro, y `at(dx, dy)` da una posición relativa a su esquina inferior izquierda.

## `placeMenu.wlk`

- Se ve mientras el jugador está COLOCANDO (siempre, salvo mientras edita una máquina).
- Muestra 4 máquinas por página, en casilleros de 2x2 celdas de a 2 por fila: el 1 arriba a la izquierda (x 18, y 10), el 2 a su derecha (x 20), y el 3 y el 4 abajo (y 8). Debajo va la ayuda (`menu/place_help.png`, fila 7). El orden sale de `machineManager` (ver [`machines/README.md`](../machines/README.md)).
- Q y E eligen la máquina anterior o la siguiente del catálogo (`chooseNext`), y pasan de página solas. Cada página muestra 4 máquinas; `prev` y `next` avanzan de a una página, sin pasarse de la primera ni de la última.
- Abajo, "HACIA DÓNDE MIRA" (fila 6) y la **brújula** (filas 2 a 5, `compassTiles`): arriba y abajo, botones de 2 celdas de ancho; izquierda y derecha, de 2 de alto; en el centro, la máquina elegida mirando hacia donde va a quedar (`compassMachine`). La dirección elegida va en amarillo. Las imágenes (`menu/compass_*.png`) las genera `assets/menu/makeArmAndTicket.py`.
- `resetPage()`: vuelve a la primera página, y redibuja si el panel se está viendo. Se usa al cambiar el catálogo (`machineManager.changeCatalog`): si el nuevo tiene menos páginas, la página actual podría no existir.
- Al hacer click en un casillero elige esa máquina (`machineManager.select`), mueve el marco amarillo encima y le avisa a `levelManager.machineSelected`: si el tutorial pide otra, el casillero se pone rojo un momento (`flashError`) y el cocinero dice cuál va.
- `MenuItem`: cada máquina dibujada en el panel. Le pide la imagen a una máquina de muestra (`menuImage(dirección)`: la máquina en chico con su nombre abajo, ver `assets/menu/makePlaceSlots.py`), así cada tipo decide qué mostrar (el brazo, por ejemplo, por ahora siempre muestra la misma).
- `selectionFrame`: el marco amarillo sobre la máquina elegida. Sólo se dibuja si esa máquina está en la página que se ve.
- `highlight(fábricas)`: las máquinas que pide el paso del tutorial; su casillero titila (`menu/slot_hint.gif`). Lo llama `levelManager` con cada aviso al tutorial.

> **RENDIMIENTO:** las imágenes y la posición del marco se calculan sólo cuando cambia algo (dirección, página o máquina elegida), no en cada frame. `selectedSlot()` es caro porque crea máquinas para comparar nombres: no llamarlo desde algo que se dibuja.

## `hud.wlk`

- `modeBanner`: muestra `menu/mode_placing.png` (COLOCANDO) o `menu/mode_editing.png` (EDITANDO, con la tecla Retroceso para salir). Lo cambia `menuManager.modeChanged`. Las imágenes las genera `assets/menu/makeBoardUi.py`.
- `sideButtons`: los botones de abajo a la izquierda, uno por fila de celdas: F RECETARIO (fila 3), M MENÚ (fila 2), ESPACIO INICIAR / PAUSA (fila 1) y 1, 2, 3 (fila 0, una celda cada uno). Cada uno es un `CellArea` con su acción, la misma que su tecla. La imagen (`menu/side_buttons.png`) tapa las teclas que trae dibujadas el fondo. `speedFrame` toma su posición de una lista armada una vez, según `simulationEngine.speed()`.

## `actionsMenu.wlk`

El menú de la máquina elegida: ROTAR (C), EDITAR (X) y BORRAR (V), una celda cada uno, debajo de la máquina (o arriba, si está en la fila de abajo). Lo que no se puede hacer se ve apagado. Lo usa `toolsManager` (ver [`tools/README.md`](../tools/README.md)).

## `armMenu.wlk`

El panel de los brazos (X sobre un brazo: cada máquina dice qué panel abre con `editPanel()`). Muestra los lados como se ven en el tablero (↑ → ↓ ←), no "Recto / Izq. / Der.", que son relativos a donde agarra:

- Fila 11, el título; filas 9 y 10, el brazo como está (`editBoxImage`) y una ficha roja "AGARRA DE ←"; fila 8, qué hacer (`editHint`).
- Desde la fila 7, los casilleros, de a 4 por fila (`editChoices`, ver `ArmKindChoice` y `ArmSideChoice` en `machines/settings.wlk`):
  - **brazo inteligente:** uno por ingrediente. Cada clic lo manda al lado siguiente (nada → ↑ → → → ↓ → ← → nada, sin el de donde agarra); si sale por algún lado va en amarillo con una flechita en la esquina. Un ingrediente sale por un solo lado. Por dentro se guarda en los filtros de siempre (`Recto`, `Izq.`, `Der.`), así la simulación no cambia.
  - **brazo común:** las cuatro direcciones; la de donde agarra va en rojo y no se elige.
- Mientras se edita, en el tablero, al lado del brazo, una flechita por cada lado por el que sale algo y las insignias de lo que sale (las del dispenser).
- Con el teclado: las flechas mueven una marca (que aparece recién al usarlas) y Enter usa el casillero marcado.

## `levelComplete.wlk`

Al completar un nivel se oscurece la pantalla y aparece una **comanda**: el nombre del nivel, lo entregado, el tiempo de cocina (los pasos de la simulación desde que se prendió), la energía usada y las máquinas que puso el jugador, y los botones **SIGUIENTE NIVEL** (N), **REPETIR** (0) y **MENÚ** (M) (en el último nivel, **JUGAR DE NUEVO**). Mientras se ve, los clics van sólo a sus botones (`playingScreen`). Se va al cargar otro nivel. Las imágenes las genera `assets/menu/makeArmAndTicket.py`; los textos se escriben con las letras del papel (`spriteText`).

## `editMenu.wlk`

Muestra los settings de la máquina que se edita (X sobre la elegida; ver [`machines/README.md`](../machines/README.md#configuración-settings)). **No sabe de qué máquina se trata**: le pide `settings()` y dibuja lo que devuelve.

- Se dibuja de arriba hacia abajo, una línea por vez. Por cada categoría: el título en mayúsculas y, por cada setting de esa categoría, su nombre y sus opciones de a 4 por fila (el ancho de la zona):

  ```
  PRODUCCION              ← categoría (una sola vez, aunque tenga varios settings)
  Ingrediente             ← setting
  [lechuga][pan][papa frita][papa]
  [tomate]
  Velocidad               ← otro setting de la misma categoría
  x0.5   x1     x2
  ```

- Un setting en columna (`isColumned()`, con su `column()`) se dibuja distinto: después de los demás settings de su categoría, en **esa columna**, con su nombre arriba y sus opciones una debajo de la otra. Los settings en columna de una misma categoría quedan uno al lado del otro. Así se ven las tres salidas del brazo inteligente (`ItemSetSetting`):

  ```
  MOVIMIENTO
  Izq.  Recto  Der.       ← un setting por columna (column() = 0, 1 y 2)
  [papa][papa] [papa]
  [lech][lech] [lech]
  ...
  ```

- Las opciones con `image` se dibujan con su imagen (`Picture`) y las otras con su `label` (`MenuText`). En columna, siempre con su imagen.
- Click en una opción: se la aplica a su setting (`setting.select(option)`). `OptionSlot` recuerda qué opción de qué setting hay en cada celda.
- Hay una marca (`overlay_cell.png`) sobre cada opción elegida (`isSelected`) de **cada** setting. Un setting que permite elegir varias (`ItemSetSetting`) muestra varias marcas.
- Se redibuja sólo cuando cambia la máquina elegida; un click sólo mueve las marcas.
- Una máquina sin settings no muestra nada.

## `levelInfoMenu.wlk`

Muestra la información del nivel en la zona `levelInfoZone` (x 0 a 4, y 1 a 11), centrada en la parte azul (columna 1.5). **No decide nada**: le avisa `levelManager` (ver [`levels/README.md`](../levels/README.md)).

| Fila (y) | Qué muestra |
|---|---|
| 10 | El nombre del nivel, en mayúsculas y en amarillo, sobre una cinta roja como el título del juego |
| 9 | Una ayuda (`showHint(texto)`): en el modo libre, `L: volver`. En los tutoriales, el botón **T SALTEAR TUTORIAL** (`assets/menu/key_skip.png`), que también se clickea: `isSkipButton(pos)` dice si un click cayó en él. Se borra al cargar otro nivel |
| 8 | `OBJETIVO`, en gris, arriba de una tarjeta de papel (como las hojas del recetario) que llega hasta el último objetivo. No aparece si el nivel no tiene objetivos con texto, como el modo libre |
| 7 a 5 | Uno por objetivo (`level.shownGoals()`), como máximo 3: la imagen del plato a la izquierda, su texto en marrón y una barra de progreso que se llena por décimos (`goal.progressTenths()`) |
| 4.5 y 3.7 | Al ganar: `¡Nivel completo!` y la tecla N (SIGUIENTE), o `¡Fin del juego!` y la tecla 0 (REINICIAR) si no hay otro nivel. Las teclas son imágenes (`assets/menu/key_next.png` y `key_restart.png`, las genera `makeKeyHints.py`) con el estilo de las teclas del fondo |
| 3.5 hacia abajo | Nada: el fondo (`background.gif`) tiene dibujadas las teclas F, M, Espacio y 1 2 3 |

| Método | Lo llama | Qué hace |
|---|---|---|
| `show(nivel)` | `levelManager.load` | Borra todo lo que había y dibuja el nombre, el título y los objetivos |
| `updateProgress(nivel)` | `levelManager`, al entregar algo y al apagar la simulación | Reemplaza sólo los objetivos (`progressMessage()` y `progressBars()` devuelven lo que se ve) |
| `showCompleted(hayOtro)` | `levelManager.finishLevel` | Agrega el mensaje y la tecla para seguir (`completedMessage()` devuelve lo que dicen) |

- **Sólo se redibuja cuando lo llaman**, nunca en cada frame. Un `MenuText` tiene el texto fijo: para cambiarlo, se saca el visual y se agrega uno nuevo.
- Guarda lo dibujado en grupos (`VisualGroup`: el nombre, la tarjeta y el título; los objetivos; el mensaje de nivel completo; y la energía) para reemplazar sólo lo que cambia.
- **El estilo lo dan las imágenes de atrás** (`assets/menu/info/`: la cinta, las tarjetas para 1 a 3 objetivos, las barras de 0 a 10 décimos y los globos para 1 a 6 líneas, que genera `makeLevelInfo.py`) **y las letras**. Las imágenes se agregan antes que los textos, porque se dibujan en ese orden.
- **Sobre el papel (la tarjeta y el globo) los textos se escriben con sprites** (`spriteText`, en `texts.wlk`), porque Wollok dibuja todos sus textos con un contorno oscuro que no se puede sacar, y ahí se ve raro. El nombre del nivel y los textos sobre el azul siguen siendo textos de Wollok (`MenuText`).
- **Las posiciones con decimales son `CellPosition`**, no `game.at`: Wollok redondea a la celda la posición de `game.at` al dibujar, y la imagen quedaría corrida.
- Wollok no corta el texto en varias líneas: con 4 celdas de ancho, los textos tienen que ser cortos.
- **Centrado:** Wollok dibuja cada texto centrado en su celda, y la parte azul va de x 0 a 4. Por eso los textos van en la columna 1.5: su centro cae en x = 2.

### `tutorialGuide.wlk`: `chefGuide`

El cocinero que guía los tutoriales, sobre el tablero. Se para al lado de la celda del paso (la del recuadro, o la máquina que se explica) y la señala con la cuchara: arriba de ella si hay lugar, si no abajo; a su izquierda, salvo en las primeras columnas. Al costado tiene un globo con el paso (`PASO 2 DE 12`) y el mensaje (como máximo 6 líneas de 16 caracteres: `maxLines()` y `maxLength()`, lo revisa un test).

| Método | Lo llama | Qué hace |
|---|---|---|
| `say(pasos, lineas, teclas, celdas)` | `levelManager`, con cada aviso al tutorial | Dibuja el cocinero y el globo, con las teclas del paso debajo del mensaje, una por fila (`tutorial/key_<nombre>.png`: "[ENTER] para seguir"). `message()`, `keys()` y `stepLabel()` devuelven lo que dice. Sin líneas (sin tutorial) no se ve; sin paso (`stepLabels()` vacío: terminó), festeja |
| `complain(lineas)` | `levelManager`, cuando el jugador hizo algo que el paso no deja | Pone cara de "uy" y lo dice en un globo rojo un momento (1.7 s), y vuelve al mensaje del paso |

Lo que dice al quejarse lo decide el tutorial (`complaintFor`, `complaintForMachine`: ver [`levels/README.md`](../levels/README.md)). Las imágenes (12 del cocinero: 3 caras, 2 poses y 2 lados; y los globos) las genera `assets/tutorial/makeChef.py`.

> **RENDIMIENTO:** si `say` recibe lo mismo que ya está diciendo (lo más común mientras se cocina: cada entrega le avisa al tutorial), no redibuja nada. **Cada mensaje es una sola imagen** (`bubbleMessages`: `assets/tutorial/messages/<n>.png`, la lista en `bubbleTexts.wlk`), en vez de una por letra (eran unas 60 por mensaje). Las genera `assets/tutorial/makeBubbleTexts.py` con los textos de `src/levels` y `src/tools`: **si se cambia o se agrega un mensaje, hay que volver a correrlo** (un test de `levelManagerTest` avisa si falta alguno). Un mensaje sin imagen (por ejemplo, "¡Esa no! Buscá la cinta.", que se arma con el nombre de la máquina) se escribe letra por letra, como antes.

### `tutorialGuide.wlk`: `tutorialMarks`

Los indicadores del tutorial sobre el tablero: `show(celdasObjetivo, celdasSeñaladas)` saca los anteriores y dibuja un recuadro (`tutorial/place.gif`) en cada celda objetivo y una flecha (`tutorial/look.gif`) arriba de la máquina de cada celda señalada (`arrowPosition`: con una de 2x2, arriba de su fila de arriba y centrada entre sus dos columnas). Lo llama `levelManager` con cada aviso al tutorial; si las marcas quedan en los mismos lugares, no hace nada. Si el jugador hace algo que el paso no deja, `flashError()` pone los recuadros en rojo (`tutorial/place_error.gif`) un momento. Las imágenes se generan con `assets/tutorial/makeMarks.py` (la roja, con `makeChef.py`).
- `positionOfRow(fila)`: la posición en pantalla de una de sus filas (la usan los tests).

## `recipeBook.wlk`

El libro de recetas: una tapa y una página por plato. Se abre con **F** (también desde la portada), **siempre en la tapa**, y se cierra con la cruz o con **F**. **Las flechas (izquierda y derecha) pasan las páginas**: la tapa está antes de la primera receta. **Mientras está abierto, la simulación queda en pausa** (`simulationEngine.pause()`), y al cerrarlo sigue desde donde estaba. Si estaba apagada, sigue apagada.

- **Cada página es una imagen entera** de 800x500 (`assets/recipes_book/`), dibujada desde la celda (5, 2): ocupa x 5 a 20 e y 2 a 11. El código no dibuja textos: sólo cambia la imagen.
- **Los botones del libro** (`bookButtons`, imágenes `menu/book_*.png`): la cruz (x 19 y 20, y 10 y 11) lo cierra, y las flechas de los costados (x 0 y x 21) pasan de página; se apagan en la primera y en la última. Un clic en la mitad izquierda del libro vuelve y en la derecha avanza. Wollok avisa los clics por celda.
- Las flechas para pasar de página están dibujadas en las imágenes: "para avanzar →" en la tapa (`cover.png`), y "← anterior" y "siguiente →" en cada receta (la última no tiene "siguiente"). Si se vuelven a exportar las páginas, hay que dibujarlas.
- Con el libro abierto, **los clicks van al libro y las demás teclas no hacen nada** (ver `userController.whenPlaying`).

| Método | Qué hace |
|---|---|
| `open()` / `close()` / `toggle()` | Abre (en la tapa) y cierra |
| `clickAt(pos, pantalla)` | Un clic con el libro abierto (ver arriba). Lo llama `BookScreen`, que es la pantalla mientras está abierto |
| `prevPage()` / `nextPage()` | Las flechas. Desde la primera receta, la izquierda vuelve a la tapa; en la tapa la izquierda, y en la última receta la derecha, no hacen nada. Con el libro cerrado, tampoco |

**Agregar un plato:**

1. Su página en `assets/recipes_book/recipe_<plato>.png`, de 800x500, con la cruz y las flechas en el mismo lugar que las demás.
2. Una línea en `pages`, en el lugar que le toca (el número que tiene dibujado).
3. Un test avisa si una receta del juego no tiene página.

## `startMenu.wlk`

La portada (`startScreen`, sin las teclas de cada opción: la genera `assets/makeCover.py`), los controles (`menuControlsOverlay`, con I: `assets/menu/menu_controls.png`, cuyo panel redibuja `makeKeyHints.py`) y el fondo del menú. En la portada las opciones se eligen **con un clic, o con ↑ ↓ y Enter** (`coverMenu`, con un recuadro amarillo en la marcada: `coverFocus`); I, F y S siguen siendo atajos. INICIAR la primera vez arma el juego (las teclas, los menús, los platitos y el primer nivel). **M** vuelve a la portada y pausa la simulación.

- `onClick(pos)`, `whenPlaying(acción)`, `start()` (Enter), `arrow(dirección)` y `back()` (Retroceso): los resuelve la pantalla activa (`recipeBook.screenOver(screen)`: la del libro si está abierto, si no la del menú). Cada pantalla sabe qué hacer: la portada elige opciones, `playingScreen` juega, y el libro (`BookScreen`) pasa de página y se cierra. `userController` sólo se los manda. El libro de recetas, en cambio, se puede abrir siempre. El recetario también es una máquina de estados: `closedBook` y `openBook`.
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

CONTROLES (con el mouse o con el teclado, como quieras)
- Clic en una celda vacía: colocar la máquina elegida en el menú de la
  derecha (sólo con el clic).
- Clic en una máquina: elegirla.
- C, X, V: rotar, editar o borrar la máquina elegida (o su menú, abajo).
- Retroceso: dejar de editar.
- W, A, S, D (o los botones del menú): hacia dónde mira la máquina.
- Q y E: cambiar de máquina en el menú.
- F: abrir y cerrar el libro de recetas (las flechas pasan las recetas).
- ESPACIO: prender y apagar la simulación.
- 1, 2 y 3: velocidad de la simulación.
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

## `texts.wlk`: `spriteText`

Escribe textos con una imagen por letra, **sin el contorno** que Wollok les pone a todos sus textos. Lo usa `levelInfoMenu` para lo que va sobre el papel.

- `spriteText.draw(texto, estilo, centroX, centroY)`: escribe el texto centrado en ese punto (en celdas) y devuelve una `SpriteLine`, que sabe sacarse (`hide()`) y decir qué escribió (`description()`, para los tests).
- Los estilos (`textFont`: marrón, 14 px; `labelFont`: gris, 11 px) y las letras están en `spriteFonts.wlk`, **que se genera** con `assets/menu/font/makeFont.py` junto con las imágenes de cada letra. Para cambiar un color o un tamaño, o agregar una letra, se cambia el script y se lo vuelve a correr.
- Una letra que no está se escribe como `?`.
- Cada letra es un visual: usarlo para textos cortos que se redibujan poco, no en cada frame. Para textos largos que no cambian (los mensajes del cocinero) conviene una imagen ya escrita, como `bubbleMessages`.

