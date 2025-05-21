import numpy as np
import cv2
# print(cv2.__version__)
img = cv2.imread("C:/Users/jiyaa/OneDrive/Desktop/OpenCV/line2.jpeg") # upload file


 
img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) # convert to grayscale



img_edges = cv2.Canny(img_gray, 100, 200)

img_blur = cv2.GaussianBlur(img_gray, (5, 5), 0) #blur the image

edges = cv2.Canny(img_gray, threshold1=50, threshold2=150, apertureSize=3) 

lines = cv2.HoughLinesP(edges, rho=1, theta=np.pi/180, threshold=0, minLineLength=0, maxLineGap=0)

# Draw lines and print coordinates
if lines is not None:
    for line in lines:
        x1, y1, x2, y2 = line[0]
        # print(f"Line detected from ({x1}, {y1}) to ({x2}, {y2})")
        cv2.line(img, (x1, y1), (x2, y2), (0, 255, 0), 2)

cv2.imshow('Detected Line', img)
cv2.waitKey(0)

min_y = 99999999
max_y = -99999999
min_x = 999999999
max_x = -999999999

for line in lines:
        x1, y1, x2, y2 = line[0]
        min_y = min(min_y, y1, y2)
        max_y = max(max_y, y1, y2)
        min_x = min(min_x, x1, x2)
        max_x = max(max_x, x1, x2)

# print(f"Smallest y value: {min_y}")
# print(f"Largest y value: {max_y}")

# print(f"Smallest x value: {min_x}")
# print(f"Largest x value: {max_x}")

print(f"(x1,y1) = {max_x},{min_y} ")
print(f"(x2,y2) = {min_x},{max_y}")

# To find slope

m = ((max_y)-(min_y))/((max_x)-(min_x))
print(f"Slope of the line is: {m}")