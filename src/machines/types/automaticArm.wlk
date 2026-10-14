import machines.machineClasses.*
import simulation.simulationEngine.*
import simulation.animationEngine.*
import directions.*
import board.*

// Brazo automático: agarra el item que le llega de un lado y lo deja del lado contrario.
// No rota: siempre se coloca mirando hacia abajo, y gira solo según de dónde le llegue el item.
// Se anima frame a frame (PNG por frame, con play de MachineAnimator) y no con GIFs.
//
// Cuando le llega un item desde el lado S:
// 1. Si no está mirando hacia S, gira hacia ahí (animación rotate).
// 2. Lo agarra y gira hacia el lado contrario (animación catch), llevando el item.
// 3. Lo entrega a la máquina de esa celda. Si está llena, espera a que lo despierte.
// Mientras tiene un item no acepta otro.
//
// MOMENTÁNEO: entregar del lado contrario es para probar el brazo hasta que tenga su lógica.
//
// OJO: las animaciones terminan dentro del tick del animationEngine, y ahí no se puede
// mover un item (se agregaría a la lista que se está recorriendo). Por eso al terminar
// cada animación el brazo sólo se agenda, y el paso siguiente lo hace en use().
// No usa playThenWake porque además tiene que actualizar facing y grabbed justo al terminar.
class AutomaticArm inherits Machine {
  // ----------- ATRIBUTOS -----------
  // Frames que hay en cada carpeta de animación (los genera assets/machines/gifToFrames.py)
  const rotateFrames = 7
  const catchFrames = 28

  var from = null       // lado del que vino el item
  var grabbed = false   // ¿ya lo llevó al lado contrario?
  var facing = down     // hacia dónde está mirando ahora (no cambia direction: el brazo no rota)

  // ----------- INICIALIZACION -----------
  // Siempre se coloca mirando hacia abajo, sin importar la dirección elegida
  override method initialize() {
    direction = down
    super()
  }

  // ----------- IDENTIDAD -----------
  override method name() = "AutomaticArm"

  // ----------- NO ROTA -----------
  // Ni con la herramienta de rotar ni en el menú
  override method rotate() {}
  override method menuImage(aDirection) = super(down)

  // ----------- DIBUJO -----------
  // Se dibuja sobre 3x3 celdas, centrado en la suya
  override method offsetX() = -1
  override method offsetY() = -1

  // Una animación del brazo, por ejemplo armAnimation(down, up, "rotate", rotateFrames)
  method armAnimation(fromSide, toSide, kind, frameCount) =
    new FrameAnimation(path = "machines/"+self.name()+"/"+fromSide.name()+"_to_"+toSide.name()+"_"+kind, frameCount = frameCount)

  // Gira de un lado a otro
  method showTurn(fromSide, toSide, afterBlock) {
    self.play(self.armAnimation(fromSide, toSide, "rotate", rotateFrames), afterBlock)
  }

  // Agarra del primer lado y gira hasta el otro
  method showCatch(fromSide, toSide, afterBlock) {
    self.play(self.armAnimation(fromSide, toSide, "catch", catchFrames), afterBlock)
  }

  // ----------- ITEMS -----------
  override method receive(anItem) {
    super(anItem)
    from = self.sideOf(anItem.destinoFinal())
    grabbed = false
    self.continueWork()
  }

  // Lado del brazo en el que está esa posición (una celda vecina)
  method sideOf(aPosition) {
    const cell = self.cell()
    return if (aPosition.x() > cell.x()) right
      else if (aPosition.x() < cell.x()) left
      else if (aPosition.y() > cell.y()) up
      else down
  }

  // ----------- TRABAJO -----------
  // Lo despierta el engine al terminar cada animación, o cuando se libera la máquina de entrega
  override method use() {
    self.continueWork()
  }

  // Hace lo que falta con el item que tiene: girar hacia él, llevarlo, o entregarlo
  method continueWork() {
    if (heldItem != null) {
      if (grabbed) self.deliver()
      else if (facing == from) self.carry()
      else self.turnToItem()
    }
  }

  // Gira hacia el lado del que vino el item
  method turnToItem() {
    self.showTurn(facing, from, {
      facing = from
      simulationEngine.schedule(1, self)
    })
  }

  // Lo agarra y gira hacia el lado contrario. El item viaja a la otra celda mientras tanto.
  method carry() {
    const to = from.invert()
    heldItem.moveInSteps(to.move(self.cell()), catchFrames)
    self.showCatch(from, to, {
      facing = to
      grabbed = true
      self.showStatic()
      simulationEngine.schedule(1, self)
    })
  }

  // Se lo entrega a la máquina de la celda contraria. Se busca acá y no al prender
  // la simulación (como next) porque depende de por dónde llegó el item.
  // Si está llena, espera a que lo despierte; si no hay máquina, se queda con el item.
  method deliver() {
    const target = board.machineAt(facing.move(self.cell()))
    if (target != null) {
      if (target.canReceive()) {
        const outgoing = heldItem
        heldItem = null
        from = null
        grabbed = false
        target.receive(outgoing)
        self.wakeWaiting()
      } else {
        target.addWaiting(self)
      }
    }
  }

  // ----------- SIMULACION -----------
  // Al apagar la simulación suelta el item y vuelve a quedar quieto mirando hacia abajo.
  // El estado se reinicia antes del super(), que corta la animación y muestra staticImage().
  override method reset() {
    heldItem = null
    from = null
    grabbed = false
    facing = down
    super()
  }
}
