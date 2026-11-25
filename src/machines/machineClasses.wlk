// Buffet Albert Einstein - las clases base de todas las máquinas: animación, imagen y comportamiento.
//
// Copyright (C) 2026  grupo objeTOMs (Mateo Bustos, Carlos Aramis Chambi Flores,
// Facundo Ramounat, Federico Scalise Giussani, Mateo Silva)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import wollok.game.*
import tools.toolsManager.*
import board.*
import simulation.simulationEngine.*
import simulation.animationEngine.*
import machines.inventory.*
import machines.settings.*
import food.foodClasses.*
import cellPosition.*

// Reproduce animaciones frame a frame (carpetas de PNG) con el animationEngine.
class MachineAnimator {
	// ----------- ATRIBUTOS -----------
	var animation = noAnimation
	// la animación que se está mostrando (noAnimation si no hay ninguna)
	var frame = 0
	// frame que se está mostrando
	var onFinish = noAction

	// ----------- METODOS ABSTRACTOS -----------
	method showFrame(path)
	
	// ----------- REPRODUCCION -----------
	method play(anAnimation, afterBlock) {
		// si ya se estaba animando, ya está en la lista de animados
		if (!self.animating()) animationEngine.animate(self)
		animation = anAnimation
		
		frame = if (animationEngine.ticking()) 0 else -1
		onFinish = afterBlock
		self.showFrame(animation.frames().first())
	}
	
	// Corta la animación donde esté, sin ejecutar el bloque del final (se usa al apagar la simulación).
	method stopAnimation() {
		if (self.animating()) animationEngine.stopAnimating(self)
		animation = noAnimation
		onFinish = noAction
	}
	
	// Reproduce esas imágenes durante exactamente `steps` pasos

	method playTimed(images, steps, afterBlock) {

		self.play(new TimedAnimation(images = images, steps = steps.max(1)), afterBlock)

	}
	// ----------- CONTRATO CON EL ANIMATION ENGINE -----------
	method animating() = animation.isRunning()
	
	// Un paso de animación: muestra el frame siguiente.
	method advance() {
		frame += 1
		if (frame < animation.size()) {
			self.showFrame(animation.frames().get(frame))
		} else {
			const afterBlock = onFinish
			onFinish = noAction
			animation = noAnimation
			animationEngine.notifyArrival()
			animationEngine.atTickEnd(afterBlock)
		}
	}
}

// Cómo se dibuja una máquina: dónde, con qué imagen y cómo se anima
class MachineSprite inherits MachineAnimator {
	// ----------- ATRIBUTOS -----------
	var property position = game.origin()
	var image = "no_texture.png" // Se establece al inicializar
	
	// ----------- METODOS ABSTRACTOS -----------
	method name()
	
	// Hace referencia a la carpeta donde se guardan sus imagenes
	method direction()
	
	// ----------- INICIALIZACION -----------
	override method initialize() {
		super()
		image = self.staticImage()
	}
	
	// ----------- DESPLAZAMIENTO DE LA IMAGEN -----------
	method drawOffsetX() = 0
	
	method drawOffsetY() = 0
	
	// ----------- IMAGENES -----------
	method image() = image
	
	// La máquina apagada: al colocarla, rotarla y con la simulación apagada
	method staticImage() = "machines/" + self.name() + "/" + self.direction().name() + "_game.png"
	
	// La máquina andando, mientras la simulación está prendida.
	method runningImage() = self.staticImage()
	
	// El GIF de la máquina andando (sólo para las que se animan con GIF, como la cinta)
	method gifImage() = "machines/" + self.name() + "/" + self.direction().name() + ".gif"
	
	// El casillero del menú de colocar, según la dirección elegida para colocarla
	method menuImage(aDirection) = "machines/" + self.name() + "/" + aDirection.name() + "_menu.png"

	// El nombre que ve el jugador, y con su artículo ("la cinta"): lo dice el cocinero del tutorial
	method label() = self.name()
	method article() = "la"
	method nameWithArticle() = self.article() + " " + self.label().toLowerCase()
	
	// ----------- ESTADOS DEL DIBUJO -----------
	method showStatic() {
		image = self.staticImage()
	}
	
	method showRunning() {
		image = self.runningImage()
	}
	
