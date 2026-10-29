# ObjectDetected.msg
# Mensaje unificado para objetos visuales (YOLO) y obstáculos del terreno (LiDAR)

# ── Tipos de Objeto (Visual / YOLO) ─────────
uint8 PERSON = 0
uint8 BICYCLE = 1
uint8 CAR = 2
uint8 MOTORCYCLE = 3
uint8 BARRENDERO = 4
uint8 BUS = 5
uint8 TRUCK = 7

# ── Tipos de Obstáculo (Terreno / LiDAR) ────
# Usamos IDs altos para no chocar con las clases de YOLO
uint8 BUMP = 100
uint8 HOLE = 101
uint8 DESCENDING_CURB = 102

# ── Identificación ──────────────────────────
int32 id                   # ID del tracker (YOLO) o ID de clúster (LiDAR)
uint8 label                # Clase semántica (YOLO) o tipo de obstáculo (BUMP/HOLE)
string label_name          # "Persona", "Resalto", etc.
float32 probability        # Confianza de la detección (0.0 a 1.0)
bool follow                # True si el robot debe seguir a este objeto

# ── Geometría 2D (Cámara) ───────────────────
Detection2D camera         # Bounding box 2D y máscara (vacío para obstáculos de terreno)
sensor_msgs/Image crop     # (Opcional) Imagen recortada del objeto para clasificación secundaria

# ── Geometría 3D (LiDAR) ────────────────────
Detection3D lidar          # Dimensiones 3D, distancia (percentil 5% o min), centroide

# ── Datos Específicos Terreno / LiDAR ───────
float32 magnitude          # Altura del resalto / Profundidad del hoyo (metros)
bool passable              # Indica si se puede pasar por encima (para obstáculos)
uint16 point_count         # Puntos LiDAR que conforman el objeto
int32 semantic_class       # -1=sin clasificar, 0..24=label YOLO (para obstáculos de terreno)
string semantic_name       # nombre legible de la clase semántica (para obstáculos de terreno)
