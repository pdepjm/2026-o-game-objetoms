import src.menu.placeMenu.*
import levels.levelsTypes.*
import simulation.simulationEngine.*
import board.*
import tools.toolsManager.*
import machines.machineManager.*
import menu.levelInfoMenu.*

object levelManager {
    const levels = [level1]
    var indexCurrentLevel = 0
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


    method start() {
        self.load(levels.first())
    }
    method load(level) {
        self._clear()
        currentLevel = level
        completed = false
        machineManager.changeCatalog(level.availableMachines())
        placeMenu.resetPage()
        level.placeFixedMachines()
        level.resetGoals()
        levelInfoMenu.show(level)
    }
    method restart() {self.load(currentLevel)}

    // Tecla L: el modo libre, con todas las máquinas y sin objetivo
    method loadFreePlay() {self.load(freePlay)}
    method hasNext() = levels.contains(currentLevel) && levels.last() != currentLevel
    
    method loadNext() {
        if (completed && self.hasNext()){
            indexCurrentLevel += 1
            self.load(levels.get(indexCurrentLevel))
        }
    }

    method toggleSimulation() {
        if (!completed) {
	    	simulationEngine.toggle()
	    	// Al apagar se borran los items: el progreso vuelve a cero
	    	if (!simulationEngine.running()) {
	    		currentLevel.resetGoals()
	    		levelInfoMenu.updateProgress(currentLevel)
	    	}
	    }
    }

    method delivered(item) {
	    if (!completed) {
		    currentLevel.delivered(item)
		    levelInfoMenu.updateProgress(currentLevel)
		    if (currentLevel.goalsMet()) self.won()
	    }
    }

    method won() {
    	completed = true                                       // las próximas entregas ya no cuentan
    	simulationEngine.after(1, { self.finishLevel() })
    }

    method finishLevel() {
    	simulationEngine.stop()                                // directo al engine: el progreso NO se borra
    	levelInfoMenu.showCompleted(self.hasNext())
    }
}