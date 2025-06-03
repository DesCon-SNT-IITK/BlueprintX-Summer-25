import cv2
import numpy as np

# Load the image
image = cv2.imread(r"C:\Users\HP\OneDrive\Documents\task3.jpg", cv2.IMREAD_GRAYSCALE)
color_image = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)  # Convert grayscale to color for better visibility

# Apply Gaussian Blur to reduce noise
blurred = cv2.GaussianBlur(image, (5, 5), 0)

# Apply Adaptive Thresholding for better contrast
adaptive_thresh = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                        cv2.THRESH_BINARY, 11, 2)

# Detect edges using Canny
edges = cv2.Canny(adaptive_thresh, 50, 150)

# Detect lines using Hough Transform
lines = cv2.HoughLinesP(edges, 1, np.pi/180, threshold=100, minLineLength=50, maxLineGap=10)

# Extract and annotate the start and end points of detected lines
if lines is not None:
    for line in lines:
        x1, y1, x2, y2 = line[0]  # Line endpoints
        print(f"Start: ({x1}, {y1}), End: ({x2}, {y2})")

        # Draw the detected lines on the image
        cv2.line(color_image, (x1, y1), (x2, y2), (255, 0, 0), 2)

        # Annotate the start and end points
        cv2.putText(color_image, f"({x1},{y1})", (x1, y1), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)
        cv2.putText(color_image, f"({x2},{y2})", (x2, y2), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)

# Show the processed image with annotations
cv2.imshow("Detected Lines with Points", color_image)
cv2.waitKey(0)
cv2.destroyAllWindows()
