#include "ecs/core/version.h"

#include <gtest/gtest.h>

namespace ecs {
namespace {

TEST(VersionTest, ReturnsConfiguredSemanticVersion) {
  EXPECT_EQ(GetVersionMajor(), 0);
  EXPECT_EQ(GetVersionMinor(), 1);
  EXPECT_EQ(GetVersionPatch(), 0);
  EXPECT_EQ(GetVersionString(), "0.1.0");
}

}  // namespace
}  // namespace ecs
