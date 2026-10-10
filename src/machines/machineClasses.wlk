// Maneja el que es cada cosa

import wollok.game.*
import tools.toolsManager.*
import board.*
import simulation.simulationEngine.*
import simulation.animationEngine.*

// Clase de máquina
// Hay que agregar los métodos de rotar, de procesar, etc.
// Las máquinas se pasan los items de mano en mano: cada una le pregunta a la
// siguiente si puede recibir (canReceive) y se lo entrega (receive).
// Cuántos items guarda cada máquina es asunto de cada subclase.
//
// Ciclo de vida de una máquina en la simulación:
// - start(): al prender la simulación. Busca a su vecina y agenda lo que necesite.
// - use(): cuando llega el paso que ella misma agendó en el simulationEngine.
// - reset(): al apagar la simulación. Suelta los items que tenía.
//
// Cuando la de adelante está llena, una máquina no pregunta en cada paso: se anota
// (waitForNext) y se duerme. Por eso TODA máquina que se libere tiene que llamar a
// wakeWaiting(), o las que esperan no se despiertan nunca.


// Reproduce animaciones frame a frame (carpetas de PNG, ver FrameAnimation) con el animationEngine.
class MachineAnimator {
	// ----------- ATRIBUTOS -----------
	var animation = null	// la animación que se está mostrando (null si no hay ninguna)
	var frame = 0			// frame que se está mostrando
	var onFinish = null		// bloque que se ejecuta al terminar (null si no hay)

	// ----------- METODOS ABSTRACTOS -----------
	method showFrame(path)	// muestra la imagen de un frame (lo implementa MachineSprite)

	// ----------- REPRODUCCION -----------
	// Empieza a mostrar la animación desde el primer frame. Si ya había otra, la reemplaza.
	// Al terminar se ejecuta afterBlock, que puede encadenar otra animación con play.
	// OJO: afterBlock corre dentro del tick del animationEngine: ahí no se puede mover
	// un item ni cortar la animación (ver playThenWake en Machine).
	method play(anAnimation, afterBlock) {
		// si ya se estaba animando, ya está en la lista de animados
		if (!self.animando()) animationEngine.animar(self)
		animation = anAnimation
		// Si se llama fuera del tick (por ejemplo desde use(), que en cada paso corre antes
		// que las animaciones), el tick que viene no tiene que saltear el primer frame.
		// Si se llama dentro del tick (encadenada desde el bloque del final), ese tick ya pasó.
		frame = if (animationEngine.ticking()) 0 else -1
		onFinish = afterBlock
		self.showFrame(animation.frames().first())
	}

	// Corta la animación donde esté, sin ejecutar el bloque del final
	// (se usa al apagar la simulación).
	method stopAnimation() {
		if (self.animando()) animationEngine.terminar(self)
		animation = null
		onFinish = null
	}



	// ----------- CONTRATO CON EL ANIMATION ENGINE -----------
	method animando() = animation !== null

	// Un paso de animación: muestra el frame siguiente.
	// El último frame se ve un paso entero, y recién en el paso siguiente termina.
	method avanzar() {
		frame += 1
		if (frame < animation.size()) {
			self.showFrame(animation.frames().get(frame))
		} else {
			const afterBlock = onFinish
			onFinish = null
			// Mientras corre el bloque sigue "animando", así si encadena otra animación con
			// play no se vuelve a anotar en la lista (ya está, y se la está recorriendo).
			if (afterBlock !== null) afterBlock.apply()
			// Si el bloque no arrancó otra animación (frame se habría vuelto a 0), terminó.
			if (frame >= animation.size()) {
				animation = null
				animationEngine.avisarLlegada()
			}
		}
	}
}


// Esta clase modifica el dibujo de las maquinas: donde se dibuja, que muestra y las animaciones frame a frame
// Todo lo relacionado con las imagenes van aca
class MachineSprite inherits MachineAnimator{
	// ----------- ATRIBUTOS -----------
	var property position = game.origin()
	var image = null	// Se establece al inicializar

	// ----------- METODOS ABSTRACTOS -----------
	method name()	// Hace referencia a la carpeta donde se guardan sus imagenes
	method direction()	// Hacia donde mira, para elegir la rotacion

	// ----------- INICIALIZACION -----------
	// OJO: Wollok inicializa los atributos recién la primera vez que se leen, no al crear
	// el objeto. Sin esto, una máquina toma la dirección que esté seleccionada cuando alguien
	// la lee por primera vez, y no la que había al crearla. Calcular la imagen acá lee
	// direction, y así queda fijada en el momento de crear la máquina.
	override method initialize() {
		super()
		image = self.staticImage()
	}

	// ----------- DESPLAZAMIENTO DE LA IMAGEN -----------
	// Sirven para desplazar la imagen antes de colocarla
	method offsetX() = 0
	method offsetY() = 0

	// ----------- IMAGENES -----------
	method image() = image

	// La máquina apagada: al colocarla, rotarla y con la simulación apagada
	method staticImage() = "machines/"+self.name()+"/"+self.direction().name() + "_game.png"

	// La máquina andando, mientras la simulación está prendida. Por defecto sigue quieta:
	// se anima frame a frame cuando hace algo. Las máquinas con GIF lo sobrescriben con gifImage().
	method runningImage() = self.staticImage()

