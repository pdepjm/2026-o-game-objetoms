// Buffet Albert Einstein - la música de fondo del juego.
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
