object menuManager {
    // Metodos para saber sobre en que menu se clickeo
    method inLevelInfoMenu(pos) = pos.x().between(0, 4) && pos.y().between(1, 14) 

    method inToolsMenu(pos) = pos.x().between(22, 25) && pos.y().between(1, 14)
}