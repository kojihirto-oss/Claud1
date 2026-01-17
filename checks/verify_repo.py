import os
import re
import datetime
import sys

# Configuration
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS_DIR = os.path.join(REPO_ROOT, "docs")
EVIDENCE_DIR = os.path.join(REPO_ROOT, "evidence", "verify_reports")
TIMESTAMP = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

# Ensure evidence directory exists
if not os.path.exists(EVIDENCE_DIR):
    os.makedirs(EVIDENCE_DIR)
    print(f"[INFO] Created {EVIDENCE_DIR}")

def test_forbidden_patterns():
    report_path = os.path.join(EVIDENCE_DIR, f"{TIMESTAMP}_forbidden_patterns.md")
    detections = []
    
    print("\n[3/4] Checking for forbidden patterns in docs/...")

    # Forbidden patterns (regex)
    patterns = [
        r'rm\s+-rf',
        r'rm\s+-fr',
        r'git\s+push\s+--force',
        r'git\s+push\s+-f(?!\w)',
        r'git\s+reset\s+--hard',
        r'curl\s+[^|]*\|\s*sh',
        r'curl\s+[^|]*\|\s*bash',
        r'wget\s+[^|]*\|\s*sh'
    ]

    checked_files = 0
    
    for root, dirs, files in os.walk(DOCS_DIR):
        for file in files:
            if file.endswith(".md"):
                checked_files += 1
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                        
                    for line_num, line in enumerate(lines, 1):
                        for pattern in patterns:
                            if re.search(pattern, line):
                                relative_path = os.path.relpath(file_path, REPO_ROOT).replace('\\', '/')
                                detections.append(f"[FORBIDDEN] {relative_path}:{line_num} -> Pattern: '{pattern}'")
                                detections.append(f"  Line: {line.strip()}")
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")

    # Generate report
    with open(report_path, 'w', encoding='utf-8') as f:
        if not detections:
            f.write(f"[PASS] forbidden_patterns: No dangerous patterns detected (0 matches)\n")
            f.write(f"Timestamp: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Patterns checked: {len(patterns)}\n")
            print("  [PASS] - No forbidden patterns")
            return True
        else:
            f.write(f"[FAIL] forbidden_patterns: Found {len(detections)//2} detection(s)\n")
            f.write(f"Timestamp: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            f.write("\n".join(detections))
            print(f"  [FAIL] - {len(detections)//2} forbidden pattern(s)")
            return False

if __name__ == "__main__":
    success = test_forbidden_patterns()
    if success:
        sys.exit(0)
    else:
        sys.exit(1)
