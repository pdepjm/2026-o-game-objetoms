import src.simulation.simulationEngine.*

// Ayuda de los tests: deja correr la simulación hasta que se apague (al ganar se apaga sola), de a 100
// pasos, sin seguir dando vueltas después de ganar. Como mucho, 10000 pasos.
object runner {
	method runUntilWon() {
		100.times({ _ => if (simulationEngine.running()) 100.times({ _ => if (simulationEngine.running()) simulationEngine.step() }) })
	}
}
