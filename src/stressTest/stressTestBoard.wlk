// Herramienta para pruebas de carga (tecla L). Se usa junto con el medidor (tecla M).
//
// Llena todo el tablero con una "serpiente" de cintas que arranca en un dispenser:
// - fila 1: dispenser en la esquina izquierda, cintas hacia la derecha, y al final una hacia arriba
// - fila 2: cintas hacia la izquierda, y al final (columna 5) una hacia arriba
// - fila 3: otra vez hacia la derecha... y así hasta la fila 13
// Así los items recorren todo el tablero y se puede ver cómo se comporta con muchos objetos.
//
// Es el PEOR CASO a propósito: un solo dispenser perfectamente regular hace que todos los
// items cambien de cinta en el mismo paso. Sirve para comparar antes y después de un cambio.

import wollok.game.*
import machines.types.belt.*
import machines.types.dispenser.*
import board.*
import directions.*
import simulation.simulationEngine.*

object stressTestBoard {
    // límites del tablero (los mismos que board.inBoard)
    const firstColumn = 5
    const lastColumn = 19
    const firstRow = 1
    const lastRow = 13

    method fill() {
        // con la simulación prendida no se puede editar el tablero (las máquinas ya buscaron a su vecina)
        if (simulationEngine.running()) {
            console.println("Apagá la simulación (5) antes de llenar el tablero")
        } else {
            self.clear()
            (firstRow..lastRow).forEach({ row => self.fillRow(row) })
            console.println("Tablero de prueba listo")
        }
    }

    // Saca todas las máquinas del tablero
    method clear() {
        (firstColumn..lastColumn).forEach({ column =>
            (firstRow..lastRow).forEach({ row => board.pop(game.at(column, row)) })
        })
    }

    // Filas impares van hacia la derecha y terminan subiendo en la última columna.
    // Filas pares van hacia la izquierda y terminan subiendo en la primera columna.
    method fillRow(row) {
        (firstColumn..lastColumn).forEach({ column =>
            self.place(column, row, self.directionAt(column, row))
        })
    }

    method directionAt(column, row) =
        if (row.odd()) { if (column == lastColumn) up else right }
        else { if (column == firstColumn) up else left }

    // La dirección se le pasa a la máquina al crearla (new Belt(direction = ...)), en vez de
    // cambiar la dirección seleccionada del jugador (toolsManager) para cada máquina.
    method place(column, row, machineDirection) {
        // el inicio de la serpiente es el dispenser; todo lo demás son cintas
        const machine =
            if (column == firstColumn && row == firstRow) new Dispenser(direction = machineDirection)
            else new Belt(direction = machineDirection)
        board.push(game.at(column, row), machine)
    }
}
