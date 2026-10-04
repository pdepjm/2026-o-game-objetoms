// Medidor de carga del juego. Sólo escribe en la terminal, no dibuja nada.
//
// CÓMO FUNCIONA
// - El reloj de la simulación debería sonar cada tickMs (100 ms).
// - El medidor anota cuánto tiempo real pasó entre un tick y el siguiente.
//   Si el juego no llega a simular y dibujar a tiempo, los ticks se atrasan.
// - Cada reportEvery ticks escribe en la terminal el promedio, el tick más lento
//   y la cantidad de items.
//
// PROMEDIO vs MÁS LENTO
// - El promedio dice si el juego, en general, llega a tiempo.
// - El más lento muestra los tirones: ticks de 50 y 150 ms promedian 100 ("ok"),
//   pero en pantalla se ven como trabas. El estado se calcula con el más lento.
//
// game.currentTime() sólo se actualiza una vez por frame, por eso no sirve para medir
// cuánto tarda un paso por dentro, pero sí el tiempo entre ticks.
//
// INDEPENDIENTE DEL JUEGO
// El medidor tiene su propio reloj (un onTick con el mismo intervalo que la simulación),
// que existe sólo mientras está prendido. Ni la simulación ni las máquinas saben que
// existe: el medidor les pregunta lo que necesita (tickMs, speed, itemCount).
// Como todos los onTick de Wollok se disparan igual (en el primer frame después de que
// se cumple el intervalo), sus atrasos son los mismos que los de la simulación.

import wollok.game.*
import src.simulationEngine.*

object stressMeter {
    // se prende y apaga con la tecla M
    var active = false

    // cada cuántos ticks escribe una línea en la terminal (10 ticks = 1 segundo a tickMs 100)
    const reportEvery = 10

    var lastTime = 0        // currentTime del tick anterior (0 si todavía no hubo)
    var ticks = 0           // ticks medidos desde el último reporte
    var elapsedMs = 0       // tiempo real que pasó en esos ticks
    var slowestMs = 0       // el tick más lento desde el último reporte

    // Prendido: engancha su reloj. Apagado: lo saca, y no cuesta nada.
    method toggle() {
        active = !active
        self.restartMeasure()
        if (active) game.onTick(simulationEngine.tickMs(), "medidor", { self.measure() })
        else game.removeTickEvent("medidor")
        console.println("Medidor de carga: " + active)
    }

    // Lo llama su propio reloj en cada tick
    method measure() {
        const now = game.currentTime()
        if (lastTime > 0) {
            const tickMs = now - lastTime
            elapsedMs += tickMs
            slowestMs = slowestMs.max(tickMs)
            ticks += 1
        }
        lastTime = now
        if (ticks == reportEvery) self.report()
    }

    method report() {
        const average = (elapsedMs / ticks).roundUp()
        const ideal = simulationEngine.tickMs()
        console.println(
            "items=" + simulationEngine.itemCount() +
            " | tick=" + average + " ms (ideal " + ideal + ")" +
            " | max=" + slowestMs + " ms" +
            " | x" + simulationEngine.speed() +
            " | " + self.status(slowestMs, ideal)
        )
        ticks = 0
        elapsedMs = 0
        slowestMs = 0
    }

    // Se evalúa con el tick más lento: un solo tirón grande ya se nota en pantalla.
    // OJO: Wollok Game sólo puede disparar un tick cuando dibuja un frame (cada ~17 ms),
    // así que aun con el tablero vacío el más lento ronda los 125 ms (medido).
    // Por eso "justo" arranca recién en 140 ms: lo de abajo es ruido normal.
    method status(slowest, ideal) =
        if (slowest > ideal * 1.5) "SOBRECARGADO"
        else if (slowest > ideal * 1.4) "justo"
        else "ok"

    method restartMeasure() {
        lastTime = 0
        ticks = 0
        elapsedMs = 0
        slowestMs = 0
    }
}
