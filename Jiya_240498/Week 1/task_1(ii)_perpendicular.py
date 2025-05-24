#TWO PERPENDICULAR LINES

import numpy as np
import cv2
# print(cv2.__version__)
img = cv2.imread("C:/Users/jiyaa/OneDrive/Desktop/OpenCV/perpendicular.jpeg") # upload file


 
img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) # convert to grayscale



img_edges = cv2.Canny(img_gray, 100, 200)

img_blur = cv2.GaussianBlur(img_gray, (5, 5), 0) #blur the image

edges = cv2.Canny(img_gray, threshold1=50, threshold2=150, apertureSize=3)  


_, binary = cv2.threshold(img_gray, 128, 255, cv2.THRESH_BINARY_INV)

# Detect horizontal lines
horizontal_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (40, 1))
horizontal_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, horizontal_kernel, iterations=1)

hlines = cv2.HoughLinesP(horizontal_lines, 1, np.pi / 180, threshold=100, minLineLength=50, maxLineGap=10)


if hlines is not None:
    for line in hlines:
        x1, y1, x2, y2 = line[0]
        # print(f"Line detected from ({x1}, {y1}) to ({x2}, {y2})")
        cv2.line(hlines, (x1, y1), (x2, y2), (0, 255, 0), 2)


min_y = 99999999
max_y = -99999999
min_x = 999999999
max_x = -999999999

for line in hlines:
        x1, y1, x2, y2 = line[0]
        min_y = min(min_y, y1, y2)
        max_y = max(max_y, y1, y2)
        min_x = min(min_x, x1, x2)
        max_x = max(max_x, x1, x2)

print(f"For horizontal lines:")

print(f"Smallest y value: {min_y}")
print(f"Largest y value: {max_y}")

print(f"Smallest x value: {min_x}")
print(f"Largest x value: {max_x}")

cv2.imshow('Detected Line', horizontal_lines)
cv2.waitKey(0)

#Detect vertical line
vertical_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, 40))
vertical_lines = cv2.morphologyEx(binary, cv2.MORPH_OPEN, vertical_kernel, iterations=1)

vlines = cv2.HoughLinesP(vertical_lines, 1, np.pi / 180, threshold=100, minLineLength=50, maxLineGap=10)


if vlines is not None:
    for line in vlines:
        a1, b1, a2, b2 = line[0]
        # print(f"Line detected from ({x1}, {y1}) to ({x2}, {y2})")
        cv2.line(vlines, (a1,b1), (a2,b2), (0, 255, 0), 2)


min_a = 99999999
max_a = -99999999
min_b = 999999999
max_b = -999999999

for line in vlines:
        a1, b1, a2, b2 = line[0]
        min_b = min(min_b, b1, b2)
        max_b = max(max_b, b1, b2)
        min_a = min(min_a, a1, a2)
        max_a = max(max_a, a1, a2)

print(f"")

print(f"For vertical lines:")

print(f"Smallest b value: {min_b}")
print(f"Largest b value: {max_b}")

print(f"Smallest a value: {min_a}")
print(f"Largest a value: {max_a}")


cv2.imshow('Detected Line', vertical_lines)
cv2.waitKey(0)

# Combine
combined = cv2.addWeighted(horizontal_lines, 0.5, vertical_lines, 0.5, 0)

cv2.imshow('Combined Line', combined)
cv2.waitKey(0)
cv2.destroyAllWindows()

image = np.zeros((500, 500, 3), dtype=np.uint8) #blank image

# Define two points
point1 = (max_x,max_y)
point2 = (max_a, max_b)

# Draw a line between the points
cv2.line(image, point1, point2, (0, 255, 0), 4)

# Show the image
cv2.imshow('Line between two points', image)
cv2.waitKey(0)
cv2.destroyAllWindows()







