
// Acá va todo el temita del reloj de la simulación, y agregar cosas a la simulación y bla bla bla
//
// CÓMO FUNCIONA
// - Es el único reloj del juego: Wollok Game llama a tick() cada tickMs milisegundos.
// - Cada tick ejecuta uno o más "pasos" (step), según la velocidad elegida.
// - Las máquinas NO se recorren en cada paso (con muchas máquinas eso era muy lento).
//   En cambio, cada máquina le pide al engine "despertame dentro de N pasos" (schedule),
//   y cuando llega ese paso el engine le manda use().
// - Al final de cada paso avanzan las animaciones de los items (animationEngine).
//
// MODOS
// - Apagada (modo construcción): no corre ningún paso y se puede editar el tablero.
// - Prendida: corre la simulación y el tablero queda bloqueado (ver toolsManager).
//   Por eso las máquinas pueden calcular a su vecina una sola vez, al prender.

import wollok.game.*
import animationEngine.*

object simulationEngine{
    // todas las máquinas que están en el tablero
    const simulatedObjects = []

    // Cantidad de casilleros de la agenda. Tiene que ser mayor que la demora
    // más larga que se agende (hoy, el dispenser: 10 pasos).
    const slotCount = 16

    // La agenda es una lista de casilleros que se usa en ronda: las máquinas a despertar
    // en el paso p están en el casillero p % slotCount.
    // Es una lista y no un Dictionary porque el Dictionary es mucho más lento.
    const agenda = (1..slotCount).map({ _ => [] })

    // número del último paso ejecutado. Nunca se reinicia, sólo crece.
    var currentStep = 0

    // milisegundos de simulación que avanza cada paso
    const property tickMs = 100

    // cantidad de pasos que se ejecutan por tick (1 = normal, 2 = x2, 3 = x3)
    var property speed = 1

    // el juego arranca en modo construcción, con la simulación apagada
    var property running = false

    // Engancha el engine al reloj de Wollok Game. Se llama una sola vez, desde el main.
    method start(){
        game.onTick(tickMs, "simulacion", {self.tick()})
    }

    // Lo llama Wollok Game cada tickMs. A velocidad x2 o x3 ejecuta 2 o 3 pasos seguidos,
    // así el resultado es el mismo que a x1, sólo que llega antes.
    method tick(){
        if (running) speed.times({ _ => self.step() })
    }

    // Un paso de simulación: se despiertan las máquinas agendadas y avanzan las animaciones.
    // Los tests llaman a step() directo para avanzar sin depender del tiempo real.
    method step(){
        currentStep += 1
        const slot = agenda.get(currentStep % slotCount)
        if (!slot.isEmpty()) {
            // Se copia y se vacía antes de despertar, porque una máquina puede volver a agendarse
            const due = slot.copy()
            slot.clear()
            due.forEach({ machine => machine.use() })
        }
        animationEngine.tick()
    }

    // Agenda que a la máquina se le mande use() dentro de esa cantidad de pasos.
    // Como mínimo es 1: nunca se despierta a nadie en el mismo paso en que agenda.
    method schedule(steps, machine){
        const delay = steps.max(1)
        if (delay >= slotCount)
            self.error("No se puede agendar a más de " + (slotCount - 1) + " pasos")
        agenda.get((currentStep + delay) % slotCount).add(machine)
    }

    // Cantidad de pasos de simulación que equivalen a esos milisegundos
    method stepsFor(milliseconds) = (milliseconds / tickMs).roundUp().max(1)

    // Prende o apaga la simulación
    method toggle(){
        if (running) self.stop() else self.run()
        console.println("Simulation: " + running)
    }

    // Prende la simulación: cada máquina busca a su vecina y agenda lo que necesite.
    // Mientras está prendida no se puede editar el tablero (ver toolsManager).
    method run(){
        running = true
        simulatedObjects.forEach({ machine => machine.start() })
    }

    // Apaga la simulación y limpia el tablero de items, para construir tranquilo.
    // Se vacía la agenda para que nadie se despierte con un item que ya no existe.
    method stop(){
        running = false
        agenda.forEach({ slot => slot.clear() })
        self.allItems().forEach({ item =>
            item.detener()
            game.removeVisual(item)
        })
        simulatedObjects.forEach({ machine => machine.reset() })
    }

    // Todos los items que hay en el tablero (cada uno está en alguna máquina)
    method allItems() = simulatedObjects.flatMap({ machine => machine.heldItems() })

    // Lo llama el board al colocar una máquina
    method addSimulatedObject(thing){
        simulatedObjects.add(thing)
    }

    // Lo llama el board al quitar una máquina
    method removeSimulatedObject(thing){
        simulatedObjects.remove(thing)
    }

    // Cantidad de despertares agendados (para tests)
    method pendingWakeUps() = agenda.sum({ slot => slot.size() })

}