	// ----------- INSTANCIACION DE ANIMACIONES -----------
	override method showFrame(path) {
		image = path
	}
	
	// Una animación de acción de la máquina
	method actionAnimation(action, frameCount) = new FrameAnimation(
		path = "machines/" + self.name() + "/" + self.direction().name() + "_" + action,
		frameCount = frameCount
	)

	// ----------- ANIMACION DE TRABAJO -----------

	// Las imágenes que se ven mientras trabaja.

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

	// Muestra una imagen fija (por ejemplo un GIF, que se anima solo) durante `steps` pasos

	method holdImage(path, steps, afterBlock) {

		image = path

		simulationEngine.after(steps, {

			self.showRunning()

			afterBlock.apply()

		})

	}
}

// Esta clase se encarga de la logica general de las maquinas.
class Machine inherits MachineSprite {
	// ----------- ATRIBUTOS -----------
	const inventory = new Inventory(capacity = self.capacity())

	// La máquina a la que entrega (noMachine si no hay ninguna): la que está en outputTarget().
	var next = noMachine

	// Los brazos que miran a esta máquina como su entrada: se les avisa cuando llega un item
	const grabbers = []

	// Cada máquina guarda su propia dirección (un objeto de directions.wlk).
	var direction = toolsManager.currentDirection()

	var property locked = false

	// ----------- DIRECCION -----------
	override method direction() = direction
	
	// Sólo se rota con la simulación apagada, así que la imagen es la quieta
	method rotate() {
		self.turn()
		self.showStatic()
		board.rotated(self)
	}

	// Cómo gira: hacia la dirección siguiente
	method turn() { direction = direction.next() }

	// ----------- LO QUE PASA AL TOCARLA -----------

	// Un clic en su celda (construyendo): queda elegida, con su menú abajo
	method clickedAt(pos, manager) { manager.pick(pos) }

	// Al editarla (X), le dice al panel de la derecha qué es, y el panel decide qué mostrar.
	method openEditorIn(panel) { panel.nothingToEdit() }

	// ----------- EVENTOS -----------
	// Avisos que recibe la máquina; por defecto no hace nada con ellos

	// La colocaron en el tablero (lo avisa board.push)
	method addedToBoard() {}
	// La sacaron del tablero (lo avisa board.pop)
	method removedFromBoard() {}
	// Cambió uno de sus ajustes desde el panel de edición (lo avisa editMenu)
	method settingChanged() {}
	// Una máquina de al lado cambió, o ésta acaba de colocarse
	method onNeighbourChanged() {}
	
	// ----------- CONFIGURACION -----------
	method settings() = []

	// Energía que consume: la base más lo que suma cada setting con su opción elegida
	method energyConsumption() = self.baseEnergy() + self.settings().sum({ setting => setting.energyCost() })

	method baseEnergy() = 0

	// El multiplicador de velocidad con el que trabaja (1 si no tiene un setting de velocidad).
	method speed() = 1

	// Los pasos que tarda en trabajar algo que a velocidad normal tarda baseSteps: nunca menos de uno
	method workSteps(baseSteps) = (baseSteps / self.speed()).round().max(1)

	// ----------- UBICACION EN EL TABLERO -----------

	// La celda del tablero que ocupa.
	method cell() = game.at(position.x() - self.drawOffsetX(), position.y() - self.drawOffsetY())
	
	// La CELDA a la que entrega (no la máquina: ésa es next).
	method outputTarget() = direction.output(self.cell(), self.width(), self.height())

	// Busca en el tablero la máquina que está en outputTarget() (noMachine si no hay ninguna).
	method nextMachine() {
		const machine = board.machineAt(self.outputTarget())
		return if (self.worksWith(machine)) machine else noMachine
	}
	
	// Simboliza la cantidad de celdas que ocupa
	method width() = 1
	method height() = 1

	// ----------- CICLO DE LA SIMULACION -----------
	method start() {
		next = self.nextMachine()
		self.showRunning()
	}
	
	// Vuelve la máquina a su estado inicial (sin items y quieta), al apagar la simulación.
	method reset() {
		grabbers.clear()
		inventory.clear()
		self.stopAnimation()
		self.showStatic()
	}
	
	// ----------- ITEMS: ENTRADA -----------

