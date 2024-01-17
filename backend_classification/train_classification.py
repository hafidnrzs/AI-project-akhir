import os
import cv2
import numpy as np
from sklearn.neural_network import MLPClassifier
from sklearn.naive_bayes import GaussianNB
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report
import pickle
import warnings
from sklearn.model_selection import cross_val_score
from skimage.feature import hog
from skimage import exposure




import sys
current_folder = os.path.dirname(__file__) # ./backend_classification  # mengubah biar lebih fleksibel
sys.path.append(current_folder)
from FeatureExtractor_GLCM import GLCMFeatureExtractor
warnings.filterwarnings("ignore")

class ImageClassifier:
    def __init__(self, dataset_dir, model_dir, feature_dir, feature_type):
        self.dataset_dir = dataset_dir
        self.model_dir = model_dir
        self.feature_dir = feature_dir
        self.feature_type = feature_type
        self.data = []
        self.labels = []
        self.feature_extractors = {     #feature extractor untuk mereduksi data
            "histogram": self.extract_histogram, 
            "glcm": self.extract_glcm,
            "hog": self.extract_hog
        }
        self.classifiers = {        #klasifikasinya
            "mlp": self.train_mlp,
            "naive_bayes": self.train_naive_bayes
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
    
    def extract_hog(self, image):
        # Resize gambar ke ukuran yang diinginkan
        resized_image = cv2.resize(image, (64, 64))  # Ganti target_width dan target_height sesuai kebutuhan

        # Hitung fitur HOG untuk setiap saluran warna
        hog_features = []
        for channel in range(resized_image.shape[2]):
            features, _ = hog(resized_image[:, :, channel], orientations=8, pixels_per_cell=(8, 8),
                            cells_per_block=(1, 1), visualize=True)

            # Normalisasi fitur HOG
            features = exposure.rescale_intensity(features, in_range=(0, 10))

            # Flatten dan reshape untuk mendapatkan array satu dimensi
            features = features.flatten()

            hog_features.extend(features)

        # Konversi hasilnya menjadi array satu dimensi
        hog_features = np.array(hog_features).reshape(1, -1)

        return hog_features

    def load_data(self):
        for folder in os.listdir(self.dataset_dir):
            folder_path = os.path.join(self.dataset_dir, folder)
            
            if os.path.isdir(folder_path):
                for file in os.listdir(folder_path):
                    file_path = os.path.join(folder_path, file)
                    
                    if file.endswith('.jpg') or file.endswith('.png') or file.endswith('.jpeg'):
                        image = cv2.imread(file_path)
                        features = self.feature_extractors[self.feature_type](image)

                        self.data.append(features)
                        self.labels.append(folder)

        self.data = np.array(self.data)
        self.labels = np.array(self.labels)

    def train_mlp(self):
        mlp = MLPClassifier(hidden_layer_sizes=(100, 50), max_iter=1000)  # Ubah parameter sesuai kebutuhan
        mlp.fit(self.data.reshape(len(self.data), -1), self.labels)
        return mlp

    def train_naive_bayes(self):
        nb = GaussianNB()
        nb.fit(self.data.reshape(len(self.data), -1), self.labels)
        return nb
        
    def train_classifier(self, classifier_type):
        X_train, X_test, y_train, y_test = train_test_split(self.data, self.labels, test_size=0.2, random_state=42) #train split

        classifier = self.classifiers[classifier_type]()
        classifier.fit(X_train.reshape(len(X_train), -1), y_train)

        y_pred = classifier.predict(X_test.reshape(len(X_test), -1))
        from sklearn.metrics import accuracy_score

        # Setelah Anda melakukan prediksi pada data pengujian
        y_pred = classifier.predict(X_test.reshape(len(X_test), -1))

        # Hitung dan cetak akurasi
        accuracy = accuracy_score(y_test, y_pred)
        print("Akurasi: {:.2f}%".format(accuracy * 100))

        print(classification_report(y_test, y_pred))

        self.classifier = classifier
        # Di dalam metode train_classifier
        scores = cross_val_score(classifier, self.data.reshape(len(self.data), -1), self.labels, cv=5)  # Ubah cv sesuai kebutuhan
        print("Cross-Validation Scores:", scores)
        print("Rata-rata Akurasi:", np.mean(scores))



    def save_classifier(self, classifier_type):
        np.save(os.path.join(self.feature_dir, 'data.npy'), self.data)
        np.save(os.path.join(self.feature_dir, 'labels.npy'), self.labels)

        classifier = self.classifier

        with open(os.path.join(self.model_dir, f'{classifier_type}_model.pkl'), 'wb') as f:
            pickle.dump(classifier, f)


if __name__ == "__main__":
    DATASET_DIR = os.path.join(current_folder, 'dataset/Car_lite')
    MODEL_DIR = os.path.join(current_folder, 'model') #model klasifikasi
    FEATURE_DIR = os.path.join(current_folder, 'fitur') 
    FEATURE_TYPE = 'histogram'  # choose from 'histogram', 'glcm', or 'hog'
    CLASSIFIER_TYPE = "mlp" # "mlp", "naive_bayes"

    # Create an instance of ImageClassifier and train the chosen classifier
    classifier = ImageClassifier(DATASET_DIR, MODEL_DIR, FEATURE_DIR, FEATURE_TYPE)
    classifier.load_data()
    classifier.train_classifier(CLASSIFIER_TYPE)
    classifier.save_classifier(CLASSIFIER_TYPE)


