# `machines/`

Las máquinas del juego: qué hacen, cómo se dibujan, qué tipos hay y cuáles aparecen en el menú.

| Archivo | Qué tiene |
|---|---|
| `machineClasses.wlk` | Las clases base de todas las máquinas: `MachineAnimator`, `MachineSprite` y `Machine` |
| `types/` | Las máquinas concretas, **una por archivo** con el nombre de su clase: `belt.wlk`, `dispenser.wlk`, `automaticArm.wlk`, `assembler.wlk`, `oven.wlk`, `cuttingMachine.wlk`, `fryer.wlk` |
| `machineManager.wlk` | El catálogo de máquinas del menú y cuál está elegida para colocar |

> **Quién conoce las máquinas concretas:** sólo `machineManager` (para el catálogo), `stressTest/stressTestBoard.wlk` (arma un tablero de prueba con cintas y un dispenser) y los tests. El resto del juego (tablero, simulación, herramientas, menú) trabaja con cualquier `Machine` sin saber cuál es. Mantenerlo así: si otra parte necesita algo de una máquina, agregarlo como método de `Machine` y que cada tipo lo sobrescriba.

## `machineClasses.wlk`: las clases base

Cada capa se ocupa de una cosa, y cada una hereda de la anterior:

```
MachineAnimator   ← reproducir animaciones frame a frame
      ▲
MachineSprite     ← qué imagen muestra y dónde se dibuja
      ▲
   Machine        ← qué hace: dirección, vecina, items, simulación
      ▲
Belt, Dispenser, AutomaticArm, ...
```

**Regla:** si cambia lo que se ve, va en `MachineSprite` (o `MachineAnimator`); si cambia lo que hace, va en `Machine`.

### `MachineAnimator`
Reproduce una `FrameAnimation` (una carpeta de PNG, ver `simulation/animationEngine.wlk`) un frame por paso de simulación, con el `animationEngine`.
- `play(animación, bloque)`: empieza desde el primer frame; al terminar ejecuta el bloque.
- `stopAnimation()`: la corta sin ejecutar el bloque.
- `animando()` y `avanzar()`: lo que le pide el `animationEngine`.
- Abstracto: `showFrame(path)`, que implementa `MachineSprite`.

> **OJO:** el bloque del final de `play()` corre dentro del tick del `animationEngine`. Ahí no se puede mover un ingrediente ni cortar la animación. Si después de la animación hay que seguir trabajando, usar `playThenWake` (en `Machine`), que despierta a la máquina para que siga en `use()`.

### `MachineSprite`
- Atributos: `position` (dónde se dibuja) e `image` (sin setter: sólo la cambian sus métodos).
- Abstractos: `name()` (la carpeta de sus imágenes) y `direction()`.
- Imágenes: `staticImage()` (`<dir>_game.png`), `runningImage()` (por defecto, la misma quieta), `gifImage()` (`<dir>.gif`) y `menuImage(dirección)` (`<dir>_menu.png`).
- `showStatic()` y `showRunning()`: pasan a la imagen quieta o a la de simulación prendida.
- `actionAnimation(acción, frames)`: arma la animación de la carpeta `<dir>_<acción>/`.
- `offsetX()` y `offsetY()`: corren el dibujo (sólo el brazo, que ocupa 3x3 celdas).

### `Machine`
- **Dirección:** `direction()` y `rotate()`.
- **Ubicación:** `cell()` (la celda que ocupa, descontando el desplazamiento del dibujo) y `nextMachine()` (la máquina hacia la que apunta).
- **Ciclo de la simulación:**
  - `start()`: al prender. Busca a su vecina (`next`) y pasa a `runningImage()`.
  - `use()`: cuando llega el paso que la máquina agendó con `simulationEngine.schedule`.
  - `reset()`: al apagar. Corta la animación y vuelve a la imagen quieta.
- **Items:** `canReceive`, `receive`, `heldItems` (por defecto, no maneja items), `canPush` y `push` (entregar a la de adelante).
- **Espera:** si la de adelante está llena, la máquina se anota (`waitForNext`) y se duerme. **Toda máquina que se libere tiene que llamar a `wakeWaiting()`**, o las que esperan no se despiertan nunca.
- `playThenWake(animación)`: reproduce una animación y, al terminar, despierta a la máquina para que siga en `use()`.

## `types/`: las máquinas

| Máquina | Qué hace hoy | Cómo se anima |
|---|---|---|
| `Belt` | Lleva un item a la máquina a la que apunta | GIF |
| `Dispenser` | Crea un ingrediente cada 1 segundo y se lo entrega a la de adelante | Frame a frame (todavía sin animación) |
| `AutomaticArm` | Agarra el item que le llega de un lado y lo entrega del lado contrario (provisorio). No rota y ocupa 3x3 celdas | Frame a frame (giro y agarre) |
| `Oven` | Todavía sin lógica | GIF |
| `Assembler`, `CuttingMachine`, `Fryer` | Todavía sin lógica | Frame a frame (todavía sin animación) |

Por defecto una máquina es **frame a frame**: con la simulación prendida se ve quieta y se anima cuando hace algo. Las que usan GIF lo declaran con `override method runningImage() = self.gifImage()`. Las imágenes de cada tipo se explican en [`assets/README.md`](../../assets/README.md), y el brazo tiene su propia guía en [`assets/machines/AutomaticArm/README.md`](../../assets/machines/AutomaticArm/README.md).

## `machineManager.wlk`: el catálogo
- `machines`: la lista de máquinas que se pueden colocar. **El orden de la lista es el orden del menú**, de a 4 por página.
- Cada elemento es un bloque que crea una máquina nueva (`{ => new Belt() }`), así cada colocación usa una instancia distinta.
- `select(...)` y `createMachine()`: la máquina elegida en el menú y una instancia nueva de ella para colocar.

## Agregar una máquina nueva
1. Las imágenes en `assets/machines/<Nombre>/` (ver [`assets/README.md`](../../assets/README.md)).
2. La clase en su propio archivo, `types/<nombre>.wlk` (el nombre de la clase empezando en minúscula), heredando de `Machine`, con `override method name() = "<Nombre>"` (el mismo nombre que la carpeta de imágenes). Importar sólo lo que use: como mínimo `machines.machineClasses.*`.
3. Si usa GIF: `override method runningImage() = self.gifImage()`.
4. Su lógica: sobrescribir `start`, `use`, `reset` y los métodos de items que necesite.
5. Importar su archivo en `machineManager.wlk` (`import machines.types.<nombre>.*`) y agregarla a la lista.
