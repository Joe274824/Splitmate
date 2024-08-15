import cv2
import numpy as np
import os


names = {1: 'guanqiao'}
recognizer = cv2.face.LBPHFaceRecognizer_create()
recognizer.read('/home/hdq/trainer.yml')
def face_detect(img):
    gray = cv2.cvtColor(img,cv2.COLOR_BGR2GRAY) 
    face_detector = cv2.CascadeClassifier("/home/hdq/haarcascade_frontalface_default.xml")
    faces = face_detector.detectMultiScale(gray) 
    for x,y,w,h in faces:
        cv2.rectangle(img,(x,y),(x+w,y+h),(0,0,255),2)
        id,confidence = recognizer.predict(gray[y:y+h,x:x+w])
        cv2.putText(img, str(confidence), (x+w,y+h), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255,0), 3)
        if confidence <80 :
            name = names.get(id, "Unknown")
            cv2.putText(img, name, (x,y), cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 255,0), 3)
#     print(type(confidence))
        print('label:',id,'confidence:',confidence)
    cv2.namedWindow('result',cv2.WINDOW_NORMAL) 
    cv2.imshow('result',img)

cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
while True:
    flag,frame = cap.read()
    if not flag:
        break 
    face_detect(frame)
    if ord('q') == cv2.waitKey(10):
        break 
cap.release()
cv2.destroyAllWindows()
cv2.waitKey(1)