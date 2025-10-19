#!/usr/bin/env python3
"""
Pixoo Prototype (Python)
Validates detection algorithms on Windows before iOS compilation

Usage:
    python proto_sweeper.py --input "C:/path/to/photos" --output results.csv

Dependencies:
    pip install opencv-python pillow numpy imagehash
"""

import argparse
import csv
import os
import sys
from pathlib import Path
from datetime import datetime
from collections import defaultdict

try:
    import cv2
    import numpy as np
    import imagehash
    from PIL import Image
except ImportError as e:
    print(f"Error: Missing dependency - {e}")
    print("Install with: pip install opencv-python pillow numpy imagehash")
    sys.exit(1)


# ============================================================================
# Configuration (matches SweeperConfig.swift)
# ============================================================================

class Config:
    DUPLICATE_HAMMING_THRESHOLD = 8
    SIMILAR_HAMMING_MIN = 9
    SIMILAR_HAMMING_MAX = 18
    BLUR_THRESHOLD = 60.0
    FLAT_ENTROPY_THRESHOLD = 3.0
    FLAT_UNIFORM_PERCENTAGE = 0.95
    BLACK_LUMINANCE_MAX = 0.1
    WHITE_LUMINANCE_MIN = 0.9
    VARIANCE_MAX = 0.01
    SKIN_TONE_THRESHOLD = 0.4
    BURST_TIME_WINDOW = 2.0


# ============================================================================
# Algorithms
# ============================================================================

def compute_phash(image_path):
    """Compute 64-bit perceptual hash"""
    try:
        img = Image.open(image_path)
        return imagehash.phash(img, hash_size=8)
    except Exception as e:
        print(f"Warning: Failed to compute pHash for {image_path}: {e}")
        return None


def compute_laplacian_variance(image_path):
    """Compute Laplacian variance (blur detection)"""
    try:
        img = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)
        if img is None:
            return 0.0
        laplacian = cv2.Laplacian(img, cv2.CV_64F)
        return laplacian.var()
    except Exception as e:
        print(f"Warning: Failed to compute Laplacian for {image_path}: {e}")
        return 0.0


def compute_entropy(image_path, bins=8):
    """Compute entropy (flat background detection)"""
    try:
        img = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)
        if img is None:
            return 0.0
        hist = cv2.calcHist([img], [0], None, [bins], [0, 256])
        hist = hist.flatten() / hist.sum()
        hist = hist[hist > 0]
        return -np.sum(hist * np.log2(hist))
    except Exception as e:
        print(f"Warning: Failed to compute entropy for {image_path}: {e}")
        return 0.0


def analyze_color(image_path):
    """Analyze color (black, white, skin tone detection)"""
    try:
        img = cv2.imread(str(image_path))
        if img is None:
            return None

        # Convert to grayscale for luminance
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        mean_lum = np.mean(gray) / 255.0
        var_lum = np.var(gray) / (255.0 ** 2)

        # Convert to HSV for skin tone detection
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        h, s, v = cv2.split(hsv)

        # Skin tone heuristic: H: 0-50, S: 0.23-0.68, V: 0.35-1.0
        skin_mask = (
            (h >= 0) & (h <= 25) &
            (s >= 59) & (s <= 173) &  # 0.23*255 to 0.68*255
            (v >= 89)  # 0.35*255
        )
        skin_percentage = np.sum(skin_mask) / skin_mask.size

        return {
            'mean_luminance': mean_lum,
            'luminance_variance': var_lum,
            'skin_tone_percentage': skin_percentage
        }
    except Exception as e:
        print(f"Warning: Failed to analyze color for {image_path}: {e}")
        return None


def hamming_distance(hash1, hash2):
    """Compute Hamming distance between two hashes"""
    if hash1 is None or hash2 is None:
        return 64
    return hash1 - hash2


# ============================================================================
# Classification
# ============================================================================

