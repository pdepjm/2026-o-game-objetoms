import machines.*
import src.userController.*

object placeMenu{
    var currentPage = 0
    var property machineSelected = 1
    var renderedItems = []

    // Resalta la herramienta seleccionada solo si pertenece a la pagina que se esta mostrando

    method prev(){
        currentPage = 0
        self.renderItems()
    }

    method next(){
        currentPage = 1
        self.renderItems()
    }

    method elementEn(pos){
        var element = 0

        if (pos.y().between(1, 2)) element = 1
        if (pos.y().between(4, 5)) element = 2
        if (pos.y().between(7, 9)) element = 3
        if (pos.y().between(10, 16)) element = 4

        // TO-DO Esto podria ponerse en el objeto de cada pagina, para mantener encapsulamiento

        if (element == 0) return 0

        return element + currentPage * 4
    }

    // Se llama solo cuando la selección fue aceptada por machineManager
    method seleccionar(tool){
        machineSelected = tool
    }

    method vaciarRenders() {
        renderedItems.forEach({item => game.removeVisual(item)})
        renderedItems = []
    }

    method renderItems() {
        // Dibuja la pagina actual del menu
        // si ya hay algo, vaciarlo
        if (renderedItems.size() > 0) self.vaciarRenders()

        //dibujar los items de la pagina actual
        const offset = currentPage * 4
        const claves = machineManager.machines().keys().asList().filter({clave => clave.between(offset+1, offset+4)})

        //para cada item del diccionario, chequeamos estar dentro del offset segun el nro de pagina.
        claves.forEach({clave =>
            // inicializar maquina para obtener los paramaetros (al finalizar la ejecucion no queda referenciada => garbage collector se lo lleva)
            const maquina = machineManager.machines().get(clave).apply()
            const positionEnPagina = clave - offset
            const altura = positionEnPagina * 3 - 2

            const renderedMenuItem = new menuItem(
                name = maquina.name(),
                position = game.at(22, altura)
            )
            game.addVisual(renderedMenuItem)
            renderedItems.add(renderedMenuItem)
        })
    }

}

// items del menu

class menuItem{
    const direcciones = ["right", "down", "left", "up"]
    var property name = "item"
    var property position = game.center()
    method image() =  "machines/"+self.name()+"/"+ direcciones.get(Tools.currentRotation()) + ".png"

}



object overlay{
    // OVERLAY PARA LOS ELEMENTOS ACTIVOS
    method position() = game.at(21,placeMenu.machineSelected()*3-3)
    method image() = "overlay.png"
}
