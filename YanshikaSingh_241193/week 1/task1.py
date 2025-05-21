import cv2

import numpy as np  
import tkinter as tk
        
from tkinter import filedialog, Tk
from PIL import Image
from pyparsing import C

root = Tk()
root.withdraw()  
file_path = filedialog.askopenfilename()
image = Image.open(r"C:/Users/HP/Documents/image_descon.jpg")  

image = cv2.imread(r"C:/Users/HP/Documents/image_descon.jpg")
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

blurred = cv2.GaussianBlur(gray, (5, 5), 0)
edges = cv2.Canny(blurred, 50, 150)
row_indexes, col_indexes = np.nonzero(edges)
print("row_indexes[0], column_indexes[0]",row_indexes[0], col_indexes[0])
# to find the slope of the line
def find_slope(x1, y1, x2, y2):
    if x2 - x1 == 0:
        return float('inf')  # vertical line
    return (y2 - y1) / (x2 - x1)
# Find the first two non-zero points
x1, y1 = col_indexes[0], row_indexes[0]
x2, y2 = col_indexes[1], row_indexes[1]
slope = find_slope(x1, y1, x2, y2)  
print("Slope of the line between the first two non-zero points:", slope)
# Draw the line on the original image
line_color = (0, 255, 0)  # Green color
line_thickness = 2
cv2.line(image, (x1, y1), (x2, y2), line_color, line_thickness)
# Show the image with the line
cv2.imshow('Image with Line', image)    

cv2.waitKey(0)
cv2.destroyAllWindows()
print("Slope of the line between the first two non-zero points:", slope)

