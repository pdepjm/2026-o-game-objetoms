import board.*
import simulation.simulationEngine.*
import tools.userTools.*

// Lo que el juego le avisa a un tutorial. Lo entienden los tutoriales y también sus pasos
// (StepTutorial le reenvía cada evento a su paso actual). Así como está no hace nada.
class TutorialEvents {
	method onLevelLoaded(level) {}
	method onToolSelected(tool) {}
	method onMachinePlaced(machine) {}
	method onMachineRemoved(machine) {}
	method onMachineRotated(machine) {}
	method onSettingChanged(machine, setting) {}
	method onSimulationToggled(running) {}
	method onDelivered(item) {}
	method onLevelWon(level) {}
	// El jugador apretó Enter para seguir (ver ExplainStep)
	method onContinue() {}
}

// Lo que el juego le avisa al tutorial del nivel, y lo que le pregunta. Se lo manda sólo levelManager.
// Así como está no hace nada y deja hacer todo: los tutoriales sobrescriben lo que necesitan.
class Tutorial inherits TutorialEvents {
	// ----------- PERMISOS -----------
	// ¿Deja usar esta herramienta (place, delete, edit, rotate) en esa celda?
	method allowsTool(tool, pos) = true
	// ¿Deja prender o apagar la simulación?
	method allowsSimulationToggle() = true

	// ----------- MENSAJE -----------
	// Las líneas que muestra levelInfoMenu debajo de la info del nivel
	// (como máximo levelInfoMenu.tutorialMaxLines(), de levelInfoMenu.tutorialMaxLength() caracteres)
	method messageLines() = []

	// Las teclas que acompañan al mensaje (por ejemplo "place": Z COLOCAR). Se dibujan debajo de él, con el
	// estilo de las teclas del fondo (assets/menu/key_<nombre>.png), y se van cuando cambia el mensaje.
	method messageKeys() = []

	// Dónde va el jugador, arriba del mensaje (por ejemplo "PASO 2 DE 8"). Vacío: no se muestra.
	method stepLabel() = ""

	// Todos los mensajes que puede llegar a mostrar, cada uno con sus líneas (lines()) y sus teclas (keys()):
	// los tests revisan que entren en el panel
	method allMessages() = []

	// ----------- INDICADORES -----------
	// Las celdas donde el jugador tiene que hacer algo: se marcan con un recuadro (ver tutorialMarks)
	method targetCells() = []
	// Las celdas de las máquinas que explica el mensaje: se señalan con una flecha arriba
	method pointedCells() = []
}

// El tutorial de los niveles que no tienen tutorial
object noTutorial inherits Tutorial {}

// Un tutorial hecho de pasos, en orden. El paso actual es el primero que todavía no se cumplió.
// La mayoría de los pasos miran cómo está el juego (no qué evento llegó), así no importa en qué
// orden haga las cosas el jugador, y si deshace algo (borra una máquina, apaga la simulación)
// vuelve a ese paso. Los que dependen de algo que no se ve en el tablero ("apretá X") se enteran
// por los eventos, que se le reenvían al paso actual (ver EventStep).
class StepTutorial inherits Tutorial {
	const steps
	// Lo que muestra después de ganar
	const finishedLines
	var won = false

	override method onLevelLoaded(level) {
		won = false
		steps.forEach({ step => step.reset() })
		self.currentStep().onLevelLoaded(level)
	}
	override method onToolSelected(tool) { self.currentStep().onToolSelected(tool) }
	override method onMachinePlaced(machine) { self.currentStep().onMachinePlaced(machine) }
	override method onMachineRemoved(machine) { self.currentStep().onMachineRemoved(machine) }
	override method onMachineRotated(machine) { self.currentStep().onMachineRotated(machine) }
	override method onSettingChanged(machine, setting) { self.currentStep().onSettingChanged(machine, setting) }
	override method onSimulationToggled(running) { self.currentStep().onSimulationToggled(running) }
	override method onDelivered(item) { self.currentStep().onDelivered(item) }
	override method onLevelWon(level) {
		self.currentStep().onLevelWon(level)
		won = true
	}
	override method onContinue() { self.currentStep().onContinue() }

