# AutomaticArm

Guía para modificar las imágenes del brazo automático. Es una máquina **frame a frame** (ver [`assets/README.md`](../../README.md)), pero es un **caso especial**: no sigue la convención `<direccion>_<accion>/` del resto.

Lo que tiene de distinto:

- Ocupa **3x3 celdas**: sus imágenes del tablero son de **150x150**.
- **No rota**: ni con la herramienta de rotar ni con W/A/S/D en el menú. Siempre se coloca mirando hacia abajo (`down`).
- **Sus animaciones van de una dirección a otra**: las carpetas se llaman `<desde>_to_<hasta>_<accion>/`, en vez de `<direccion>_<accion>/`.
- **Al prender la simulación sigue quieto**: sólo se anima cuando le llega un ingrediente.

## Cómo funciona en el juego

1. Se coloca mirando hacia abajo (`down_game.png`), sin importar la dirección elegida.
2. Cuando una máquina vecina (por ejemplo, una cinta que apunta hacia el brazo) le entrega un ingrediente. **La entrada es fija: siempre es el lado izquierdo (`left`)**, venga de donde venga el ingrediente:
   1. Si no está mirando hacia la izquierda, **gira hacia ese lado**: animación `<hacia donde mira>_to_left_rotate`.
   2. **Lo agarra y gira hacia el lado de salida `T`**: animación `left_to_<T>_catch`. El ingrediente viaja con la pinza hasta la celda de ese lado.
   3. **Lo entrega a la máquina de la celda de `T`** y queda quieto mirando hacia ahí (`<T>_game.png`).

   `T` se configura con la herramienta edit, **relativo al recorrido del ingrediente** (entra por la izquierda y viaja hacia la derecha): *Recto* → `right`, *Izquierda* → `up`, *Derecha* → `down`. Es el setting `OutputSideSetting` (ver [`machines/README.md`](../../../src/machines/README.md#configuración-settings)).
3. Mientras tiene un ingrediente no acepta otro. Si la máquina de la celda contraria está llena, espera a que se libere; si no hay ninguna máquina, se queda con el ingrediente.
4. Al apagar la simulación suelta lo que tenía y vuelve a mirar hacia abajo.

Por ejemplo, con la salida en *Recto*, una cinta a la izquierda y otra a la derecha:

```
 [Belt →] [ Brazo ] [Belt →]
```

`down_to_left_rotate` → `left_to_right_catch` → `right_game.png`, y el ingrediente sigue por la cinta de la derecha. El siguiente ingrediente arranca desde esa pose: `right_to_left_rotate` → `left_to_right_catch`.

> [!NOTE]
> Configurar hacia dónde entrega no se pierde al apagar la simulación: es configuración, no estado (`reset()` sólo vuelve a mirar hacia abajo).

### Las celdas alrededor del brazo

El brazo se dibuja sobre 3x3 celdas, pero en el tablero **ocupa sólo la del centro** (la celda donde se hizo click). Por eso:

- Las máquinas que le entregan y reciben ingredientes van en las celdas vecinas, aunque queden debajo de su dibujo.
- En el código, `position` es la esquina del dibujo (corrida con `drawOffsetX()` y `drawOffsetX()`, que valen `-1`), y `cell()` es la celda del centro. Para cualquier cálculo sobre el tablero se usa `cell()`.

Si se cambia el tamaño de las imágenes, hay que cambiar también `drawOffsetX()` y `drawOffsetX()`.

## Qué hay en la carpeta

| Archivo | Tamaño | Para qué se usa |
|---|---|---|
| `<dir>_game.png` | 150x150 | El brazo quieto mirando hacia `<dir>`. Se usan los 4: es la pose en la que queda después de entregar |
| `down_menu.png` | 100x100 | El brazo en el menú de máquinas (siempre éste, porque no rota) |
| `left_menu.png`, `right_menu.png`, `up_menu.png` | — | **No se usan** (el brazo no rota). Se pueden borrar |
| `<desde>_to_<hasta>_rotate/` | 150x150 cada PNG | Girar de `<desde>` a `<hasta>`: **7 frames** (`0.png` a `6.png`) |
| `<desde>_to_<hasta>_catch/` | 150x150 cada PNG | Agarrar y girar de `<desde>` a `<hasta>`: **28 frames** (`0.png` a `27.png`) |

`<dir>`, `<desde>` y `<hasta>` son siempre `up`, `down`, `left` o `right`.

### Qué animaciones se usan hoy

- **`_rotate`: las 12.** El brazo puede estar mirando hacia cualquier lado cuando le llega un ingrediente desde cualquier otro.
- **`_catch`: sólo las 3 que salen de `left`** (`left_to_right`, `left_to_up`, `left_to_down`), porque la entrada es fija. Las demás quedan listas para cuando el brazo tenga otras entradas.

### Para que no se vean saltos

Una animación empieza donde terminó la anterior, así que tienen que coincidir:

- el **primer frame** de `<X>_to_<S>_rotate` con `<X>_game.png`;
- el **último frame** de `<X>_to_<S>_rotate` con el **primer frame** de `<S>_to_<T>_catch`;
- el **último frame** de `<S>_to_<T>_catch` con `<T>_game.png`.

## Por qué frames y no GIFs

Wollok carga cada GIF una sola vez y todos los brazos que lo muestran comparten la misma animación: la segunda vez no arranca desde el principio (aparece a la mitad, o congelada en el último frame). Con un PNG por frame, cada brazo lleva su propio frame. Ver `MachineAnimator` en `src/machines/machineClasses.wlk`.

El juego muestra **un frame por paso de simulación** (100 ms a x1), así que respeta la pausa y la velocidad x2/x3.

## Modificar una animación

Los GIFs originales ya no están en el repo: **las carpetas de frames son la fuente**. Hay dos formas de cambiar una animación:

- **Editando los PNG de la carpeta** directamente (respetando la cantidad y la numeración: `0.png`, `1.png`, ...).
- **Desde un GIF nuevo**, con `gifToFrames.py`. Parado en `assets/`:
  ```bash
  python3 machines/gifToFrames.py machines/AutomaticArm/down_to_up_catch.gif --solo
  ```
  Genera (o reemplaza) la carpeta con el mismo nombre del GIF, remuestreada a 100 ms por frame para que dure lo mismo que el GIF. Usar `--solo`: sin él, el script busca las otras direcciones cambiando sólo la última del nombre (`down_to_right_catch`, `down_to_down_catch`...), que no es como se nombran las del brazo. Después **borrar el GIF de la carpeta**: el juego no lo usa, pero lo cargaría igual al arrancar.

Si cambia la cantidad de frames:

1. **Todas las direcciones de un mismo tipo tienen que tener la misma cantidad** (el código usa un solo número para todos los `_rotate` y otro para todos los `_catch`).
2. Actualizar `rotateFrames` / `catchFrames` en la clase `AutomaticArm` (`src/machines/types/automaticArm.wlk`) y las mismas constantes en `test/animationTest.wtest`.
3. Correr los tests:
   ```bash
   wollok test --skipValidations -p ./
   ```

### Hacer las otras direcciones

Las imágenes de cada dirección son la misma imagen girada. Girando 90° en sentido horario, las direcciones pasan así: `down → left → up → right → down`. Al girar una animación se giran **las dos** direcciones del nombre:

| Original | 90° horario | 180° | 270° horario |
|---|---|---|---|
| `down_to_up` | `left_to_right` | `up_to_down` | `right_to_left` |
| `down_to_left` | `left_to_up` | `up_to_right` | `right_to_down` |
| `down_to_right` | `left_to_down` | `up_to_left` | `right_to_up` |

> [!WARNING]
> `machines/assetRotate.py` sirve para los `<dir>_game.png`, pero **no** para las animaciones `_to_`: sólo cambia la última dirección del nombre, así que generaría archivos con el nombre equivocado.

## Agregar una animación nueva

Por ejemplo, una animación `drop` para soltar el ingrediente:

1. Crear las carpetas `<desde>_to_<hasta>_drop/` (150x150), todas con la misma cantidad de frames.
2. En la clase `AutomaticArm`, agregar la cantidad de frames (`const dropFrames = ...`) y, en el grupo de dibujo, un método que la reproduzca, como `showTurn` y `showCatch`:
   ```wollok
   method showDrop(fromSide, toSide, afterBlock) {
     self.play(self.armAnimation(fromSide, toSide, "drop", dropFrames), afterBlock)
   }
   ```
   La lógica del brazo (grupo de trabajo) llama a `showDrop(...)`, y el bloque se ejecuta cuando termina la animación.

> [!WARNING]
> El bloque del final se ejecuta mientras el `animationEngine` avanza las animaciones: ahí **no se puede mover un ingrediente** (`move`/`moveInSteps`). Si hace falta, el brazo se agenda con `simulationEngine.schedule(1, self)` y lo hace en `use()`, como hacen `turnToItem` y `carry`.

## Cosas a tener en cuenta

- **Nombres exactos:** el código arma las rutas con el nombre (`"machines/AutomaticArm/" + desde + "_to_" + hasta + "_" + tipo + "/" + frame + ".png"`). Si un nombre no coincide, el juego no encuentra la imagen.
- **Animaciones cortas:** cada frame es una imagen más que el juego carga al arrancar. Hoy son 420 frames (24 carpetas).
- **Velocidad:** cada ingrediente tarda unos 3,5 s en pasar por el brazo (0,7 s de giro y 2,8 s de catch), contra 0,5 s de una cinta. Las máquinas que lo alimentan van a juntar ingredientes en cola.
