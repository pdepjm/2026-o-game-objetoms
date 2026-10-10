import tools.toolsManager.*
import machines.machineManager.*
import menu.menuManager.*

object placeMenu{
    var currentPage = 0
    var renderedItems = []

    // Sólo se dibuja mientras es el panel activo (herramienta place)
    var visible = false

    method currentPage() = currentPage

    // Mensajes que le manda menuManager

    method show() {
        visible = true
        self.renderItems()
    }

    method hide() {
        visible = false
        self.vaciarRenders()
        if (game.hasVisual(overlay)) game.removeVisual(overlay)
    }

    // Selecciona la máquina del slot clickeado, si hay una en ese slot
    method onClick(pos) {
        const slot = self.slotAt(pos)
        const pageMachines = machineManager.machinesOfPage(currentPage)

        if (slot > 0 && slot <= pageMachines.size()) {
            machineManager.select(pageMachines.get(slot - 1))
            self.updateOverlay()
        }
    }

    // Cambiar de página sólo redibuja si el panel se está viendo
    method prev(){
        currentPage = 0
        if (visible) self.renderItems()
    }

    method next(){
        currentPage = 1
        if (visible) self.renderItems()
    }


    // GETTERS DE POSICIONES DE LOS SLOTS 
    /* 
        El metodo calcular el desplazamiento dentro de la zona elegida. Es decir, si el slot = 4,
        entonces rowOffset devuelve 1. Ese 1 representa cuanto se debe mover en Y para dibujar la
        maquina en el menu.

        Este cambio provoca que el 1er slot, sea el mas alto.
    */
    method rowOffset(slot) = (4 - slot) * 3 + 1

    // Devuelve el numero de slot en el que se clickeo, responde a ¿En qué slot cayó este click?
    method slotAt(pos){
        var slot = 0

        if (pos.y().between(10, 16)) slot = 1
        if (pos.y().between(7, 9)) slot = 2
        if (pos.y().between(4, 5)) slot = 3
        if (pos.y().between(1, 2)) slot = 4

        // TO-DO Esto podria ponerse en el objeto de cada pagina, para mantener encapsulamiento

        return slot
    }

    // Es utilizado para actualizar el overlay, responde a ¿En qué slot está la máquina que tengo elegida?
    method selectedSlot() {
        var slot = 0
        var position = 0

        machineManager.machinesOfPage(currentPage).forEach({ factory =>
            position += 1
            if (factory.apply().name() == machineManager.selectedName()) slot = position
        })

        return slot
    }

    // -------------------------------------------------------------

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



    // DIBUJAR LAS MAQUINAS EN EL MENU
    
    // Remueve de la pantalla todos los items dibujados hasta ese momento
    method vaciarRenders() {
        renderedItems.forEach({item => game.removeVisual(item)})
        renderedItems = []
    }

    // Renderiza en pantalla las maquinas que pertenecen a la pagina
    // Para cambiar el orden de las maquinas, modificar el orden de la lista "machines" (machineManager).
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

            const renderedMenuItem = new MenuItem(
                name = maquina.name(),
                position = menuManager.interactiveZone().at(1, self.rowOffset(slot))
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
        image = "machines/" + name + "/" + toolsManager.currentDirection().name() + "_menu.png"
    }
}



object overlay{
    // OVERLAY PARA LOS ELEMENTOS ACTIVOS
    // RENDIMIENTO: antes la posición se calculaba en cada frame con placeMenu.selectedSlot(),
    // que crea varias máquinas: sólo el overlay costaba ~12 ms por frame (de 17 disponibles).
    // Ahora la posición se guarda y placeMenu.updateOverlay() la cambia cuando hace falta.
    // Sin setter: desde afuera sólo se lo puede mover a un slot (moveToSlot).
    var position = menuManager.interactiveZone().origin()

    method position() = position
    method image() = "overlay.png"

    // Se ubica al lado del slot (1 a 4) de la máquina seleccionada: una fila más abajo
    // que el ítem, porque el overlay mide 4 filas y el ítem 2 (queda centrado)
    method moveToSlot(slot) {
        position = menuManager.interactiveZone().at(0, placeMenu.rowOffset(slot) - 1)
    }
}
