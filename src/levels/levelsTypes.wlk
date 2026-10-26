import levels.levelClasses.*
import food.foodTypes.*
import machines.machineManager.*
import machines.types.belt.*
import machines.types.dispenser.*
import machines.types.automaticArm.*
import machines.types.smartRoboticArm.*
import machines.types.assembler.*
import machines.types.oven.*
import machines.types.cuttingMachine.*
import machines.types.fryer.*

object freePlay inherits Level(
    name = "Libre", 
    availableMachines = machineManager.allMachines(),
    goals = [noGoal]
) {}

object level1 inherits Level(
	name = "Nivel 1",
	// La freidora sólo trabaja con brazos: el común mete la papa cortada, y el inteligente
	// (con su salida filtrando papas fritas) espera a que se fría para sacarla. El común no
	// sirve para sacarla: se la lleva apenas entra, sin freír.
	availableMachines = [
        { => new Belt() }, 
        { => new Dispenser() }, 
        { => new CuttingMachine() },
        { => new Fryer()},
        { => new SmartRoboticArm() }
    ],
	goals = [
        new DeliveryGoal(
            kind = friedPotato, 
            amount = 10, 
            label = "Papas Fritas"
        )
    ]
) {}