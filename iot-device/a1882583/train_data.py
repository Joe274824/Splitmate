import cv2
import os
import numpy as np


dataset_path = '/home/hgq/Projects/mobile/face_data'
face_data = []
labels = []

for folder in os.listdir(dataset_path):
    folder_path = os.path.join(dataset_path, folder)
    if os.path.isdir(folder_path):
        label = int(folder) 
        # label = folder
        for file in os.listdir(folder_path):
            file_path = os.path.join(folder_path, file)
            if file_path.endswith('.jpg') or file_path.endswith('.png'):
                image = cv2.imread(file_path, 0)
                if image is not None:
                    face_detector = cv2.CascadeClassifier('/home/hgq/Projects/mobile/haarcascade_frontalface_default.xml')
                    faces = face_detector.detectMultiScale(image)
                    for (x, y, w, h) in faces:
                        face_data.append(image[y:y+h, x:x+w])
                        labels.append(label)
                else:
                    print(f"Warning: Skipped unrecognized image file {file_path}")

if len(face_data) > 0:
    labels = np.array(labels)
    face_samples = face_data
    
    recognizer = cv2.face.LBPHFaceRecognizer_create()
    
    recognizer.train(face_samples, labels)
    recognizer.write('/home/hgq/Projects/mobile/trainer.yml')
    print('Model trained and saved successfully!')
else:
    print('No valid image data found for training.')