def classify_useless(phash, laplacian, entropy, color_analysis):
    """Classify image as useless (blur, flat, black, white, finger)"""
    labels = []
    reasons = []

    # Blur
    if laplacian < Config.BLUR_THRESHOLD:
        labels.append('BLUR')
        reasons.append(f'Floue (netteté {laplacian:.1f} < {Config.BLUR_THRESHOLD})')

    # Flat
    if entropy < Config.FLAT_ENTROPY_THRESHOLD:
        labels.append('FLAT')
        reasons.append(f'Fond quasi-uni (entropie {entropy:.2f} < {Config.FLAT_ENTROPY_THRESHOLD})')

    if color_analysis:
        # Black
        if (color_analysis['mean_luminance'] < Config.BLACK_LUMINANCE_MAX and
            color_analysis['luminance_variance'] < Config.VARIANCE_MAX):
            labels.append('BLACK')
            reasons.append(f'Noire (luminance {color_analysis["mean_luminance"]*100:.1f}%)')

        # White
        if (color_analysis['mean_luminance'] > Config.WHITE_LUMINANCE_MIN and
            color_analysis['luminance_variance'] < Config.VARIANCE_MAX):
            labels.append('WHITE')
            reasons.append(f'Blanche (luminance {color_analysis["mean_luminance"]*100:.1f}%)')

        # Finger
        if (color_analysis['skin_tone_percentage'] > Config.SKIN_TONE_THRESHOLD and
            color_analysis['luminance_variance'] < 0.05):
            labels.append('FINGER')
            reasons.append(f'Doigt probable ({color_analysis["skin_tone_percentage"]*100:.0f}% peau)')

    return labels, ' • '.join(reasons) if reasons else ''


# ============================================================================
# Grouping
# ============================================================================

def group_duplicates_and_similars(features):
    """Group features by Hamming distance"""
    groups = {'duplicates': [], 'similars': []}
    processed = set()

    for i, (path1, feat1) in enumerate(features.items()):
        if path1 in processed:
            continue

        duplicate_group = [path1]
        similar_group = [path1]

        for path2, feat2 in list(features.items())[i+1:]:
            if path2 in processed:
                continue

            dist = hamming_distance(feat1['phash'], feat2['phash'])

            if dist <= Config.DUPLICATE_HAMMING_THRESHOLD:
                duplicate_group.append(path2)
            elif Config.SIMILAR_HAMMING_MIN <= dist <= Config.SIMILAR_HAMMING_MAX:
                similar_group.append(path2)

        if len(duplicate_group) > 1:
            groups['duplicates'].append(duplicate_group)
            processed.update(duplicate_group)
        elif len(similar_group) > 1:
            groups['similars'].append(similar_group)
            processed.update(similar_group)

    return groups


def group_bursts(image_files):
    """Group burst photos by timestamp proximity"""
    bursts = []
    sorted_files = sorted(image_files, key=lambda p: os.path.getmtime(p))

    current_burst = []
    last_time = None

    for path in sorted_files:
        mtime = os.path.getmtime(path)

        if last_time and (mtime - last_time) <= Config.BURST_TIME_WINDOW:
            current_burst.append(path)
        else:
            if len(current_burst) > 1:
                bursts.append(current_burst)
            current_burst = [path]

        last_time = mtime

    if len(current_burst) > 1:
        bursts.append(current_burst)

    return bursts


# ============================================================================
# Main Processing
# ============================================================================

