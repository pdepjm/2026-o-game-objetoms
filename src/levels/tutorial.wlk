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
import cellPosition.*
import simulation.simulationEngine.*
import tools.userTools.*
import menu.hud.levelInfoMenu.*

// Lo que el juego le avisa a un tutorial.
class TutorialEvents {
	method onLevelLoaded(level) {}
	method onMachinePlaced(machine) {}
	method onMachineRemoved(machine) {}
	method onMachineRotated(machine) {}
	method onSettingChanged(machine, setting) {}
	method onSimulationToggled(running) {}
	method onDelivered(item) {}
	method onLevelWon(level) {}
	// El jugador apretó Enter para seguir
	method onContinue() {}
}

// Lo que el juego le avisa al tutorial del nivel, y lo que le pregunta.
class Tutorial inherits TutorialEvents {
	// ----------- PERMISOS -----------
	method allowsTool(tool, pos) = true
	// ¿Deja prender o apagar la simulación?
	method allowsSimulationToggle() = true
	// ¿Está esperando que el jugador apriete Enter (o toque el globo) para seguir?
	method waitsForContinue() = false

	// ----------- SALTEAR -----------
	method skipButton(menu) = menu.newSkipButton()
	// Saltearlo da por hechos todos los tutoriales
	method skip(manager) { manager.skipTutorials() }
	// Se da por hecho: se anota como completado ese nivel, si no lo estaba
	method completeIn(completedLevels, level) {
		if (!completedLevels.contains(level)) completedLevels.add(level)
	}

	// ----------- MENSAJE -----------
	// Lo que dice ahora el cocinero (un ChefSpeech)
	method speech() = noSpeech

	// Todo lo que puede llegar a decir el cocinero (para los tests y para generar sus imágenes)
	method allMessages() = []

	// ----------- INDICADORES -----------
	method targetCells() = []
	// Las celdas de las máquinas que explica el mensaje: se señalan con una flecha arriba
	method pointedCells() = []

	// ----------- LO QUE DICE EL COCINERO SI ALGO NO VA -----------
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

// Un tutorial hecho de pasos, en orden.
class StepTutorial inherits Tutorial {
	// Para los nombres de sus imágenes (assets/tutorial/steps/<name>_<paso>.png)
	const name
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

	// Lo normal es que el último paso no se cumpla solo ("esperá a que lleguen las papas")
	method currentStep() = steps.findOrDefault({ step => !step.isDone() }, steps.last())

	// Después de ganar deja hacer todo
	override method allowsTool(tool, pos) = won || self.currentStep().allowsTool(tool, pos)
	override method allowsSimulationToggle() = won || self.currentStep().allowsSimulationToggle()
	override method waitsForContinue() = !won && self.currentStep().waitsForContinue()

	override method speech() = if (won) self.finishedSpeech() else self.stepSpeech(self.stepNumber())

	// El número del paso actual, empezando en 1
	method stepNumber() {
		const current = self.currentStep()
		return (1 .. steps.size()).find({ n => steps.get(n - 1) == current })
	}

	method stepSpeech(n) = new ChefSpeech(
		image = name + "_" + n,
		label = "PASO " + n + " DE " + steps.size(),
		lines = steps.get(n - 1).lines(),
		keys = steps.get(n - 1).keys(),
		focus = self.focusAt(n)
	)

	// Al ganar festeja, sin paso ni teclas, donde estaba
	method finishedSpeech() = new ChefSpeech(image = name + "_done", lines = finishedLines, focus = self.focusAt(steps.size()))

	// La celda que señala el cocinero en el paso n: la del paso o, si no marca ninguna, la del último que marcó
	method focusAt(n) {
		const pointing = steps.take(n).filter({ step => !step.focusCells().isEmpty() })
		return if (pointing.isEmpty()) noSpeech.focus() else pointing.last().focusCells().first()
	}

	override method allMessages() = (1 .. steps.size()).map({ n => self.stepSpeech(n) }) + [self.finishedSpeech()]

	// Después de ganar no marca nada
	override method targetCells() = if (won) [] else self.currentStep().targetCells()
	override method pointedCells() = if (won) [] else self.currentStep().pointedCells()

	// Después de ganar no se queja de nada
	override method complaintFor(tool, pos) = if (won) [] else tool.complaintIn(self.currentStep(), pos)
	override method complaintForMachine(factory) = if (won) [] else self.currentStep().complaintForMachine(factory)
	override method wantedMachines() = if (won) [] else self.currentStep().wantedMachines()
}

// Un paso del tutorial: qué dice y qué deja hacer.
class TutorialStep inherits TutorialEvents {
	const property lines
	// Las teclas que se explican en este paso
	const property keys = []
	// Las celdas donde deja colocar, borrar y rotar.
	const cells = []
	// Las que se marcan con el recuadro (en una máquina de 2x2, sólo la de abajo a la izquierda).
	const marked = cells
	// Las celdas de las máquinas que explica el mensaje.
	const pointsAt = []
	const allowsSimulation = false

	method isDone() = false

	// Vuelve a empezar (al cargar o reiniciar el nivel).
	method reset() {}

	// En sus celdas deja hacer todo.
	method allowsTool(tool, pos) = tool.canUseAnywhere() || self.isCell(pos)

	method isCell(pos) = cells.any({ cell => pos.x() == cell.x() && pos.y() == cell.y() })

	method allowsSimulationToggle() = allowsSimulation
	method waitsForContinue() = false

	method targetCells() = marked
	// Si pide hacer algo, sólo el recuadro
	method pointedCells() = if (cells.isEmpty()) pointsAt else []
	// Las celdas que puede señalar el cocinero
	method focusCells() = self.targetCells() + self.pointedCells()

	// Lo que dice el cocinero.
	method complaintFor(tool, pos) =
		if (cells.isEmpty()) self.waitingComplaint()
		else if (!self.isCell(pos)) ["Ahí no: es en", "el recuadro."]
		else []
	// Lo que dice si se hace algo en un paso que no pide hacer nada en el tablero
	method waitingComplaint() = []
	method complaintForMachine(factory) = []
	method wantedMachines() = []
}

// Se cumple cuando en todas sus celdas hay una máquina que cumple la condición
class MachineStep inherits TutorialStep {
	// Qué tiene que cumplir la máquina de cada celda (por ejemplo, mirar hacia la derecha)
	const condition = { machine => true }
	// Las máquinas del catálogo (las fábricas de machineManager) que deja construir
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

// Un paso que se cumple con un evento y se queda cumplido (aunque después el jugador haga otra cosa)
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

// Lo que dice el cocinero: su imagen ya dibujada (assets/tutorial/steps/<image>.png) y lo que dice en ella.
class ChefSpeech {
	const property image
	const property label = ""
	const property lines = []
	const property keys = []
	// La celda que señala
	const property focus = new CellPosition(x = 9, y = 5)

	// Sin paso, terminó el tutorial: festeja
	method mood() = if (label.isEmpty()) "happy" else "talk"
}

// Sin tutorial, el cocinero no dice nada
const noSpeech = new ChefSpeech(image = "")
