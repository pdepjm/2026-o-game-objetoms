// Tipos de máquinas

import machines.machine.*
import simulation.simulationEngine.*
import simulation.animationEngine.*
import simulation.ingredientes.*
import wollok.game.*
import directions.*
import board.*


// Cinta: lleva de a un item hacia la máquina a la que apunta
class Belt inherits Maquina{
  // el item que tiene encima (null si está vacía)
  var item = null

  override method name() = "Belt"

  // Sólo acepta un item si está vacía
  override method canReceive() = item == null

  // Toma el item, lo anima hacia su celda y pide que la despierten cuando termine de llegar
  override method receive(anItem) {
	item = anItem
	// viene siempre de una celda vecina: ya se sabe cuántos pasos lleva (ver moveInSteps)
	anItem.moveInSteps(position, animationEngine.pasosPorCelda())
	simulationEngine.schedule(animationEngine.pasosPorCelda(), self)
  }

  override method heldItems() = if (item == null) [] else [item]

  override method reset() {
	super()
	item = null
  }

  // Cuando el item terminó de llegar, lo pasa a la siguiente máquina y despierta
  // a las que esperaban para entregarle algo.
  // Si no puede entregarlo, espera a la de adelante (ver waitForNext).
  override method use() {
	if (item != null) {
		if (item.moviendose()) {
			simulationEngine.schedule(1, self)
		} else if (self.canPush()) {
			const outgoing = item
			item = null
			self.push(outgoing)
			self.wakeWaiting()
		} else {
			self.waitForNext()
		}
	}
  }

}

class Oven inherits Maquina{
  override method name() = "Oven"
}

class Fryer inherits Maquina{
  override method name() = "Fryer"

}

class CuttingMachine inherits Maquina{
  override method name() = "CuttingMachine"
}

class Assembler inherits Maquina{
  override method name() = "Assembler"
}

class Dispenser inherits Maquina{
  // Dispensa un item cada un determinado tiempo
  override method name() = "Dispenser"

  var item = { => new Carne() } // item a dispensar, instanciador de clase.

  // tiempo de simulación entre un dispense y el siguiente
  method intervalMs() = 1000

  // el mismo intervalo, medido en pasos de simulación
  method intervalSteps() = simulationEngine.stepsFor(self.intervalMs())

  // Busca a su vecina (super) y agenda el primer dispense
  override method start() {
	super()
	simulationEngine.schedule(self.intervalSteps(), self)
  }

  // Se cumplió el intervalo: dispensa y agenda el próximo.
  // Si no puede entregar, espera a la de adelante (ver waitForNext).
  override method use(){
	if (self.canPush()) {
		self.dispense()
		simulationEngine.schedule(self.intervalSteps(), self)
	} else {
		self.waitForNext()
	}
  }

  // Crea un item nuevo sobre el dispenser y se lo entrega a la máquina de adelante
  method dispense(){
	const newItem = item.apply()
	newItem.position(self.position())
	simulationEngine.addItem(newItem)
	self.push(newItem)
  }
}

// Brazo automático: agarra el item que le llega de un lado y lo deja del lado contrario.
// No rota: siempre se coloca mirando hacia abajo, y gira solo según de dónde le llegue el item.
// Se anima con FrameAnimated (PNG por frame) y no con GIFs: ver animationEngine.wlk.
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
class AutomaticArm inherits FrameAnimated and Maquina {
  // Frames que hay en cada carpeta de animación (los genera assets/machines/gifToFrames.py)
  const rotateFrames = 7
  const catchFrames = 28

  var item = null       // el item que está moviendo (null si está libre)
  var from = null       // lado del que vino el item
  var grabbed = false   // ¿ya lo llevó al lado contrario?
  var facing = down     // hacia dónde está mirando ahora (no cambia direction: el brazo no rota)

  override method name() = "AutomaticArm"
  override method offsetX() = -1
  override method offsetY() = -1

  // Siempre se coloca mirando hacia abajo, sin importar la dirección elegida
  override method initialize() {
    direction = down
    super()
  }

  // No rota, ni con la herramienta de rotar ni en el menú
  override method rotate() {}
  override method menuImage(aDirection) = super(down)

  // Quieto, mirando hacia donde quedó
  override method staticImage() = "machines/"+self.name()+"/"+facing.name() + "_game.png"

  // Al prender la simulación sigue quieto: sólo se anima cuando le llega un item
  override method runningImage() = self.staticImage()

  // Una animación del brazo, por ejemplo armAnimation(down, up, "rotate", rotateFrames)
  method armAnimation(fromSide, toSide, kind, frameCount) =
    new FrameAnimation(path = "machines/"+self.name()+"/"+fromSide.name()+"_to_"+toSide.name()+"_"+kind, frameCount = frameCount)

  override method canReceive() = item == null

  override method heldItems() = if (item == null) [] else [item]

  override method receive(anItem) {
    item = anItem
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

  // Lo despierta el engine al terminar cada animación, o cuando se libera la máquina de entrega
  override method use() {
    self.continueWork()
  }

  // Hace lo que falta con el item que tiene: girar hacia él, llevarlo, o entregarlo
  method continueWork() {
    if (item != null) {
      if (grabbed) self.deliver()
      else if (facing == from) self.carry()
      else self.turnToItem()
    }
  }

  // Gira hacia el lado del que vino el item
  method turnToItem() {
    self.play(self.armAnimation(facing, from, "rotate", rotateFrames), {
      facing = from
      simulationEngine.schedule(1, self)
    })
  }

  // Lo agarra y gira hacia el lado contrario. El item viaja a la otra celda mientras tanto.
  method carry() {
    const to = from.invert()
    item.moveInSteps(to.move(self.cell()), catchFrames)
    self.play(self.armAnimation(from, to, "catch", catchFrames), {
      facing = to
      grabbed = true
      self.image(self.staticImage())
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
        const outgoing = item
        item = null
        from = null
        grabbed = false
        target.receive(outgoing)
        self.wakeWaiting()
      } else {
        target.addWaiting(self)
      }
    }
  }

  // Al apagar la simulación corta la animación y vuelve a quedar quieto mirando hacia abajo
  override method reset() {
    self.stopAnimation()
    item = null
    from = null
    grabbed = false
    facing = down
    super()
  }
}