	// Lo normal es que el último paso no se cumpla solo ("esperá a que lleguen las papas"), y se
	// termine al ganar. Si igual se cumplen todos, se queda en el último.
	method currentStep() = steps.findOrDefault({ step => !step.isDone() }, steps.last())

	// Después de ganar deja hacer todo
	override method allowsTool(tool, pos) = won || self.currentStep().allowsTool(tool, pos)
	override method allowsSimulationToggle() = won || self.currentStep().allowsSimulationToggle()

	override method messageLines() = if (won) finishedLines else self.currentStep().lines()
	override method messageKeys() = if (won) [] else self.currentStep().keys()
	override method stepLabel() = if (won) "" else "PASO " + self.stepNumber() + " DE " + steps.size()

	// El número del paso actual, empezando en 1
	method stepNumber() = (1 .. steps.size()).find({ n => steps.get(n - 1) == self.currentStep() })

	override method allMessages() = steps + [new TutorialStep(lines = finishedLines)]

	// Después de ganar no marca nada
	override method targetCells() = if (won) [] else self.currentStep().targetCells()
	override method pointedCells() = if (won) [] else self.currentStep().pointedCells()
}

// Un paso del tutorial: qué dice y qué deja hacer. Éste nunca se cumple: sirve de último paso
// (por ejemplo, "esperá a que lleguen las papas"), que termina cuando se gana.
// Un paso o pide hacer algo (cells: se marcan con el recuadro) o explica una máquina (pointsAt: se
// señala con la flecha), no las dos cosas: si tiene cells, la flecha no se muestra. Para explicar y
// después pedir, dos pasos: un ExplainStep y el que pide.
class TutorialStep inherits TutorialEvents {
	const property lines
	// Las teclas que se explican en este paso (ver Tutorial.messageKeys): así el texto no tiene que decir "Z:"
	const property keys = []
	// Las celdas donde deja colocar, borrar y rotar. Se marcan con un recuadro.
	// Para una máquina de 2x2, sus cuatro celdas.
	const cells = []
	// Las celdas de las máquinas que explica el mensaje. Se señalan con una flecha arriba.
	const pointsAt = []
	const allowsSimulation = false

	method isDone() = false

	// Vuelve a empezar (al cargar o reiniciar el nivel). Lo sobrescriben los pasos que se acuerdan de algo.
	method reset() {}

	// En sus celdas deja hacer todo. Fuera de ellas, sólo editar: también las máquinas fijas, que el
	// jugador tiene que poder configurar (por ejemplo, qué larga un Dispenser)
	method allowsTool(tool, pos) = tool == edit || self.isCell(pos)

	method isCell(pos) = cells.any({ cell => pos.x() == cell.x() && pos.y() == cell.y() })

	method allowsSimulationToggle() = allowsSimulation

	method targetCells() = cells
	// Si pide hacer algo, sólo el recuadro (ver arriba)
	method pointedCells() = if (cells.isEmpty()) pointsAt else []
}

// Se cumple cuando en todas sus celdas hay una máquina que cumple la condición: { machine => ... }
// (si son las cuatro celdas de una máquina de 2x2, la misma máquina en todas)
class MachineStep inherits TutorialStep {
	const condition

	override method isDone() = cells.all({ cell =>
		const machine = board.machineAt(cell)
		return machine != null && condition.apply(machine)
	})
}

// Se cumple mientras la simulación está prendida (si se apaga, vuelve a este paso)
class RunStep inherits TutorialStep(allowsSimulation = true) {
	override method isDone() = simulationEngine.running()
}

// Un paso que se cumple con un evento y se queda cumplido (aunque después el jugador haga otra cosa),
// para lo que no se ve en el tablero. Cada tipo de evento es una subclase que sobrescribe ese evento
// y llama a happened(). Vuelve a empezar al cargar o reiniciar el nivel.
class EventStep inherits TutorialStep {
	var done = false

	method happened() { done = true }

	override method isDone() = done
	override method reset() { done = false }
}

// Explica algo (señalado con pointsAt) y se cumple cuando el jugador aprieta Enter para seguir
class ExplainStep inherits EventStep {
	override method onContinue() { self.happened() }
}

// Se cumple al elegir esa herramienta (Z, X, C o V)
class ToolStep inherits EventStep {
	const tool

	override method onToolSelected(selected) { if (selected == tool) self.happened() }
}
