import machines.machineClasses.*
import machines.settings.*
import simulation.simulationEngine.*
import simulation.animationEngine.*
import directions.*
import board.*

// Brazo automático: agarra el item que le llega por la izquierda (la entrada es fija) y lo
// entrega recto, a la izquierda o a la derecha de su recorrido, según cómo se configure.
// No rota: siempre se coloca mirando hacia abajo, y gira solo para agarrar y entregar.
// Se anima frame a frame (PNG por frame, con play de MachineAnimator) y no con GIFs.
//
// Cuando le llega un item:
// 1. Si no está mirando hacia la entrada, gira hacia ahí (animación rotate).
// 2. Lo agarra y gira hacia el lado de salida (animación catch), llevando el item.
// 3. Lo entrega a la máquina de esa celda (tryPush). Si está llena, espera a que se libere.
// Mientras tiene un item no acepta otro.
//
// El item no viaja a la celda del brazo (por eso sobrescribe onReceive): el brazo lo
// gira y lo lleva a la celda de salida. Cada animación termina en la etapa segura del
// animationEngine (bloques pendientes), así el bloque puede girar, mover el item y
// entregar directo, sin perder pasos.
class AutomaticArm inherits Machine {
	// ----------- ATRIBUTOS -----------
	// Frames que hay en cada carpeta de animación (los genera assets/machines/gifToFrames.py)
	const rotateFrames = 7
	const catchFrames = 28

	// Siempre recibe por la izquierda; hacia dónde entrega se configura (recto, izquierda o derecha)
	const inputSide = left
	const outputSetting = new OutputSideSetting(value = straightOut)

	var from = null       // lado del que vino el item
	var grabbed = false   // ¿ya lo llevó al lado contrario?

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

	override method settings() = [outputSetting]

	// ----------- DIBUJO -----------
	// Se dibuja sobre 3x3 celdas, centrado en la suya
	override method drawOffsetX() = -1

	override method drawOffsetY() = -1

	// Una animación del brazo, por ejemplo armAnimation(down, up, "rotate", rotateFrames)
	method armAnimation(fromSide, toSide, kind, frameCount) = new FrameAnimation(
		path = "machines/" + self.name() + "/" + fromSide.name() + "_to_" + toSide.name() + "_" + kind,
		frameCount = frameCount
	)

	// Gira de un lado a otro
	method showTurn(fromSide, toSide, afterBlock) {
		self.play(self.armAnimation(fromSide, toSide, "rotate", rotateFrames), afterBlock)
	}

	// Agarra del primer lado y gira hasta el otro
	method showCatch(fromSide, toSide, afterBlock) {
		self.play(self.armAnimation(fromSide, toSide, "catch", catchFrames), afterBlock)
	}

	// ----------- ITEMS -----------
	// El item no se anima hasta la celda del brazo: el brazo gira hacia él y lo lleva
	// al lado opuesto. Por eso se sobrescribe onReceive (y no receive).
	override method onReceive(item) {
		from = inputSide
		grabbed = false
		if (direction == from) self.carry() else self.turnToItem()
	}

	// Lado por el que entrega, según lo configurado (relativo al lado de entrada)
	method outputSide() = outputSetting.value().sideFor(inputSide)

	// Gira hacia el lado del que vino el item
	method turnToItem() {
		self.showTurn(direction, from, {
			direction = from
			self.carry()
		})
	}

	// Lo agarra y gira hacia el lado contrario. El item viaja a la otra celda mientras tanto.
	method carry() {
		const to = self.outputSide()
		self.itemToPush().moveInSteps(to.move(self.cell()), catchFrames)
		self.showCatch(from, to, {
			direction = to
			// Entrega hacia el lado al que quedó mirando (el contrario al del que vino el item).
			// next se calculó al prender, mirando hacia otro lado: se vuelve a buscar.
			next = self.nextMachine()
			grabbed = true
			self.showStatic()
			self.tryPush()
		})
	}

	// Se entera de que entregó: queda libre para el próximo item
	override method onPushed(item) {
		from = null
		grabbed = false
	}

	// ----------- SIMULACION -----------
	// Al apagar la simulación suelta el item y vuelve a quedar quieto mirando hacia abajo.
	// El estado se reinicia antes del super(), que vacía el inventario y muestra staticImage().
	override method reset() {
		from = null
		grabbed = false
		direction = down
		super()
	}
}
