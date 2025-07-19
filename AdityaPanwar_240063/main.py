from fastapi import FastAPI, File, UploadFile
from fastapi.responses import StreamingResponse
import cv2
import numpy as np
import io

app = FastAPI()

def rescaleFrame(frame):
    height, width = frame.shape[:2]
    scale_factor = max(height, width) / 500
    dimensions = (int(width / scale_factor), int(height / scale_factor))
    return cv2.resize(frame, dimensions, interpolation=cv2.INTER_AREA)

def skeletonize(img):
    _, img_bin = cv2.threshold(img, 100, 255, cv2.THRESH_BINARY)
    skel = np.zeros(img_bin.shape, np.uint8)
    kernel = cv2.getStructuringElement(cv2.MORPH_CROSS, (3, 3))

    while True:
        eroded = cv2.erode(img_bin, kernel)
        temp = cv2.dilate(eroded, kernel)
        temp = cv2.subtract(img_bin, temp)
        skel = cv2.bitwise_or(skel, temp)
        img_bin = eroded.copy()
        if cv2.countNonZero(img_bin) == 0:
            break
    return skel

@app.post("/redraw")
async def redraw_image(file: UploadFile = File(...)):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)

    img_rescaled = rescaleFrame(img)
    _, binary = cv2.threshold(img_rescaled, 150, 255, cv2.THRESH_BINARY_INV)

    kernel = np.ones((5, 5), np.uint8)
    morph_gradient = cv2.morphologyEx(binary, cv2.MORPH_GRADIENT, kernel)

    skeleton = skeletonize(binary)
    skeleton_color = cv2.cvtColor(skeleton, cv2.COLOR_GRAY2BGR)
    edges = cv2.Canny(skeleton_color, 50, 150, apertureSize=3)

    linesP = cv2.HoughLinesP(edges, 1, np.pi/180, threshold=0, minLineLength=0, maxLineGap=0)
    if linesP is not None:
        for x1, y1, x2, y2 in linesP[:, 0]:
            cv2.line(img_rescaled, (x1, y1), (x2, y2), (0, 255, 0), 2)

    # Encode the image as PNG and return
    _, img_encoded = cv2.imencode('.png', img_rescaled)
    return StreamingResponse(io.BytesIO(img_encoded.tobytes()), media_type="image/png")
