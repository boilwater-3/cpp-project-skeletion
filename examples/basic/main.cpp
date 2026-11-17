#include <iostream>

#include "ecs/core/version.h"

int main() {
  std::cout << "ecs version: " << ecs::GetVersionString() << '\n';
  return 0;
}
