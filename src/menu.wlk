import maquinas.*

object menu{
    var property image = "menu0/menu0_default.png"
    var paginaActual = 0
    var tool_selected = 0

    method position() = game.at(21,0)

    // Resalta la herramienta seleccionada solo si pertenece a la pagina que se esta mostrando
    method actualizarImagen() {
        const carpeta = "menu" + paginaActual.toString()
        const elementoEnPagina = tool_selected - paginaActual * 4

        if (elementoEnPagina.between(1, 4))
            image = carpeta + "/" + carpeta + "_elem" + elementoEnPagina.toString() + "_selected.png"
        else
            image = carpeta + "/" + carpeta + "_default.png"
    }

    method prev(){
        paginaActual = 0
        self.actualizarImagen()
    }

    method next(){
        paginaActual = 1
        self.actualizarImagen()
    }

    method elementoEn(pos){
        var elemento = 0

        if (pos.y().between(1, 2)) elemento = 4

        if (pos.y().between(4, 5)) elemento = 3

        if (pos.y().between(7, 9)) elemento = 2

        if (pos.y().between(10, 13)) elemento = 1

        // TO-DO Esto podria ponerse en el objeto de cada pagina, para mantener encapsulamiento

        if (elemento == 0) return 0

        return elemento + paginaActual * 4
    }

    // Se llama solo cuando la selección fue aceptada por toolManager
    method seleccionar(tool){
        tool_selected = tool
        self.actualizarImagen()
    }
}

// Maneja cual es la Tool Seleccionada actual
object toolManager{
	// Tenemos dos motedos.
	// selectedTool va a devolver una nueva instancia de la herramienta seleccionada.
	// chooseTool va a validar el click y va a actualizar selectedTool segun corresponda.

	const herramientas = new Dictionary()

	var selectedTool =  {=> new Cinta()}

	// Orientación con la que se crean las máquinas: 0 = right, 1 = down, 2 = left, 3 = up
	var orientacion = 0

	method initialize() {
		herramientas.put(1, {=> new Cinta()})
        herramientas.put(2, {=> new Ensambladora()})
		herramientas.put(3, {=> new Horno()})
        herramientas.put(4, {=> new Cortadora()})
		herramientas.put(5, {=> new Freidora()})
		herramientas.put(6, {=> new Dispensadora()})
	}

	method selectedTool() {
		const maquina = selectedTool.apply()
		maquina.orientar(orientacion)
		return maquina
	}

	method rotar() {
		orientacion = (orientacion + 1) % 4
	}

	method chooseTool(pos){
		const elemento = menu.elementoEn(pos)

		if (herramientas.containsKey(elemento)) {
			selectedTool = herramientas.get(elemento)
			menu.seleccionar(elemento)
		}
	}
}