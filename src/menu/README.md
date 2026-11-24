# `menu/`

Las pantallas del juego y todo lo que se dibuja fuera de las máquinas. Está ordenado como se ve la pantalla de juego, en tres capas: el **HUD** (lo fijo alrededor del tablero), el **tablero** (fuera de `menu/`: `board.wlk` y `machines/`) y lo que va **encima del tablero**.

```
menu/
  screenManager.wlk     el que cambia de pantalla
  screens.wlk           las 5 pantallas (y la portada)
  recipeBook.wlk        las páginas del recetario (lo que muestra bookScreen)
  levelComplete.wlk     el ticket de nivel completo (lo que muestra levelCompleteScreen)
  hud/                  lo que rodea al tablero
    hud.wlk             hud (junta las dos columnas) + modeBanner, sideButtons, speedFrame
    leftPanel.wlk       la columna izquierda: info del nivel y botones
    rightPanel.wlk      la columna derecha: el cartel y el panel de colocar o de editar
    levelInfoMenu.wlk   la info del nivel (+ el botón de saltear el tutorial)
    placeMenu.wlk       el panel de COLOCANDO
    editMenu.wlk        el panel de EDITANDO (los ajustes de la máquina)
    armMenu.wlk         el panel de EDITANDO de los brazos
  overBoard/            lo que va encima del tablero
    tutorialGuide.wlk   el cocinero con su globo (+ chefBubble, clickeable) y las marcas del tutorial
    bubbleTexts.wlk     generado: los mensajes del globo
    actionsMenu.wlk     ROTAR / EDITAR / BORRAR debajo de la máquina elegida
  drawing/              herramientas de dibujo
    visuals.wlk         Picture, Button, VisualGroup
    texts.wlk           MenuText, spriteText, SpriteFont
    spriteFonts.wlk     generado: el ancho de cada letra
```

Lo común de los clics (`ClickTargets`, `CellArea`, `nothingClicked`) está en [`input/clickManager.wlk`](../input/README.md).

| Zona (`hud`) | Celdas | Qué muestra |
|---|---|---|
| `bannerZone` | x 18 a 21, y 12 | COLOCANDO o EDITANDO (`modeBanner`) |
| `interactiveZone` | x 18 a 21, y 0 a 11 | El panel del modo: las máquinas para colocar, o los ajustes de la máquina que se edita |
| `leftZone` | x 0 a 4, y 0 a 12 | La columna izquierda: `levelInfoZone` (y 1 a 11) y los botones de abajo (x 0 a 3, y 0 a 3) |

`spriteFonts.wlk` y `bubbleTexts.wlk` son **generados** (`assets/menu/font/makeFont.py` y `assets/tutorial/makeBubbleTexts.py`): no se editan a mano.

## Las pantallas: `screenManager.wlk` y `screens.wlk`

`screenManager` es **el único que cambia de pantalla**. Sabe cuál está activa y le pasa cada clic y cada tecla, con un mensaje que dice qué quiere el jugador (`enter()`, `toggleSimulation()`, `nextLevel()`...). La pantalla decide qué hacer: nadie pregunta en qué pantalla está.

| Pantalla | Cuándo | Clics | Teclas |
|---|---|---|---|
| `coverScreen` | La portada | Las 4 opciones (`coverMenu`, cada una con su zona) | Arriba y abajo mueven la marca, Enter elige, I controles, F libro, S sale |
| `instructionsScreen` | Los controles | La fila de abajo vuelve | Enter, I y Retroceso vuelven; F libro |
| `playingScreen` | Jugando | Por capas: `chefBubble`, `actionsMenu`, `hud`, el tablero (`boardArea`) | Las del juego; Enter sigue el tutorial o aplica la opción marcada; S mira hacia abajo |
| `bookScreen` | El recetario abierto, **encima** de otra | La cruz, la mitad izquierda y la derecha | Izquierda y derecha pasan de página; F y Retroceso lo cierran; las demás no hacen nada |
| `levelCompleteScreen` | El ticket, **encima** del juego | Sus botones | N, 0 y M (lo cierran primero); Enter aprieta el primer botón |

- Las tres primeras se reemplazan entre sí: `changeScreen` sale de la actual (`leave`) y entra en la nueva (`show`).
- El libro y el ticket se abren **encima** (`cover`): guardan cuál quedó abajo (`under`), y al cerrarse (`uncover`) se vuelve a ella tal como estaba. La de abajo se entera con `hideUnderOverlay()` / `showAfterOverlay()`.
- Todas heredan de `Screen`, que tiene **todas las teclas vacías por defecto**: cada pantalla redefine sólo las que usa. Por eso, con el libro abierto, S o Espacio no hacen nada.
- La primera vez que se juega se arman los platitos y el primer nivel (`newGame`); las siguientes, se sigue donde estaba (`resumedGame`).
- **M** vuelve a la portada y pausa la simulación. Con el ticket abierto, también lo cierra.

