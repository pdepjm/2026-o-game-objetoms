# `menu/`

Las pantallas del juego y todo lo que se dibuja fuera de las máquinas. Está ordenado como se ve la pantalla de juego, en tres capas: el **HUD** (lo fijo alrededor del tablero), el **tablero** (fuera de `menu/`: `board.wlk` y `machines/`) y lo que va **encima del tablero**.

```
menu/
  screenClasses.wlk     Screen, OverlayScreen, CellArea, KeyAction (y nothingClicked, noKeyAction)
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
    tutorialImages.wlk  generado: lo que dibuja cada imagen del cocinero
    actionsMenu.wlk     ROTAR / EDITAR / BORRAR debajo de la máquina elegida
  drawing/              herramientas de dibujo
    visuals.wlk         Picture, Button, VisualGroup
    texts.wlk           MenuText
```


| Zona (`hud`) | Celdas | Qué muestra |
|---|---|---|
| `bannerZone` | x 18 a 21, y 12 | COLOCANDO o EDITANDO (`modeBanner`) |
| `interactiveZone` | x 18 a 21, y 0 a 11 | El panel del modo: las máquinas para colocar, o los ajustes de la máquina que se edita |
| `leftZone` | x 0 a 4, y 0 a 12 | La columna izquierda: `levelInfoZone` (y 1 a 11) y los botones de abajo (x 0 a 3, y 0 a 3) |

`tutorialImages.wlk` es **generado** (`assets/tutorial/makeSteps.py`): no se edita a mano.

## Las pantallas: `screenClasses.wlk`, `screenManager.wlk` y `screens.wlk`

`screenManager` es **el único que cambia de pantalla**. Sabe cuál está activa y le pasa cada clic y cada tecla (por su nombre: `press("enter")`, `press("arrow", dirección)`...). La pantalla decide qué hacer: nadie pregunta en qué pantalla está.

`Screen` (en `screenClasses.wlk`, no hereda de nadie) hace lo mismo para todas; cada pantalla sólo **declara** dos listas:

- `clickableAreas()`: lo que se clickea, de lo que se ve más arriba a lo de más abajo. Un clic va a la primera zona que lo acepta (`handlesClick(pos)`), o a `nothingClicked`, que no hace nada: **CLIC → screenManager → pantalla activa → la acción de la zona, o nothingClicked**.
- `keyActions()`: sus teclas (`KeyAction(key, action)`; la acción recibe el valor de la tecla: una dirección, un número). Después van las de todas (`sharedKeys()`: F abre el libro), así una pantalla puede redefinir una tecla común poniéndola en su lista. Una tecla que nadie declara no hace nada (`noKeyAction`).
- Lo que se ve: `visuals()` (cada uno con `show()` y `hide()`) se agrega al entrar y se saca al salir. Las pantallas con un dibujo especial (el juego, el libro, el ticket) redefinen `show()` / `hide()`.
- `MenuScreen` (portada y controles) deja siempre el fondo azul, también detrás del libro.

| Pantalla | Cuándo | Clics | Teclas |
|---|---|---|---|
| `coverScreen` | La portada | Las 4 opciones (`coverMenu`, cada una con su zona) | Arriba y abajo mueven la marca, Enter elige, I controles, F libro, S sale |
| `instructionsScreen` | Los controles | La fila de abajo vuelve | Enter, I y Retroceso vuelven; F libro |
| `playingScreen` | Jugando | Por capas: `chefBubble`, `actionsMenu`, `hud`, el tablero (`boardArea`) | Las del juego; Enter sigue el tutorial o aplica la opción marcada; S mira hacia abajo |
| `bookScreen` | El recetario abierto, **encima** de otra | La cruz, la mitad izquierda y la derecha | Izquierda y derecha pasan de página; F y Retroceso lo cierran; las demás no hacen nada |
| `levelCompleteScreen` | El ticket, **encima** del juego | Sus botones | N, 0 y M (lo cierran primero); Enter aprieta el primer botón |

