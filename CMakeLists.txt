cmake_minimum_required(VERSION 3.5)
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
# uncomment the following section in order to fill in
# further dependencies manually.
# find_package(<dependency> REQUIRED)

find_package(std_msgs REQUIRED)

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

find_package(rosidl_default_generators REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/BoolStamped.msg"
  "msg/CAN.msg"
  "msg/CANEthStatus.msg"
  "msg/CANGroup.msg"
  "msg/ControladorFloat.msg"
  "msg/ControladorStr.msg"
  "msg/EPOSAnalog.msg"
  "msg/EPOSConsigna.msg"
  "msg/EPOSDigital.msg"
  "msg/EPOSStatus.msg"
  "msg/FloatStamped.msg"
  "msg/IntStamped.msg"
  "msg/IOAnalogue.msg"
  "msg/MasterSwitch.msg"
  "msg/OpenLoop.msg"
  "msg/Override.msg"
  "msg/PetConduccion.msg"
  "msg/RecCommand.msg"
  "msg/StringStamped.msg"
  "msg/Telemetry.msg"
  "srv/BrakeCalibration.srv"

  "msg/GestionMision.msg"
  "msg/ModoMision.msg"

  "mdef/escribano/Accion.msg"
  "mdef/escribano/AmmoCount.msg"
  "mdef/escribano/AmmoType.msg"
  "mdef/escribano/BrakeStatus.msg"
  "mdef/escribano/CameraSelection.msg"
  "mdef/escribano/Designation.msg"
  "mdef/escribano/Fase.msg"
  "mdef/escribano/FireMode.msg"
  "mdef/escribano/FireStatus.msg"
  "mdef/escribano/FocusCommand.msg"
  "mdef/escribano/LaserRange.msg"
  "mdef/escribano/Mision.msg"
  "mdef/escribano/Misiones.msg"
  "mdef/escribano/MovementStatus.msg"
  "mdef/escribano/MovementType.msg"
  "mdef/escribano/PositionTurret.msg"
  "mdef/escribano/Tarea.msg"
  "mdef/escribano/TareaCdP.msg"
  "mdef/escribano/WeaponType.msg"
  "mdef/escribano/ZoomCommand.msg"

  "gps_msg/RMC.msg"

  "JKU_msgs/Joy.msg"

  DEPENDENCIES  std_msgs
 )

ament_package()