## Los clics

Un clic baja de nivel en nivel con **la misma regla** (`ClickTargets`, en `input/clickManager.wlk`): cada grupo dice que un clic es suyo mirando **su zona**, y recién al recibirlo se lo pasa a la primera de sus partes que lo quiera, de la que se ve más arriba a la de más abajo. Cada uno es consultado una sola vez. Un clic que no es de nadie (la pared de la cocina) no hace nada (`nothingClicked`).

Por ejemplo, un clic en la flecha de arriba de "HACIA DÓNDE MIRA": `screenManager` → `playingScreen` (el globo no, `actionsMenu` no, el `hud` sí) → `hud` (`leftPanel` no, `rightPanel` sí) → `rightPanel` → el panel que se ve (`placeMenu`) → la flecha → `toolsManager.currentDirection(up)`.

## `drawing/visuals.wlk`: lo común a los menús

Wollok le pide `position()` e `image()` a **cada visual en cada frame**, así que todo lo que se dibuja guarda las dos cosas: la posición es una constante (`CellPosition`, que no crea nada al dibujarse) y la imagen sólo cambia cuando alguien la cambia.

- `Picture(image, position)`: una imagen fija. Sabe mostrarse y sacarse (`show()`, `hide()`). Las subclases cambian la imagen asignándola (`MenuItem`, `TutorialMark`, `BookButton`, `modeBanner`...).
- `Button(image, zone, action)`: un `CellArea` (ver `input/clickManager.wlk`) con imagen, dibujada en la esquina de abajo a la izquierda de su zona (`CompassTile`, los botones del ticket).
- `VisualGroup`: lo que dibujó un panel. `add(visual)` lo agrega a la pantalla; `keep(algo)` guarda algo que ya se dibujó solo (un texto de `spriteText`); `clear()` saca todo (cada cosa sabe sacarse con `hide()`).

## `hud/`: el HUD

- **`hud`** junta las dos columnas: las muestra juntas (`show()`, lo llama `playingScreen`) y, en un clic, se lo pasa a la columna donde cayó. También sabe dónde está cada parte (las zonas de la tabla de arriba).
- **`leftPanel`**: la columna izquierda. La info del nivel la dibuja `levelManager` al cargar cada nivel (`levelInfoMenu`); acá están sus clics: el botón de saltear el tutorial (`skipTutorialButton`) y los botones de abajo (`sideButtons`).
- **`rightPanel`**: la columna derecha. Tiene el cartel (`modeBanner`) y el panel que se ve, y recibe lo que avisa `toolsManager`:
  - `modeChanged(modo)`: el cartel y el panel. Cada modo dice qué panel le toca (`panelIn`): COLOCANDO, `placeMenu`; EDITANDO, el que eligió la máquina (`editor`);
  - `directionChanged()`: las imágenes de las máquinas del panel (cambian con W/A/S/D);
  - `chooseMachine(paso)`: teclas Q y E;
  - `moveFocus` / `chooseFocused`: las flechas y Enter mientras se edita.
- **Editar una máquina (doble despacho):** `rightPanel.edit(máquina)` le dice a la máquina "abrite en mí" (`openEditorIn`), y la máquina contesta **qué es**: `editSettings` (horno, freidora, cortadora, dispenser, ensamblador), `editArm` (los brazos) o `nothingToEdit` (la cinta, el platito, una celda vacía). Cada uno de esos tres mensajes hace siempre lo mismo, así que **no hay `if`**: lo decide la clase de la máquina. La máquina no conoce ningún panel.
- Los paneles (`placeMenu`, `editMenu`, `armMenu`, y `noPanel` antes de jugar) entienden los mismos mensajes (`show()`, `hide()`, y son `ClickTargets`), así nadie pregunta cuál se está viendo.

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

## `hud/hud.wlk`: el cartel y los botones

- `modeBanner`: muestra `menu/mode_placing.png` (COLOCANDO) o `menu/mode_editing.png` (EDITANDO, con la tecla Retroceso para salir). Lo cambia `rightPanel.modeChanged`. Las imágenes las genera `assets/menu/makeBoardUi.py`.
- `sideButtons`: los botones de abajo a la izquierda, uno por fila de celdas: F RECETARIO (fila 3), M MENÚ (fila 2), ESPACIO INICIAR / PAUSA (fila 1) y 1, 2, 3 (fila 0, una celda cada uno). Cada uno es un `CellArea` con su zona y su acción, la misma que su tecla. La imagen (`menu/side_buttons.png`) tapa las teclas que trae dibujadas el fondo. `speedFrame` toma su posición de una lista armada una vez, según `simulationEngine.speed()`.

