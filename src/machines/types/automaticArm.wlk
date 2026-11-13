// Buffet Albert Einstein - el brazo automático: agarra un item y lo entrega recto, a la izquierda o a la derecha.
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

import machines.machineClasses.*
import machines.settings.*
import simulation.simulationEngine.*
import simulation.animationEngine.*
import directions.*
import board.*

// Brazo automático: agarra el item que le llega por su ÚNICA entrada y lo entrega recto, a la
// izquierda o a la derecha de su recorrido, según cómo se configure.
// La entrada es el lado que se elige al colocarlo y al rotarlo. Descansa mirando hacia ella,
// y gira solo para agarrar y entregar. Sólo recibe de la máquina que esté en su entrada.
// Se anima frame a frame (PNG por frame, con play de MachineAnimator) y no con GIFs.
//
// Cuando le llega un item:
// 1. Si no está mirando hacia la entrada, gira hacia ahí (animación rotate).
// 2. Lo agarra y gira hacia el lado de salida (animación catch), llevando el item.
// 3. Lo entrega a la máquina de esa celda (tryPush). Si está llena, espera a que se libere.
// Mientras tiene un item no acepta otro.
//
// El item no viaja a la celda del brazo (por eso sobrescribe onReceive): el brazo lo
// gira y lo lleva a la celda de salida. Cada animación termina en la etapa segura del
// animationEngine (bloques pendientes), así el bloque puede girar, mover el item y
// entregar directo, sin perder pasos.
class AutomaticArm inherits Machine {
	// ----------- ATRIBUTOS -----------
	// Frames que hay en cada carpeta de animación (los genera assets/machines/gifToFrames.py)
	const rotateFrames = 7
	const catchFrames = 28

	// El lado por el que recibe: el que se eligió al colocarlo, y cambia al rotarlo.
	// direction, en cambio, es hacia dónde está mirando la pinza en este momento.
	var inputSide = null
	// Hacia dónde entrega se configura (recto, izquierda o derecha, relativo a la entrada)
	const outputSetting = new OutputSideSetting(value = straightOut)

	var from = null       // lado del que vino el item
	var grabbed = false   // ¿ya lo llevó al lado contrario?

	// ----------- INICIALIZACION -----------
	// La entrada es la dirección elegida; leer direction fija la elegida en este momento (ver MachineSprite)
	// y super() muestra la imagen quieta, mirando hacia la entrada.
	override method initialize() {
		inputSide = direction
		super()
	}

	// ----------- IDENTIDAD -----------
	override method name() = "AutomaticArm"
	override method baseEnergy() = 2

	// ----------- ROTACION -----------
	// Rotar mueve la entrada, y el brazo descansa mirando hacia ella
	override method rotate() {
		inputSide = inputSide.next()
		direction = inputSide
		self.showStatic()
	}

	method inputSide() = inputSide

	// Por ahora el menú muestra siempre la misma imagen
	override method menuImage(aDirection) = self.assetFolder() + "down_menu.png"

	// Sólo recibe de la máquina que está en su entrada
	override method acceptsSource(source) = source === self.inputMachine()

	override method isArm() = true

	override method settings() = [outputSetting]

	// ----------- DIBUJO -----------
	// Se dibuja sobre 3x3 celdas, centrado en la suya
	override method drawOffsetX() = -1

	override method drawOffsetY() = -1

	// La carpeta de sus imágenes. Los brazos que heredan de éste pueden compartirla.
	method assetFolder() = "machines/AutomaticArm/"

	override method staticImage() = self.assetFolder() + direction.name() + "_game.png"

	// Una animación del brazo, por ejemplo armAnimation(down, up, "rotate", rotateFrames)
	method armAnimation(fromSide, toSide, kind, frameCount) = new FrameAnimation(
		path = self.assetFolder() + fromSide.name() + "_to_" + toSide.name() + "_" + kind,
		frameCount = frameCount
	)

	// Gira de un lado a otro
	method showTurn(fromSide, toSide, afterBlock) {
		self.play(self.armAnimation(fromSide, toSide, "rotate", rotateFrames), afterBlock)
	}

	// Agarra del primer lado y gira hasta el otro
	method showCatch(fromSide, toSide, afterBlock) {
		self.play(self.armAnimation(fromSide, toSide, "catch", catchFrames), afterBlock)
	}

	// ----------- ITEMS -----------
	// El item no se anima hasta la celda del brazo: el brazo gira hacia él y lo lleva
	// al lado opuesto. Por eso se sobrescribe onReceive (y no receive).
	override method onReceive(item) {
		from = inputSide
		grabbed = false
		if (direction == from) self.carry() else self.turnToItem()
	}

	// Lado por el que entrega, según lo configurado (relativo al lado de entrada)
	method outputSide() = outputSetting.value().sideFor(inputSide)

	// Lado por el que entrega ESE item. Los brazos que eligen según el item lo sobrescriben.
	method outputSideFor(item) = self.outputSide()

	// Gira hacia el lado del que vino el item
	method turnToItem() {
		self.showTurn(direction, from, {
			direction = from
			self.carry()
		})
	}

	// Lo agarra y gira hacia el lado contrario. El item viaja a la otra celda mientras tanto.
	method carry() {
		const to = self.outputSideFor(self.itemToPush())
		self.itemToPush().moveInSteps(to.move(self.cell()), catchFrames)
		self.showCatch(from, to, {
			direction = to
			// Entrega hacia el lado al que quedó mirando (el contrario al del que vino el item).
			// next se calculó al prender, mirando hacia otro lado: se vuelve a buscar.
			next = self.nextMachine()
			grabbed = true
			self.showStatic()
			self.tryPush()
		})
	}

	// Se entera de que entregó: queda libre para el próximo item
	override method onPushed(item) {
		from = null
		grabbed = false
		simulationEngine.after(1, { self.tryGrab() })
	}

	// ----------- AGARRAR DE LA ENTRADA -----------
	// La máquina de su entrada, sin importar hacia dónde apunte (null si no hay)
	method inputMachine() = board.machineAt(inputSide.move(self.cell()))

	// Si está libre y en su entrada hay un item agarrable (el de una cinta que pasa por ahí), lo toma.
	// Lo avisa la máquina de la entrada cuando le llega un item, y el brazo mismo al quedar libre.
	// SIEMPRE revisa el estado antes de actuar: entre el aviso y este momento pasan cosas.
	method tryGrab() {
		const source = self.inputMachine()
		const item = if (source == null) null else source.grabbableItem()
		if (item != null && self.canReceive(item)) {
			source.surrender(item)
			self.receive(item)
		}
	}

	// ----------- SIMULACION -----------
	// Se anota en la máquina de su entrada para enterarse de lo que le llega
	override method start() {
		super()
		const source = self.inputMachine()
		if (source != null) source.addGrabber(self)
	}

	// Al apagar la simulación suelta el item y vuelve a quedar quieto mirando hacia la entrada.
	// El estado se reinicia antes del super(), que vacía el inventario y muestra staticImage().
	override method reset() {
		from = null
		grabbed = false
		direction = inputSide
		super()
	}
}
