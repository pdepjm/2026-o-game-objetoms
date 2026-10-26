# `food/`

Lo que circula por las máquinas: los items (ingredientes y platos), los procesos que sufren y las recetas.

| Archivo | Qué tiene |
|---|---|
| `foodClasses.wlk` | Los procesos (`cutting`, `frying`, `burning`, `cooking`) y las clases `IngredientKind`, `DishKind` e `Item` |
| `foodPaths.wlk` | Las familias de ingredientes (`potatoFamily`, `meatFamily`...), que arman la ruta de sus imágenes |
| `foodTypes.wlk` | Los kinds concretos: ingredientes (`potato`, `meat`...) y platos (`burger`) |
| `recipesClasses.wlk` | Las clases `Requirement` y `Recipe` |
| `recipes.wlk` | Las recetas concretas (`burgerRecipe`) |

## `foodClasses.wlk`

- **Procesos** (`cutting`, `frying`, `burning`, `cooking`): objetos vacíos que representan lo que hace cada máquina. Se comparan por identidad. `burning` no lo aplica ninguna máquina a propósito: es lo que le pasa a un item que se queda demasiado en la freidora.
- `Item`: lo que está en el tablero. Se mueve (`Animado`, de `simulation/animationEngine.wlk`) y delega en su `kind`, que cambia cuando lo procesan. Lo crean el `Dispenser` y las recetas (`prepare()`).
- **Kinds**: qué es un item en este momento. Hay dos clases, y `Item` no necesita saber cuál tiene:
  - `IngredientKind`: un ingrediente (papa, papa cortada...). Guarda sus transiciones: con qué proceso se convierte en qué. Cada kind concreto las carga en su `initialize()` con `turnsInto(proceso, resultado)`.
  - `DishKind`: un plato final. Ningún proceso se le puede aplicar.
  - Los dos entienden `accepts(item)`: un kind es también un **filtro de items** que deja pasar a los que son de ese kind. Lo usan los filtros de salida del brazo inteligente (`ItemSetSetting`, en `machines/settings.wlk`).

### Contrato de un item

Lo que las máquinas y las recetas le pueden pedir a un item:

| Método | Para qué | Quién lo usa |
|---|---|---|
| `canProcess(proceso)` | Saber si se le puede aplicar un proceso | Las máquinas que procesan, para aceptarlo o no |
| `process(proceso)` | Transformarlo. **Sólo se llama si `canProcess` dio verdadero** | Las máquinas que procesan |
| `kind()` | Qué es ahora (`potato`, `cutPotato`...) | Las recetas, para comparar |
| `image()` | La imagen de su kind | Wollok Game |
| `processTime()` | Cuántos pasos de simulación tarda en procesarse (por defecto 5) | `ProcessingMachine` |

## `foodPaths.wlk`

Una familia por ingrediente con más de un estado. `image(estado)` arma la ruta siguiendo la convención de [`assets/README.md`](../../assets/README.md#food): `potatoFamily.image("cut")` → `food/Ingredients/potatoes/potato_cut.png`. Los platos de un solo estado escriben su ruta directamente.

## `foodTypes.wlk`

| Ingrediente | Transiciones |
|---|---|
| Papa | `potato` → (`cutting`) → `cutPotato` → (`frying`) → `friedPotato` → (`burning`) → `burntPotato` |
| Lechuga | `lettuce` → (`cutting`) → `cutLettuce` |
| Tomate | `tomato` → (`cutting`) → `cutTomato` |
| Pan | `bun` → (`cutting`) → `cutBun` |
| Carne | `meat` → (`cooking`) → `cookedMeat` |

Platos (`DishKind`): `burger`.

## `recipesClasses.wlk`

- `Requirement`: un kind y cuántos hacen falta (`amount`).
  - `isSatisfiedBy(item)`: si el item es de ese kind.
  - `isCoveredBy(items)`: si entre esos items hay suficientes.
  - `stillNeeds(item, items)`: si el item le sirve, sabiendo lo que ya se juntó.
- `Recipe`: sus requisitos y el kind del plato que sale (`result`).
  - `canBeMadeWith(items)`: si alcanza con esos items para prepararla.
  - `stillNeeds(item, items)`: si el item le sirve a algún requisito. El Assembler lo usa para aceptar sólo lo que le falta, así nunca junta de más.
  - `totalItems()`: cuántos items hacen falta en total.
  - `prepare()`: crea un plato nuevo (`new Item(kind = result)`).

## `recipes.wlk`

- `burgerRecipe`: pan cortado, lechuga cortada, tomate cortado y dos carnes cocidas → `burger`. Las recetas son objetos bien conocidos, igual que los kinds.
