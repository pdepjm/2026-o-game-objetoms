import src.userTools.*
import machines.*
import src.userController.*
import src.board.CellPosition

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

    // El overlay solo se dibuja si la máquina seleccionada está en la página que se ve.
    // Se llama sólo cuando cambia algo (al elegir una máquina o cambiar de página),
    // y acá se le fija la posición al overlay. selectedSlot() es caro (crea máquinas
    // para comparar nombres), así que NO hay que llamarlo desde algo que se dibuja.
    method updateOverlay() {
        const slot = self.selectedSlot()
        const inCurrentPage = slot > 0

        if (inCurrentPage) overlay.moveToSlot(slot)
        if (inCurrentPage && !game.hasVisual(overlay)) game.addVisual(overlay)
        if (!inCurrentPage && game.hasVisual(overlay)) game.removeVisual(overlay)
    }

    method vaciarRenders() {
        renderedItems.forEach({item => game.removeVisual(item)})
        renderedItems = []
    }

    method renderItems() {

        self.updateOverlay()
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
                position = new CellPosition(x = 22, y = altura)
            )
            renderedMenuItem.updateImage()
            game.addVisual(renderedMenuItem)
            renderedItems.add(renderedMenuItem)
        })


    }

    // Actualiza la imagen de los items del menú. Lo llama toolsManager cuando cambia
    // la dirección (W/A/S/D), que es lo único que cambia esas imágenes.
    method updateImages() {
        renderedItems.forEach({ item => item.updateImage() })
    }

}

// items del menú

// RENDIMIENTO: todo lo que Wollok Game le pide a un visual en cada frame (image y position)
// tiene que ser un dato ya guardado, no algo que se calcule. Se dibuja ~60 veces por segundo.
class MenuItem{
    var property name = "item"
    var property position = game.center()

    // La imagen se guarda y se recalcula sólo cuando cambia la dirección (ver updateImage).
    // Antes se armaba el texto en cada frame.
    // Sin setter: desde afuera sólo se le puede pedir que se actualice (updateImage).
    var image = null

    method image() = image

    method updateImage() {
        image = "machines/" + name + "/" + toolsManager.currentDirection().name() + ".png"
    }
}



object overlay{
    // OVERLAY PARA LOS ELEMENTOS ACTIVOS
    // RENDIMIENTO: antes la posición se calculaba en cada frame con placeMenu.selectedSlot(),
    // que crea varias máquinas: sólo el overlay costaba ~12 ms por frame (de 17 disponibles).
    // Ahora la posición se guarda y placeMenu.updateOverlay() la cambia cuando hace falta.
    // Sin setter: desde afuera sólo se lo puede mover a un slot (moveToSlot).
    var position = new CellPosition(x = 21, y = 0)

    method position() = position
    method image() = "overlay.png"

    // Se ubica al lado del slot (1 a 4) de la máquina seleccionada
    method moveToSlot(slot) {
        position = new CellPosition(x = 21, y = slot * 3 - 3)
    }
}
