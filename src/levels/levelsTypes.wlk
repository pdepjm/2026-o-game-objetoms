import levels.levelClasses.*
import food.foodTypes.*
import food.recipes.*
import machines.machineManager.*
import machines.types.belt.*
import machines.types.dispenser.*
import machines.types.automaticArm.*
import machines.types.smartRoboticArm.*
import machines.types.assembler.*
import machines.types.oven.*
import machines.types.cuttingMachine.*
import machines.types.fryer.*
import cellPosition.*
import board.*
import directions.*

object freePlay inherits Level(
    name = "Libre", 
    availableMachines = machineManager.allMachines(),
    availableRecipes = recipeBook.all(),
    goals = [noGoal]
) {}

object level1 inherits Level(
	name = "Nivel 1",
	availableMachines = [
        { => new Belt() }, 
        { => new CuttingMachine() },
        { => new Fryer()},
        { => new SmartRoboticArm() }
    ],
    availableRecipes = [],
	goals = [
        new DeliveryGoal(
            kind = friedPotato, 
            amount = 2, 
            label = "Papas Fritas"
        )
    ],
    fixedMachines = [
        new Placement(
            position = new CellPosition(x=5, y=7),
            factory = {=> new Dispenser(direction = right, availableKinds = [potato, lettuce, tomato])}
        )
    ]
) {}
object level2 inherits Level(
	name = "Nivel 2",
	availableMachines = [
        { => new Belt() }, 
        { => new CuttingMachine() },
        { => new Fryer()},
        { => new Oven()},
        { => new SmartRoboticArm() }
    ],
    availableRecipes = [cheeseBurgerRecipe, doubleBurgerRecipe],
	goals = [
        new DeliveryGoal(
            kind = cheeseBurger, 
            amount = 3, 
            label = "Cheeseburgers"
        ),
        new DeliveryGoal(
            kind = friedPotato, 
            amount = 3, 
            label = "Papas fritas"
        )
    ],
    buildZones = [
        new Zone(
            minX = 11,
            maxX = 19,
            minY = 9,
            maxY = 13
        )
    ],
    fixedMachines = [
        new Placement(
            position = new CellPosition(x=11, y=13),
            factory = {=> new Dispenser(direction = right, availableKinds = [meat, bun, potato, cheese])}
        ),
        new Placement(
            position = new CellPosition(x=11, y=12),
            factory = {=> new Dispenser(direction = right, availableKinds = [meat, bun, potato, cheese])}
        ),
        new Placement(
            position = new CellPosition(x=11, y=11),
            factory = {=> new Dispenser(direction = right, availableKinds = [meat, bun, potato, cheese])}
        ),
        new Placement(
            position = new CellPosition(x=11, y=10),
            factory = {=> new Dispenser(direction = right, availableKinds = [meat, bun, potato, cheese])}
        ),
        new Placement(
            position = new CellPosition(x=17, y=11),
            factory = {=> new Assembler(direction = up)}
        )
    ]
) {}