	// El GIF de la máquina andando (sólo para las que se animan con GIF, como la cinta)
	method gifImage() = "machines/"+self.name()+"/"+self.direction().name() + ".gif"

	// La imagen del menú de máquinas, según la dirección elegida para colocarla
	method menuImage(aDirection) = "machines/"+self.name()+"/"+aDirection.name() + "_menu.png"

	// ----------- ESTADOS DEL DIBUJO -----------
	// Con la simulación apagada se ve quieta (staticImage) y prendida, animada (runningImage).
	method showStatic() {
		image = self.staticImage()
	}
	method showRunning() {
		image = self.runningImage()
	}

	// ----------- INSTANCIACION DE ANIMACIONES -----------
	// Muestra un frame de una animación (ver MachineAnimator)
	override method showFrame(path) { image = path }

	// Una animación de acción de la máquina: la carpeta machines/<name>/<direccion>_<accion>/
	// Por ejemplo, actionAnimation("dispense", 8) para un dispenser hacia la derecha
	// usa machines/Dispenser/right_dispense/0.png ... 7.png
	method actionAnimation(action, frameCount) =
		new FrameAnimation(path = "machines/"+self.name()+"/"+self.direction().name()+"_"+action, frameCount = frameCount)
}	

// Esta clase se encarga de la logica general de las maquinas
class Machine inherits MachineSprite{
	// ----------- ATRIBUTOS -----------

	// Máquinas que quisieron entregarle un item y no pudieron porque estaba llena.
	// Se quedan dormidas hasta que esta máquina se libere y las despierte.
	const waiting = []

	// La máquina hacia la que apunta (null si no hay ninguna).
	// Se calcula una sola vez al prender la simulación: con la simulación prendida
	// no se puede editar el tablero, así que no cambia.
	var next = null

	// Cada máquina guarda su propia dirección (un objeto de directions.wlk).
	// Nace con la dirección seleccionada al momento de colocarla.
	var direction = toolsManager.currentDirection()


	// ----------- DIRECCION -----------
	override method direction() = direction
	
	// Sólo se rota con la simulación apagada (ver toolsManager), así que la imagen es la quieta
	method rotate() {
		direction = direction.next()
		self.showStatic()
	}


	//----------- UBICACION EN EL TABLERO -----------

	// La celda del tablero que ocupa. Es position sin el desplazamiento del dibujo:
	// para casi todas las máquinas son iguales, pero no para las que se dibujan corridas.
	method cell() = game.at(position.x() - self.offsetX(), position.y() - self.offsetY())
	
	// Busca en el tablero la máquina hacia la que apunta (null si no hay ninguna).
	// Es una consulta cara con muchas máquinas: durante la simulación se usa next.
	method nextMachine() = board.machineAt(direction.move(self.cell()))


	
	//----------- CICLO DE LA SIMULACION -----------
	// Se llama al prender la simulación: busca a su vecina y pasa a la imagen animada
	method start() {
		next = self.nextMachine()
		self.showRunning()
	}

	// El simulationEngine la llama cuando llega el paso que la máquina agendó.
	// Por defecto no hace nada: una máquina que nunca agenda, nunca se despierta.
	method use() {}

	
	// Vuelve la máquina a su estado inicial (sin items y quieta), al apagar la simulación
	method reset() {
		waiting.clear()
		self.stopAnimation()
		self.showStatic()
	}
	


	//----------- ITEMS -----------
	// canReceive, receive y heldItems son valores por defecto para una máquina que no maneja
	// items: las que sí lo hacen (por ejemplo Belt) los sobrescriben.

	// ¿Puede aceptar un item más? Por defecto una máquina no acepta items
	method canReceive() = false

	// Otra máquina le entrega un item. Sólo se llama si canReceive() dio true.
	method receive(anItem) {}

	// Items que tiene encima la máquina en este momento
	method heldItems() = []

	// ¿Hay una máquina adelante y puede recibir?
	method canPush() = next != null && next.canReceive()

	// Le entrega el item a la máquina de adelante. Sólo se llama si canPush() dio true.
	method push(anItem) {
		next.receive(anItem)
	}



	//----------- ESPERA -----------
	// Otra máquina se anota para que la despierten cuando haya lugar.
	// No hace falta revisar repetidos: una máquina anotada no hace nada hasta que la despierten.
	method addWaiting(machine) { waiting.add(machine) }

	// Se llama cuando la máquina se libera: despierta a todas las que esperaban.
	method wakeWaiting() {
		if (!waiting.isEmpty()) {
			waiting.forEach({ machine => simulationEngine.schedule(1, machine) })
			waiting.clear()
		}
	}

	// No pudo entregar: se anota en la de adelante para que la despierte cuando se libere.
	// Si no hay máquina adelante, no hay a quién esperar: se queda dormida sin gastar nada.
	method waitForNext() {
		if (next != null) next.addWaiting(self)
	}

	// ----------- ANIMACION DE TRABAJO -----------
	// Reproduce la animación y, al terminar, se agenda para seguir trabajando en use().
	// El trabajo no se hace en el bloque del final porque corre dentro del tick del
	// animationEngine, donde no se puede mover items (se agregarían a la lista que se recorre).
	method playThenWake(anAnimation) {
		self.play(anAnimation, { simulationEngine.schedule(1, self) })
	}
}


