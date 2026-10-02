find_package(HYPRE 2.33 CONFIG REQUIRED)
add_library(sc26_problem_dependencies INTERFACE)
target_link_libraries(sc26_problem_dependencies INTERFACE HYPRE::HYPRE)
