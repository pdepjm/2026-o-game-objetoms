# `levels/`

Los niveles del juego. **Todavía se están armando** (ver el plan más abajo): hoy hay objetivos y un `levelManager` mínimo, pero ningún nivel.

| Archivo | Qué tiene |
|---|---|
| `levelClasses.wlk` | Los objetivos: `DeliveryGoal` y `noGoal` (ver abajo) |
| `levelManager.wlk` | `levelManager`. Por ahora sólo tiene `delivered(item)`, que llama `DeliverySlot` cuando se entrega algo, y todavía no hace nada con eso |
| `niveles.wlk` | `Nivel`: una clase vacía que no se usa. Se reemplaza por `Level` en la fase 3 del plan |

## Objetivos

Lo que pide un nivel para ganarlo. Todo objetivo entiende:

| Método | Para qué |
|---|---|
| `delivered(item)` | Se entera de que se entregó un item en un platito |
| `isMet()` | ¿Se cumplió? |
| `progressText()` | El texto que va a mostrar la info del nivel, por ejemplo `"Papas cortadas: 2/3"` |
| `reset()` | Vuelve a cero (al apagar la simulación, el progreso se pierde) |

- **`DeliveryGoal(kind, amount, label)`**: entregar `amount` items de ese kind. Cuenta sólo los del kind pedido (usa `kind.accepts(item)`). `label` es cómo se muestra, porque los kinds no tienen un nombre para mostrar. El texto no pasa de `amount` aunque se entreguen de más.

  ```wollok
  new DeliveryGoal(kind = cutPotato, amount = 3, label = "Papas cortadas")
  ```

- **`noGoal`**: el objetivo del modo libre. Nunca se cumple, no cuenta nada y su texto es vacío. Es un objeto nulo: entiende los mismos mensajes, así nadie tiene que preguntar si un nivel tiene objetivo.

Para agregar otro tipo de objetivo (por ejemplo, "sin quemar nada"), alcanza con que entienda esos cuatro mensajes.

## La pantalla

La zona reservada para la información del nivel está en `menu/menuManager.wlk` (`levelInfoZone`), con su archivo todavía vacío, `menu/levelInfoMenu.wlk`.

> [!NOTE]
> El plan para implementar los niveles (`Level`, `levelManager`, puntos de entrega, objetivos y la entrada para el tutorial) está en [`docs/Plan-Implementacion-Niveles.md`](../../docs/Plan-Implementacion-Niveles.md), con un checklist de las fases que ya se hicieron.