## `actionsMenu.wlk`

El menú de la máquina elegida: ROTAR (C), EDITAR (X) y BORRAR (V), una celda cada uno, debajo de la máquina (o arriba, si está en la fila de abajo). Lo que no se puede hacer se ve apagado. Lo usa `toolsManager` (ver [`tools/README.md`](../tools/README.md)). Está encima del tablero: en `playingScreen` va antes que el tablero, así un clic en sus celdas es suyo. Guarda la zona de sus tres celdas al mostrarse (`nowhere` mientras está escondido).

## `armMenu.wlk`

El panel de los brazos (X sobre un brazo: el brazo contesta `editArm`, ver `rightPanel`). Muestra los lados como se ven en el tablero (↑ → ↓ ←), no "Recto / Izq. / Der.", que son relativos a donde agarra:

- Fila 11, el título; filas 9 y 10, el brazo como está (`editBoxImage`) y una ficha roja "AGARRA DE ←"; fila 8, qué hacer (`editHint`).
- Desde la fila 7, los casilleros, de a 4 por fila (`editChoices`, ver `ArmKindChoice` y `ArmSideChoice` en `machines/types/arms.wlk`):
  - **brazo inteligente:** uno por ingrediente. Cada clic lo manda al lado siguiente (nada → ↑ → → → ↓ → ← → nada, sin el de donde agarra); si sale por algún lado va en amarillo con una flechita en la esquina. Un ingrediente sale por un solo lado. Por dentro se guarda en los filtros de siempre (`Recto`, `Izq.`, `Der.`), así la simulación no cambia.
  - **brazo común:** las cuatro direcciones; la de donde agarra va en rojo y no se elige.
- Mientras se edita, en el tablero, al lado del brazo, una flechita por cada lado por el que sale algo y las insignias de lo que sale (las mismas del dispenser y el ensamblador).
- Con el teclado: las flechas mueven una marca (que aparece recién al usarlas) y Enter usa el casillero marcado.

## `levelComplete.wlk`

