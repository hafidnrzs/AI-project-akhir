import os
import cv2
import numpy as np
import pickle

import sys
current_folder = os.path.dirname(__file__) # ./backend_classification
sys.path.append(current_folder)
from FeatureExtractor_GLCM import GLCMFeatureExtractor

class ImageClassifierTester:
    def __init__(self, model_dir, feature_dir, feature_type):
        self.model_dir = model_dir
        self.feature_dir = feature_dir
        self.feature_type = feature_type
        self.data = None
        self.labels = None
        self.classifier = None
        self.feature_extractors = {
            "histogram": self.extract_histogram,
            "glcm": self.extract_glcm
        }

    def extract_histogram(self, image):
        hist = cv2.calcHist([image], [0, 1, 2], None, [8, 8, 8], [0, 256, 0, 256, 0, 256])
        cv2.normalize(hist, hist)
        hist = hist.flatten()
        # Flatten and reshape histogram to 1-dimensional array
        hist = hist.reshape(1, -1)
        return hist

    def extract_glcm(self, image):
        feature_extractor = GLCMFeatureExtractor()
        glcm_features = feature_extractor.compute_glcm_features(image)
        return glcm_features

    def load_data(self):
        self.data = np.load(os.path.join(self.feature_dir, 'data.npy'))
        self.labels = np.load(os.path.join(self.feature_dir, 'labels.npy'))

    def load_classifier(self, classifier_type):
        model_file = os.path.join(self.model_dir, f'{classifier_type}_model.pkl')
        with open(model_file, 'rb') as f:
            self.classifier = pickle.load(f)

    def read_image(self, test_image_path):
        image = cv2.imread(test_image_path)
        return image

    def process_image(self, image):
        image = image
        return image

    def test_classifier(self, test_image_path):
        image = self.read_image(test_image_path)	
        image = self.process_image(image)
        features = self.feature_extractors[self.feature_type](image)
        features = features.reshape(1, -1)

        prediction = self.classifier.predict(features)
        return prediction[0], features, image


if __name__ == "__main__":
    MODEL_DIR = os.path.join(current_folder, 'model')
    FEATURE_DIR = os.path.join(current_folder, 'fitur')
    FEATURE_TYPE = 'histogram'  # choose from 'histogram', 'glcm', or 'histogram_glcm'
    CLASSIFIER_TYPE = "mlp"  # "mlp", "naive_bayes"

    TEST_IMAGE_PATH = os.path.join(current_folder, 'C:\SEMESTER 3\FOLDER MATERI SEM 3\KECERDASAN BUATAN\backend_classification\dataset\Car_lite\Mobil\Mitsubishi_Eclipse Cross_2019_23_16_150_15_4_71_66_173_26_FWD_5_4_SUV_Tnj.jpg')

    # Create an instance of ImageClassifierTester
    tester = ImageClassifierTester(MODEL_DIR, FEATURE_DIR, FEATURE_TYPE)
    tester.load_data()
    tester.load_classifier(CLASSIFIER_TYPE)

    # Test the classifier on the test image
    prediction = tester.test_classifier(TEST_IMAGE_PATH)
    print("Prediction:", prediction)
#coba apakah bisa ke update