// Maneja el que es cada cosa
//
// Las clases base de todas las máquinas, en tres capas:
//   MachineAnimator   ← reproducir animaciones frame a frame
//         ▲
//   MachineSprite     ← qué imagen muestra y dónde se dibuja
//         ▲
//   Machine           ← qué hace: dirección, vecina, items, simulación
//
// El contrato completo (qué sobrescribir para crear una máquina nueva) está en
// src/machines/README.md, sección "El contrato de Machine".

import wollok.game.*
import tools.toolsManager.*
import board.*
import simulation.simulationEngine.*
import simulation.animationEngine.*
import machines.inventory.*
import cellPosition.*

// Reproduce animaciones frame a frame (carpetas de PNG, ver FrameAnimation) con el animationEngine.
class MachineAnimator {
	// ----------- ATRIBUTOS -----------
	var animation = null
	// la animación que se está mostrando (null si no hay ninguna)
	var frame = 0
	// frame que se está mostrando
	var onFinish = null // bloque que se ejecuta al terminar (null si no hay)

	// ----------- METODOS ABSTRACTOS -----------
	method showFrame(path)
	
	// muestra la imagen de un frame (lo implementa MachineSprite)
	// ----------- REPRODUCCION -----------
	// Empieza a mostrar la animación desde el primer frame. Si ya había otra, la reemplaza.
	// Al terminar se ejecuta afterBlock, que puede encadenar otra animación con play.
	method play(anAnimation, afterBlock) {
		// si ya se estaba animando, ya está en la lista de animados
		if (!self.animando()) animationEngine.animar(self)
		animation = anAnimation
		
		// Si se llama fuera del tick (por ejemplo desde una acción agendada, que en cada paso
		// corre antes que las animaciones), el tick que viene no tiene que saltear el primer frame.
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
	

	// Reproduce esas imágenes durante exactamente `steps` pasos (ver TimedAnimation)

	method playTimed(images, steps, afterBlock) {

		self.play(new TimedAnimation(images = images, steps = steps.max(1)), afterBlock)

	}
	// ----------- CONTRATO CON EL ANIMATION ENGINE -----------
	method animando() = animation !== null
	
	// Un paso de animación: muestra el frame siguiente.
	// El último frame se ve un paso entero, y recién en el paso siguiente termina.
	// El bloque del final NO corre acá: se encola en el animationEngine para que se
	// ejecute al final del tick, donde ya se puede mover items y encadenar animaciones.
	method avanzar() {
		frame += 1
		if (frame < animation.size()) {
			self.showFrame(animation.frames().get(frame))
		} else {
			const afterBlock = onFinish
			onFinish = null
			animation = null
			animationEngine.avisarLlegada()
			if (afterBlock !== null) animationEngine.alTerminar(afterBlock)
		}
	}
}

// Esta clase modifica el dibujo de las maquinas: donde se dibuja, que muestra y las animaciones frame a frame
// Todo lo relacionado con las imagenes van aca
class MachineSprite inherits MachineAnimator {
	// ----------- ATRIBUTOS -----------
	var property position = game.origin()
	var image = null // Se establece al inicializar
	
	// ----------- METODOS ABSTRACTOS -----------
	method name()
	
	// Hace referencia a la carpeta donde se guardan sus imagenes
	method direction()
	
	// Hacia donde mira, para elegir la rotacion
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
	method drawOffsetX() = 0
	
	method drawOffsetY() = 0
	
	// ----------- IMAGENES -----------
	method image() = image
	
	// La máquina apagada: al colocarla, rotarla y con la simulación apagada
	method staticImage() = "machines/" + self.name() + "/" + self.direction().name() + "_game.png"
	
	// La máquina andando, mientras la simulación está prendida. Por defecto sigue quieta:
	// se anima frame a frame cuando hace algo. Las máquinas con GIF lo sobrescriben con gifImage().
	method runningImage() = self.staticImage()
	
	// El GIF de la máquina andando (sólo para las que se animan con GIF, como la cinta)
	method gifImage() = "machines/" + self.name() + "/" + self.direction().name() + ".gif"
	
	// La imagen del menú de máquinas, según la dirección elegida para colocarla
	method menuImage(aDirection) = "machines/" + self.name() + "/" + aDirection.name() + "_menu.png"
	
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
	override method showFrame(path) {
		image = path
	}
	
	// Una animación de acción de la máquina: la carpeta machines/<name>/<direccion>_<accion>/
	// Por ejemplo, actionAnimation("dispense", 8) para un dispenser hacia la derecha
	// usa machines/Dispenser/right_dispense/0.png ... 7.png
	method actionAnimation(action, frameCount) = new FrameAnimation(
		path = "machines/" + self.name() + "/" + self.direction().name() + "_" + action,
		frameCount = frameCount
	)

	// ----------- ANIMACION DE TRABAJO -----------

	// Las imágenes que se ven mientras trabaja. Por defecto, la imagen andando (la máquina quieta).

