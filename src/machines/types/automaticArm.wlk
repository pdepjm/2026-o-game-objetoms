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
// 3. Lo entrega a la máquina de esa celda (tryPush). Si está llena, espera a que se libere.
// Mientras tiene un item no acepta otro.
//
// MOMENTÁNEO: entregar del lado contrario es para probar el brazo hasta que tenga su lógica.
//
// El item no viaja a la celda del brazo (por eso sobrescribe onReceive): el brazo lo
// gira y lo lleva al lado opuesto. Cada animación termina en la etapa segura del
// animationEngine (bloques pendientes), así el bloque puede girar, mover el item y
// entregar directo, sin perder pasos.
class AutomaticArm inherits Machine {
	// ----------- ATRIBUTOS -----------
	// Frames que hay en cada carpeta de animación (los genera assets/machines/gifToFrames.py)
	const rotateFrames = 7
	const catchFrames = 28

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

	// ----------- DIBUJO -----------
	// Se dibuja sobre 3x3 celdas, centrado en la suya
	override method offsetX() = -1

	override method offsetY() = -1

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
		from = self.sideOf(item.destinoFinal())
		grabbed = false
		if (direction == from) self.carry() else self.turnToItem()
	}

	// Lado del brazo en el que está esa posición (una celda vecina)
	method sideOf(aPosition) {
		const cell = self.cell()
		return if (aPosition.x() > cell.x()) right
			else if (aPosition.x() < cell.x()) left
			else if (aPosition.y() > cell.y()) up
			else down
	}

	// Gira hacia el lado del que vino el item
	method turnToItem() {
		self.showTurn(direction, from, {
			direction = from
			self.carry()
		})
	}

	// Lo agarra y gira hacia el lado contrario. El item viaja a la otra celda mientras tanto.
	method carry() {
		const to = from.invert()
		self.itemToPush().moveInSteps(to.move(self.cell()), catchFrames)
		self.showCatch(from, to, {
			direction = to
			grabbed = true
			self.showStatic()
			self.tryPush()
		})
	}

	// Entrega hacia el lado al que está mirando (que después del catch es el contrario
	// al del que vino el item). Se busca acá y no al prender la simulación (como next)
	// porque depende de por dónde llegó el item.
	override method outputTarget() = board.machineAt(direction.move(self.cell()))

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
