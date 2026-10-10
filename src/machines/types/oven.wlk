import machines.machineClasses.*

class Oven inherits Machine{
  override method name() = "Oven"

  // Se anima con GIF mientras la simulación está prendida
  override method runningImage() = self.gifImage()
}
