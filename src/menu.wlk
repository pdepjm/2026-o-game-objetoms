import maquinas.*
import src.userController.*

object menu{
    var paginaActual = 0
    var property tool_selected = 1


    // Resalta la herramienta seleccionada solo si pertenece a la pagina que se esta mostrando

    method prev(){
        paginaActual = 0
        self.renderItems()
    }

    method next(){
        paginaActual = 1
        self.renderItems()
    }

    method elementoEn(pos){
        var elemento = 0

        if (pos.y().between(1, 2)) elemento = 1
        if (pos.y().between(4, 5)) elemento = 2
        if (pos.y().between(7, 9)) elemento = 3
        if (pos.y().between(10, 13)) elemento = 4

        // TO-DO Esto podria ponerse en el objeto de cada pagina, para mantener encapsulamiento

        if (elemento == 0) return 0

        return elemento + paginaActual * 4
    }

    // Se llama solo cuando la selección fue aceptada por MachineManager
    method seleccionar(tool){
        tool_selected = tool
    }

    var renderedItems = []

    method renderItems() {

        // Dibuja la pagina actual del menu
        // si ya hay algo, vaciarlo
        //TO-DO: delegar
        if (renderedItems.size() > 0) {
            renderedItems.forEach({item => game.removeVisual(item)})
            renderedItems = []
        }

        //dibujar los items de la pagina actual
        const rotacionActual = Tools.currentRotation()
        const offset = paginaActual * 4
        const claves = MachineManager.maquinas().keys().asList()

        //para cada item del diccionario, chequeamos estar dentro del offset segun el nro de pagina.
        claves.forEach({clave =>
            if (clave > offset && clave <= offset + 4) {
                // inicializar maquina para obtener los paramaetros (al finalizar la ejecucion no queda referenciada => garbage collector se lo lleva)
                const maquina = MachineManager.maquinas().get(clave).apply()
                const posicionEnPagina = clave - offset
                const altura = posicionEnPagina * 3 - 2

                const renderedMenuItem = new menuItem(
                    name = maquina.name(),
                    position = game.at(22, altura)
                )
                game.addVisual(renderedMenuItem)
                renderedItems.add(renderedMenuItem)
            }
        })
    }


}

// items del menu

class menuItem{
    const direcciones = ["right", "down", "left", "up"]
    var property name = "item"
    var property position = game.center() 
    method image() =  "maquinas/"+self.name()+"/"+ direcciones.get(Tools.currentRotation()) + ".png"
    
}



object overlay{
    // OVERLAY PARA LOS ELEMENTOS ACTIVOS
    method position() = game.at(21,menu.tool_selected()*3-3)
    method image() = "overlay.png"
}

