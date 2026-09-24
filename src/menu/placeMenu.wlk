import src.userTools.*
import machines.*
import src.userController.*

object placeMenu{
    var currentPage = 0
    var renderedItems = []

    method currentPage() = currentPage

    method prev(){
        currentPage = 0
        self.renderItems()
    }

    method next(){
        currentPage = 1
        self.renderItems()
    }

    // Slot (1 a 4) de la página actual donde se hizo click, 0 si no fue sobre un slot
    method slotAt(pos){
        var slot = 0

        if (pos.y().between(1, 2)) slot = 1
        if (pos.y().between(4, 5)) slot = 2
        if (pos.y().between(7, 9)) slot = 3
        if (pos.y().between(10, 16)) slot = 4

        // TO-DO Esto podria ponerse en el objeto de cada pagina, para mantener encapsulamiento

        return slot
    }

    // Slot (1 a 4) de la máquina seleccionada en la página actual, 0 si está en otra página
    method selectedSlot() {
        var slot = 0
        var position = 0

        machineManager.machinesOfPage(currentPage).forEach({ factory =>
            position += 1
            if (factory.apply().name() == machineManager.selectedName()) slot = position
        })

        return slot
    }

    // El overlay solo se dibuja si la máquina seleccionada está en la página que se ve
    method updateOverlay() {
        const inCurrentPage = self.selectedSlot() > 0

        if (inCurrentPage && !game.hasVisual(overlay)) game.addVisual(overlay)
        if (!inCurrentPage && game.hasVisual(overlay)) game.removeVisual(overlay)
    }

    method vaciarRenders() {
        renderedItems.forEach({item => game.removeVisual(item)})
        renderedItems = []
    }

    method renderItems() {
        // Dibuja la pagina actual del menu
        // si ya hay algo, vaciarlo
        if (renderedItems.size() > 0) self.vaciarRenders()

        var slot = 0

        machineManager.machinesOfPage(currentPage).forEach({ factory =>
            slot += 1
            // inicializar maquina para obtener los paramaetros (al finalizar la ejecucion no queda referenciada => garbage collector se lo lleva)
            const maquina = factory.apply()
            const altura = slot * 3 - 2

            const renderedMenuItem = new MenuItem(
                name = maquina.name(),
                position = game.at(22, altura)
            )
            game.addVisual(renderedMenuItem)
            renderedItems.add(renderedMenuItem)
        })

        self.updateOverlay()
    }

}

// items del menu

class MenuItem{
    var property name = "item"
    var property position = game.center()
    method image() =  "machines/"+self.name()+"/"+ toolsManager.currentDirection().name() + ".png"

}



object overlay{
    // OVERLAY PARA LOS ELEMENTOS ACTIVOS
    method position() = game.at(21,placeMenu.selectedSlot()*3-3)
    method image() = "overlay.png"
}
