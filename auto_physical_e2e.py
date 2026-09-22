import cv2
import numpy as np
import csv
from pathlib import Path

VIDEO = "/home/naveen/Mediapipe/physical_ground.mp4"
OUTPUT = "/home/naveen/Mediapipe/physical_e2e_results.csv"

cap = cv2.VideoCapture(VIDEO)

if not cap.isOpened():
    raise RuntimeError(f"Cannot open: {VIDEO}")

fps = cap.get(cv2.CAP_PROP_FPS)
total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

print("=" * 60)
print("HSV2 Lite - AUTOMATIC Physical E2E Analysis")
print("=" * 60)
print(f"Video : {VIDEO}")
print(f"FPS   : {fps:.3f}")
print(f"Frames: {total}")
print("=" * 60)

# ---------------------------------------------------------
# Read first frame
# ---------------------------------------------------------

ok, first = cap.read()

if not ok:
    raise RuntimeError("Could not read first frame")

display = first.copy()

print()
print("Select ROI 1: D455 RGB/camera view")
print("Drag rectangle and press ENTER.")
print("Press C to cancel.")

d455_roi = cv2.selectROI(
    "Select D455 RGB View",
    display,
    showCrosshair=True,
    fromCenter=False
)

cv2.destroyWindow("Select D455 RGB View")

print()
print("Select ROI 2: HSV2 phone/display")
print("Drag rectangle around the phone screen and press ENTER.")

phone_roi = cv2.selectROI(
    "Select HSV2 Phone Display",
    display,
    showCrosshair=True,
    fromCenter=False
)

cv2.destroyWindow("Select HSV2 Phone Display")

dx, dy, dw, dh = map(int, d455_roi)
px, py, pw, ph = map(int, phone_roi)

if dw <= 0 or dh <= 0:
    raise RuntimeError("Invalid D455 ROI")

if pw <= 0 or ph <= 0:
    raise RuntimeError("Invalid phone ROI")

print("\nROIs selected:")
print(f"D455 : x={dx}, y={dy}, w={dw}, h={dh}")
print(f"Phone: x={px}, y={py}, w={pw}, h={ph}")

# ---------------------------------------------------------
# Automatic person detection
#
# Uses HOG person detector.
# ---------------------------------------------------------

hog = cv2.HOGDescriptor()
hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())

# ---------------------------------------------------------
# HSV2 display detection
#
# We look for the text/box region changing after person
# detection appears. This is a heuristic and must be
# validated against the actual video.
# ---------------------------------------------------------

cap.set(cv2.CAP_PROP_POS_FRAMES, 0)

prev_phone = None
phone_scores = []

events = []

frame_number = 0

print("\nProcessing video automatically...")
print("This may take some time.\n")

while True:

    ok, frame = cap.read()

    if not ok:
        break

    # -----------------------------------------------------
    # D455 ROI
    # -----------------------------------------------------

    d455 = frame[dy:dy+dh, dx:dx+dw]

    # Resize for HOG
    scale = 1.0

    if d455.shape[1] > 640:
        scale = 640.0 / d455.shape[1]
        d455_small = cv2.resize(
            d455,
            None,
            fx=scale,
            fy=scale
        )
    else:
        d455_small = d455

    # Person detection
    boxes, weights = hog.detectMultiScale(
        d455_small,
        winStride=(8, 8),
        padding=(8, 8),
        scale=1.05
    )

    person_found = False

    if len(boxes) > 0:
        for weight in weights:
            if float(weight) > 0.0:
                person_found = True
                break

    # -----------------------------------------------------
    # Phone ROI
    # -----------------------------------------------------

    phone = frame[py:py+ph, px:px+pw]

    gray = cv2.cvtColor(phone, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (5, 5), 0)

    # Frame-to-frame screen change score
    phone_score = 0.0

    if prev_phone is not None:
        diff = cv2.absdiff(gray, prev_phone)
        phone_score = float(np.mean(diff))

    prev_phone = gray

    phone_scores.append(phone_score)

    # -----------------------------------------------------
    # Store frame state
    # -----------------------------------------------------

    events.append({
        "frame": frame_number,
        "person": person_found,
        "phone_change": phone_score
    })

    frame_number += 1

    if frame_number % 100 == 0:
        print(
            f"\rProcessed {frame_number}/{total}",
            end="",
            flush=True
        )