def process_images(input_dir, output_csv):
    """Process all images in directory and export results"""
    input_path = Path(input_dir)
    image_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.gif', '.heic'}

    # Find all images
    image_files = [
        p for p in input_path.rglob('*')
        if p.suffix.lower() in image_extensions
    ]

    if not image_files:
        print(f"No images found in {input_dir}")
        return

    print(f"Found {len(image_files)} images. Processing...")

    # Extract features
    features = {}
    for i, img_path in enumerate(image_files, 1):
        print(f"  [{i}/{len(image_files)}] {img_path.name}")

        phash = compute_phash(img_path)
        laplacian = compute_laplacian_variance(img_path)
        entropy = compute_entropy(img_path, bins=8)
        color = analyze_color(img_path)

        features[str(img_path)] = {
            'phash': phash,
            'laplacian': laplacian,
            'entropy': entropy,
            'color': color,
            'size': img_path.stat().st_size
        }

    # Group duplicates & similars
    print("\nGrouping duplicates and similars...")
    groups = group_duplicates_and_similars(features)
    print(f"  Found {len(groups['duplicates'])} duplicate groups")
    print(f"  Found {len(groups['similars'])} similar groups")

    # Group bursts
    print("\nGrouping burst photos...")
    bursts = group_bursts(image_files)
    print(f"  Found {len(bursts)} burst groups")

    # Classify useless photos
    print("\nClassifying useless photos...")
    useless = {}
    for path, feat in features.items():
        labels, reason = classify_useless(
            feat['phash'],
            feat['laplacian'],
            feat['entropy'],
            feat['color']
        )
        if labels:
            useless[path] = {'labels': labels, 'reason': reason}

    print(f"  Found {len(useless)} useless photos")

    # Export to CSV
    print(f"\nExporting results to {output_csv}...")
    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['ID', 'Path', 'Group', 'Type', 'Reason', 'Size (bytes)', 'Recommendation'])

        row_id = 1

        # Write duplicate groups
        for group_id, group in enumerate(groups['duplicates'], 1):
            for idx, path in enumerate(group):
                writer.writerow([
                    row_id,
                    path,
                    f'DUP-{group_id}',
                    'Duplicate',
                    'Hamming ≤ 8',
                    features[path]['size'],
                    'KEEP' if idx == 0 else 'DELETE'
                ])
                row_id += 1

        # Write similar groups
        for group_id, group in enumerate(groups['similars'], 1):
            for idx, path in enumerate(group):
                writer.writerow([
                    row_id,
                    path,
                    f'SIM-{group_id}',
                    'Similar',
                    'Hamming 9-18',
                    features[path]['size'],
                    'KEEP' if idx == 0 else 'REVIEW'
                ])
                row_id += 1

        # Write bursts
        burst_paths = {p for burst in bursts for p in burst}
        for group_id, burst in enumerate(bursts, 1):
            for idx, path in enumerate(burst):
                if str(path) not in [r[1] for r in writer]:  # Avoid duplicates
                    writer.writerow([
                        row_id,
                        str(path),
                        f'BURST-{group_id}',
                        'Burst',
                        'Timestamps ±2s',
                        features[str(path)]['size'],
                        'KEEP' if idx == 0 else 'DELETE'
                    ])
                    row_id += 1

        # Write useless photos
        for path, info in useless.items():
            if path not in burst_paths:  # Avoid duplicates
                writer.writerow([
                    row_id,
                    path,
                    '',
                    ', '.join(info['labels']),
                    info['reason'],
                    features[path]['size'],
                    'DELETE'
                ])
                row_id += 1

    print(f"\nDone! Results saved to {output_csv}")
    print(f"\nSummary:")
    print(f"  Total images: {len(image_files)}")
    print(f"  Duplicate groups: {len(groups['duplicates'])}")
    print(f"  Similar groups: {len(groups['similars'])}")
    print(f"  Burst groups: {len(bursts)}")
    print(f"  Useless photos: {len(useless)}")


# ============================================================================
# CLI
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Pixoo Prototype - Validate detection algorithms on Windows'
    )
    parser.add_argument('--input', '-i', required=True, help='Input directory with images')
    parser.add_argument('--output', '-o', default='results.csv', help='Output CSV file')

    args = parser.parse_args()

    if not os.path.isdir(args.input):
        print(f"Error: Input directory does not exist: {args.input}")
        sys.exit(1)

    process_images(args.input, args.output)


if __name__ == '__main__':
    main()
