// Medidor de carga del juego. Sólo escribe en la terminal, no dibuja nada.
//
// CÓMO FUNCIONA
// - El reloj de la simulación debería sonar cada tickMs (100 ms).
// - El medidor anota cuánto tiempo real pasó entre un tick y el siguiente.
//   Si el juego no llega a simular y dibujar a tiempo, los ticks se atrasan.
// - Cada reportEvery ticks escribe en la terminal el promedio y la cantidad de items.
//
// game.currentTime() sólo se actualiza una vez por frame, por eso no sirve para medir
// cuánto tarda un paso por dentro, pero sí el tiempo entre ticks.
// En los tests no hay frames (currentTime vale 0), así que el medidor no hace nada.

import wollok.game.*
import simulationEngine.*

object stressMeter {
    // se prende y apaga con la tecla M
    var property active = false

    // cada cuántos ticks escribe una línea en la terminal (10 ticks = 1 segundo a tickMs 100)
    const reportEvery = 10

    // items creados desde que se prendió la simulación
    var itemCount = 0

    var lastTime = 0        // currentTime del tick anterior (0 si todavía no hubo)
    var ticks = 0           // ticks medidos desde el último reporte
    var elapsedMs = 0       // tiempo real que pasó en esos ticks

    method toggle() {
        active = !active
        self.restartMeasure()
        console.println("Medidor de carga: " + active)
    }

    // Lo llama el Dispenser cada vez que crea un item
    method itemCreated() { itemCount += 1 }

    // Lo llama el simulationEngine al apagar la simulación, que borra todos los items
    method resetItems() { itemCount = 0 }

    // Lo llama simulationEngine.tick() en cada tick
    method measure() {
        if (active) {
            const now = game.currentTime()
            if (lastTime > 0) {
                elapsedMs += now - lastTime
                ticks += 1
            }
            lastTime = now
            if (ticks == reportEvery) self.report()
        }
    }

    method report() {
        const average = (elapsedMs / ticks).roundUp()
        const ideal = simulationEngine.tickMs()
        console.println(
            "items=" + itemCount +
            " | tick=" + average + " ms (ideal " + ideal + ")" +
            " | x" + simulationEngine.speed() +
            " | " + self.status(average, ideal)
        )
        ticks = 0
        elapsedMs = 0
    }

    method status(average, ideal) =
        if (average > ideal * 1.5) "SOBRECARGADO"
        else if (average > ideal * 1.1) "justo"
        else "ok"

    method restartMeasure() {
        lastTime = 0
        ticks = 0
        elapsedMs = 0
    }
}
