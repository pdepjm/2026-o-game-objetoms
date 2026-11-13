// Buffet Albert Einstein - la información del nivel en la pantalla: nombre, objetivos, progreso y tutorial.
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

import wollok.game.*
import menu.menuManager.*
import menu.menuText.*
import cellPosition.*
import menu.spriteText.*
import menu.spriteFonts.*

// La información del nivel, en la zona de la izquierda (levelInfoZone: x 0 a 4, y 1 a 14).
// Se dibuja de arriba hacia abajo:
//
//   NIVEL 1                 ← fila 13: el nombre del nivel, en amarillo sobre una cinta roja
//   L: volver               ← fila 12: una ayuda (sólo en el modo libre, ver showHint)
//   [T] SALTEAR TUTORIAL    ← fila 12, en los tutoriales: también se clickea (ver isSkipButton)
//   OBJETIVO                ← fila 11, en una tarjeta de papel (sólo si el nivel tiene objetivos con texto)
//   [plato] Papas: 2/3      ← filas 10 a 8, en la tarjeta: uno por objetivo (como máximo 3), con su barra
//   PASO 2 DE 8             ← fila 7.5, en un globo de diálogo: dónde va el tutorial
//   Las papas salen         ← desde la fila 7 hacia abajo, en el globo: el mensaje del tutorial
//   [Z] COLOCAR             ← sus teclas, con el estilo de las del fondo, desde la fila 3.65 hacia arriba
//   ¡Nivel completo!        ← fila 4.6, sólo al ganar
//   [N] SIGUIENTE           ← la tecla para seguir, con el estilo de las teclas del fondo (ver keyHintRow)
//   [F] RECETARIO ...       ← debajo, el fondo (background.gif) ya tiene dibujadas otras teclas: no escribir ahí
//
// Los textos se centran en la parte azul (x 0 a 4): Wollok dibuja el texto centrado en su celda,
// así que con column = 1.5 el centro queda en x = 2. El estilo lo dan las imágenes de atrás
// (assets/menu/info/, las genera makeLevelInfo.py) y, sobre el papel (la tarjeta y el globo), las letras:
// Wollok dibuja sus textos con un contorno oscuro que ahí se ve raro, así que se escriben con una imagen
// por letra (ver spriteText.wlk). El nombre del nivel y los textos sobre el azul siguen siendo de Wollok.
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
    const stepLabelRow = 7.5
    // Los objetivos: el texto un poco arriba del centro de su fila y corrido a la derecha (deja lugar a la
    // imagen del plato), y la barra abajo, a partir de x 1.3
    const goalTextColumn = 2
    const goalTextOffset = 0.18
    const goalBarOffset = 0.14
    const goalBarColumn = 1.3
    // La tecla para seguir (assets/menu/key_*.png, 200x25): justo arriba de la línea punteada que el fondo
    // tiene sobre la tecla F, y alineada con las teclas del fondo (empieza en el borde izquierdo)
    const keyHintRow = 3.7
    // Las teclas del tutorial: la de más abajo en la fila 3.65, y cada una 0.6 filas más arriba
    const firstKeyRow = 3.65
    const keyHeight = 0.6
    // Las líneas del tutorial van más juntas que una fila, para que se lean como un párrafo
    const tutorialLineHeight = 0.55
    const property tutorialMaxLines = 6
    // Lo más largo que entra una línea en el panel (no se controla al dibujar: lo revisan los tests)
    const property tutorialMaxLength = 16

    // Los colores (RRGGBBAA) de los textos de Wollok: amarillo sobre la cinta, blanco sobre el azul.
    // Los del papel (marrón y gris) son los de las letras: ver assets/menu/font/makeFont.py
    const yellow = "FFD015FF"
    const white = "FFFFFFFF"
    const red = "FF5A4DFF"

    // Las imágenes de atrás (la cinta, la tarjeta, el globo, los platos) empiezan 12 px adentro de la parte azul
    const imageColumn = 0.24

    // Lo dibujado, separado según cuándo se reemplaza
    var energyTexts = []     // el contador de energía: cambia al colocar, borrar o editar máquinas
    var skipButton = null    // el botón para saltear el tutorial (null si el nivel no tiene tutorial)
    var levelTexts = []      // la cinta, el nombre, la ayuda, la tarjeta y el título: cambian al cargar otro nivel
    var progressTexts = []   // cada objetivo (plato, texto y barra): cambian con cada entrega
    var completedTexts = []  // el mensaje de nivel completo
    var tutorialTexts = []   // las líneas del tutorial: cambian con lo que hace el jugador
    var tutorialFrame = []   // el globo y el paso
    var tutorialKeys = []    // las teclas del tutorial

    // Al cargar un nivel: borra todo lo anterior y dibuja el nombre y los objetivos.
    // Las imágenes van antes que los textos: Wollok dibuja en el orden en que se agregan.
    method show(level) {
        self.remove(levelTexts + progressTexts + completedTexts + energyTexts)
        completedTexts = []
        energyTexts = []
        skipButton = null
        levelTexts = [
            self.addImage("menu/info/ribbon.png", nameRow),
            self.addText(level.name().toUpperCase(), column, nameRow, yellow)
        ]
        // un poco más arriba que la fila, para que no quede pegado a la tarjeta (sigue en la fila 12: el click
        // se reconoce por celda)
        if (level.hasTutorial()) {
            skipButton = self.addKeyHint("menu/key_skip.png", "skip", hintRow + 0.2)
            levelTexts.add(skipButton)
        }
        const goals = level.shownGoals().size()
        if (goals > 0) {
            // la tarjeta va del título hasta el borde de abajo de la fila del último objetivo
            levelTexts.add(self.addImage("menu/info/card_" + goals + ".png", goalTitleRow - goals))
            levelTexts.add(self.addSpriteText("OBJETIVO", labelFont, column, goalTitleRow))
        }
        progressTexts = self.addProgress(level)
    }

    // ¿Es una celda del botón para saltear el tutorial? (la imagen ocupa x 0 a 4 de la fila 12)
    method isSkipButton(pos) = self.showsSkipButton() && pos.y() == hintRow && pos.x().between(0, 3)

    method showsSkipButton() = skipButton != null

    // Una ayuda debajo del nombre (por ejemplo, "L: volver" en el modo libre). Se borra al cargar otro nivel.
    method showHint(text) {
        levelTexts.add(self.addText(text, hintRow))
    }

    // El contador de energía, debajo de la tarjeta de objetivos (rojo si se pasó del límite). Los niveles
    // sin límite no lo muestran.
    method updateEnergy(level, total) {
        self.remove(energyTexts)
        energyTexts = []
        const limit = level.energyLimit()
        if (limit.isLimited()) {
            const color = if (limit.allows(total)) white else red
            energyTexts.add(self.addText(limit.text(total), column, goalTitleRow - level.shownGoals().size() - 1, color))
        }
    }

    // Lo que dice el contador de energía (para los tests)
    method energyMessage() = energyTexts.map({ visual => visual.description() })

    // Cambió el progreso (una entrega, o se apagó la simulación): reemplaza sólo los objetivos
    method updateProgress(level) {
        self.remove(progressTexts)
        progressTexts = self.addProgress(level)
    }

    // Se ganó el nivel: el mensaje y la tecla para seguir
    method showCompleted(hasNext) {
        self.remove(completedTexts)
        completedTexts = if (hasNext)
            [self.addText("¡Nivel completo!", completedRow), self.addKeyHint("menu/key_next.png", "N: siguiente", keyHintRow)]
        else
            [self.addText("¡Fin del juego!", completedRow), self.addKeyHint("menu/key_restart.png", "0: reiniciar", keyHintRow)]
    }

    // Lo que dice el mensaje de nivel completo, en orden (para los tests)
    method completedMessage() = completedTexts.map({ visual => visual.description() })

    // Los textos del nombre, la ayuda y el título del objetivo, en orden (para los tests)
    method levelMessage() = levelTexts.filter({ visual => visual.isText() }).map({ visual => visual.description() })

    // Lo que dicen los objetivos, en orden (para los tests)
    method progressMessage() = progressTexts.filter({ visual => visual.isText() }).map({ visual => visual.description() })

    // Las barras de los objetivos que se ven, en orden (para los tests)
    method progressBars() = progressTexts.filter({ visual => !visual.isText() && visual.image().startsWith("menu/info/bar_") }).map({ visual => visual.image() })

    // El mensaje del tutorial: borra el anterior y, si hay líneas, dibuja el globo, el paso (fila 7.5) y una
    // línea debajo de la otra desde la fila 7. Sus teclas (imágenes como las del fondo) van afuera del globo,
    // de abajo hacia arriba desde la fila 3.65, la primera arriba. Cada tecla ocupa más o menos lo que una
    // línea: entre las dos, como máximo 6 (lo revisan los tests). Sin líneas (noTutorial) no queda nada.
    method showTutorialMessage(stepLabel, lines, keys) {
        self.remove(tutorialFrame + tutorialTexts + tutorialKeys)
        tutorialFrame = []
        tutorialTexts = []
        const shown = lines.take(tutorialMaxLines)
        if (!shown.isEmpty()) {
            tutorialFrame.add(self.addImage("menu/info/bubble_" + shown.size() + ".png", self.bubbleBottom(shown.size())))
            if (stepLabel != "") tutorialFrame.add(self.addSpriteText(stepLabel, labelFont, column, stepLabelRow))
        }
        var row = firstTutorialRow
        shown.forEach({ line =>
            tutorialTexts.add(self.addSpriteText(line, textFont, column, row))
            row -= tutorialLineHeight
        })
        var keyRow = firstKeyRow + keyHeight * (keys.size() - 1)
        tutorialKeys = keys.map({ key =>
            const hint = self.addKeyHint("menu/key_" + key + ".png", key, keyRow)
            keyRow -= keyHeight
            return hint
        })
    }

    // Dónde termina abajo el globo (con la cola), en filas, según cuántas líneas tiene. makeLevelInfo.py lo
    // hace empezar 16 px arriba del centro de la fila del paso, y medir 16 + 25 + 27.5 por línea extra + 18
    // + 16 (la cola) px. Si cambia uno, cambiar el otro.
    method bubbleBottom(lineCount) {
        const top = (stepLabelRow + 0.5) * 50 + 16
        const height = (16 + 25 + (lineCount - 1) * tutorialLineHeight * 50 + 18 + 16).round()
        return (top - height) / 50
    }

    // Las teclas del mensaje del tutorial que se ven, en orden (para los tests)
    method tutorialMessageKeys() = tutorialKeys.map({ hint => hint.description() })

    // Las líneas del mensaje del tutorial que se ven, en orden (para los tests)
    method tutorialMessage() = tutorialTexts.map({ label => label.text() })

    // El paso que se ve arriba del mensaje del tutorial ("" si no hay)
    method tutorialStepLabel() = tutorialFrame.filter({ visual => visual.isText() }).map({ visual => visual.description() }).join("")

    // ----------- DIBUJO -----------

    // Por cada objetivo, en su fila: la imagen del plato, su texto y su barra
    method addProgress(level) {
        var row = firstProgressRow
        const visuals = []
        level.shownGoals().forEach({ goal =>
            visuals.add(self.addImage(goal.image(), row))
            visuals.add(self.addSpriteText(goal.progressText(), textFont, goalTextColumn, row + goalTextOffset))
            visuals.add(self.addVisual(new InfoImage(image = "menu/info/bar_" + goal.progressTenths() + ".png", position = self.exactPosition(goalBarColumn, row + goalBarOffset))))
            row -= 1
        })
        return visuals
    }

    // Una imagen de 200x25 que empieza en el borde izquierdo, alineada con las teclas del fondo
    method addKeyHint(image, description, row) =
        self.addVisual(new KeyHint(image = image, description = description, position = self.exactPosition(0, row)))

    // Un texto en blanco, en la columna del centro (la ayuda y el mensaje de nivel completo)
    method addText(text, row) = self.addText(text, column, row, white)

    // Un texto sin contorno (sobre el papel), centrado en esa columna y esa fila como los de Wollok
    method addSpriteText(text, font, textColumn, row) = spriteText.draw(text, font, textColumn + 0.5, row + 0.5)

    method addText(text, textColumn, row, color) =
        self.addVisual(new MenuText(text = text, position = self.positionAt(textColumn, row), textColor = color))

    // Una imagen de atrás (la cinta, la tarjeta, el globo) o un plato, con su borde de abajo en esa fila
    method addImage(image, row) = self.addVisual(new InfoImage(image = image, position = self.exactPosition(imageColumn, row)))

    // Una posición con decimales que se respeta al dibujar: Wollok redondea a la celda las de game.at
    // (llama a round()), y CellPosition no (ver cellPosition.wlk)
    method exactPosition(x, y) = new CellPosition(x = x, y = y)

    method addVisual(visual) {
        game.addVisual(visual)
        return visual
    }

    // Saca lo dibujado: cada cosa sabe sacarse (un texto con sprites tiene una imagen por letra)
    method remove(texts) {
        texts.forEach({ text => text.hide() })
    }

    // La posición en pantalla de una fila, en la columna del centro (las filas son las de la pantalla;
    // la zona empieza en la 1)
    method positionOfRow(row) = self.positionAt(column, row)

    method positionAt(textColumn, row) = menuManager.levelInfoZone().at(textColumn, row - menuManager.levelInfoZone().origin().y())
}

// Una tecla con lo que hace, dibujada en una imagen con el estilo de las teclas del fondo.
// description es lo que dice (para los tests): la imagen ya lo tiene escrito. No se llama text porque
// Wollok dibuja el text() de cualquier visual, y se vería escrito encima de la imagen.
class KeyHint {
    const property image
    const property description
    const property position

    method isText() = false
    method hide() { game.removeVisual(self) }
}

// Una imagen de la info del nivel que no es un texto: la cinta, la tarjeta, el globo, un plato o una barra
class InfoImage {
    const property image
    const property position

    method isText() = false
    method description() = image
    method hide() { game.removeVisual(self) }
}
