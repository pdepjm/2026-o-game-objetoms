// Buffet Albert Einstein - las clases de los tutoriales y de sus pasos.
//
// Copyright (C) 2026  grupo objeTOMs (Mateo Bustos, Carlos Aramis Chambi Flores,
// Facundo Ramounat, Federico Scalise Giussani, Mateo Silva)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import board.*
import simulation.simulationEngine.*
import tools.userTools.*
import menu.levelInfoMenu.*

// Lo que el juego le avisa a un tutorial. Lo entienden los tutoriales y también sus pasos
// (StepTutorial le reenvía cada evento a su paso actual). Así como está no hace nada.
class TutorialEvents {
	method onLevelLoaded(level) {}
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
	// ¿Deja usar esta acción (place, delete, edit, rotate) en esa celda?
	method allowsTool(tool, pos) = true
	// ¿Deja prender o apagar la simulación?
	method allowsSimulationToggle() = true
	// ¿Está esperando que el jugador apriete Enter (o toque el globo) para seguir?
	method waitsForContinue() = false

	// ----------- SALTEAR -----------
	// El botón de saltear que dibuja la info del nivel (noSkipButton si no hay tutorial)
	method skipButton(menu) = menu.addSkipButton()
	// Saltearlo da por hechos todos los tutoriales (ver levelManager.skipTutorials)
	method skip(manager) { manager.skipTutorials() }
	// Se da por hecho: se anota como completado ese nivel, si no lo estaba
	method completeIn(completedLevels, level) {
		if (!completedLevels.contains(level)) completedLevels.add(level)
	}

	// ----------- MENSAJE -----------
	// Las líneas que dice el cocinero en su globo (ver chefGuide)
	// (como máximo chefGuide.maxLines() contando las teclas, de chefGuide.maxLength() caracteres)
	method messageLines() = []

	// Las teclas que acompañan al mensaje (por ejemplo "place": [Z] para colocar). El cocinero las dice en
	// su globo, debajo del mensaje, una por fila (assets/tutorial/key_<nombre>.png): cada una ocupa el lugar
	// de una línea.
	method messageKeys() = []

	// Dónde va el jugador, arriba del mensaje (por ejemplo "PASO 2 DE 8"). Vacío: no se muestra.
	method stepLabels() = []

	// Todos los mensajes que puede llegar a mostrar, cada uno con sus líneas (lines()) y sus teclas (keys()):
	// los tests revisan que entren en el panel
	method allMessages() = []

	// ----------- INDICADORES -----------
	// Las celdas donde el jugador tiene que hacer algo: se marcan con un recuadro (ver tutorialMarks)
	method targetCells() = []
	// Las celdas de las máquinas que explica el mensaje: se señalan con una flecha arriba
	method pointedCells() = []

	// ----------- LO QUE DICE EL COCINERO SI ALGO NO VA -----------
	// (ver chefGuide). [] es que no dice nada.
	// Usó esa acción (place, rotate, edit, delete) en esa celda, y el tutorial no lo deja (allowsTool dio false)
	method complaintFor(tool, pos) = []
	// Eligió en el menú de colocar una máquina (su fábrica) que el paso no pide
	method complaintForMachine(factory) = []
	// Las máquinas (fábricas) que pide el paso: el menú de colocar las resalta
	method wantedMachines() = []
}

// El tutorial de los niveles que no tienen tutorial
object noTutorial inherits Tutorial {
	override method skipButton(menu) = noSkipButton
	override method skip(manager) {}
	override method completeIn(completedLevels, level) {}
}

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
	override method waitsForContinue() = !won && self.currentStep().waitsForContinue()

	override method messageLines() = if (won) finishedLines else self.currentStep().lines()
	override method messageKeys() = if (won) [] else self.currentStep().keys()
	override method stepLabels() = if (won) [] else ["PASO " + self.stepNumber() + " DE " + steps.size()]

	// El número del paso actual, empezando en 1
	method stepNumber() = (1 .. steps.size()).find({ n => steps.get(n - 1) == self.currentStep() })

	override method allMessages() = steps + [new TutorialStep(lines = finishedLines)]

	// Después de ganar no marca nada
	override method targetCells() = if (won) [] else self.currentStep().targetCells()
	override method pointedCells() = if (won) [] else self.currentStep().pointedCells()

	// Después de ganar no se queja de nada
	override method complaintFor(tool, pos) = if (won) [] else tool.complaintIn(self.currentStep(), pos)
	override method complaintForMachine(factory) = if (won) [] else self.currentStep().complaintForMachine(factory)
	override method wantedMachines() = if (won) [] else self.currentStep().wantedMachines()
}

