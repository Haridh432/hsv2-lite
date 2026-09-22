import cv2
import os
import glob
import statistics
from ultralytics import YOLO

# ============================================================
# FILES
# ============================================================

EXTERNAL_VIDEO = "/home/naveen/Videos/video2.mp4"
APP_VIDEO      = "/home/naveen/Videos/video1.mp4"

# Previously identified synchronization events
EXTERNAL_SYNC_FRAME = 26
APP_SYNC_FRAME      = 44

# Detection settings
CONF_THRESHOLD = 0.45
REQUIRED_CONSECUTIVE_FRAMES = 2

# Search only after the sync event
SEARCH_AFTER_SYNC = True

# ============================================================
# LOAD MODEL
# ============================================================

print("\n==========================================")
print(" HSV2 Lite Physical GT Auto Analyzer")
print("==========================================")

print("\nLoading YOLO model...")

try:
    model = YOLO("yolov8n.pt")
except Exception as e:
    print("\n❌ Could not load YOLO model.")
    print(e)
    print("\nIf yolov8n.pt is not available, place it in:")
    print("~/Mediapipe/hsv2-lite-main/")
    raise SystemExit(1)

# ============================================================
# VIDEO INFORMATION
# ============================================================

def video_info(path):
    cap = cv2.VideoCapture(path)

    if not cap.isOpened():
        raise RuntimeError(f"Cannot open: {path}")

    fps = cap.get(cv2.CAP_PROP_FPS)
    frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration = frames / fps

    cap.release()

    return fps, frames, duration


ext_fps, ext_frames, ext_duration = video_info(EXTERNAL_VIDEO)
app_fps, app_frames, app_duration = video_info(APP_VIDEO)

print("\nExternal video:")
print(f"  FPS      : {ext_fps:.3f}")
print(f"  Frames   : {ext_frames}")
print(f"  Duration : {ext_duration:.2f} s")

print("\nHSV2 Lite screen recording:")
print(f"  FPS      : {app_fps:.3f}")
print(f"  Frames   : {app_frames}")
print(f"  Duration : {app_duration:.2f} s")

# ============================================================
# SYNC
# ============================================================

external_sync_time = EXTERNAL_SYNC_FRAME / ext_fps
app_sync_time = APP_SYNC_FRAME / app_fps

# Convert APP timeline onto EXTERNAL timeline
offset = external_sync_time - app_sync_time

print("\n==========================================")
print(" Synchronization")
print("==========================================")

print(f"External sync frame : {EXTERNAL_SYNC_FRAME}")
print(f"External sync time  : {external_sync_time:.6f} s")

print(f"App sync frame      : {APP_SYNC_FRAME}")
print(f"App sync time       : {app_sync_time:.6f} s")

print(f"\nAlignment offset    : {offset:.6f} s")
print(f"Alignment offset    : {offset * 1000:.2f} ms")

# ============================================================
# PERSON DETECTION
# ============================================================

def find_first_person(
    video_path,
    fps,
    start_frame,
    output_name,
    label
):
    cap = cv2.VideoCapture(video_path)

    if not cap.isOpened():
        raise RuntimeError(f"Cannot open {video_path}")

    cap.set(cv2.CAP_PROP_POS_FRAMES, start_frame)

    consecutive = 0
    frame_number = start_frame

    print(f"\nScanning {label}...")

    while True:
        ret, frame = cap.read()

        if not ret:
            break

        results = model(
            frame,
            verbose=False,
            conf=CONF_THRESHOLD,
            classes=[0]   # COCO class 0 = person
        )

        person_found = False
        best_box = None
        best_conf = 0.0

        for result in results:
            if result.boxes is None:
                continue

            for box in result.boxes:
                conf = float(box.conf[0])

                if conf >= CONF_THRESHOLD:
                    person_found = True

                    if conf > best_conf:
                        best_conf = conf
                        best_box = box

        if person_found:
            consecutive += 1
        else:
            consecutive = 0

        if person_found and consecutive >= REQUIRED_CONSECUTIVE_FRAMES:

            timestamp = frame_number / fps

            # Draw detection
            if best_box is not None:
                xyxy = best_box.xyxy[0].cpu().numpy().astype(int)

                x1, y1, x2, y2 = xyxy

                cv2.rectangle(
                    frame,
                    (x1, y1),
                    (x2, y2),
                    (0, 255, 0),
                    3
                )

                cv2.putText(
                    frame,
                    f"PERSON {best_conf:.2f}",
                    (x1, max(30, y1 - 10)),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.8,
                    (0, 255, 0),
                    2
                )

            cv2.putText(
                frame,
                f"{label} T = {timestamp:.3f}s",
                (20, 40),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.9,
                (0, 255, 255),
                2
            )

            cv2.imwrite(output_name, frame)

            cap.release()

            return frame_number, timestamp, best_conf

        frame_number += 1

    cap.release()

    return None, None, None


# ============================================================
# T0
# ============================================================

print("\n==========================================")
print(" Finding T0")
print("==========================================")

t0_frame, t0_time, t0_conf = find_first_person(
    EXTERNAL_VIDEO,
    ext_fps,
    EXTERNAL_SYNC_FRAME,
    "T0_external_detected.jpg",
    "EXTERNAL"
)

if t0_frame is None:
    print("\n❌ No person detected in external video.")
    raise SystemExit(1)

print("\n✅ T0 FOUND")
print(f"Frame      : {t0_frame}")
print(f"Timestamp  : {t0_time:.6f} s")
print(f"Confidence : {t0_conf:.3f}")

# ============================================================
# T1
# ============================================================

print("\n==========================================")
print(" Finding T1")
print("==========================================")

t1_frame, t1_app_time, t1_conf = find_first_person(
    APP_VIDEO,
    app_fps,
    APP_SYNC_FRAME,
    "T1_app_detected.jpg",
    "HSV2 LITE"
)

if t1_frame is None:
    print("\n❌ No person detected in HSV2 Lite screen recording.")
    raise SystemExit(1)

print("\n✅ T1 FOUND")
print(f"Frame      : {t1_frame}")
print(f"App time   : {t1_app_time:.6f} s")
print(f"Confidence : {t1_conf:.3f}")

# ============================================================
# ALIGN T1 TO EXTERNAL TIMELINE
# ============================================================

t1_aligned = t1_app_time + offset

physical_e2e = t1_aligned - t0_time
physical_e2e_ms = physical_e2e * 1000

# ============================================================
# FINAL RESULT
# ============================================================

print("\n")
print("==========================================")
print(" FINAL PHYSICAL GT RESULT")
print("==========================================")

print(f"T0 frame              : {t0_frame}")
print(f"T0 time               : {t0_time:.6f} s")

print(f"T1 frame              : {t1_frame}")
print(f"T1 app time           : {t1_app_time:.6f} s")
print(f"T1 aligned time       : {t1_aligned:.6f} s")

print("------------------------------------------")

print(f"Physical E2E          : {physical_e2e_ms:.2f} ms")

print("------------------------------------------")

if physical_e2e_ms < 0:
    print("⚠️ Negative latency.")
    print("Check synchronization or detection selection.")

elif physical_e2e_ms > 2000:
    print("⚠️ Very large latency.")
    print("Check whether the first person detections are correct.")

else:
    print("✅ Physical E2E measurement completed.")

print("\nSaved evidence:")
print("  T0_external_detected.jpg")
print("  T1_app_detected.jpg")

print("\n==========================================")