- Las tres primeras se reemplazan entre sí: `changeScreen` sale de la actual (`leave`) y entra en la nueva (`show`).
- El libro y el ticket se abren **encima** (`cover`): guardan cuál quedó abajo (`under`), y al cerrarse (`uncover`) se vuelve a ella tal como estaba. La de abajo se entera con `hideUnderOverlay()` / `showAfterOverlay()`.
- Cada pantalla declara sólo las teclas que usa. Por eso, con el libro abierto, S o Espacio no hacen nada.
- Con otra encima, la de abajo queda como está (`hideUnderOverlay()` / `showAfterOverlay()` no hacen nada), salvo las del menú, que se esconden detrás del libro.
- La primera vez que se juega se arman los platitos y el primer nivel (`newGame`); las siguientes, se sigue donde estaba (`resumedGame`).
- **M** vuelve a la portada y pausa la simulación. Con el ticket abierto, también lo cierra.

## Los clics

Una zona clickeable es cualquier objeto que entiende `handlesClick(pos)` ("¿la celda es tuya?") y `onClick(pos)`. La más común es `CellArea(zone, action)`: una `Zone` (en `cellPosition.wlk`; `rectangle.of(x, y, ancho, alto)` arma una desde su esquina de abajo a la izquierda) y lo que hace. Un `CellArea` sin acción sólo se traga los clics de su zona.

Las partes del HUD no son pantallas: cada una devuelve su lista (`clickableAreas()`), y `playingScreen` las junta en una sola, en orden: el globo del cocinero, `actionsMenu`, la columna izquierda (saltear, los botones de abajo y, al final, la columna entera), la derecha (las zonas del panel que se ve y, al final, la columna y el cartel enteros) y el tablero. Un clic que no es de nadie (la pared de la cocina) no hace nada.

> **Rendimiento:** por clic se recorre una lista de unas 30 zonas y se corta en la primera que dice que sí. Los clics son pocos: no hace falta una tabla por celda.

## `drawing/visuals.wlk`: lo común a los menús

Wollok le pide `position()` e `image()` a **cada visual en cada frame**, así que todo lo que se dibuja guarda las dos cosas: la posición es una constante (`CellPosition`, que no crea nada al dibujarse) y la imagen sólo cambia cuando alguien la cambia.

- `Picture(image, position)`: una imagen fija. Sabe mostrarse y sacarse (`show()`, `hide()`). Las subclases cambian la imagen asignándola (`MenuItem`, `TutorialMark`, `BookButton`, `modeBanner`...).
- `Button(image, zone, action)`: un `CellArea` (ver `screenClasses.wlk`) con imagen, dibujada en la esquina de abajo a la izquierda de su zona (`CompassTile`, los botones del ticket).
- `VisualGroup`: lo que dibujó un panel. `add(visual)` lo agrega a la pantalla; `clear()` saca todo (cada cosa sabe sacarse con `hide()`).

## `hud/`: el HUD

- **`hud`** junta las dos columnas: las muestra juntas (`show()`, lo llama `playingScreen`) y junta sus zonas clickeables. También sabe dónde está cada parte (las zonas de la tabla de arriba).
- **`leftPanel`**: la columna izquierda. La info del nivel la dibuja `levelManager` al cargar cada nivel (`levelInfoMenu`); acá están sus clics: el botón de saltear el tutorial (`skipTutorialButton`) y los botones de abajo (`sideButtons`).
- **`rightPanel`**: la columna derecha. Tiene el cartel (`modeBanner`) y el panel que se ve, y recibe lo que avisa `toolsManager`:
  - `modeChanged(modo)`: el cartel y el panel. Cada modo dice qué panel le toca (`panelIn`): COLOCANDO, `placeMenu`; EDITANDO, el que eligió la máquina (`editor`);
  - `directionChanged()`: las imágenes de las máquinas del panel (cambian con W/A/S/D);
  - `chooseMachine(paso)`: teclas Q y E;
  - `moveFocus` / `chooseFocused`: las flechas y Enter mientras se edita.
