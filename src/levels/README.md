# `levels/`

| Archivo | Qué tiene |
|---|---|
| `niveles.wlk` | `Nivel`: una clase para los niveles del juego. **Todavía no se usa** |

La idea, es que cada nivel muestre en el menú sólo las máquinas disponibles para ese nivel. Hoy el menú muestra todas las del catálogo de `machines/machineManager.wlk`.

La zona de la pantalla reservada para la información del nivel está en `menu/menuManager.wlk` (`levelInfoZone`), con su archivo vacío `menu/levelInfoMenu.wlk`.

> [!NOTE]
> El plan para implementar los niveles (`Level`, `levelManager`, puntos de entrega, objetivos y la entrada para el tutorial) está en [`docs/Plan-Implementacion-Niveles.md`](../../docs/Plan-Implementacion-Niveles.md), con un checklist de las fases que ya se hicieron.
