// Buffet Albert Einstein - los brazos: el automático y el inteligente.
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
import food.foodTypes.*
import food.foodClasses.*

// Brazo automático: agarra el item que le llega por su ÚNICA entrada y lo entrega recto
class AutomaticArm inherits Machine {
	// ----------- ATRIBUTOS -----------
	const rotateFrames = 4
	const rotateSteps = 7
	const catchFrames = 14
	const catchSteps = 28

	// El lado por el que recibe: el que se eligió al colocarlo, y cambia al rotarlo.
	var inputSide = up
	// Hacia dónde entrega se configura (recto, izquierda o derecha, relativo a la entrada)
	const outputSetting = new OutputSideSetting(value = straightOut)

	var from = up
	var grabbed = false   // ¿ya lo llevó al lado contrario?

	// ----------- INICIALIZACION -----------
	override method initialize() {
		inputSide = direction
		super()
	}

	// ----------- IDENTIDAD -----------
	override method name() = "AutomaticArm"
	override method label() = "Brazo"
	override method article() = "el"
	override method baseEnergy() = 2

	// ----------- ROTACION -----------
	override method turn() {
		inputSide = inputSide.next()
		direction = inputSide
	}

	method inputSide() = inputSide

	// Por ahora el menú muestra siempre la misma imagen
	override method menuImage(aDirection) = self.assetFolder() + "down_menu.png"

	// Sólo recibe de la máquina que está en su entrada
	override method acceptsSource(source) = source === self.inputMachine()

	override method worksWithArmOnlyMachines() = true

	override method settings() = [outputSetting]

	// ----------- DIBUJO -----------
	override method drawOffsetX() = -1

	override method drawOffsetY() = -1

	// La carpeta de sus imágenes.
	method assetFolder() = "machines/AutomaticArm/"

	override method staticImage() = self.assetFolder() + direction.name() + "_game.png"

	// Una animación del brazo, por ejemplo armAnimation(down, up, "rotate", rotateFrames, rotateSteps)
	method armAnimation(fromSide, toSide, kind, frameCount, steps) = new FrameAnimation(
		path = self.assetFolder() + fromSide.name() + "_to_" + toSide.name() + "_" + kind,
		frameCount = frameCount,
		steps = steps
	)

	// Gira de un lado a otro
	method showTurn(fromSide, toSide, afterBlock) {
		self.play(self.armAnimation(fromSide, toSide, "rotate", rotateFrames, rotateSteps), afterBlock)
	}

	// Agarra del primer lado y gira hasta el otro
	method showCatch(fromSide, toSide, afterBlock) {
		self.play(self.armAnimation(fromSide, toSide, "catch", catchFrames, catchSteps), afterBlock)
	}

	// ----------- ITEMS -----------
	override method onReceive(item) {
		from = inputSide
		grabbed = false
		if (direction == from) self.carry() else self.turnToItem()
	}

	// Lado por el que entrega, según lo configurado (relativo al lado de entrada)
	method outputSide() = outputSetting.value().sideFor(inputSide)

	// ----------- EL PANEL DEL BRAZO (ver armMenu) -----------

	// Se edita como brazo: el panel muestra sus lados (o, el inteligente, sus ingredientes)
	override method openEditorIn(panel) { panel.editArm(self) }
	method editTitle() = "BRAZO"
	method editHint() = "DEJA TODO HACIA"
	// El brazo como se ve en el tablero, en un cuadro (assets/menu/makeArmAndCompass.py)
	method editBoxImage() = "menu/arm_box_auto_" + inputSide.name() + ".png"
	method editChoices() = [up, right, down, left].map({ side => new ArmSideChoice(arm = self, side = side) })

	// Deja todo hacia ese lado del tablero: la salida (relativa a la entrada) que da a ese lado
	method chooseOutputSide(side) {
		outputSetting.value([straightOut, leftOut, rightOut].find({ output => output.sideFor(inputSide) == side }))
	}

	// Lo que se ve en el tablero al lado del brazo mientras se edita: por qué lados sale algo, y qué
	method sendsTo(side) = self.outputSide() == side
	method kindsTo(side) = []

	// Lado por el que entrega ESE item.
	method outputSideFor(item) = self.outputSide()

	// Gira hacia el lado del que vino el item
	method turnToItem() {
		self.showTurn(direction, from, {
			direction = from
			self.carry()
		})
	}

	// Lo agarra y gira hacia el lado contrario.
	method carry() {
		const to = self.outputSideFor(self.itemToPush())
		self.itemToPush().moveInSteps(to.move(self.cell()), catchSteps)
		self.showCatch(from, to, {
			direction = to
			// Entrega hacia el lado al que quedó mirando (el contrario al del que vino el item).
			next = self.nextMachine()
			grabbed = true
			self.showStatic()
			self.tryPush()
		})
	}

	// Se entera de que entregó: queda libre para el próximo item
	override method onPushed(item) {
		from = inputSide
		grabbed = false
		simulationEngine.after(1, { self.tryGrab() })
	}

	// ----------- AGARRAR DE LA ENTRADA -----------
	method inputMachine() = board.machineAt(inputSide.move(self.cell()))

	// Si está libre y en su entrada hay un item agarrable (el de una cinta que pasa por ahí), lo toma.
	method tryGrab() {
		const source = self.inputMachine()
		source.grabbableItem().grabbedBy(self, source)
	}

