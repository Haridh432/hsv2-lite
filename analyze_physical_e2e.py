import cv2
import numpy as np
from pathlib import Path

VIDEO = "/home/naveen/Mediapipe/physical_ground.mp4"

cap = cv2.VideoCapture(VIDEO)

if not cap.isOpened():
    raise RuntimeError(f"Cannot open video: {VIDEO}")

fps = cap.get(cv2.CAP_PROP_FPS)
frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
duration = frame_count / fps if fps > 0 else 0

print("=" * 60)
print("HSV2 Lite Physical E2E Latency Analysis")
print("=" * 60)
print(f"Video       : {VIDEO}")
print(f"FPS         : {fps:.3f}")
print(f"Frames      : {frame_count}")
print(f"Duration    : {duration:.2f} sec")
print("=" * 60)

cap.release()

print("""
For each trial identify:

T0 = frame where the person FIRST becomes visible
     in the D455 RGB view.

T1 = frame where the corresponding "person"
     detection FIRST appears on the HSV2 phone display.

IMPORTANT:
- Do NOT use the yellow line as T0 if the person is already visible.
- Use the first actual visible frame.
- Use the first corresponding detection, not a later stable detection.
""")

trials = []

print("\nEnter trials.")
print("Example: T0=134, T1=154")
print("Press ENTER with empty T0 to finish.\n")

trial_no = 1

while True:
    t0_input = input(f"Trial {trial_no} T0 frame: ").strip()

    if not t0_input:
        break

    t1_input = input(f"Trial {trial_no} T1 frame: ").strip()

    try:
        t0 = int(t0_input)
        t1 = int(t1_input)
    except ValueError:
        print("Invalid frame number. Try again.")
        continue

    if t1 < t0:
        print("ERROR: T1 must be >= T0.")
        continue

    latency_ms = ((t1 - t0) / fps) * 1000.0

    trials.append({
        "trial": trial_no,
        "t0": t0,
        "t1": t1,
        "frames": t1 - t0,
        "latency_ms": latency_ms,
    })

    print(f"  -> {latency_ms:.2f} ms\n")
    trial_no += 1


if not trials:
    print("\nNo trials entered.")
    raise SystemExit


latencies = np.array([x["latency_ms"] for x in trials], dtype=float)

print("\n" + "=" * 60)
print("TRIAL RESULTS")
print("=" * 60)

for x in trials:
    print(
        f"Trial {x['trial']:2d}: "
        f"T0={x['t0']:4d}  "
        f"T1={x['t1']:4d}  "
        f"frames={x['frames']:3d}  "
        f"latency={x['latency_ms']:.2f} ms"
    )

print("\n" + "=" * 60)
print("PHYSICAL E2E LATENCY SUMMARY")
print("=" * 60)

print(f"Trials : {len(latencies)}")
print(f"Min    : {np.min(latencies):.2f} ms")
print(f"Mean   : {np.mean(latencies):.2f} ms")
print(f"p50    : {np.percentile(latencies, 50):.2f} ms")
print(f"p95    : {np.percentile(latencies, 95):.2f} ms")
print(f"p99    : {np.percentile(latencies, 99):.2f} ms")
print(f"Max    : {np.max(latencies):.2f} ms")

print("\n" + "=" * 60)
print("FINAL TABLE ROW")
print("=" * 60)

print(
    f"Physical E2E | "
    f"p50={np.percentile(latencies,50):.2f} ms | "
    f"p95={np.percentile(latencies,95):.2f} ms | "
    f"p99={np.percentile(latencies,99):.2f} ms | "
    f"N={len(latencies)} | "
    f"Video={fps:.3f} FPS"
)