- **Editar una máquina (doble despacho):** `rightPanel.edit(máquina)` le dice a la máquina "abrite en mí" (`openEditorIn`), y la máquina contesta **qué es**: `editSettings` (horno, freidora, cortadora, dispenser, ensamblador), `editArm` (los brazos) o `nothingToEdit` (la cinta, el platito, una celda vacía). Cada uno de esos tres mensajes hace siempre lo mismo, así que **no hay `if`**: lo decide la clase de la máquina. La máquina no conoce ningún panel.
- Los paneles (`placeMenu`, `editMenu`, `armMenu`, y `noPanel` antes de jugar) entienden los mismos mensajes (`show()`, `hide()` y `clickableAreas()`), así nadie pregunta cuál se está viendo.

## `placeMenu.wlk`

- Se ve mientras el jugador está COLOCANDO (siempre, salvo mientras edita una máquina).
- Muestra 4 máquinas por página, en casilleros de 2x2 celdas de a 2 por fila: el 1 arriba a la izquierda (x 18, y 10), el 2 a su derecha (x 20), y el 3 y el 4 abajo (y 8). Debajo va la ayuda (`menu/place_help.png`, fila 7). El orden sale de `machineManager` (ver [`machines/README.md`](../machines/README.md)).
- Q y E eligen la máquina anterior o la siguiente del catálogo (`chooseNext`), y pasan de página solas. Cada página muestra 4 máquinas; `prev` y `next` avanzan de a una página, sin pasarse de la primera ni de la última.
- Abajo, "HACIA DÓNDE MIRA" (fila 6) y la **brújula** (filas 2 a 5, `compassTiles`): arriba y abajo, botones de 2 celdas de ancho; izquierda y derecha, de 2 de alto; en el centro, la máquina elegida mirando hacia donde va a quedar (`compassMachine`). La dirección elegida va en amarillo. Las imágenes (`menu/compass_*.png`) las genera `assets/menu/makeArmAndCompass.py`.
- `resetPage()`: vuelve a la primera página, y redibuja si el panel se está viendo. Se usa al cambiar el catálogo (`machineManager.changeCatalog`): si el nuevo tiene menos páginas, la página actual podría no existir.
- Al hacer click en un casillero elige esa máquina (`machineManager.select`), mueve el marco amarillo encima y le avisa a `levelManager.machineSelected`: si el tutorial pide otra, el casillero se pone rojo un momento (`flashError`) y el cocinero dice cuál va.
- `MenuItem`: cada máquina dibujada en el panel. Le pide la imagen a la máquina de muestra de su fábrica (`machineManager.sampleOf`, se crea una sola vez; `menuImage(dirección)`: la máquina en chico con su nombre abajo, ver `assets/menu/makePlaceSlots.py`), así cada tipo decide qué mostrar (el brazo, por ejemplo, por ahora siempre muestra la misma).
- `selectionFrame`: el marco amarillo sobre la máquina elegida. Sólo se dibuja si esa máquina está en la página que se ve.
- `highlight(fábricas)`: las máquinas que pide el paso del tutorial; su casillero titila (`menu/slot_hint.gif`). Lo llama `levelManager` con cada aviso al tutorial.

> **RENDIMIENTO:** las imágenes y la posición del marco se calculan sólo cuando cambia algo (dirección, página o máquina elegida), no en cada frame. Lo que más cuesta al dibujar el panel es agregar y sacar sus visuals (unos 60 ms por vez), no las máquinas de muestra.

## `hud/hud.wlk`: el cartel y los botones

