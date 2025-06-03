import cv2
import numpy as np
import pandas as pd

def rescaleFrame(frame):

    height = int(frame.shape[0])
    width = int(frame.shape[1])
    w=int(width/800)
    h=int(height/800)
    if h==0 or w==0:
        return frame
    elif(h > w):
        n = h
    else:
        n = w    

    
    dimensions = (int(width/n),int(height/n))

    return cv2.resize(frame, dimensions, interpolation=cv2.INTER_AREA)

# Load Image
image = rescaleFrame(cv2.imread(r"C:\Users\adity\OneDrive\Desktop\Blueprint1.jpg"))
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
edges = cv2.Canny(image, threshold1=180, threshold2=250, apertureSize=3)

# Detect Lines
lines = cv2.HoughLinesP(edges, 1, np.pi / 180, threshold=5, minLineLength=0, maxLineGap=0)

# Prepare Data Storage
line_data = []

for i, line in enumerate(lines):
    x1, y1, x2, y2 = line[0]
    slope = (y2 - y1) / (x2 - x1) if x2 != x1 else None  # Handle vertical lines
    
    # Draw Line
    cv2.line(image, (x1, y1), (x2, y2), (0, 255, 0), 2)
    
    # Store Data
    line_data.append({"Line_ID": i + 1, "Start": (x1, y1), "End": (x2, y2), "Slope": slope})

# Save Outputs
cv2.imshow("output", image)
pd.DataFrame(line_data).to_csv("line_data.csv", index=False)
cv2.waitKey(0)
cv2.destroyAllWindows
