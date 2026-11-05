// src/sound/musicManager.wlk
import wollok.game.*

// Música de fondo del juego.
// Los sonidos de Wollok Game sólo suenan con el juego iniciado (por eso el
// schedule del main) y cada sonido suena UNA sola vez: playBackground() crea
// un sonido nuevo cada vez que se lo pide.
//

object musicManager {
    var backgroundSound = null

    method playBackground() {
        self.stopBackground()
        backgroundSound = game.sound("sound/music/background.mp3")
        backgroundSound.shouldLoop(true)
        backgroundSound.volume(0.6) // más bajita, para que los efectos no queden tapados
        backgroundSound.play()
    }

    method stopBackground() {
        if (backgroundSound != null) {
            backgroundSound.stop()
            backgroundSound = null
        }
    }
}
