# `food/`

Lo que circula por las máquinas: los items (ingredientes y platos), los procesos que sufren y las recetas.

| Archivo | Qué tiene |
|---|---|
| `foodClasses.wlk` | Los procesos (`cutting`) y las clases `IngredientKind`, `DishKind` e `Item` |
| `foodTypes.wlk` | Los kinds concretos (`potato`, `cutPotato`, `friedPotato`) |
| `recipesClasses.wlk` | Las clases `Requirement` y `Recipe` |
| `recipes.wlk` | Las recetas concretas (`friedPotatoRecipe`) |

## `foodClasses.wlk`

- **Procesos** (`cutting`): objetos vacíos que representan lo que hace cada máquina. Se comparan por identidad.
- `Item`: lo que está en el tablero. Se mueve (`Animado`, de `simulation/animationEngine.wlk`) y delega en su `kind`, que cambia cuando lo procesan. Lo crean el `Dispenser` y las recetas (`prepare()`).
- **Kinds**: qué es un item en este momento. Hay dos clases, y `Item` no necesita saber cuál tiene:
  - `IngredientKind`: un ingrediente (papa, papa cortada...). Guarda sus transiciones: con qué proceso se convierte en qué. Cada kind concreto las carga en su `initialize()` con `turnsInto(proceso, resultado)`.
  - `DishKind`: un plato final. Ningún proceso se le puede aplicar.

### Contrato de un item

Lo que las máquinas y las recetas le pueden pedir a un item:

| Método | Para qué | Quién lo usa |
|---|---|---|
| `canProcess(proceso)` | Saber si se le puede aplicar un proceso | Las máquinas que procesan, para aceptarlo o no |
| `process(proceso)` | Transformarlo. **Sólo se llama si `canProcess` dio verdadero** | Las máquinas que procesan |
| `kind()` | Qué es ahora (`potato`, `cutPotato`...) | Las recetas, para comparar |
| `image()` | La imagen de su kind | Wollok Game |

## `foodTypes.wlk`

Por ahora sólo la papa: `potato` → (`cutting`) → `cutPotato`. `friedPotato` es un plato (`DishKind`): no sale de un proceso sino de `friedPotatoRecipe`. Las imágenes están en `assets/food/potatoes/`.

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

- `friedPotatoRecipe`: una papa cortada → una papa frita. Las recetas son objetos bien conocidos, igual que los kinds.
