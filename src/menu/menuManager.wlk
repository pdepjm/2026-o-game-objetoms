import src.cellPosition.CellPosition
import menu.placeMenu.*
import menu.editMenu.*
import menu.toolBar.*
import tools.toolsManager.*
import tools.userTools.*
import wollok.game.*

class Zone {
    const minX
    const maxX
    const minY
    const maxY

    method contains(pos) = pos.x().between(minX, maxX) && pos.y().between(minY, maxY)

    // Posicion relativa desde la esquina inferior izquierda
    method at(dx, dy) = new CellPosition(x= minX + dx, y= minY + dy)

    // Getter de posicion inicial
    method origin() = self.at(0, 0)
}

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
        maxY = 14
    )
    const toolBarZone = new Zone(
        minX = 21,
        maxX = 24,
        minY = 15,
        maxY = 15
    )
    const interactiveZone = new Zone(
        minX = 21,
        maxX = 24,
        minY = 1,
        maxY = 14
    )

    // Panel que se ve en la zona interactiva
    var activePanel = emptyMenu

    // Qué panel le toca a cada herramienta (delete y rotate no muestran nada, ver panelFor)
    const panels = new Dictionary()

    method initialize() {
        panels.put(place, placeMenu)
        panels.put(edit, editMenu)
    }

    // Lo llama main al arrancar: muestra la barra y el panel de la herramienta elegida
    method setUp() {
        toolBar.show()
        self.toolChanged(toolsManager.selectedTool())
    }

    // EVENTOS

    // Cambió la herramienta (toolsManager.select)
    method toolChanged(tool) {
        toolBar.refresh()

        const newPanel = self.panelFor(tool)
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

    // Pasar de página (teclas Q y E). Sólo el panel de place tiene páginas.
    method prevPage() {
        placeMenu.prev()
    }

    method nextPage() {
        placeMenu.next()
    }

    // Click dentro de la zona interactiva (toolsManager.onClick)
    method onClick(pos) {
        activePanel.onClick(pos)
    }

    method panelFor(tool) = panels.getOrElse(tool, { => emptyMenu })

    // Metodo para saber si se clickeo en la zona interactiva
    method inInteractiveMenu(pos) = interactiveZone.contains(pos)

    // Getters
    method levelInfoZone() = levelInfoZone
    method toolBarZone() = toolBarZone
    method interactiveZone() = interactiveZone
}

// Panel sin contenido: lo usan las herramientas que todavía no muestran nada
object emptyMenu {
    method show() {}
    method hide() {}
    method onClick(pos) {}
}
