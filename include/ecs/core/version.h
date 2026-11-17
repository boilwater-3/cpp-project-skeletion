#ifndef ECS_CORE_VERSION_H_
#define ECS_CORE_VERSION_H_

#include <string>

#include "ecs/ecs_export.h"

namespace ecs {

ECS_EXPORT int GetVersionMajor();
ECS_EXPORT int GetVersionMinor();
ECS_EXPORT int GetVersionPatch();
ECS_EXPORT std::string GetVersionString();

}  // namespace ecs

#endif  // ECS_CORE_VERSION_H_
