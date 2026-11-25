// Buffet Albert Einstein - carga los niveles, lleva cuál se está jugando y avisa cuándo se gana.
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

import src.food.recipes.*
import src.menu.hud.placeMenu.*
import levels.levelsTypes.*
import levels.levelClasses.*
import simulation.simulationEngine.*
import board.*
import tools.toolsManager.*
import machines.machineManager.*
import menu.hud.levelInfoMenu.*
import menu.overBoard.tutorialGuide.*
import menu.screenManager.*

object levelManager {
    // Los niveles en el orden en que se juegan.
    var levels = [tutorialLevel, hotDogTutorialLevel, energyTutorialLevel, level1, level2, level3, level4]
    // Los que ya se ganaron, para saber a cuál volver desde el modo libre (levelToPlay).
    const completedLevels = []
    // Arranca en el modo libre (y no en null): así entregar algo o apretar 5 antes de start() no rompe
    var currentLevel = freePlay
    var completed = false   // Si se cumplio el nivel actual

    method _clear() {
        simulationEngine.reset()
        board.clear()
        toolsManager.reset()
    }

    method currentLevel() = currentLevel
    method completed() = completed
    // Los niveles en el orden en que se juegan
    method levels() = levels
    method completedLevels() = completedLevels

    // Para los tests: otros niveles, y sin ninguno completado
    method changeLevels(newLevels) {
        levels = newLevels
        completedLevels.clear()
    }

    // El nivel que le toca jugar: el primero que todavía no se ganó (si se ganaron todos, el último)
    method levelToPlay() = levels.findOrDefault({ level => !completedLevels.contains(level) }, levels.last())

    method start() {
        self.load(self.levelToPlay())
    }
    method load(level) {
        self._clear()
        currentLevel = level
        completed = false
        machineManager.changeCatalog(level.availableMachines())
        recipeBook.changeAvailable(level.availableRecipes())
        placeMenu.resetPage()
        board.buildZones(level.buildZones(), level.blockedLayer())
        level.placeFixedMachines()
        level.resetGoals()
        levelInfoMenu.show(level)
        self._showEnergy()
        level.showHints(levelInfoMenu)
        self._notifyTutorial({ tutorial => tutorial.onLevelLoaded(level) })
        // el menú de la máquina elegida, arriba de las máquinas fijas
        toolsManager.boardChanged()
        self._cookingChanged()
    }
    method restart() {self.load(currentLevel)}

    // El modo libre, con todas las máquinas y sin objetivo
    method loadFreePlay() {self.load(freePlay)}

    // Tecla L: del nivel al modo libre, y del modo libre de vuelta al nivel que le toca jugar.
    method toggleFreePlay() {
        if (!simulationEngine.running()) {
            currentLevel.toggleFreePlay(self)
        }
    }

    // La posición del nivel actual en levels.
    method currentIndex() = (0 .. levels.size() - 1).find({ index => levels.get(index) == currentLevel })
    method hasNext() = levels.contains(currentLevel) && levels.last() != currentLevel
    
    method loadNext() {
        if (completed && self.hasNext()){
            self.load(levels.get(self.currentIndex() + 1))
        }
    }

    method toggleSimulation() {
        // Prender necesita energía de sobra; apagar siempre se puede
        if (!completed && self.tutorial().allowsSimulationToggle() && (simulationEngine.running() || self.hasEnergy())) {
	    	simulationEngine.toggle()
	    	// Al apagar se borran los items: el progreso vuelve a cero
	    	if (!simulationEngine.running()) {
	    		currentLevel.resetGoals()
	    		levelInfoMenu.updateProgress(currentLevel)
	    	}
	    	self._notifyTutorial({ tutorial => tutorial.onSimulationToggled(simulationEngine.running()) })
	    	self._cookingChanged()
	    }
    }

    // Mientras se cocina queda todo limpio: sin el panel de editar, el menú de la máquina
    method _cookingChanged() {
        if (simulationEngine.running()) {
            toolsManager.cookingStarted()
            chefGuide.silence()
            tutorialMarks.hide()
        } else {
            toolsManager.cookingStopped()
            chefGuide.speak()
            tutorialMarks.reveal()
        }
    }

