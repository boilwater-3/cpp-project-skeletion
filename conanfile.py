from conan import ConanFile
from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout

_BASE_DEPS = {
    "spdlog": "spdlog/1.12.0",
    "fmt": "fmt/10.2.1",
}

_GTEST_VERSION = "gtest/1.12.1"


class EcsConan(ConanFile):
    name = "ecs"
    version = "0.1.0"
    settings = "os", "compiler", "build_type", "arch"

    options = {
        "enable_testing": [True, False],
    }

    default_options = {
        "enable_testing": False,
        # 显式固定第三方链接形态，避免依赖 recipe 默认值导致构建行为漂移。
        "spdlog/*:shared": False,
        "fmt/*:shared": False,
        "gtest/*:shared": False,
    }

    def requirements(self):
        self.requires(_BASE_DEPS["spdlog"])
        self.requires(_BASE_DEPS["fmt"], override=True)

    def build_requirements(self):
        if self.options.enable_testing:
            self.test_requires(_GTEST_VERSION)

    def generate(self):
        CMakeDeps(self).generate()
        tc = CMakeToolchain(self)
        tc.generate()

    def layout(self):
        cmake_layout(self)