Al completar un nivel se oscurece la pantalla y aparece una **comanda**: el nombre del nivel, lo entregado, el tiempo de cocina (los pasos de la simulación desde que se prendió), la energía usada y las máquinas que puso el jugador, y los botones **SIGUIENTE NIVEL** (N), **REPETIR** (0) y **MENÚ** (M) (en el último nivel, **JUGAR DE NUEVO**). **Sólo dibuja**: lo que dice lo arma el resultado del nivel (`LevelResult.lines()`, ver [`levels/README.md`](../levels/README.md#al-ganar-el-resultado-y-el-final)) y los botones los elige el final (`ending.showButtonsIn(ticket)`: `showNextLevelButtons()` o `showPlayAgainButtons()`). Lo dibuja `screenManager.showLevelComplete(resultado)` y lo muestra `levelCompleteScreen`, encima del juego: mientras se ve, los clics van sólo a sus botones. Siguiente, repetir y menú primero lo cierran y después hacen lo suyo. Las imágenes las genera `assets/menu/makeArmAndTicket.py`; los textos se escriben con las letras del papel (`spriteText`).

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
- Click en una opción: se la aplica a su setting (`setting.select(option)`). `OptionSlot` recuerda qué opción de qué setting hay en cada celda, y es el click target de esa celda.
- Hay una marca (`overlay_cell.png`) sobre cada opción elegida (`isSelected`) de **cada** setting. Un setting que permite elegir varias (`ItemSetSetting`) muestra varias marcas.
- Se redibuja sólo cuando cambia la máquina elegida; un click sólo mueve las marcas.
- Una máquina sin settings no muestra nada.

## `levelInfoMenu.wlk`

Muestra la información del nivel en la zona `levelInfoZone` (x 0 a 4, y 1 a 11), centrada en la parte azul (columna 1.5). **No decide nada**: le avisa `levelManager` (ver [`levels/README.md`](../levels/README.md)).

| Fila (y) | Qué muestra |
|---|---|
| 10 | El nombre del nivel, en mayúsculas y en amarillo, sobre una cinta roja como el título del juego |
| 9 | Una ayuda (`showHint(texto)`): en el modo libre, `L: volver`. En los tutoriales, el botón **T SALTEAR TUTORIAL** (`assets/menu/key_skip.png`), que también se clickea (`skipTutorialButton`, en la columna izquierda: ver `leftPanel`). Se borra al cargar otro nivel |
| 8 | `OBJETIVO`, en gris, arriba de una tarjeta de papel (como las hojas del recetario) que llega hasta el último objetivo. No aparece si el nivel no tiene objetivos con texto, como el modo libre |
| 7 a 5 | Uno por objetivo (`level.shownGoals()`), como máximo 3: la imagen del plato a la izquierda, su texto en marrón y una barra de progreso que se llena por décimos (`goal.progressTenths()`) |
| 4.5 y 3.7 | Al ganar: `¡Nivel completo!` y la tecla N (SIGUIENTE), o `¡Fin del juego!` y la tecla 0 (REINICIAR) si no hay otro nivel. Las teclas son imágenes (`assets/menu/key_next.png` y `key_restart.png`, las genera `makeKeyHints.py`) con el estilo de las teclas del fondo |
| 3.5 hacia abajo | Nada: el fondo (`background.gif`) tiene dibujadas las teclas F, M, Espacio y 1 2 3 |

| Método | Lo llama | Qué hace |
|---|---|---|
| `show(nivel)` | `levelManager.load` | Borra todo lo que había y dibuja el nombre, el título y los objetivos |
| `updateProgress(nivel)` | `levelManager`, al entregar algo y al apagar la simulación | Reemplaza sólo los objetivos (`progressMessage()` y `progressBars()` devuelven lo que se ve) |
| `showCompleted(final)` | `levelManager.finishLevel` | El final elige qué se muestra (`showNextLevelHint()` o `showGameOverHint()`): el mensaje y la tecla para seguir (`completedMessage()` devuelve lo que dicen) |

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
- **Los botones del libro** (`bookButtons`, imágenes `menu/book_*.png`; sus zonas están en `bookScreen`): la cruz (x 19 y 20, y 10 y 11) lo cierra, y las flechas de los costados (x 0 y x 21) pasan de página; se apagan en la primera y en la última. Un clic en la mitad izquierda del libro vuelve y en la derecha avanza. Wollok avisa los clics por celda.
- Las flechas para pasar de página están dibujadas en las imágenes: "para avanzar →" en la tapa (`cover.png`), y "← anterior" y "siguiente →" en cada receta (la última no tiene "siguiente"). Si se vuelven a exportar las páginas, hay que dibujarlas.
- El libro abierto es una pantalla más (`bookScreen`, en `screens.wlk`), encima de la que estaba: **los clics van al libro y las demás teclas no hacen nada**. `recipeBook` sólo maneja las páginas.

| Método | Qué hace |
|---|---|
| `open()` / `close()` / `toggle()` | Abre (en la tapa) y cierra |
| `prevPage()` / `nextPage()` | Las flechas. Desde la primera receta, la izquierda vuelve a la tapa; en la tapa la izquierda, y en la última receta la derecha, no hacen nada. Con el libro cerrado, tampoco |

**Agregar un plato:**

1. Su página en `assets/recipes_book/recipe_<plato>.png`, de 800x500, con la cruz y las flechas en el mismo lugar que las demás.
2. Una línea en `pages`, en el lugar que le toca (el número que tiene dibujado).
3. Un test avisa si una receta del juego no tiene página.

## La portada (`screens.wlk`)

La portada (`startScreen`, sin las teclas de cada opción: la genera `assets/makeCover.py`), los controles (`menuControlsOverlay`, con I: `assets/menu/menu_controls.png`, cuyo panel redibuja `makeKeyHints.py`) y el fondo del menú. En la portada las opciones se eligen **con un clic, o con las flechas y Enter** (`coverMenu`, con un recuadro amarillo en la marcada: `coverFocus`); I, F y S siguen siendo atajos. Cada opción (`CoverOption`) tiene su zona y sabe qué hacer al elegirla.

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

## `drawing/texts.wlk`: `spriteText`

Escribe textos con una imagen por letra, **sin el contorno** que Wollok les pone a todos sus textos. Lo usa `levelInfoMenu` para lo que va sobre el papel.

- `spriteText.draw(texto, estilo, centroX, centroY)`: escribe el texto centrado en ese punto (en celdas) y devuelve una `SpriteLine`, que sabe sacarse (`hide()`) y decir qué escribió (`description()`, para los tests).
- Los estilos (`textFont`: marrón, 14 px; `labelFont`: gris, 11 px) y las letras están en `spriteFonts.wlk`, **que se genera** con `assets/menu/font/makeFont.py` junto con las imágenes de cada letra. Para cambiar un color o un tamaño, o agregar una letra, se cambia el script y se lo vuelve a correr.
- Una letra que no está se escribe como `?`.
- Cada letra es un visual: usarlo para textos cortos que se redibujan poco, no en cada frame. Para textos largos que no cambian (los mensajes del cocinero) conviene una imagen ya escrita, como `bubbleMessages`.

