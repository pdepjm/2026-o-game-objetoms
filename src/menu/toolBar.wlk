import wollok.game.*
import tools.toolsManager.*
import menu.menuManager.*

object toolBar {
    var image = "tools/default.png"
    const zone = menuManager.toolBarZone()

    method position() = zone.origin()
    method image() = image
    method refresh() {
        if (toolsManager.selectedTool() != null)
            image = "tools/" + toolsManager.selectedTool().name() + "_selected.png"
        else
            image = "tools/default.png"
    }
    method show() {game.addVisual(self)}
}
