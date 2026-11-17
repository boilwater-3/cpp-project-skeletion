# ProjectSummary.cmake
# 项目配置汇总打印
# 与 setup 分离，使生命周期在所有产品目录添加后输出最终状态

macro(ecs_print_project_summary)
    message(STATUS "Configuration Summary")
    message(STATUS "  └─ Project: ${PROJECT_NAME} ${PROJECT_VERSION}")
    message(STATUS "  └─ C++ Standard: C++${CMAKE_CXX_STANDARD}")
    message(STATUS "  └─ Build shared libs: ${BUILD_SHARED_LIBS}")
    message(STATUS "  └─ LTO: ${ENABLE_LTO}")
    message(STATUS "  └─ Sanitizers: ASan=${ENABLE_ASAN}, UBSan=${ENABLE_UBSAN}, TSan=${ENABLE_TSAN}")
    message(STATUS "  └─ Build examples: ${ENABLE_EXAMPLES}")
    message(STATUS "  └─ Build tests: ${ENABLE_TESTING}")
    message(STATUS "  └─ Install support: ${ENABLE_INSTALL}")
endmacro()
