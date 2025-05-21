import cv2
import numpy as np
import tkinter as tk
from tkinter import filedialog

def redraw_line_and_find_endpoints(image_path, line_color=(0, 255, 0), line_thickness=2):
    print(f"Trying to read image at: {image_path}")
    image = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)

    if image is None:
        print(f"Error: Could not read image at {image_path}")
        return None, None, None

    _, binary = cv2.threshold(image, 127, 255, cv2.THRESH_BINARY)

    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    if not contours:
        print("No contours found.")
        return None, None, None

    cnt = contours[0]
    [vx, vy, x, y] = cv2.fitLine(cnt, cv2.DIST_L2, 0, 0.01, 0.01)

    rows, cols = image.shape[:2]
    length = max(rows, cols)

    x1 = int(x - vx * length)
    y1 = int(y - vy * length)
    x2 = int(x + vx * length)
    y2 = int(y + vy * length)

    image_color = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
    cv2.line(image_color, (x1, y1), (x2, y2), line_color, line_thickness)

    return image_color, (x1, y1), (x2, y2)

# GUI file picker
def select_and_process_image():
    root = tk.Tk()
    root.withdraw()  # Hide the root window

    file_path = filedialog.askopenfilename(
        title="Select an Image File",
        filetypes=[("Image files", "*.jpg *.jpeg *.png *.bmp *.tif")]
    )

    if not file_path:
        print("No file selected.")
        return

    print(f"Selected file: {file_path}")
    image_with_line, start_point, end_point = redraw_line_and_find_endpoints(file_path)

    if image_with_line is not None:
        print("Start point:", start_point)
        print("End point:", end_point)
        cv2.imshow("Detected Line", image_with_line)
        cv2.waitKey(0)
        cv2.destroyAllWindows()
    else:
        print("Line detection failed.")

# Run it
select_and_process_image()
