
// Acá va todo el temita del reloj de la simulación, y agregar cosas a la simulación y bla bla bla
// Es el único reloj del juego: en cada paso avanzan las máquinas y las animaciones.

import wollok.game.*
import animationEngine.*

object simulationEngine{
    const simulatedObjects = []

    // milisegundos de simulación que avanza cada paso
    const property tickMs = 100

    // cantidad de pasos que se ejecutan por tick (1 = normal, 2 = x2, 3 = x3)
    var property speed = 1

    // el juego arranca en modo construcción, con la simulación apagada
    var property running = false

    method start(){
        game.onTick(tickMs, "simulacion", {self.tick()})
    }

    method tick(){
        if (running) speed.times({ _ => self.step() })
    }

    // Un paso de simulación: actúan las máquinas y avanzan las animaciones
    method step(){
        simulatedObjects.forEach({
            simulatedItem => simulatedItem.use()
        })
        animationEngine.tick()
    }

    // Prende o apaga la simulación
    method toggle(){
        if (running) self.stop() else running = true
        console.println("Simulation: " + running)
    }

    // Apaga la simulación y limpia el tablero de items, para construir tranquilo
    method stop(){
        running = false
        self.allItems().forEach({ item =>
            item.detener()
            game.removeVisual(item)
        })
        simulatedObjects.forEach({ machine => machine.reset() })
    }

    // Todos los items que hay en el tablero (cada uno está en alguna máquina)
    method allItems() = simulatedObjects.flatMap({ machine => machine.heldItems() })

    // al momento de poner una máquina, debería simularse
    method addSimulatedObject(thing){
        simulatedObjects.add(thing)
    }

    method removeSimulatedObject(thing){
        simulatedObjects.remove(thing)
    }

}