	// ¿Puede aceptar este item?
	method canReceive(item) = inventory.hasRoom()

	// ¿Acepta items que le entrega `source`?
	method acceptsSource(source) = self.worksWith(source)

	// Lo que se pregunta antes de entregar: quién lo entrega y qué item es.
	method canReceiveFrom(source, item) = self.acceptsSource(source) && self.canReceive(item)

	// ¿Trabaja con esa máquina vecina, de la que recibe o a la que entrega?
	method worksWith(neighbour) = true

	// ¿Trabaja con una máquina que sólo trabaja con brazos (como la freidora)?
	method worksWithArmOnlyMachines() = false

	// ----------- PREGUNTAS DE LAS VECINAS -----------
	method asList() = [self]
	// ¿Le entrega a esa celda?
	method feeds(aCell) = self.outputTarget() == aCell
	// ¿Cumple la condición?
	method satisfies(condition) = condition.apply(self)
	// Dónde se dibuja la flecha del tutorial que la señala: arriba de ella, centrada sobre ella.
	method arrowPosition(aCell) = new CellPosition(x = self.cell().x() + (self.width() - 1) / 2, y = self.cell().y() + self.height())

	// Otra máquina le entrega un item.
	method receive(item) {
		inventory.add(item)
		self.onReceive(item)
		self.notifyGrabbers()
	}

	// Avisa a los brazos que la miran que hay algo para agarrar (llegó un item, o terminó de procesarse)
	method notifyGrabbers() {
		grabbers.forEach({ grabber => simulationEngine.after(1, { grabber.tryGrab() }) })
	}

	// Qué le pasa al item que acaba de llegar.
	method onReceive(item) {
		item.moveInSteps(self.position(), animationEngine.stepsPerCell())
		simulationEngine.after(animationEngine.stepsPerCell(), { self.onArrived(item) })
	}

	// El item terminó de llegar.
	method onArrived(item) {
		if (inventory.items().contains(item)) self.tryPush()
	}

	// El item que un brazo puede agarrar sin que esta máquina se lo entregue (noItem si no hay ninguno).
	method grabbableItem() = noItem

	// Un brazo se llevó el item: deja de ser de esta máquina y despierta a las que esperaban lugar
	method surrender(item) {
		inventory.release(item)
	}

	method addGrabber(arm) {
		grabbers.add(arm)
	}

	// ----------- ITEMS: SALIDA -----------

	// Qué item se entrega (por defecto, el primero del inventario)
	method itemToPush() = if (inventory.isEmpty()) noItem else inventory.first()

	// Se entera de que entregó un item (por defecto, no hace nada).
	method onPushed(item) {}

	// Intenta entregar el primer item al destino.
	method tryPush() {
		self.itemToPush().deliverFrom(self, next)
	}

	// Entrega ese item a ese destino
	method deliver(item, target) {
		if (target.canReceiveFrom(self, item)) {
			inventory.release(item)
			target.receive(item)
			self.onPushed(item)
		} else {
			target.whenFree({ self.tryPush() })
		}
	}

	// ----------- ALMACENAMIENTO -----------

	// Cuántos items guarda a la vez (por defecto, uno)
	method capacity() = 1

	// Items que tiene encima la máquina en este momento
	method heldItems() = inventory.items()

	// Anota una acción para cuando esta máquina libere lugar
	method whenFree(action) {
		inventory.whenFree(action)
	}
}

// "No hay máquina": lo que el tablero devuelve para una celda vacía
object noMachine {
	method asList() = []
	// Un clic en una celda vacía coloca ahí la máquina elegida
	method clickedAt(pos, manager) { manager.placeAt(pos) }
	// En una celda vacía no hay nada para editar
	method openEditorIn(panel) { panel.nothingToEdit() }
	method worksWithArmOnlyMachines() = false
	method locked() = false
	method settings() = []
	method feeds(aCell) = false
	method satisfies(condition) = false
	method arrowPosition(aCell) = new CellPosition(x = aCell.x(), y = aCell.y() + 1)
	method onNeighbourChanged() {}
	method canReceiveFrom(source, item) = false
	method whenFree(action) {}
	method grabbableItem() = noItem
	method surrender(item) {}
	method addGrabber(arm) {}
}
