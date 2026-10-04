import wollok.game.*
import menu.menuManager.*

// Panel de la zona interactiva mientras la herramienta activa es edit.
// Responde a show, hide y onClick, igual que el resto de los paneles (ver menuManager).
object editMenu{
	method show() {
		game.addVisual(infoText)
	}

	method hide() {
		if (game.hasVisual(infoText)) game.removeVisual(infoText)
	}

	method onClick(pos) {}
}

// Por ahora sólo dice "Info"; más adelante va a mostrar la información de la máquina
object infoText {
	const position = menuManager.interactiveZone().at(1, 12)

	method position() = position
	method text() = "Info"
	method textColor() = "FFFFFFFF"
}