- `modeBanner`: muestra `menu/mode_placing.png` (COLOCANDO) o `menu/mode_editing.png` (EDITANDO, con la tecla Retroceso para salir). Lo cambia `rightPanel.modeChanged`. Las imágenes las genera `assets/menu/makeBoardUi.py`.
- `sideButtons`: los botones de abajo a la izquierda, uno por fila de celdas: F RECETARIO (fila 3), M MENÚ (fila 2), ESPACIO INICIAR / PAUSA (fila 1) y 1, 2, 3 (fila 0, una celda cada uno). Cada uno es un `CellArea` con su zona y su acción, la misma que su tecla. **No es un visual**: los botones están dibujados en todos los cuadros del fondo (`background.gif`, los pega `assets/menu/makeBoardUi.py`), así que Wollok no tiene que dibujarlos en cada frame. `speedFrame` (el marco amarillo, un visual aparte) toma su posición de una lista armada una vez, según `simulationEngine.speed()`.

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

Al completar un nivel se oscurece la pantalla y aparece una **comanda**: el nombre del nivel, lo entregado, el título del final ("PEDIDO COMPLETO", o "¡FIN DEL JUEGO!" en el último nivel) y los botones **SIGUIENTE NIVEL** (N), **REPETIR** (0) y **MENÚ** (M) (en el último nivel, **JUGAR DE NUEVO** y **MENÚ**). **Es una sola imagen por nivel** (`levels/complete/<nivel>.png`, con el oscurecido, el papel, el cocinero, los textos y los botones ya dibujados): los niveles son fijos y lo que dice no cambia, así que Wollok dibuja un visual en vez de uno por letra. La imagen la elige el resultado del nivel (`LevelResult.image()`, ver [`levels/README.md`](../levels/README.md#al-ganar-el-resultado-y-el-final)) y los botones el final (`ending.showButtonsIn(ticket)`: `showNextLevelButtons()` o `showPlayAgainButtons()`). Los botones son `CellArea` **sin imagen**, en las celdas donde están dibujados (SIGUIENTE / JUGAR DE NUEVO: x 9 a 12, y 3; REPETIR: x 9 y 10, y 2; MENÚ: x 11 y 12, o 10 y 11 en el último nivel, y 2). Lo dibuja `screenManager.showLevelComplete(resultado)` y lo muestra `levelCompleteScreen`, encima del juego: mientras se ve, los clics van sólo a sus botones, y Enter aprieta el primero (`pressFirstButton()`). Siguiente, repetir y menú primero lo cierran y después hacen lo suyo. `image()` devuelve la imagen que se ve (para los tests). Las imágenes las genera `assets/levels/makeLevelImages.py`: **si cambia un nivel o su objetivo, hay que volver a correrlo**.

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
- Con el teclado: las flechas mueven una marca amarilla (`optionFocus`) que aparece recién al usarlas, como en `armMenu`; Enter aplica la opción marcada.
- Una máquina sin settings no muestra nada.

## `levelInfoMenu.wlk`

Muestra la información del nivel en la zona `levelInfoZone` (x 0 a 4, y 1 a 11), centrada en la parte azul (columna 1.5). **No decide nada**: le avisa `levelManager` (ver [`levels/README.md`](../levels/README.md)).

| Fila (y) | Qué muestra |
|---|---|
| 10 | El nombre del nivel, en mayúsculas y en amarillo, sobre una cinta roja como el título del juego |
| 9 | Una ayuda (`showHint(texto)`): en el modo libre, `L: volver`. En los tutoriales, el botón **T SALTEAR TUTORIAL** (`assets/menu/key_skip.png`), que también se clickea (`skipTutorialButton`, en la columna izquierda: ver `leftPanel`). Se borra al cargar otro nivel |
| 8 | La parte de arriba de una tarjeta de papel (como las hojas del recetario), con `OBJETIVO` en gris (`levels/info/goal_title.png`). No aparece si el nivel no tiene objetivos con texto, como el modo libre |
| 7 a 5 | Uno por objetivo (`level.shownGoals()`), como máximo 3: **una sola imagen por objetivo** con su pedazo de tarjeta (el último, con el borde de abajo), el plato, su texto en marrón (`Papas Fritas: 1/2`) y la barra de progreso (por décimos). Hay una imagen por cada cantidad entregada, de 0 a la pedida: `levels/info/<nivel>_goal<i>_<k>.png` (`goal.progressImage(prefijo)`) |
| 6 a 4 | El contador de energía, debajo del último objetivo (si el nivel tiene límite: `updateEnergy`) |
| 3.5 hacia abajo | Nada: el fondo (`background.gif`) tiene dibujadas las teclas F, M, Espacio y 1 2 3 |

| Método | Lo llama | Qué hace |
|---|---|---|
| `show(nivel)` | `levelManager.load` | Borra todo lo que había y dibuja el nombre, el título y los objetivos |
| `updateProgress(nivel)` | `levelManager`, al entregar algo y al apagar la simulación | Cambia sólo las imágenes de los objetivos (`goalImages()` devuelve las que se ven) |
| `updateEnergy(nivel, total)` | `levelManager`, al cargar y al cambiar las máquinas | Reescribe el contador de energía (`energyMessage()` devuelve lo que dice) |

- **Sólo se redibuja cuando lo llaman**, nunca en cada frame. Un `MenuText` tiene el texto fijo: para cambiarlo, se saca el visual y se agrega uno nuevo.
- Guarda lo dibujado en grupos (`VisualGroup`: la cinta y el título de los objetivos, `backgroundImages()`; el nombre y la ayuda; los objetivos, `goalImages()`; y la energía, `energyMessage()`). El botón de saltear (`SkipButton`, o `noSkipButton` sin tutorial) se muestra y se saca solo para reemplazar sólo lo que cambia.
- **Sobre el papel no se escribe nada en el juego**: el título y los objetivos ya vienen escritos en sus imágenes (`assets/levels/info/`, junto con la cinta; las genera `assets/levels/makeLevelImages.py`, que le pide los niveles a Wollok: **si cambia un objetivo, hay que volver a correrlo**, y un test avisa). Así cada objetivo es un visual, y no uno por letra. El nombre del nivel y los textos sobre el azul son textos de Wollok (`MenuText`). Las imágenes se agregan antes que los textos, porque se dibujan en ese orden.
- **Las posiciones con decimales son `CellPosition`**, no `game.at`: Wollok redondea a la celda la posición de `game.at` al dibujar, y la imagen quedaría corrida.
- Wollok no corta el texto en varias líneas: con 4 celdas de ancho, los textos tienen que ser cortos.
- **Centrado:** Wollok dibuja cada texto centrado en su celda, y la parte azul va de x 0 a 4. Por eso los textos van en la columna 1.5: su centro cae en x = 2.

### `tutorialGuide.wlk`: `chefGuide`

El cocinero que guía los tutoriales, sobre el tablero. Se para al lado de la celda del paso (la del recuadro, o la máquina que se explica) y la señala con la cuchara: arriba de ella si hay lugar, si no abajo; a su izquierda, salvo en las primeras columnas. Al costado tiene un globo con el paso (`PASO 2 DE 12`), el mensaje (como máximo 6 líneas de 16 caracteres: `maxLines()` y `maxLength()`, lo revisa un test) y, debajo, una fila por tecla ("[ENTER] para seguir").

| Método | Lo llama | Qué hace |
|---|---|---|
| `say(speech)` | `levelManager`, con cada aviso al tutorial | Muestra lo que dice el tutorial ahora (`tutorial.speech()`, un `ChefSpeech`: imagen, paso, líneas, teclas y la celda que señala). `message()`, `keys()` y `stepLabel()` devuelven lo que dice. Sin líneas (sin tutorial) no se ve; sin paso (terminó), festeja |
| `complain(lineas)` | `levelManager`, cuando el jugador hizo algo que el paso no deja | Muestra un momento (1.7 s) la queja genérica y vuelve al mensaje del paso. Las líneas se guardan (`complaint()`, para los tests), pero no se dibujan |
| `bubbleContains(celda)` | `chefBubble` | Si la celda toca el globo: un clic ahí, mientras explica, es seguir (como Enter) |

**Cada mensaje es UNA imagen ya dibujada** con el cocinero, el globo, el paso, las líneas y las teclas: `tutorial/steps/<tutorial>_<paso>.png` (`fries_3`, `hotDog_6`, `energy_2`) y `tutorial/steps/<tutorial>_done.png` para el final (el cocinero festeja, sin paso). La queja es siempre la misma imagen: `tutorial/steps/oops_right.png` u `oops_left.png` (cocinero "uy" y globo rojo con "¡UY! Así no: fijate qué te pido.", con el globo del mismo lado que el del mensaje).

**Dónde se dibuja** (`ChefLayout`, con la celda que señala y la cantidad de filas del globo): la celda que señala un paso es la primera de su recuadro o de su flecha; si no marca ninguna (prender la simulación, el final), la del último paso que marcó (`StepTutorial.focusAt`). Con ella salen la pose (cuchara abajo o arriba), el lado al que mira, de qué lado va el globo (no pasa del panel de la derecha) y su alto. La imagen es la caja que ocupan el cocinero y el globo juntos, y se dibuja en su esquina de abajo a la izquierda (`left()`, `bottom()`). La de la queja mide lo mismo de ancho y se dibuja con el cocinero en el mismo lugar.

**Las imágenes se generan** con `assets/tutorial/makeSteps.py`: le pide a Wollok (con un test temporal) la firma de cada mensaje (`chefGuide.signatureOf`: imagen, paso, líneas, teclas, cara, pose, lado y dónde van el cocinero y el globo, en px) y dibuja cada una con eso. Las firmas quedan en `src/menu/overBoard/tutorialImages.wlk` (**generado**): un test de `tutorialTest` avisa si un mensaje no tiene imagen o cambió desde que se dibujó. **Si se cambia un mensaje, un paso o una celda de un tutorial, hay que volver a correrlo.**

> **RENDIMIENTO:** Wollok redibuja cada visual en cada frame: el cocinero es un solo visual (antes eran el cocinero, el globo, el paso letra por letra, el mensaje y las teclas). Si `say` recibe lo mismo que ya está diciendo (lo más común mientras se cocina: cada entrega le avisa al tutorial), no redibuja nada.

### `tutorialGuide.wlk`: `tutorialMarks`

Los indicadores del tutorial sobre el tablero: `show(celdasObjetivo, celdasSeñaladas)` saca los anteriores y dibuja un recuadro (`tutorial/place.gif`) en cada celda objetivo (las que marca el paso: con una máquina de 2x2, sólo la de abajo a la izquierda, donde se hace clic) y una flecha (`tutorial/look.gif`) arriba de la máquina de cada celda señalada (`arrowPosition`: con una de 2x2, arriba de su fila de arriba y centrada entre sus dos columnas). Lo llama `levelManager` con cada aviso al tutorial; si las marcas quedan en los mismos lugares, no hace nada. Si el jugador hace algo que el paso no deja, `flashError()` pone los recuadros en rojo (`tutorial/place_error.gif`) un momento. La roja se genera con `assets/tutorial/makeChef.py`.
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

## Textos sin contorno

Wollok dibuja todos sus textos con un contorno oscuro que no se puede sacar. Lo que va sobre papel (el globo del cocinero, los objetivos, la comanda) está **escrito en imágenes ya generadas** (`assets/tutorial/steps/` y `assets/levels/`), así cada cosa es un solo visual. Para cambiar un texto, se cambia el script que lo genera y se lo vuelve a correr. `MenuText` (`texts.wlk`) queda para los textos de Wollok sobre el azul.
