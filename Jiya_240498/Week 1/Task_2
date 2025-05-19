Alternative line detection method

Objective:    Research and propose an alternative approach to detect straight lines in an image without using the standard OpenCV methods like Canny edge detection or Hough Line Transform. The aim is to understand other viable techniques for line detection and assess their applicability.


Straight line detection using Principal component analysis(PCA)

PCA is a well-known metric method that produces the base axes of a distribution of data.
 Given an ideal straight line in two dimension, it has some principal components deduced from the eigenvectors and eigenvalues of the scatter matrix. The eigenvector means one main direction of the distribution of the pixels of a line and the eigenvalue means how long the distribution is.
The time complexity is O(ka).

For instance, in the case of large-scale outdoor scenario, autonomous and safe navigation is ensured by the classical sensor fusion architectures integrating an Inertial Navigation System (INS) with GPS, typically indicated as GPS-INS [2, 3], which has been extensively exploited by researchers considering fixed-wing [4, 5], helicopter [6, 7], and multirotor [8] UAVs. Nevertheless, a wide range of both military and applications, for example, urban and indoor surveillance.

Pseudocode of PCA
1.	Standardization.
2.	Compute the covariance matrix.
3.	Compute eigenvectors and eigenvalues from the covariance matrix.
4.	Compute the feature vector and principal components
5.	Project the data onto the selected principal components for dimensionality reduction.


 

Limitations of PCA for outlier detection
One limitation of PCA is, it is sensitive to outliers. It’s based on minimizing squared distances of the points to the components, so it can be heavily affected by outliers (remote points can have very large squared distances). To address this, robust PCA is often used, where the extreme values in each dimension are removed before performing the transformation. The example below includes this.
Another limitation of PCA (as well as Mahalanobis distances and similar methods), is it can break down if the correlations are in only certain regions of the data, which is frequently true if the data is clustered. Where data is well-clustered, it may be necessary to cluster (or segment) the data first, and then perform PCA on each subset of the data.

Comparison with open cv

  Functionality:
•	PCA is a technique for reducing the dimensionality of data, often used as part of a larger machine learning pipeline.
•	OpenCV is a full-fledged computer vision library that offers a wide variety of tools and algorithms for image and video processing.
Scope:
•	PCA is specifically focused on data reduction and feature extraction.
•	OpenCV covers everything from simple image processing to complex algorithms for object detection, machine learning, and deep learning.
•  

Refrences- 
Pattern Recognition Letters
Volume 27, Issue 14, 15 October 2006, Pages 1744-1754

Jian Li, Xiangjing An and Hangen He, "Line segments detection with scale analysis: A principal component analysis based approach," 2009 IEEE International Conference on Intelligent Computing and Intelligent Systems, Shanghai, China, 2009, pp. 43-47, doi: 10.1109/ICICISYS.2009.5357737. keywords: {Principal component analysis;Image segmentation;Image edge detection;Image analysis;Performance analysis;Data mining;Object detection;Computer vision;Helium;Automation;Line segment detection;principal component analysis;multi-scale analysis},

https://medium.com/intro-to-artificial-intelligence/principal-component-analysis-pca-cd282196b7d5

