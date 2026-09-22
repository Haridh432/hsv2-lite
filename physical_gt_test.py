import cv2

def get_video_info(path):
    cap = cv2.VideoCapture(path)

    if not cap.isOpened():
        raise RuntimeError(f"Cannot open video: {path}")

    fps = cap.get(cv2.CAP_PROP_FPS)
    frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration = frames / fps if fps > 0 else 0

    cap.release()

    print(f"\nVideo: {path}")
    print(f"FPS: {fps:.3f}")
    print(f"Frames: {frames}")
    print(f"Duration: {duration:.3f} s")

    return fps, frames, duration


def timestamp_from_frame(path, frame_number):
    cap = cv2.VideoCapture(path)

    if not cap.isOpened():
        raise RuntimeError(f"Cannot open video: {path}")

    fps = cap.get(cv2.CAP_PROP_FPS)

    cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)
    ok, frame = cap.read()

    if not ok:
        cap.release()
        raise RuntimeError(f"Cannot read frame {frame_number}")

    cv2.imshow("Selected Frame", frame)
    cv2.waitKey(1)

    timestamp = frame_number / fps

    cap.release()
    cv2.destroyAllWindows()

    return timestamp


def ask_timestamp(video_name, description):
    print("\n----------------------------------------")
    print(video_name)
    print(description)
    print("----------------------------------------")

    frame = int(input("Enter frame number: "))

    return frame


print("\n========================================")
print(" Physical Ground-Truth E2E Test")
print(" Person-based validation")
print("========================================")

video1 = input("\nEnter Video 1 path (external recording): ").strip()
video2 = input("Enter Video 2 path (HSV2 Lite screen recording): ").strip()

fps1, _, _ = get_video_info(video1)
fps2, _, _ = get_video_info(video2)

print("\n\nSTEP 1: Synchronization event")
print("Find the SAME clap/hand movement in both videos.")

sync1 = int(input("Video 1 sync-event frame: "))
sync2 = int(input("Video 2 sync-event frame: "))

sync_time1 = sync1 / fps1
sync_time2 = sync2 / fps2

offset = sync_time1 - sync_time2

print("\nSynchronization:")
print(f"Video 1 sync time = {sync_time1:.3f} s")
print(f"Video 2 sync time = {sync_time2:.3f} s")
print(f"Alignment offset = {offset:.3f} s")

print("\n\nSTEP 2: Find T0")
print("Video 1 = external recording")
print("Find the FIRST clear frame where the person is visible.")

t0_frame = int(input("Video 1 T0 frame: "))
t0_video1 = t0_frame / fps1

print(f"T0 in Video 1 = {t0_video1:.3f} s")

print("\n\nSTEP 3: Find T1")
print("Video 2 = HSV2 Lite screen recording")
print("Find the FIRST frame where person detection appears.")

t1_frame = int(input("Video 2 T1 frame: "))
t1_video2 = t1_frame / fps2

print(f"T1 in Video 2 = {t1_video2:.3f} s")

# Convert Video 2 timestamp to Video 1 timeline
t1_aligned = t1_video2 + offset

e2e = t1_aligned - t0_video1
e2e_ms = e2e * 1000

print("\n========================================")
print(" RESULT")
print("========================================")

print(f"T0 = {t0_video1:.3f} s")
print(f"T1 = {t1_aligned:.3f} s")
print(f"Physical E2E = {e2e_ms:.2f} ms")

if e2e_ms < 0:
    print("\nWARNING: Negative latency.")
    print("Check synchronization timestamps.")
elif e2e_ms > 2000:
    print("\nWARNING: Very large latency.")
    print("Check whether T0/T1 were selected correctly.")
else:
    print("\nMeasurement completed.")

print("\n========================================")
