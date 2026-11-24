# `test/`

Los tests están ordenados igual que `src/`: cada carpeta prueba la carpeta del mismo nombre.

| Carpeta | Qué prueba |
|---|---|
| `board/` | El tablero, las zonas donde se puede construir, las máquinas de varias celdas, `Zone` y lo que se clickea (`CellArea`, el orden de las capas) |
| `food/` | Los ingredientes, los platos y las recetas |
| `machines/` | Cada familia de máquinas (`processingTest`: horno, freidora y cortadora; `armsTest`: los brazos), el ensamblador, los platitos, los ajustes, el inventario y la energía |
| `simulation/` | El reloj de la simulación y las animaciones |
| `levels/` | `levelManager`, las máquinas fijas de los niveles, el tutorial y **una partida ganada por nivel** (`levelSolutionsTest`) |
| `menu/` | Las pantallas (`screensTest`: portada, controles, libro y ticket), el HUD (`hudTest`) y el recetario |
| (raíz) | Las direcciones, y `runner.wlk`, la ayuda común de los tests |

Se corren todos con el mismo comando que el CI:

```
wollok test --skipValidations -p ./
```

y uno solo con `-f test/<carpeta>/<archivo>.wtest` (o un test con `-t "<descripción>"`).

## Que tarden poco

- **Jugar un nivel entero es lo más caro.** Cada nivel se juega una sola vez, y en esa partida se revisa todo lo que pasa al ganar (el ticket, el cocinero, las marcas y el botón SIGUIENTE). Para jugar hasta ganar está `runner.runUntilWon()`: avanza de a 100 pasos y deja de avanzar apenas la simulación se apaga.
- **Lo que más tarda dentro de un test es agregar y sacar visuales** (unos 16 ms cada uno, y más cuantos más hay en pantalla). Cada cambio de paso del tutorial redibuja al cocinero, con una imagen por letra en "PASO 2 DE 12": por eso `levels/tutorialTest` sigue siendo el archivo más lento.
- Armar sólo lo que el test usa: `playingScreen.show()` y `deliveryPoints.setUp()` sólo cuando el test dibuja el HUD o entrega platos.

## Una rareza de Wollok CLI (1.1.0)

**El primer test que corre en un proceso nuevo de `wollok test` puede fallar** aunque esté bien: pasa con algunos tests que juegan un nivel o arman el tutorial. Con la suite completa no se nota (el primero es uno liviano de `board/`), pero sí al correr un solo archivo o un solo test con `-t`. Si un test falla sólo así, probarlo con otro test liviano adelante antes de buscar el error en el código.
