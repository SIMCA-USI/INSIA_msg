# Detection3D.msg
# Información geométrica y física extraída del LiDAR.
# Unidad de medida de posición, dimensiones y distancias: metros.
# Unidad de medida de ángulos: radianes.

# Número de puntos LiDAR válidos en el clúster
uint16 num_valid_points

# Distancia mínima al borde más cercano del objeto al sensor (metros)
float32 min_dist_to_obs

# Centroide del clúster en coordenadas del sensor (metros)
geometry_msgs/Point location   # x=adelante, y=lateral, z=altura

# Dimensiones de la OBB orientada
float32 height   # dimensión en Z (metros)
float32 width    # dimensión en Y (metros)
float32 length   # dimensión en X (metros)
float32 yaw      # orientación de la OBB respecto a X del sensor (radianes)

# Huella esférica del clúster en coordenadas esféricas del sensor LiDAR.
# Permite saber el ángulo sólido que ocupa el objeto en el FOV del sensor.
# Convenio: x=r (rango en metros), y=theta (azimut en rad), z=phi (elevación en rad)
geometry_msgs/Point32 min_cuboid  # esquina inferior-cercana del cuboid esférico
geometry_msgs/Point32 max_cuboid  # esquina superior-lejana del cuboid esférico

# Confianza de la estimación LiDAR (ej. dbscan_confidence, 0.0..1.0)
float32 score
