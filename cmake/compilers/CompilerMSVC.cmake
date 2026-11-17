# CompilerMSVC.cmake
# 为 MSVC 编译器定义 target 级编译/链接选项应用函数。
# 本文件仅定义函数，不直接调用 add_compile_options() / add_link_options()。

function(apply_msvc_options)
    set(one_value_args ENABLE_WARNINGS)
    set(multi_value_args TARGETS LINK_TARGETS)
    cmake_parse_arguments(ARG "" "${one_value_args}" "${multi_value_args}" ${ARGN})

    if(NOT MSVC)
        message(FATAL_ERROR "apply_msvc_options() requires an MSVC compiler")
    endif()
    if(NOT ARG_TARGETS)
        message(FATAL_ERROR "apply_msvc_options() requires TARGETS")
    endif()
    if(NOT ARG_LINK_TARGETS)
        set(ARG_LINK_TARGETS ${ARG_TARGETS})
    endif()

    message(STATUS "Configuring for MSVC compiler")
    message(STATUS "  └─ Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")

    # /MP：多源文件并行编译；/Zc:inline：剔除 COMDAT 重复定义，缩减代码体积；/utf-8：统一源/执行字符集为 UTF-8。
    set(_msvc_common_compile_options /MP /Zc:inline /utf-8)
    # /permissive- 与 /Zc:referenceBinding 需 VS2017+（MSVC 1910）。
    if(MSVC_VERSION GREATER_EQUAL 1910)
        list(APPEND _msvc_common_compile_options
            /permissive-           # 严格遵循标准 C++，禁用历史非标准扩展
            /Zc:referenceBinding)  # 禁止临时量绑定到非 const 左值引用（标准要求）
    endif()

    foreach(_target IN LISTS ARG_TARGETS)
        if(NOT TARGET "${_target}")
            message(FATAL_ERROR "Compiler target does not exist: ${_target}")
        endif()
        target_compile_options("${_target}" PRIVATE ${_msvc_common_compile_options})
        # _USE_MATH_DEFINES：MSVC 下 M_PI 等常量需要它，且必须在首个 <cmath> 之前生效。
        target_compile_definitions("${_target}" PRIVATE _USE_MATH_DEFINES)
        if(ARG_ENABLE_WARNINGS)
            target_compile_options("${_target}" PRIVATE
                /W4      # 最高信息级别警告（启用绝大多数警告，含 C4xxx 系列）
                /WX-     # 警告不视为错误（保留告警但允许编译继续）
                /w14242  # 从 size_t 隐式截断转换（如 sizeof 结果赋给 int）
                /w14254  # 运算符转换可能导致数据丢失
                /w14263  # 成员函数签名与基类虚函数不一致（虚表未覆盖）
                /w14265  # 类有虚函数但析构函数非 virtual（多态资源泄漏风险）
                /w14287  # 非 const 成员函数调用非 static 数据成员的 this 误用
                /we4289  # 将 for-range 局部变量声明错误使用为错误（标准兼容）
                /w14296  # 表达式始终为 false（疑似逻辑错误）
                /w14311  # 指针截断转换为更小整型（64→32 位指针丢失高位）
                /w14545  # 函数体之前的不确定语句（逗号表达式误写）
                /w14546  # 在形参列表前误用逗号（误写为函数调用）
                /w14547  # 在实参列表前误用逗号
                /w14549  # 形参实参类型不一致（signed/unsigned 提醒）
                /w14555  # 表达式无副作用（疑似缺赋值运算符）
                /w14619  # pragma warning 描述格式错误
                /w14640  # 线程不安全静态局部变量的使用风险提醒
                /w14826  # 从 size_t 到带符号整型的转换可能溢出
                /w14905  # 宽字符串字面量拼接为窄字符串（类型不一致）
                /w14906  # 字符串字面量拼接跨字符串类型不一致
                /w14928) # 异常规范误用（如 throw() 旧式标注）
        else()
            target_compile_options("${_target}" PRIVATE /W3)  # 标准信息级别警告
        endif()

        target_compile_options("${_target}" PRIVATE
            $<$<CONFIG:Debug>:/Z7>                                                # 生成旧式完整调试信息（嵌入 .obj，便于调试）
            $<$<CONFIG:Debug>:/Od>                                                # 关闭优化，变量观察值与源码一致
            $<$<AND:$<CONFIG:Debug>,$<NOT:$<BOOL:${ENABLE_ASAN}>>>:/RTC1>         # 运行期检查（与 ASan 互斥）
            $<$<AND:$<CONFIG:Debug>,$<VERSION_GREATER_EQUAL:${MSVC_VERSION},1910>>:/JMC>  # 启用 Just My Code 调试（仅步入用户代码）
            $<$<CONFIG:Release>:/O2>                                              # 标准优化（真发布档：不保留调试产物）
            $<$<CONFIG:Release>:/Ob2>                                             # 任意内联
            $<$<CONFIG:Release>:/Oi>                                              # 启用内建函数
            $<$<CONFIG:Release>:/GS->                                             # 关闭缓冲区安全检查（性能向，牺牲溢出防护）
            $<$<CONFIG:RelWithDebInfo>:/O2>                                       # 标准优化，兼顾性能与可调试性
            $<$<CONFIG:RelWithDebInfo>:/Ob2>                                      # 任意内联
            $<$<CONFIG:RelWithDebInfo>:/Oi>                                       # 启用内建函数
            $<$<CONFIG:RelWithDebInfo>:/Z7>                                       # 生成完整调试信息
            $<$<CONFIG:MinSizeRel>:/O1>                                           # 以代码体积为目标优化
            $<$<CONFIG:MinSizeRel>:/Os>)                                          # 优化时优先代码体积（而非速度）
    endforeach()

    foreach(_target IN LISTS ARG_LINK_TARGETS)
        if(NOT TARGET "${_target}")
            message(FATAL_ERROR "Compiler link target does not exist: ${_target}")
        endif()
        target_link_options("${_target}" PRIVATE
            $<$<CONFIG:Debug>:/DEBUG:FULL>          # 生成完整 PDB 调试符号
            $<$<CONFIG:Debug>:/INCREMENTAL>         # 启用增量链接，加快反复链接速度
            $<$<CONFIG:Release>:/OPT:REF>           # 移除未引用函数/数据
            $<$<CONFIG:Release>:/OPT:ICF>           # 折叠等价 COMDAT 段
            $<$<CONFIG:Release>:/INCREMENTAL:NO>    # 关闭增量链接，配合 /OPT 优化
            $<$<CONFIG:RelWithDebInfo>:/DEBUG:FULL> # 生成完整 PDB 调试符号
            $<$<CONFIG:RelWithDebInfo>:/OPT:REF>    # 移除未引用函数/数据
            $<$<CONFIG:RelWithDebInfo>:/OPT:ICF>    # 折叠等价 COMDAT 段
            $<$<CONFIG:RelWithDebInfo>:/INCREMENTAL:NO>
            $<$<CONFIG:MinSizeRel>:/OPT:REF>        # 移除未引用函数/数据
            $<$<CONFIG:MinSizeRel>:/OPT:ICF>)       # 折叠等价 COMDAT 段
    endforeach()

    if(ARG_ENABLE_WARNINGS)
        message(STATUS "  └─ Warnings: Enhanced (/W4 + additional checks)")
    else()
        message(STATUS "  └─ Warnings: Standard (/W3)")
    endif()
endfunction()
