import cv2

# 使用视频流的 URL，替换为你的视频流地址
stream_url = "/home/hgq/Projects/mobile/output_video.avi"

# 打开视频流
cap = cv2.VideoCapture(stream_url)

if not cap.isOpened():
    print("无法打开视频流")
    exit()

while True:
    ret, frame = cap.read()

    if not ret:
        print("无法接收帧，结束")
        break

    # 显示帧
    cv2.imshow('Video Stream', frame)

    # 按 'q' 退出
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# 释放资源
cap.release()
cv2.destroyAllWindows()
