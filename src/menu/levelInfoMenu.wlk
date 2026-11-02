import wollok.game.*
import menu.menuManager.*
import menu.menuText.*

// La información del nivel, en la zona de la izquierda (levelInfoZone: x 0 a 4, y 1 a 14).
// Se dibuja de arriba hacia abajo, en la columna del centro de la zona:
//
//   NIVEL 1                 ← fila 13: el nombre del nivel
//   L: volver               ← fila 12: una ayuda (sólo en el modo libre, ver showHint)
//   OBJETIVO                ← fila 11 (sólo si el nivel tiene objetivos con texto)
//   Papas Fritas: 2/3       ← filas 10 a 8: una por objetivo (como máximo 3)
//   Las papas salen         ← desde la fila 7 hacia abajo: el mensaje del tutorial (ver showTutorialMessage)
//   ¡Nivel completo!        ← fila 4.6, sólo al ganar
//   [N] SIGUIENTE           ← la tecla para seguir, con el estilo de las teclas del fondo (ver keyHintPosition)
//   [F] RECETARIO ...       ← debajo, el fondo (background.gif) ya tiene dibujadas otras teclas: no escribir ahí
//
// Los textos se centran en la parte azul (x 0 a 4): Wollok dibuja el texto centrado en su celda,
// así que con column = 1.5 el centro queda en x = 2.
// RENDIMIENTO: sólo se redibuja cuando levelManager avisa algo, nunca en cada frame.
object levelInfoMenu {
    // Centra los textos en la parte azul (ver arriba)
    const column = 1.5
    const nameRow = 13
    const hintRow = 12
    const goalTitleRow = 11
    const firstProgressRow = 10
    const completedRow = 4.6
    const firstTutorialRow = 7
    // La tecla para seguir (assets/menu/key_*.png, 200x25): justo arriba de la línea punteada que el fondo
    // tiene sobre la tecla F, y alineada con las teclas del fondo (empieza en el borde izquierdo)
    const keyHintPosition = game.at(0, 3.7)
    // Las líneas del tutorial van más juntas que una fila, para que se lean como un párrafo
    const tutorialLineHeight = 0.55
    const property tutorialMaxLines = 6
    // Lo más largo que entra una línea en el panel (no se controla al dibujar: lo revisan los tests)
    const property tutorialMaxLength = 16

    // Lo dibujado, separado según cuándo se reemplaza
    var levelTexts = []      // el nombre, la ayuda y el título: cambian sólo al cargar otro nivel
    var progressTexts = []   // una línea por objetivo: cambian con cada entrega
    var completedTexts = []  // el mensaje de nivel completo
    var tutorialTexts = []   // el mensaje del tutorial: cambia con lo que hace el jugador

    // Al cargar un nivel: borra todo lo anterior y dibuja el nombre y los objetivos
    method show(level) {
        self.remove(levelTexts + progressTexts + completedTexts)
        completedTexts = []
        levelTexts = [self.addText(level.name().toUpperCase(), nameRow)]
        if (!level.progressLines().isEmpty())
            levelTexts.add(self.addText("OBJETIVO", goalTitleRow))
        progressTexts = self.addProgress(level)
    }

    // Una ayuda debajo del nombre (por ejemplo, "L: volver" en el modo libre). Se borra al cargar otro nivel.
    method showHint(text) {
        levelTexts.add(self.addText(text, hintRow))
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
            [self.addText("¡Nivel completo!", completedRow), self.addKeyHint("menu/key_next.png", "N: siguiente")]
        else
            [self.addText("¡Fin del juego!", completedRow), self.addKeyHint("menu/key_restart.png", "0: reiniciar")]
    }

    // Lo que dice el mensaje de nivel completo, en orden (para los tests)
    method completedMessage() = completedTexts.map({ visual => visual.text() })

    // El mensaje del tutorial: borra el anterior y escribe una línea debajo de la otra desde la fila 7
    // (como máximo 6). Con [] (lo que devuelve noTutorial) no queda nada.
    method showTutorialMessage(lines) {
        self.remove(tutorialTexts)
        tutorialTexts = []
        var row = firstTutorialRow
        lines.take(tutorialMaxLines).forEach({ line =>
            tutorialTexts.add(self.addText(line, row))
            row -= tutorialLineHeight
        })
    }

    // Las líneas del mensaje del tutorial que se ven, en orden (para los tests)
    method tutorialMessage() = tutorialTexts.map({ label => label.text() })

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

    method addKeyHint(image, text) {
        const hint = new KeyHint(image = image, text = text, position = keyHintPosition)
        game.addVisual(hint)
        return hint
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

// Una tecla con lo que hace, dibujada en una imagen con el estilo de las teclas del fondo.
// text es lo que dice (para los tests): la imagen ya lo tiene escrito.
class KeyHint {
    const property image
    const property text
    const property position
}
