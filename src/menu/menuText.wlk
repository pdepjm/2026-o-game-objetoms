import wollok.game.*

// Un texto de los menús: el título de una categoría, el nombre de un setting, una opción sin imagen
// o una línea de la información del nivel. Lo usan editMenu y levelInfoMenu.
// El texto es fijo: para cambiarlo, se saca el visual y se agrega uno nuevo.
class MenuText {
    const property text
    const property position
    const property textColor = "FFFFFFFF"

    // Lo que dice (lo entiende también KeyHint, que es una imagen: así se pueden pedir las dos cosas juntas)
    method description() = text

    method isText() = true

    method hide() { game.removeVisual(self) }
}