    // ¿La energía que gastan las máquinas entra en el límite del nivel?
    method hasEnergy() = currentLevel.energyLimit().allows(board.totalEnergy())

    // Muestra cuánta energía se gasta (si el nivel tiene límite)
    method _showEnergy() { levelInfoMenu.updateEnergy(currentLevel, board.totalEnergy()) }

    method delivered(item) {
	    if (!completed) {
		    currentLevel.delivered(item)
		    levelInfoMenu.updateProgress(currentLevel)
		    self._notifyTutorial({ tutorial => tutorial.onDelivered(item) })
		    if (currentLevel.goalsMet()) self.won()
	    }
    }

    method won() {
    	completed = true                                       // las próximas entregas ya no cuentan
    	if (levels.contains(currentLevel) && !completedLevels.contains(currentLevel)) completedLevels.add(currentLevel)
    	self._notifyTutorial({ tutorial => tutorial.onLevelWon(currentLevel) })
    	simulationEngine.after(1, { self.finishLevel() })
    }

    method finishLevel() {
    	simulationEngine.stop()
    	self._cookingChanged()                                 // vuelve el cocinero, a festejar
    	screenManager.showLevelComplete(new LevelResult(level = currentLevel, ending = self.ending()))
    }

    // Cómo termina el nivel que se ganó: con otro nivel después, o fin del juego
    method ending() = if (self.hasNext()) nextLevelEnding else lastLevelEnding

    // ----------- TUTORIAL -----------

    method tutorial() = currentLevel.tutorial()

    method machinePlaced(machine) {
        self._showEnergy()
        self._notifyTutorial({ tutorial => tutorial.onMachinePlaced(machine) })
    }
    method machineRemoved(machine) {
        self._showEnergy()
        self._notifyTutorial({ tutorial => tutorial.onMachineRemoved(machine) })
    }
    method machineRotated(machine) { self._notifyTutorial({ tutorial => tutorial.onMachineRotated(machine) }) }
    // Si con la simulación prendida se sube un setting y se pasa del límite, se apaga
    method settingChanged(machine, setting) {
        self._showEnergy()
        if (simulationEngine.running() && !self.hasEnergy()) self.toggleSimulation()
        self._notifyTutorial({ tutorial => tutorial.onSettingChanged(machine, setting) })
    }
    // Enter: seguir después de una explicación.
    method continueTutorial() { self._notifyTutorial({ tutorial => tutorial.onContinue() }) }

    // La tecla T o el botón SALTEAR TUTORIAL
    method skipTutorial() {
        currentLevel.tutorial().skip(self)
    }

    // Da por hechos todos los tutoriales y carga el primer nivel que toca jugar
    method skipTutorials() {
        levels.forEach({ level => level.tutorial().completeIn(completedLevels, level) })
        self.load(self.levelToPlay())
    }

    // ¿Deja usar esa acción en esa celda?
    method allowsTool(tool, pos) = self.tutorial().allowsTool(tool, pos)

    // ----------- CUANDO ALGO NO VA -----------

    // El tutorial no dejó usar esa acción en esa celda (toolsManager)
    method toolRejected(tool, pos) { self._complain(self.tutorial().complaintFor(tool, pos)) }

    // Se eligió una máquina en el menú de colocar (placeMenu): si no es la que pide el paso
    method machineSelected(factory) {
        const complaint = self.tutorial().complaintForMachine(factory)
        if (!complaint.isEmpty()) placeMenu.flashError(factory)
        self._complain(complaint)
    }

    method _complain(complaint) {
        if (!complaint.isEmpty()) {
            chefGuide.complain(complaint)
            tutorialMarks.flashError()
        }
    }

    // Le avisa al tutorial y muestra su mensaje (lo dice el cocinero), sus teclas
    method _notifyTutorial(event) {
        const before = self.tutorial().targetCells()
        event.apply(self.tutorial())
        const targets = self.tutorial().targetCells()
        if (!targets.isEmpty() && targets != before) toolsManager.jumpTo(targets.first())
        tutorialMarks.show(targets, self.tutorial().pointedCells())
        chefGuide.say(self.tutorial().speech())
        placeMenu.highlight(self.tutorial().wantedMachines())
    }
}