	// Las que se animan frame a frame lo sobrescriben con actionAnimation(...).frames()

	method workImages() = [self.runningImage()]



	// Se ve trabajando durante `steps` pasos, vuelve a la imagen andando y ejecuta el bloque.

	// Las que usan un GIF lo sobrescriben con holdImage.

	method animateWork(steps, afterBlock) {

		self.playTimed(self.workImages(), steps, {

			self.showRunning()

			afterBlock.apply()

		})

	}



	// Muestra una imagen fija (por ejemplo un GIF, que se anima solo) durante `steps` pasos,

	// vuelve a la imagen andando y ejecuta el bloque. No pasa por el animationEngine.

	method holdImage(path, steps, afterBlock) {

		image = path

		simulationEngine.after(steps, {

			self.showRunning()

			afterBlock.apply()

		})

	}
}

// Esta clase se encarga de la logica general de las maquinas.
// Una máquina nueva sobrescribe SÓLO lo que la hace distinta (ver el contrato en
// src/machines/README.md). El flujo de items — recibir, guardar, entregar y despertar
// a las que esperan — lo da esta clase: no se reimplementa en cada tipo.
//
// Ciclo de vida de una máquina en la simulación:
// - start(): al prender la simulación. Busca a su vecina y agenda lo que necesite.
// - reset(): al apagar la simulación. Vacía el inventario y corta las animaciones.
//
// El flujo de un item que llega:
//   receive(item) → onReceive(item) → (el item llega a la celda) → onArrived(item) → tryPush()
// Si la de adelante no puede recibir, se anota con whenFree y reintenta cuando se libere.
class Machine inherits MachineSprite {
	// ----------- ATRIBUTOS -----------
	// Los items que guarda y las acciones que esperan a que se libere lugar.
	// El inventario se encarga de despertar a las que esperan al liberar un item.
	const inventory = new Inventory(capacity = self.capacity())

	// La máquina a la que entrega (null si no hay ninguna): la que está en outputTarget().
	// Se calcula al prender la simulación: con la simulación prendida no se puede editar
	// el tablero, así que no cambia. Si una máquina cambia de dirección mientras corre
	// (el brazo), la vuelve a calcular con nextMachine().
	var next = null

	// Los brazos que miran a esta máquina como su entrada: se les avisa cuando llega un item,
	// por si pueden agarrarlo (ver grabbableItem). Se anotan al prender la simulación.
	const grabbers = []

	// Cada máquina guarda su propia dirección (un objeto de directions.wlk).
	// Nace con la dirección seleccionada al momento de colocarla.
	var direction = toolsManager.currentDirection()

	var property locked = false

	// ----------- DIRECCION -----------
	override method direction() = direction
	
	// Sólo se rota con la simulación apagada (ver toolsManager), así que la imagen es la quieta
	method rotate() {
		direction = direction.next()
		self.showStatic()
	}
	
	// ----------- CONFIGURACION -----------
	// Los settings que acepta (ver settings.wlk), que el menú de la herramienta edit deja cambiar.
	// Por defecto no tiene ninguno; la sobrescriben las máquinas configurables.
	method settings() = []

	// Energía que consume: la base más lo que suma cada setting con su opción elegida
	method energyConsumption() = self.baseEnergy() + self.settings().sum({ setting => setting.energyCost() })

	method baseEnergy() = 0

	//----------- UBICACION EN EL TABLERO -----------

	// La celda del tablero que ocupa. Es position sin el desplazamiento del dibujo:
	// para casi todas las máquinas son iguales, pero no para las que se dibujan corridas.
	method cell() = game.at(position.x() - self.drawOffsetX(), position.y() - self.drawOffsetY())
	
	// La CELDA a la que entrega (no la máquina: ésa es next). Por defecto, la pegada a su
	// borde de adelante. Sobrescribirlo si el dibujo marca la salida en otra celda.
	method outputTarget() = direction.output(self.cell(), self.width(), self.height())

	// Busca en el tablero la máquina que está en outputTarget() (null si no hay ninguna).
	// Durante la simulación se usa next, que la guarda.
	// Una máquina que sólo trabaja con el brazo (armOnly) no entrega a otra cosa que no sea un brazo.
	method nextMachine() {
		const machine = board.machineAt(self.outputTarget())
		return if (self.armOnly() && machine != null && !machine.isArm()) null else machine
	}
	
	// Simboliza la cantidad de celdas que ocupa
	method width() = 1
	method height() = 1

	//----------- CICLO DE LA SIMULACION -----------
	// Se llama al prender la simulación: busca a su vecina y pasa a la imagen animada
	method start() {
		next = self.nextMachine()
		self.showRunning()
	}
	
	// Vuelve la máquina a su estado inicial (sin items y quieta), al apagar la simulación.
	// Las que tengan estado propio lo reinician ANTES de llamar a super().
	method reset() {
		grabbers.clear()
		inventory.clear()
		self.stopAnimation()
		self.showStatic()
	}
	
