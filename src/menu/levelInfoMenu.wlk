import wollok.game.*
import menu.menuManager.*
import menu.menuText.*

// La información del nivel, en la zona de la izquierda (levelInfoZone: x 0 a 4, y 1 a 14).
// Se dibuja de arriba hacia abajo, en la columna del centro de la zona:
//
//   NIVEL 1                 ← fila 13: el nombre del nivel
//   OBJETIVO                ← fila 11 (sólo si el nivel tiene objetivos con texto)
//   Papas Fritas: 2/3       ← filas 10 a 8: una por objetivo (como máximo 3)
//   ¡Nivel completo!        ← fila 6, sólo al ganar
//   N: siguiente            ← fila 5
//
// Las filas 4 a 1 quedan libres (para el mensaje del tutorial, más adelante).
// RENDIMIENTO: sólo se redibuja cuando levelManager avisa algo, nunca en cada frame.
object levelInfoMenu {
    // la columna del centro de la zona, que tiene 5 de ancho
    const column = 2
    const nameRow = 13
    const goalTitleRow = 11
    const firstProgressRow = 10
    const completedRow = 6

    // Lo dibujado, separado según cuándo se reemplaza
    var levelTexts = []      // el nombre y el título: cambian sólo al cargar otro nivel
    var progressTexts = []   // una línea por objetivo: cambian con cada entrega
    var completedTexts = []  // el mensaje de nivel completo

    // Al cargar un nivel: borra todo lo anterior y dibuja el nombre y los objetivos
    method show(level) {
        self.remove(levelTexts + progressTexts + completedTexts)
        completedTexts = []
        levelTexts = [self.addText(level.name().toUpperCase(), nameRow)]
        if (!level.progressLines().isEmpty())
            levelTexts.add(self.addText("OBJETIVO", goalTitleRow))
        progressTexts = self.addProgress(level)
    }

    // Cambió el progreso (una entrega, o se apagó la simulación): reemplaza sólo esas líneas
    method updateProgress(level) {
        self.remove(progressTexts)
        progressTexts = self.addProgress(level)
    }

    // Se ganó el nivel: el mensaje y la tecla para seguir
    method showCompleted(hasNext) {
        self.remove(completedTexts)
        completedTexts = if (hasNext)
            [self.addText("¡Nivel completo!", completedRow), self.addText("N: siguiente", completedRow - 1)]
        else
            [self.addText("¡Fin del juego!", completedRow), self.addText("0: reiniciar", completedRow - 1)]
    }

    // ----------- DIBUJO -----------

    method addProgress(level) {
        var row = firstProgressRow
        const texts = []
        level.progressLines().forEach({ line =>
            texts.add(self.addText(line, row))
            row -= 1
        })
        return texts
    }

    method addText(text, row) {
        const label = new MenuText(text = text, position = self.positionOfRow(row))
        game.addVisual(label)
        return label
    }

    method remove(texts) {
        texts.forEach({ text => game.removeVisual(text) })
    }

    // La posición en pantalla de una fila (las filas son las de la pantalla; la zona empieza en la 1)
    method positionOfRow(row) = menuManager.levelInfoZone().at(column, row - menuManager.levelInfoZone().origin().y())
}
