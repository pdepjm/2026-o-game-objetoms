import maquinas.*
object menu{
    var paginaActual = 0

    method position() = game.at(21,0)


    var property image = "menu0.png"

    method prev(){
        paginaActual = 0
        self.image("menu0.png")
    }

    method next(){
        paginaActual = 1
        self.image("menu1.png")
    }
    method obtenerElemento(pos){
        var region = 0

        // Guard clause: se hizo click fuera de las columnas de elementos
        if (pos.x()>=24 || pos.x()<=21){
            return  0
		}

        if (pos.y()>=1 && pos.y() <=2){
            region = 4
        }

        if (pos.y()>=4 && pos.y() <=5){
            region = 3
        }

        if (pos.y()>=7 && pos.y() <=9){
            region = 2
        }

        if (pos.y()>=11 && pos.y() <=13){
            region = 1
        }
		// se establecen lambdas que instancien las maquinas/herramientas.
        // TO-DO Esto podria ponerse en el objeto de cada pagina, para mantener encapsulamiento 
      

        return region + paginaActual * 4
    }
    
}






// Maneja cual es la Tool Seleccionada actual
object toolManager{
	// Tenemos dos motedos.
	// selectedTool va a devolver una nueva instancia de la herramienta seleccionada.
	// chooseTool va a validar el click y va a actualizar selectedTool segun corresponda.

	// herramienta default y aplicar la lambda de la herramietna seleccioanda
	var selectedTool =  {=> new Cinta()}
	method selectedTool() = selectedTool.apply()
	method chooseTool(pos){
        
        var elemento = menu.obtenerElemento(pos)
		// Este método, depende donde se hizo click, establece la herramienta seleccionada
		// a la clase correspondiente al elemento

		// se establecen lambdas que instancien las maquinas/herramientas.
		if (elemento == 4){
			selectedTool =  {=> new Cinta()}
		}

		if (elemento == 3){
			selectedTool = {=> new Horno()}
		}

        if (elemento == 5){
			selectedTool = {=> new Freidora()}
		}
	}
}