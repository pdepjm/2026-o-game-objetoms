import src.food.recipes.*
import src.menu.placeMenu.*
import levels.levelsTypes.*
import simulation.simulationEngine.*
import board.*
import tools.toolsManager.*
import machines.machineManager.*
import menu.levelInfoMenu.*

object levelManager {
    // Los niveles en el orden en que se juegan. Es var sólo para que los tests usen sus propios niveles (changeLevels)
    var levels = [level1, level2]
    // Los que ya se ganaron, para saber a cuál volver desde el modo libre (levelToPlay).
    // Se guardan mientras el juego está abierto: al cerrarlo se pierden.
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
    // Los niveles en el orden en que se juegan (lo usan los tests, para cargarlos todos)
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
        // Antes de las máquinas fijas, así las marcas de las celdas bloqueadas quedan debajo de ellas
        board.buildZones(level.buildZones())
        level.placeFixedMachines()
        level.resetGoals()
        levelInfoMenu.show(level)
        if (level == freePlay) levelInfoMenu.showHint("L: volver")
    }
    method restart() {self.load(currentLevel)}

    // El modo libre, con todas las máquinas y sin objetivo
    method loadFreePlay() {self.load(freePlay)}

    // Tecla L: del nivel al modo libre, y del modo libre de vuelta al nivel que le toca jugar.
    // Con la simulación prendida no hace nada.
    method toggleFreePlay() {
        if (!simulationEngine.running()) {
            if (currentLevel == freePlay) self.load(self.levelToPlay()) else self.loadFreePlay()
        }
    }

    // La posición del nivel actual en levels. Se busca cada vez (y no se guarda un índice), así no
    // se desfasa cuando se llega a un nivel por otro camino (start, la tecla L, load).
    method currentIndex() = (0 .. levels.size() - 1).find({ index => levels.get(index) == currentLevel })
    method hasNext() = levels.contains(currentLevel) && levels.last() != currentLevel
    
    method loadNext() {
        if (completed && self.hasNext()){
            self.load(levels.get(self.currentIndex() + 1))
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
    	if (levels.contains(currentLevel) && !completedLevels.contains(currentLevel)) completedLevels.add(currentLevel)
    	simulationEngine.after(1, { self.finishLevel() })
    }

    method finishLevel() {
    	simulationEngine.stop()                                // directo al engine: el progreso NO se borra
    	levelInfoMenu.showCompleted(self.hasNext())
    }
}