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
import menu.drawing.visuals.*

// La información del nivel, en la zona de la izquierda (levelInfoZone: x 0 a 4, y 1 a 11).
object levelInfoMenu {
    // Centra los textos en la parte azul
    const column = 1.5
    const nameRow = 10
    const hintRow = 9
    const goalTitleRow = 8
    const firstProgressRow = 7
    // Los colores (RRGGBBAA) de los textos de Wollok: amarillo sobre la cinta, blanco sobre el azul.
    const yellow = "FFD015FF"
    const white = "FFFFFFFF"
    const red = "FF5A4DFF"

    // Las imágenes de atrás y de los objetivos (assets/levels/info/, ver makeLevelImages.py)
    const imageColumn = 0.24
    const folder = "levels/info/"

    // Lo dibujado, separado según cuándo se reemplaza
    const energyTexts = new VisualGroup()
    var skipButton = noSkipButton
    const backgrounds = new VisualGroup()  // la cinta y el título de los objetivos
    const levelTexts = new VisualGroup()
    const goalPictures = new VisualGroup()  // una imagen por objetivo

    // Al cargar un nivel: borra todo lo anterior y dibuja el nombre y los objetivos.
    method show(level) {
        [backgrounds, levelTexts, goalPictures, energyTexts].forEach({ group => group.clear() })
        skipButton.hide()
        backgrounds.add(self.image(folder + "ribbon.png", nameRow))
        levelTexts.add(self.text(level.name().toUpperCase(), column, nameRow, yellow))
        // el botón de saltear, si el nivel tiene tutorial
        skipButton = level.tutorial().skipButton(self)
        skipButton.show()
        if (!level.shownGoals().isEmpty()) backgrounds.add(self.image(folder + "goal_title.png", goalTitleRow))
        self.drawProgress(level)
    }

    // ¿Es una celda del botón para saltear el tutorial?
    method isSkipButton(pos) = skipButton.handlesClick(pos)

    // El botón de saltear el tutorial, todavía sin dibujar (lo pide el tutorial del nivel).
    method newSkipButton() = new SkipButton(image = "menu/key_skip.png", position = self.exactPosition(0, hintRow + 0.2), zone = rectangle.of(0, hintRow, 4, 1))

    // Una ayuda debajo del nombre (por ejemplo, "L: volver" en el modo libre).
    method showHint(text) {
        levelTexts.add(self.text(text, column, hintRow, white))
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
        goalPictures.clear()
        self.drawProgress(level)
    }

    // Las imágenes de atrás: la cinta y el título de los objetivos (para los tests)
    method backgroundImages() = backgrounds.visuals().map({ visual => visual.image() })

    // Las imágenes de los objetivos que se ven, en orden (para los tests)
    method goalImages() = goalPictures.visuals().map({ visual => visual.image() })

    // ----------- DIBUJO -----------

    // Por cada objetivo, en su fila: su imagen según cuántos van entregados (tarjeta, plato, texto y barra)
    method drawProgress(level) {
        const goals = level.shownGoals()
        goals.size().times({ number =>
            goalPictures.add(self.image(goals.get(number - 1).progressImage(folder + level.imageKey() + "_goal" + number + "_"), firstProgressRow + 1 - number))
        })
    }

    method text(text, textColumn, row, color) = new MenuText(text = text, position = self.positionAt(textColumn, row), textColor = color)

    // Una imagen de atrás o de un objetivo, con su borde de abajo en esa fila
    method image(image, row) = new Picture(image = image, position = self.exactPosition(imageColumn, row))

    // Una posición con decimales que se respeta al dibujar: Wollok redondea a la celda las de game.at
    method exactPosition(x, y) = new CellPosition(x = x, y = y)

    // La posición en pantalla de una fila, en la columna del centro
    method positionOfRow(row) = self.positionAt(column, row)

    method positionAt(textColumn, row) = hud.levelInfoZone().at(textColumn, row - hud.levelInfoZone().origin().y())
}

// Los niveles sin tutorial no tienen botón de saltear.
object noSkipButton {
    method handlesClick(pos) = false
    method show() {}
    method hide() {}
}

// El botón de saltear el tutorial: una imagen con su tecla, que también se clickea
class SkipButton inherits Picture {
    const zone

    method handlesClick(pos) = zone.contains(pos)
}

// El botón de saltear el tutorial, como parte clickeable de la columna izquierda
object skipTutorialButton {
    method handlesClick(pos) = levelInfoMenu.isSkipButton(pos)
    method onClick(pos) { levelManager.skipTutorial() }
}
