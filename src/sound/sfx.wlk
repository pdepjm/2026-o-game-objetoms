// src/sound/sfx.wlk
import wollok.game.*

// Efectos de sonido de las interacciones del jugador (UI).
//
// OJO: los tests NO abren el juego, y un game.sound().play() sin juego abierto
// tira excepción. Por eso "enabled" arranca en false y sólo el juego lo prende
// (ver main.wpgm): así los tests corren en silencio sin romperse.
//
// Cada sonido se crea nuevo en cada reproducción: los sonidos de Wollok Game
// suenan UNA sola vez (ver musicManager para la música, que sí loopea).
object sfx {
	var enabled = false

	method enable() {
		enabled = true
	}

	method play(soundFile) {
		if (enabled) {
			const sound = game.sound(soundFile)
			sound.volume(0.35) // bajo, para no tapar la música de fondo
			sound.play()
		}
	}

	// ----------- INTERACCIONES DEL JUGADOR -----------
	method place() { self.play("sound/ui/place_machine.mp3") }

	method delete() { self.play("sound/ui/delete_machine.mp3") }

	method rotate() { self.play("sound/ui/rotate_machine.mp3") }

	method invalid() { self.play("sound/ui/invalid.mp3") }

	method toolSelect() { self.play("sound/ui/tool_select.mp3") }

	method menuSelect() { self.play("sound/ui/menu_select.mp3") }

	method pageChange() { self.play("sound/ui/page_change.mp3") }

	method directionChange() { self.play("sound/ui/direction_change.mp3") }

	method speedChange() { self.play("sound/ui/speed_change.mp3") }

	method simulationStart() { self.play("sound/ui/simulation_start.mp3") }

	method simulationStop() { self.play("sound/ui/simulation_stop.mp3") }
}