cap.release()

print("\n\nAutomatic processing complete.")

# ---------------------------------------------------------
# Detect T0 events
# ---------------------------------------------------------

person_frames = [
    e["frame"]
    for e in events
    if e["person"]
]

if not person_frames:
    print("\nNo person detections found.")
    print("The HOG detector may need a different detection method.")
    raise SystemExit

# Group consecutive person detections into entry events

groups = []

start = person_frames[0]
previous = person_frames[0]

for f in person_frames[1:]:

    if f - previous > 5:
        groups.append((start, previous))
        start = f

    previous = f

groups.append((start, previous))

print("\nDetected person events:")

for i, (a, b) in enumerate(groups, 1):
    print(
        f"  Event {i}: frames {a} -> {b} "
        f"({b-a+1} frames)"
    )

# ---------------------------------------------------------
# Automatic T1 estimation
#
# Look for strong phone-screen change shortly after T0.
# ---------------------------------------------------------

phone_array = np.array(phone_scores)

baseline = np.median(phone_array)
mad = np.median(np.abs(phone_array - baseline))

threshold = baseline + max(3.0 * mad, 8.0)

print(f"\nPhone-change baseline : {baseline:.3f}")
print(f"Phone-change threshold: {threshold:.3f}")

results = []

for event_id, (t0_start, t0_end) in enumerate(groups, 1):

    t0 = t0_start

    # Search up to 2 seconds after T0
    max_frames = int(fps * 2.0)

    search_end = min(
        t0 + max_frames,
        len(events) - 1
    )

    t1 = None

    for f in range(t0 + 1, search_end + 1):

        if phone_scores[f] > threshold:

            t1 = f
            break

    if t1 is None:
        continue

    latency = ((t1 - t0) / fps) * 1000.0

    results.append({
        "trial": event_id,
        "t0": t0,
        "t1": t1,
        "frame_difference": t1 - t0,
        "latency_ms": latency
    })

# ---------------------------------------------------------
# Save results
# ---------------------------------------------------------

with open(
    OUTPUT,
    "w",
    newline=""
) as f:

    writer = csv.DictWriter(
        f,
        fieldnames=[
            "trial",
            "t0",
            "t1",
            "frame_difference",
            "latency_ms"
        ]
    )

    writer.writeheader()
    writer.writerows(results)

# ---------------------------------------------------------
# Statistics
# ---------------------------------------------------------

if not results:

    print("\nNo valid physical E2E events detected.")
    print("The automatic phone-output detector needs calibration.")
    print(f"\nCSV saved: {OUTPUT}")
    raise SystemExit

latencies = np.array(
    [r["latency_ms"] for r in results],
    dtype=float
)

print("\n" + "=" * 60)
print("AUTOMATIC PHYSICAL E2E RESULTS")
print("=" * 60)

for r in results:

    print(
        f"Trial {r['trial']:2d}: "
        f"T0={r['t0']:5d} "
        f"T1={r['t1']:5d} "
        f"Δframes={r['frame_difference']:3d} "
        f"latency={r['latency_ms']:.2f} ms"
    )

print("\n" + "=" * 60)
print("SUMMARY")
print("=" * 60)

print(f"Valid trials : {len(latencies)}")
print(f"Mean         : {np.mean(latencies):.2f} ms")
print(f"Min          : {np.min(latencies):.2f} ms")
print(f"p50          : {np.percentile(latencies, 50):.2f} ms")
print(f"p95          : {np.percentile(latencies, 95):.2f} ms")
print(f"p99          : {np.percentile(latencies, 99):.2f} ms")
print(f"Max          : {np.max(latencies):.2f} ms")

print("\nCSV:")
print(OUTPUT)
