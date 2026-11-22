// Buffet Albert Einstein - conoce los menús y reenvía a cada uno lo que pasa en el juego.
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

import src.cellPosition.CellPosition
import menu.placeMenu.*
import menu.editMenu.*
import menu.modeBanner.*
import menu.sideButtons.*
import tools.toolsManager.*
import sound.sfx.*
import wollok.game.*
import board.*

// Único que conoce los menús: el resto del juego le avisa lo que pasó (eventos)
// y él se lo reenvía al menú que corresponda.
//
// Los paneles de la zona interactiva (placeMenu, editMenu y emptyMenu) responden a los
// mismos mensajes, así el manager no tiene que preguntar de cuál se trata:
// show(), hide() y onClick(pos).
// Lo que sólo tiene sentido en place (cambiar de página y refrescar las imágenes de las
// máquinas) se lo manda directo a placeMenu, que lo ignora si no se está viendo.

object menuManager {
    const levelInfoZone = new Zone(
        minX = 0,
        maxX = 4,
        minY = 1,
        maxY = 11
    )
    // El cartel COLOCANDO / EDITANDO
    const bannerZone = new Zone(
        minX = 18,
        maxX = 21,
        minY = 12,
        maxY = 12
    )
    const interactiveZone = new Zone(
        minX = 18,
        maxX = 21,
        minY = 0,
        maxY = 11
    )

    // Panel que se ve en la zona interactiva
    var activePanel = emptyMenu

    // Qué panel le toca a cada modo: colocando, el de colocar; editando, el de editar
    const panels = new Dictionary()

    method initialize() {
        panels.put(placingMode, placeMenu)
        panels.put(editingMode, editMenu)
    }

    // Lo llama startMenu al empezar a jugar: el cartel, los botones de abajo a la izquierda y el panel
    // del modo
    method setUp() {
        modeBanner.show()
        sideButtons.show()
        self.modeChanged(toolsManager.mode())
    }

    // EVENTOS

    // Cambió el modo (toolsManager.changeMode): el cartel y el panel de la derecha
    method modeChanged(mode) {
        modeBanner.change(mode)

        const newPanel = self.panelFor(mode)
        if (newPanel != activePanel) {
            activePanel.hide()
            activePanel = newPanel
            activePanel.show()
        }
    }

    // Cambió la dirección con la que se colocan las máquinas (toolsManager.currentDirection)
    method directionChanged() {
        placeMenu.updateImages()
    }

    // Q y E: la máquina anterior o la siguiente del menú de colocar (si estaba editando, vuelve a colocar)
    method chooseMachine(step) {
        toolsManager.stopEditing()
        placeMenu.chooseNext(step)
    }

    // Click dentro de la zona interactiva (toolsManager.onClick)
    method onClick(pos) {
        activePanel.onClick(pos)
    }

    method panelFor(mode) = panels.getOrElse(mode, { => emptyMenu })

    // Metodo para saber si se clickeo en la zona interactiva
    method inInteractiveMenu(pos) = interactiveZone.contains(pos)

    // Getters
    method levelInfoZone() = levelInfoZone
    method bannerZone() = bannerZone
    method interactiveZone() = interactiveZone
}

// Panel sin contenido: el que se ve antes de empezar a jugar
object emptyMenu {
    method show() {}
    method hide() {}
    method onClick(pos) {}
}
