import cv2
import numpy as np
import pandas as pd
import json

def detect_lines(input_image,output_image_path, output_csv_path, output_json_path):
    # Load image
    image = cv2.imread(input_image)
    if image is None:
        raise FileNotFoundError(f"Image not found at {input_image}")
    
    # Convert to grayscale + edge detection (Canny)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 50, 150, apertureSize=3)
    
    # Detect lines using Hough Transform
    lines = cv2.HoughLinesP(edges, 1, np.pi/180, threshold=100, minLineLength=50, maxLineGap=10)
    
    if lines is None:
        print("No lines detected!")
        return
    
    # Prepare data storage
    line_data = []
    
    # Draw lines and compute slopes
    for i, line in enumerate(lines):
        x1, y1, x2, y2 = line[0]
        
        x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)
        # Calculate slope (avoid division by zero)
        if x2 - x1 != 0:
            slope = (y2 - y1) / (x2 - x1)
        else:
            slope = float('inf')  # Vertical line
        
        # Store line data
        line_data.append({
            "Line ID": i + 1,
            "Start (x1, y1)": (x1, y1),
            "End (x2, y2)": (x2, y2),
            "Slope": slope
        })
        
        # Draw line on original image
        cv2.line(image, (x1, y1), (x2, y2), (0, 255, 0), 2)
    
    # Save output image with detected lines
    cv2.imwrite(output_image_path, image)
    
    # Export to CSV
    df = pd.DataFrame(line_data)
    df.to_csv(output_csv_path, index=False)
    
    # Export to JSON
    with open(output_json_path, 'w') as f:
        json.dump(line_data, f, indent=4)
    
    print(f"✅ Lines detected and saved to {output_image_path}")
    print(f"📊 Data exported to {output_csv_path} and {output_json_path}")

# Example usage
if __name__ == "__main__":
    input_image = "input.jpg" 
    output_image = "output_with_lines.jpg"
    output_csv = "lines_data.csv"
    output_json = "lines_data.json"
    
    detect_lines(input_image, output_image, output_csv, output_json)