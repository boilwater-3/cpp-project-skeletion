#include "ecs/core/version.h"

#include <string>

namespace ecs {

int GetVersionMajor() { return 0; }

int GetVersionMinor() { return 1; }

int GetVersionPatch() { return 0; }

std::string GetVersionString() { return "0.1.0"; }

}  // namespace ecs
