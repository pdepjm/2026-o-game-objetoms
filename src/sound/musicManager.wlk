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

import wollok.game.*

// Música de fondo del juego.
object musicManager {
    var backgroundSound = noSound

    method playBackground() {
        self.stopBackground()
        backgroundSound = game.sound("sound/music/background.mp3")
        backgroundSound.shouldLoop(true)
        backgroundSound.volume(0.6)
        backgroundSound.play()
    }

    method stopBackground() {
        backgroundSound.stop()
        backgroundSound = noSound
    }
}

// "No hay música sonando": detenerla no hace nada
object noSound {
    method stop() {}
}
