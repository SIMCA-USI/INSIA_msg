# Detection2D.msg
# Información extraída exclusivamente de la imagen de cámara (YOLO + Segmentación).
# Unidad de medida de bbox y mask: píxeles.

# Bounding box 2D [x1, y1, x2, y2] en píxeles
float32[4] bbox

# Máscara de segmentación (polígono en píxeles)
geometry_msgs/Polygon mask_contour

# Confianza de la detección del modelo de visión (0.0..1.0)
float32 score
