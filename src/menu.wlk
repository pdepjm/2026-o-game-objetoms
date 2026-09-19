import maquinas.*
object menu{
    var paginaActual = 0

    method prev(){
            paginaActual = 0
            game.removeVisual(firstPage)
        }

    method next(){
        paginaActual = 1
        game.addVisual(firstPage)
    }
    method obtenerElemento(pos){
        var elemento = 0

        // Guard clause: se hizo click fuera de las columnas de elementos
        if (pos.x()>=24 || pos.x()<=21){
            return  0
		}

		// se establecen lambdas que instancien las maquinas/herramientas.
        if(paginaActual ==0){
            if (pos.y()>=1 && pos.y() <=2){
                elemento = 4
            }

            if (pos.y()>=4 && pos.y() <=5){
                elemento = 3
            }

            if (pos.y()>=7 && pos.y() <=9){
                elemento = 2
            }

            if (pos.y()>=11 && pos.y() <=13){
                elemento = 1
            }
        }

        if(paginaActual ==1){
            if (pos.y()>=1 && pos.y() <=2){
                elemento = 8
            }

            if (pos.y()>=4 && pos.y() <=5){
                elemento = 7
            }

            if (pos.y()>=7 && pos.y() <=9){
                elemento = 6
            }

            if (pos.y()>=11 && pos.y() <=13){
                elemento = 5
            }
        }

        return elemento
    }
    
}


object firstPage{
    var property position = game.at(21, 0)
    var property image = "menu1.png"
    
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