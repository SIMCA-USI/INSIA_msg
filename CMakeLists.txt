cmake_minimum_required(VERSION 3.8)
project(insia_msg)

# Default to C99
if(NOT CMAKE_C_STANDARD)
  set(CMAKE_C_STANDARD 99)
endif()

# Default to C++14
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  # the following line skips the linter which checks for copyrights
  # uncomment the line when a copyright and license is not present in all source files
  #set(ament_cmake_copyright_FOUND TRUE)
  # the following line skips cpplint (only works in a git repo)
  # uncomment the line when this package is not in a git repo
  #set(ament_cmake_cpplint_FOUND TRUE)
  ament_lint_auto_find_test_dependencies()
endif()

# =============================================================================
#  DESCUBRIMIENTO AUTOMÁTICO DE INTERFACES
#
#  - Recorre TODAS las subcarpetas buscando .msg / .srv / .action
#    (basta con crear una carpeta nueva con interfaces, no hay que tocar nada).
#  - Analiza los tipos que usa cada interfaz:
#      * tipos locales (mismo paquete)  -> deben existir en el propio paquete
#      * tipos externos (pkg/Tipo)      -> se hace find_package(pkg) automático
#    Las interfaces con dependencias inexistentes se saltan con un WARNING
#    (en cascada: si se salta A y B usa A, también se salta B).
#  - Nombres duplicados: gana la carpeta prioritaria (msg/, srv/, action/) y
#    luego el orden alfabético; el resto se ignora con un WARNING.
# =============================================================================

# ON -> error en vez de aviso si una interfaz tiene dependencias rotas
option(INSIA_MSG_STRICT "Fallar si alguna interfaz tiene dependencias inexistentes" OFF)

# Carpetas (primer nivel) que nunca se recorren
set(EXCLUDED_DIRS build install log)

# Interfaces concretas a ignorar a mano (ruta relativa al paquete), p.ej. srv/Foo.srv
set(EXCLUDED_INTERFACES "")

# Carpetas con prioridad en caso de nombres duplicados
set(PRIORITY_DIRS msg srv action)

set(PRIMITIVE_TYPES
  bool byte char float32 float64
  int8 uint8 int16 uint16 int32 uint32 int64 uint64
  string wstring
)

# --- 1. Buscar ficheros -------------------------------------------------------
file(GLOB_RECURSE all_files CONFIGURE_DEPENDS
  RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
  "${CMAKE_CURRENT_SOURCE_DIR}/*.msg"
  "${CMAKE_CURRENT_SOURCE_DIR}/*.srv"
  "${CMAKE_CURRENT_SOURCE_DIR}/*.action"
)

set(priority_files "")
set(other_files "")
foreach(rel IN LISTS all_files)
  if(rel MATCHES "(^|/)\\.")            # carpetas/ficheros ocultos (.git, .idea...)
    continue()
  endif()
  string(REGEX MATCH "^[^/]+" top "${rel}")
  if(top IN_LIST EXCLUDED_DIRS)
    continue()
  endif()
  if(rel IN_LIST EXCLUDED_INTERFACES)
    message(STATUS "[${PROJECT_NAME}] Excluida a mano: ${rel}")
    continue()
  endif()
  if(top IN_LIST PRIORITY_DIRS AND rel MATCHES "/")
    list(APPEND priority_files ${rel})
  else()
    list(APPEND other_files ${rel})
  endif()
endforeach()
list(SORT priority_files)
list(SORT other_files)
set(candidates ${priority_files} ${other_files})

# --- 2. Quitar duplicados -----------------------------------------------------
set(seen_keys "")
set(selected "")
foreach(rel IN LISTS candidates)
  get_filename_component(name ${rel} NAME)
  get_filename_component(ext  ${rel} LAST_EXT)
  string(SUBSTRING ${ext} 1 -1 kind)
  set(key "${kind}/${name}")
  string(MAKE_C_IDENTIFIER "${key}" key_id)
  if(key IN_LIST seen_keys)
    message(WARNING "[${PROJECT_NAME}] '${rel}' ignorada: ya se usa '${OWNER_${key_id}}' para ${key}")
    continue()
  endif()
  list(APPEND seen_keys ${key})
  set(OWNER_${key_id} ${rel})
  list(APPEND selected ${rel})
endforeach()

