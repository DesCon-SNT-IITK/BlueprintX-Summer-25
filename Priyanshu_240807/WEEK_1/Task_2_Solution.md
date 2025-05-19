# WEEK 1; TASK 2 SOLUTION

**Gradient-Based Line Detection + RANSAC Line Fitting**

 * Detecting edges using Canny and then applying Hough Transform
 * Detect edges using gradient filters ( using Sobel)
 * use RANSAC to fit straight lines on these points.

**Pipeline Breakdown (Step By Step)**

1. **Grayscale Conversion**
   * Convert the image to grayscale to simplify processing.

2. **Apply Gradient Filter(Sobel)**
   * Gx = sobel horizontal gradient (x-axis)
   * Gy = soble vertical gradient (y-axis)
   * G = Gradient magnitude
                 G = sqrt( (Gx^2) + (Gy^2) )

3. **Thresholding the Gradient Magnitude**
    * Finding strong edges
    * threshold edges = 100
            Edges = G > 100

4. **Get coordinates of non-zero pixels in edges**
    * Extract coordinates(x,y) of all non-zero pixels in the thresholded gradient image.

5. **Line Fitting using RANSAC**
    * in input set of edge points
    * use RANSAC regression to
      * Fit a line using above points
      * identify inliers(points that close to the line)
    * remove inliers and repeat until  no significant sets remain.

6. **Result**
    * Get starting point(x1, y1)

           min_inlier_x = x1
           min_inlier_y = y1

          ending point(x2, y2)

           max_inlier_x = x2
           max_inlier_y = y2

          slope = (y2 - y1)/(x2 - x1)

***Peudocode***
* step 1: Read and preprocess
img = read_image('PATH_OF_IMAGE')
gray = cvtColor(img, COLOR_BGR2GRAY)

* step 2: Apply Gradient filter
Gx = sobel(img, axis='x')
Gy = sobel(img, axis='y')
G = sqrt( (Gx**2) + (Gy**2) )

* step 3: Threshold to get edges
edges = G > Threshold
edges_points = get_nonzero_coordinates(edges)

* step 4: Fit lines using RANSAC
while edge_point != 0:
    line_model = run_RANSAC(edge_points)
    inliers = get_points_close_to_line(line_model, edge_points)

    if len(inliers) < MIN_INLIERS:
        break

    lines.append(line_model)
    edge_points = edge_point - inliers

* Step 5: output
for line in lines:
    x1, y1, x2, y2 = get_line_endpoints(line)
    if x1 == x2:
       slope = 'undefine'
    else:
       slope = (y2-y1)/(x2-x1)
    line = draw.line(pt1= (x1, y1), pt=(x2, y2), color = (255, 255, 255), thickness = 1)
    imshow(Line)

***Resources/References***
1. **RANSAC Regression**
    It helped implement robust line fitting that can reject outliers.
    link - https://www.youtube.com/watch?v=BHNNz6jCuHw
2. **Sobel Edge Detection**
    Used to compute horizontal and vertical gradients
    link - https://www.youtube.com/watch?v=Yz7h9L4gecQ
3. **Canny and Hough Transform**
    To detecting edges and print lines
    link (Canny Edge Detection) - https://docs.opencv.org/4.x/da/d22/tutorial_py_canny.html#autotoc_md1302
    link (Hough Line Transform) - https://docs.opencv.org/4.x/d6/d10/tutorial_py_houghlines.html