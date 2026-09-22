import cv2
import sys
import os

if len(sys.argv) != 2:
    print("Usage: python3 sync_event.py <video.mp4>")
    sys.exit(1)

video_path = sys.argv[1]

if not os.path.exists(video_path):
    print(f"❌ File not found: {video_path}")
    sys.exit(1)

cap = cv2.VideoCapture(video_path)

if not cap.isOpened():
    print("❌ Cannot open video")
    sys.exit(1)

fps = cap.get(cv2.CAP_PROP_FPS)
total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

print("\n======================================")
print(" SYNC EVENT FRAME FINDER")
print("======================================")
print(f"FPS    : {fps:.3f}")
print(f"Frames : {total_frames}")
print("\nControls:")
print("  SPACE = next frame")
print("  b     = previous frame")
print("  s     = select sync frame")
print("  q     = quit")
print("======================================")

frame_number = 0

while True:
    cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)
    ret, frame = cap.read()

    if not ret:
        print("End of video.")
        break

    timestamp = frame_number / fps

    display = frame.copy()

    cv2.putText(
        display,
        f"Frame: {frame_number} | Time: {timestamp:.3f} s",
        (20, 40),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.9,
        (0, 255, 0),
        2
    )

    cv2.imshow("Sync Event Finder", display)

    key = cv2.waitKey(0) & 0xFF

    if key == 32:          # SPACE
        frame_number += 1

    elif key == ord("b"):
        frame_number = max(0, frame_number - 1)

    elif key == ord("s"):
        filename = f"sync_frame_{frame_number}.jpg"
        cv2.imwrite(filename, frame)

        print("\n✅ SYNC EVENT SELECTED")
        print(f"Frame     : {frame_number}")
        print(f"Timestamp : {timestamp:.3f} s")
        print(f"Saved     : {filename}\n")

        break

    elif key == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()
