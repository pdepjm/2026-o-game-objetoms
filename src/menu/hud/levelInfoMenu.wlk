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
import menu.hud.hud.*
import levels.levelManager.*
import menu.drawing.texts.*
import cellPosition.*
import menu.drawing.spriteFonts.*
import menu.drawing.visuals.*

// La información del nivel, en la zona de la izquierda (levelInfoZone: x 0 a 4, y 1 a 11).
object levelInfoMenu {
    // Centra los textos en la parte azul
    const column = 1.5
    const nameRow = 10
    const hintRow = 9
    const goalTitleRow = 8
    const firstProgressRow = 7
    const completedRow = 5
    // Los objetivos: el texto un poco arriba del centro de su fila y corrido a la derecha
    const goalTextColumn = 2
    const goalTextOffset = 0.18
    const goalBarOffset = 0.14
    const goalBarColumn = 1.3
    // La tecla para seguir (assets/menu/key_*.png, 200x25)
    const keyHintRow = 4.25
    // Los colores (RRGGBBAA) de los textos de Wollok: amarillo sobre la cinta, blanco sobre el azul.
    const yellow = "FFD015FF"
    const white = "FFFFFFFF"
    const red = "FF5A4DFF"

    // Las imágenes de atrás
    const imageColumn = 0.24

    // Lo dibujado, separado según cuándo se reemplaza
    const energyTexts = new VisualGroup()
    var skipButton = noSkipButton
    const levelTexts = new VisualGroup()
    const progressTexts = new VisualGroup()
    const completedTexts = new VisualGroup()  // el mensaje de nivel completo

    // Al cargar un nivel: borra todo lo anterior y dibuja el nombre y los objetivos.
    method show(level) {
        [levelTexts, progressTexts, completedTexts, energyTexts].forEach({ group => group.clear() })
        levelTexts.add(self.image("menu/info/ribbon.png", nameRow))
        levelTexts.add(self.text(level.name().toUpperCase(), column, nameRow, yellow))
        // el botón de saltear, si el nivel tiene tutorial
        skipButton = level.tutorial().skipButton(self)
        skipButton.showIn(levelTexts)
        const goals = level.shownGoals().size()
        if (goals > 0) {
            // la tarjeta va del título hasta el borde de abajo de la fila del último objetivo
            levelTexts.add(self.image("menu/info/card_" + goals + ".png", goalTitleRow - goals))
            levelTexts.keep(self.spriteText("OBJETIVO", labelFont, column, goalTitleRow))
        }
        self.drawProgress(level)
    }

    // ¿Es una celda del botón para saltear el tutorial?
    method isSkipButton(pos) = skipButton.handlesClick(pos)

    // El botón de saltear el tutorial, todavía sin dibujar (lo pide el tutorial del nivel).
    method newSkipButton() = new KeyHint(image = "menu/key_skip.png", descriptionText = "skip", position = self.exactPosition(0, hintRow + 0.2), zone = rectangle.of(0, hintRow, 4, 1))

    // Una ayuda debajo del nombre (por ejemplo, "L: volver" en el modo libre).
    method showHint(text) {
        levelTexts.add(self.text(text, hintRow))
    }

    // El contador de energía, debajo de la tarjeta de objetivos (rojo si se pasó del límite).
    method updateEnergy(level, total) {
        energyTexts.clear()
        level.energyLimit().showIn(self, total, goalTitleRow - level.shownGoals().size() - 1)
    }

    // Lo llama el límite de energía del nivel: escribe el contador, en rojo si no alcanza la energía
    method showEnergy(text, row, enough) {
        energyTexts.add(self.text(text, column, row, if (enough) white else red))
    }

    // Lo que dice el contador de energía (para los tests)
    method energyMessage() = energyTexts.visuals().map({ visual => visual.description() })

    // Cambió el progreso (una entrega, o se apagó la simulación): reemplaza sólo los objetivos
    method updateProgress(level) {
        progressTexts.clear()
        self.drawProgress(level)
    }

    // Se ganó el nivel: el mensaje y la tecla para seguir
    method showCompleted(ending) {
        completedTexts.clear()
        ending.showIn(self)
    }