	//----------- ITEMS: ENTRADA -----------

	// ¿Puede aceptar este item? Por defecto, si hay lugar en el inventario.
	// Las que sólo aceptan ciertos items lo sobrescriben con super(item) && ...
	// y las que no aceptan ninguno, con false.
	method canReceive(item) = inventory.hasRoom()

	// ¿Acepta items que le entrega `source`? Por defecto de cualquiera, salvo que sea armOnly.
	method acceptsSource(source) = !self.armOnly() || source.isArm()

	// Lo que se pregunta antes de entregar: quién lo entrega y qué item es.
	// Las máquinas sobrescriben canReceive (qué items) y acceptsSource (de quién), no éste.
	method canReceiveFrom(source, item) = self.acceptsSource(source) && self.canReceive(item)

	// Una máquina armOnly sólo recibe de un brazo y sólo entrega a un brazo (la freidora)
	method armOnly() = false

	method isArm() = false

	// Otra máquina le entrega un item. No se sobrescribe: guarda el item
	// y llama a onReceive, donde cada máquina define qué le pasa.
	method receive(item) {
		inventory.add(item)
		self.onReceive(item)
		self.notifyGrabbers()
	}

	// Avisa a los brazos que la miran que hay algo para agarrar (llegó un item, o terminó de procesarse)
	method notifyGrabbers() {
		grabbers.forEach({ grabber => simulationEngine.after(1, { grabber.tryGrab() }) })
	}

	// Qué le pasa al item que acaba de llegar. Por defecto se anima hasta la celda
	// de la máquina y, cuando termina de llegar, llama a onArrived.
	method onReceive(item) {
		item.moveInSteps(self.position(), animationEngine.pasosPorCelda())
		simulationEngine.after(animationEngine.pasosPorCelda(), { self.onArrived(item) })
	}

	// El item terminó de llegar. Por defecto se entrega a la siguiente, como una cinta.
	// Las que hacen algo con el item (procesarlo, juntarlo con otros) lo sobrescriben.
	// OJO: si un brazo se lo llevó mientras venía en camino, ya no hay nada que entregar.
	method onArrived(item) {
		if (inventory.items().contains(item)) self.tryPush()
	}

	// El item que un brazo puede agarrar sin que esta máquina se lo entregue (null si no hay ninguno).
	// Sólo la cinta lo ofrece: a una máquina que está procesando no se le saca el item.
	method grabbableItem() = null

	// Un brazo se llevó el item: deja de ser de esta máquina y despierta a las que esperaban lugar
	method surrender(item) {
		inventory.release(item)
	}

	method addGrabber(arm) {
		grabbers.add(arm)
	}

	//----------- ITEMS: SALIDA -----------

	// Qué item se entrega (por defecto, el primero del inventario)
	method itemToPush() = if (inventory.isEmpty()) null else inventory.first()

	// Se entera de que entregó un item (por defecto, no hace nada).
	// Lo sobrescribe el que tiene que enterarse, como el Dispenser para agendar el próximo.
	method onPushed(item) {}

	// Intenta entregar el primer item al destino. Si el destino no puede recibirlo,
	// se anota para reintentar cuando se libere. SIEMPRE revisa el estado antes de
	// actuar: entre el intento y la entrega pueden pasar cosas.
	method tryPush() {
		const item = self.itemToPush()
		const target = next
		if (item != null && target != null) {
			if (target.canReceiveFrom(self, item)) {
				inventory.release(item)
				target.receive(item)
				self.onPushed(item)
			} else {
				target.whenFree({ self.tryPush() })
			}
		}
	}

	//----------- ALMACENAMIENTO -----------

	// Cuántos items guarda a la vez (por defecto, uno)
	method capacity() = 1

	// Items que tiene encima la máquina en este momento
	method heldItems() = inventory.items()

	// Anota una acción para cuando esta máquina libere lugar
	method whenFree(action) {
		inventory.whenFree(action)
	}
}

// Una máquina que procesa items: acepta los que puede procesar, trabaja el tiempo

// que dice el item, lo transforma y lo entrega.

// Cada subclase dice qué proceso aplica y, si quiere, cómo se ve trabajando.

class ProcessingMachine inherits Machine {

	method foodProcess()    // abstracto: cutting, cooking, frying…



	override method canReceive(item) = super(item) && item.canProcess(self.foodProcess())



	// Se llama cuando terminó de procesar un item (por defecto, no hace nada). Lo usa la freidora para quemarlo.
	method onProcessed(item) {}

	override method onArrived(item) {

		self.animateWork(item.processTime(), {

			// Un brazo pudo haberse llevado el item mientras trabajaba: entonces ya no es de esta máquina
			if (self.heldItems().contains(item)) {
				item.process(self.foodProcess())
				self.tryPush()
				self.notifyGrabbers()
				self.onProcessed(item)
			}

		})

	}

}