// Un paso del tutorial: qué dice y qué deja hacer. Éste nunca se cumple: sirve de último paso
// (por ejemplo, "esperá a que lleguen las papas"), que termina cuando se gana.
// Un paso o pide hacer algo (cells: se marcan con el recuadro) o explica una máquina (pointsAt: se
// señala con la flecha), no las dos cosas: si tiene cells, la flecha no se muestra. Para explicar y
// después pedir, dos pasos: un ExplainStep y el que pide.
class TutorialStep inherits TutorialEvents {
	const property lines
	// Las teclas que se explican en este paso (ver Tutorial.messageKeys): así el texto no tiene que decir "C:"
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
	method allowsTool(tool, pos) = tool.canUseAnywhere() || self.isCell(pos)

	method isCell(pos) = cells.any({ cell => pos.x() == cell.x() && pos.y() == cell.y() })

	method allowsSimulationToggle() = allowsSimulation
	method waitsForContinue() = false

	method targetCells() = cells
	// Si pide hacer algo, sólo el recuadro (ver arriba)
	method pointedCells() = if (cells.isEmpty()) pointsAt else []

	// Lo que dice el cocinero (ver Tutorial). Fuera del recuadro: que es en el recuadro. Si el paso no
	// tiene recuadro, lo que espera (ver waitingComplaint).
	method complaintFor(tool, pos) =
		if (cells.isEmpty()) self.waitingComplaint()
		else if (!self.isCell(pos)) ["Ahí no: es en", "el recuadro."]
		else []
	// Lo que dice si se hace algo en un paso que no pide hacer nada en el tablero
	method waitingComplaint() = []
	method complaintForMachine(factory) = []
	method wantedMachines() = []
}

// Se cumple cuando en todas sus celdas hay una máquina que cumple la condición: { machine => ... }
// (si son las cuatro celdas de una máquina de 2x2, la misma máquina en todas)
class MachineStep inherits TutorialStep {
	// Qué tiene que cumplir la máquina de cada celda (por ejemplo, mirar hacia la derecha)
	const condition = { machine => true }
	// Las máquinas del catálogo (las fábricas de machineManager) que deja construir: así no hace falta
	// preguntarle a la máquina qué es. Vacía: no restringe cuál (por ejemplo, en los pasos de editar o rotar).
	const allowedMachines = []

	override method allowsTool(tool, pos) = super(tool, pos) && tool.allowsMachine(allowedMachines)

	override method isDone() = cells.all({ cell => board.machineAt(cell).satisfies(condition) })

	// En el recuadro, pero con otra máquina elegida: cuál es la que va
	override method complaintFor(tool, pos) =
		if (self.isCell(pos) && !tool.allowsMachine(allowedMachines)) self.wrongMachineComplaint()
		else super(tool, pos)
	override method complaintForMachine(factory) =
		if (allowedMachines.isEmpty() || allowedMachines.contains(factory)) [] else self.wrongMachineComplaint()
	method wrongMachineComplaint() = ["¡Esa no! Buscá", allowedMachines.first().apply().nameWithArticle() + "."]
	override method wantedMachines() = allowedMachines
}

// Se cumple mientras la simulación está prendida (si se apaga, vuelve a este paso)
class RunStep inherits TutorialStep(allowsSimulation = true) {
	override method isDone() = simulationEngine.running()
	override method waitingComplaint() = ["Ahora no: apretá", "Espacio para", "cocinar."]
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
	override method waitsForContinue() = !self.isDone()
	override method waitingComplaint() = ["Primero leé y", "apretá Enter", "para seguir."]
}