# --- 3. Analizar dependencias de cada interfaz --------------------------------
foreach(rel IN LISTS selected)
  string(MAKE_C_IDENTIFIER "${rel}" id)
  set(LOCAL_DEPS_${id} "")
  set(EXT_DEPS_${id} "")
  set(MISSING_EXT_${id} "")

  # Leer y normalizar para poder tratarlo como lista CMake de forma segura
  file(READ ${CMAKE_CURRENT_SOURCE_DIR}/${rel} content)
  string(REPLACE "\r" "" content "${content}")
  string(REPLACE ";" "," content "${content}")
  string(REPLACE "[" "(" content "${content}")
  string(REPLACE "]" ")" content "${content}")
  string(REPLACE "\n" ";" lines "${content}")

  foreach(line IN LISTS lines)
    if(NOT line MATCHES "^[ \t]*([A-Za-z][A-Za-z0-9_/]*)")
      continue()                         # vacía, comentario o separador ---
    endif()
    set(type "${CMAKE_MATCH_1}")
    string(REPLACE "/msg/" "/" type "${type}")
    if(type IN_LIST PRIMITIVE_TYPES)
      continue()
    endif()
    if(type MATCHES "^([^/]+)/([^/]+)$")
      set(pkg ${CMAKE_MATCH_1})
      set(tname ${CMAKE_MATCH_2})
      if(pkg STREQUAL PROJECT_NAME)
        list(APPEND LOCAL_DEPS_${id} ${tname})
      else()
        list(APPEND EXT_DEPS_${id} "${pkg}/${tname}")
      endif()
    else()
      list(APPEND LOCAL_DEPS_${id} ${type})
    endif()
  endforeach()

  # Comprobar dependencias externas (paquete instalado y tipo existente)
  foreach(dep IN LISTS EXT_DEPS_${id})
    string(REGEX MATCH "^([^/]+)/([^/]+)$" _ "${dep}")
    set(pkg ${CMAKE_MATCH_1})
    set(tname ${CMAKE_MATCH_2})
    if(NOT DEFINED _CHECKED_PKG_${pkg})
      find_package(${pkg} QUIET)
      set(_CHECKED_PKG_${pkg} TRUE)
    endif()
    if(NOT ${pkg}_FOUND)
      list(APPEND MISSING_EXT_${id} "${dep} (paquete no encontrado)")
    elseif(NOT EXISTS "${${pkg}_DIR}/../msg/${tname}.msg"
       AND NOT EXISTS "${${pkg}_DIR}/../msg/${tname}.idl")
      list(APPEND MISSING_EXT_${id} "${dep}")
    endif()
  endforeach()
endforeach()

# --- 4. Descartar interfaces con dependencias rotas (en cascada) --------------
set(valid ${selected})
set(skipped "")
set(changed TRUE)
while(changed)
  set(changed FALSE)

  set(valid_msgs "")
  foreach(rel IN LISTS valid)
    if(rel MATCHES "\\.msg$")
      get_filename_component(stem ${rel} NAME_WE)
      list(APPEND valid_msgs ${stem})
    endif()
  endforeach()

  set(next "")
  foreach(rel IN LISTS valid)
    string(MAKE_C_IDENTIFIER "${rel}" id)
    set(missing ${MISSING_EXT_${id}})
    foreach(t IN LISTS LOCAL_DEPS_${id})
      if(NOT t IN_LIST valid_msgs)
        list(APPEND missing ${t})
      endif()
    endforeach()

    if(missing)
      list(REMOVE_DUPLICATES missing)
      string(REPLACE ";" ", " missing_str "${missing}")
      set(msg "[${PROJECT_NAME}] '${rel}' NO se compila: faltan tipos -> ${missing_str}")
      if(INSIA_MSG_STRICT)
        message(FATAL_ERROR "${msg}")
      endif()
      message(WARNING "${msg}")
      list(APPEND skipped ${rel})
      set(changed TRUE)
    else()
      list(APPEND next ${rel})
    endif()
  endforeach()
  set(valid ${next})
endwhile()

if(NOT valid)
  message(FATAL_ERROR "[${PROJECT_NAME}] No hay ninguna interfaz válida que compilar")
endif()

# --- 5. Staging (rosidl exige carpetas msg/ srv/ action/) ---------------------
set(STAGE_DIR ${CMAKE_CURRENT_BINARY_DIR}/staged_interfaces)
file(REMOVE_RECURSE ${STAGE_DIR})   # evita restos de interfaces borradas/excluidas

set(INTERFACE_FILES "")
set(DEP_PKGS "")
foreach(rel IN LISTS valid)
  get_filename_component(name ${rel} NAME)
  get_filename_component(ext  ${rel} LAST_EXT)
  string(SUBSTRING ${ext} 1 -1 kind)

  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/${rel} ${STAGE_DIR}/${kind}/${name} COPYONLY)
  list(APPEND INTERFACE_FILES "${STAGE_DIR}:${kind}/${name}")

  string(MAKE_C_IDENTIFIER "${rel}" id)
  foreach(dep IN LISTS EXT_DEPS_${id})
    string(REGEX MATCH "^[^/]+" pkg "${dep}")
    list(APPEND DEP_PKGS ${pkg})
  endforeach()
endforeach()
if(DEP_PKGS)
  list(REMOVE_DUPLICATES DEP_PKGS)
  list(SORT DEP_PKGS)
endif()

# Avisar si falta alguna dependencia en package.xml
file(READ ${CMAKE_CURRENT_SOURCE_DIR}/package.xml package_xml)
foreach(pkg IN LISTS DEP_PKGS)
  if(NOT package_xml MATCHES "<(depend|build_depend)>[ \t]*${pkg}[ \t]*</")
    message(WARNING "[${PROJECT_NAME}] Añade <depend>${pkg}</depend> a package.xml")
  endif()
endforeach()

list(LENGTH valid n_ok)
list(LENGTH skipped n_skip)
message(STATUS "[${PROJECT_NAME}] Interfaces a compilar: ${n_ok} | saltadas: ${n_skip} | dependencias: ${DEP_PKGS}")

# --- 6. Generar ---------------------------------------------------------------
set(dep_args "")
if(DEP_PKGS)
  set(dep_args DEPENDENCIES ${DEP_PKGS})
endif()

rosidl_generate_interfaces(${PROJECT_NAME}
  ${INTERFACE_FILES}
  ${dep_args}
)

ament_export_dependencies(rosidl_default_runtime ${DEP_PKGS})

ament_package()