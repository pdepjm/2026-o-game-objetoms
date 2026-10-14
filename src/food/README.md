# `food/`

Lo que circula por las máquinas: los ingredientes y las recetas.

| Archivo | Qué tiene |
|---|---|
| `ingredientes.wlk` | Los ingredientes (`Ingrediente`, `Carne`) |
| `recetas.wlk` | Las recetas (`Hamburguesa`). Todavía sin usar |

## `ingredientes.wlk`

- `Ingrediente`: la clase de todo ingrediente. **Todavía está vacía.**
- `Carne`: el único ingrediente por ahora. Se mueve (`Animado`, ver [`simulation/`](../simulation/README.md)) y se dibuja con `pepita.png` provisoriamente. Entiende `cocinar(tiempo)` y `cortar()`, que cambia su imagen a `pepita_cortada.png`. Lo crea el `Dispenser`.

### Contrato de un ingrediente (a implementar, fase 4 del [plan](../../docs/plan-contrato-maquinas.md))

Para que las máquinas que procesan sean genéricas, lo que se le puede hacer a un ingrediente tiene que estar en `Ingrediente` y no en cada clase:

| Método | Para qué | Quién lo usa |
|---|---|---|
| `puedeCortarse()`, `puedeCocinarse()`, `puedeFreirse()` | Saber si una máquina lo acepta | `canReceive(item)` de cada máquina |
| `cortar()`, `cocinar(tiempo)`, `freir(tiempo)` | Transformarlo | `onArrived(item)` de cada máquina |
| `estado()` | Cómo está: `raw`, `cut`, `cooked`, `fried` (los mismos nombres que sus imágenes, ver [`assets/README.md`](../../assets/README.md#food)) | Las recetas, para preguntar "¿está cortada?" |

Las imágenes salen del estado: `food/<ingredients>/<ingredient>_<state>.png`.

## `recetas.wlk`

- `Hamburguesa`: una receta de ejemplo (carne y pan). Todavía no la usa el juego. La idea es que la lista sea de clases de ingredientes (y su estado), para que el Assembler pueda preguntar qué le falta (fase 7 del plan).