	// ----------- SIMULACION -----------
	override method start() {
		super()
		self.inputMachine().addGrabber(self)
	}

	// Al apagar la simulación suelta el item y vuelve a quedar quieto mirando hacia la entrada.
	override method reset() {
		from = inputSide
		grabbed = false
		direction = inputSide
		super()
	}
}

// Una de las tres salidas del brazo inteligente: hacia dónde va
class ArmRoute {
	const property output
	const property filter

	method accepts(item) = filter.accepts(item)

	// El lado del tablero por el que sale, para un brazo que agarra de inputSide
	method sideFor(inputSide) = output.sideFor(inputSide)
}

// "Ninguna salida": la de un ingrediente que el brazo no agarra
object noRoute {
	method sideFor(inputSide) = noSide
	method filter() = noFilter
}

object noFilter {
	method contains(kind) = false
	method add(kind) {}
	method remove(kind) {}
}

// Brazo inteligente: igual que el automático, pero tiene tres salidas (izquierda, recta y derecha)
class SmartRoboticArm inherits AutomaticArm {
	// Los ingredientes que se pueden elegir en cada salida (hasta 13 para no salirse de la pantalla)
	const kinds = [
		friedPotato, burntPotato,
		eggFryed,
		cookedMeat,
		sausageCooked
	]

	// En el orden de prioridad: recta, izquierda, derecha
	const routes = [
		new ArmRoute(output = straightOut, filter = new ItemSetSetting(outputName = "Recto", columnIndex = 1, kinds = kinds, value = [])),
		new ArmRoute(output = leftOut, filter = new ItemSetSetting(outputName = "Izq.", columnIndex = 0, kinds = kinds, value = [])),
		new ArmRoute(output = rightOut, filter = new ItemSetSetting(outputName = "Der.", columnIndex = 2, kinds = kinds, value = []))
	]

	override method name() = "AutomaticArm"
	override method label() = "Brazo intel."
	override method baseEnergy() = 3

	// Las mismas imágenes del automático, recoloreadas en naranja (assets/machines/recolor.ps1)
	override method assetFolder() = "machines/SmartRoboticArm/"

	override method settings() = routes.map({ route => route.filter() })

	// La salida que deja pasar a ese item
	method routeFor(item) = routes.find({ route => route.accepts(item) })

	// ¿Alguna de sus salidas deja pasar a ese item?
	method canTake(item) = routes.any({ route => route.accepts(item) })

	override method outputSideFor(item) = self.routeFor(item).output().sideFor(inputSide)

	// ¿Toma un item de ese kind?
	method takes(kind) = self.canTake(new Item(kind = kind))

	// El lado por el que saldría un item de ese kind
	method exitSideFor(kind) = self.routeFor(new Item(kind = kind)).output().sideFor(inputSide)

	// No toma lo que no tiene por dónde salir
	override method canReceive(item) = super(item) && self.canTake(item)

	// ----------- EL PANEL DEL BRAZO (ver armMenu) -----------

	override method editTitle() = "BRAZO INTELIGENTE"
	override method editHint() = "CLIC: CAMBIA HACIA DÓNDE"
	override method editBoxImage() = "menu/arm_box_smart_" + inputSide.name() + ".png"
	override method editChoices() = kinds.map({ kind => new ArmKindChoice(arm = self, kind = kind) })
	// Los ingredientes del panel, en el orden de sus casilleros
	method editKinds() = kinds

	// El lado del tablero por el que sale ese ingrediente (noSide si no lo agarra)
	method sideOf(kind) = routes.findOrDefault({ route => route.filter().contains(kind) }, noRoute).sideFor(inputSide)

	method cycle(kind) {
		const options = [noSide] + [up, right, down, left].filter({ side => side != inputSide })
		const index = (0 .. options.size() - 1).find({ i => options.get(i) == self.sideOf(kind) })
		self.sendTo(kind, options.get((index + 1).rem(options.size())))
	}

	// Que ese ingrediente salga sólo por ese lado del tablero (noSide: que no lo agarre)
	method sendTo(kind, side) {
		routes.forEach({ route => route.filter().remove(kind) })
		routes.findOrDefault({ route => route.sideFor(inputSide) == side }, noRoute).filter().add(kind)
	}

	override method sendsTo(side) = !self.kindsTo(side).isEmpty()
	override method kindsTo(side) = kinds.filter({ kind => self.sideOf(kind) == side })
}

// ----------- LOS CASILLEROS DEL PANEL DEL BRAZO (ver armMenu) -----------

// Brazo inteligente: un ingrediente.
class ArmKindChoice {
	const arm
	const kind

	method images() {
		const side = arm.sideOf(kind)
		return if (side == noSide) ["menu/arm_item.png", kind.image()]
			else ["menu/arm_item_on.png", kind.image(), "menu/arm_chip_" + side.name() + ".png"]
	}

	method choose() { arm.cycle(kind) }
}

class ArmSideChoice {
	const arm
	const side

	method images() = ["menu/arm_dir_" + side.name() + self.state() + ".png"]

	method state() = if (side == arm.inputSide()) "_grab" else if (side == arm.outputSide()) "_on" else ""

	method choose() { if (side != arm.inputSide()) arm.chooseOutputSide(side) }
}

// "Por ningún lado": el lado de un ingrediente que el brazo inteligente no agarra
object noSide {
	method name() = "none"
}