    method showNextLevelHint() {
        completedTexts.add(self.text("¡Nivel completo!", completedRow))
        completedTexts.add(self.keyHint("menu/key_next.png", "N: siguiente", keyHintRow))
    }

    method showGameOverHint() {
        completedTexts.add(self.text("¡Fin del juego!", completedRow))
        completedTexts.add(self.keyHint("menu/key_restart.png", "0: reiniciar", keyHintRow))
    }

    // Lo que dice el mensaje de nivel completo, en orden (para los tests)
    method completedMessage() = completedTexts.visuals().map({ visual => visual.description() })

    // Los textos del nombre, la ayuda y el título del objetivo, en orden (para los tests)
    method levelMessage() = levelTexts.visuals().flatMap({ visual => visual.textLines() })

    // Lo que dicen los objetivos, en orden (para los tests)
    method progressMessage() = progressTexts.visuals().flatMap({ visual => visual.textLines() })

    // Las barras de los objetivos que se ven, en orden (para los tests)
    method progressBars() = progressTexts.visuals().flatMap({ visual => visual.barImages() })

    // ----------- DIBUJO -----------

    // Por cada objetivo, en su fila: la imagen del plato, su texto y su barra
    method drawProgress(level) {
        var row = firstProgressRow
        level.shownGoals().forEach({ goal =>
            progressTexts.add(self.image(goal.image(), row))
            progressTexts.keep(self.spriteText(goal.progressText(), textFont, goalTextColumn, row + goalTextOffset))
            progressTexts.add(new ProgressBarImage(image = "menu/info/bar_" + goal.progressTenths() + ".png", position = self.exactPosition(goalBarColumn, row + goalBarOffset)))
            row -= 1
        })
    }

    // Una imagen de 200x25 que empieza en el borde izquierdo, alineada con las teclas del fondo
    method keyHint(image, description, row) = new KeyHint(image = image, descriptionText = description, position = self.exactPosition(0, row))

    // Un texto en blanco, en la columna del centro (la ayuda y el mensaje de nivel completo)
    method text(text, row) = self.text(text, column, row, white)

    method text(text, textColumn, row, color) = new MenuText(text = text, position = self.positionAt(textColumn, row), textColor = color)

    // Un texto sin contorno (sobre el papel), centrado en esa columna y esa fila como los de Wollok.
    method spriteText(text, font, textColumn, row) = spriteText.draw(text, font, textColumn + 0.5, row + 0.5)

    // Una imagen de atrás (la cinta, la tarjeta, el globo) o un plato, con su borde de abajo en esa fila
    method image(image, row) = new InfoImage(image = image, position = self.exactPosition(imageColumn, row))

    // Una posición con decimales que se respeta al dibujar: Wollok redondea a la celda las de game.at
    method exactPosition(x, y) = new CellPosition(x = x, y = y)

    // La posición en pantalla de una fila, en la columna del centro
    method positionOfRow(row) = self.positionAt(column, row)

    method positionAt(textColumn, row) = hud.levelInfoZone().at(textColumn, row - hud.levelInfoZone().origin().y())
}

// Una tecla con lo que hace, dibujada en una imagen con el estilo de las teclas del fondo.
object noSkipButton {
    method handlesClick(pos) = false
    method showIn(group) {}
}

// Una imagen de la info del nivel que no es un texto: la cinta, la tarjeta, el globo
class InfoImage inherits Picture {
    method textLines() = []
    method barImages() = []
    method description() = image
}

class KeyHint inherits InfoImage {
    const descriptionText
    // Dónde se la clickea: sólo el botón de saltear el tutorial (las otras ayudas no se clickean)
    const zone = nowhere

    override method description() = descriptionText
    method handlesClick(pos) = zone.contains(pos)
    method showIn(group) { group.add(self) }
}

// La barra de progreso de un objetivo
class ProgressBarImage inherits InfoImage {
    override method barImages() = [image]
}

// El botón de saltear el tutorial, como parte clickeable de la columna izquierda
object skipTutorialButton {
    method handlesClick(pos) = levelInfoMenu.isSkipButton(pos)
    method onClick(pos) { levelManager.skipTutorial() }
}
