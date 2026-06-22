import urllib.request
import json
import zipfile
import io
import subprocess

def get_git_credentials():
    try:
        proc = subprocess.Popen(
            ['git', 'credential', 'fill'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        stdout, stderr = proc.communicate(input="protocol=https\nhost=github.com\n\n")
        creds = {}
        for line in stdout.splitlines():
            if '=' in line:
                key, val = line.split('=', 1)
                creds[key.strip()] = val.strip()
        return creds.get('password')
    except Exception as e:
        print(f"Failed to get git credentials: {e}")
        return None

def get_latest_run_logs():
    token = get_git_credentials()
    if token:
        print("Successfully retrieved git credential token.")
    else:
        print("No git credential token found, running unauthenticated.")

    headers = {'User-Agent': 'Mozilla/5.0'}
    if token:
        headers['Authorization'] = f'token {token}'

    # 1. Get latest run
    url = "https://api.github.com/repos/AbhishekkumarDubey04/laundryApplication/actions/runs"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as response:
        runs = json.loads(response.read())['workflow_runs']
        if not runs:
            print("No runs found.")
            return
        run = runs[0]
        print(f"Run ID: {run['id']}, Event: {run['event']}, Status: {run['status']}, Conclusion: {run['conclusion']}")
        print(f"HTML URL: {run['html_url']}")

    # 2. Get jobs
    jobs_url = run['jobs_url']
    req_jobs = urllib.request.Request(jobs_url, headers=headers)
    with urllib.request.urlopen(req_jobs) as response:
        jobs = json.loads(response.read())['jobs']
        for job in jobs:
            print(f"Job: {job['name']}, Conclusion: {job['conclusion']}")
            for step in job['steps']:
                print(f"  Step: {step['name']} -> {step['conclusion']}")

    # 3. Download logs zip
    logs_url = f"https://api.github.com/repos/AbhishekkumarDubey04/laundryApplication/actions/runs/{run['id']}/logs"
    print(f"Downloading logs from: {logs_url}")
    req_logs = urllib.request.Request(logs_url, headers=headers)
    try:
        with urllib.request.urlopen(req_logs) as response:
            zip_data = response.read()
            with zipfile.ZipFile(io.BytesIO(zip_data)) as z:
                # Find log file for the build step
                for name in z.namelist():
                    # Job steps log files look like "Build-iOS-Unsigned-Bundle/5_Build-iOS-App-Unsigned.txt" or similar
                    if "unsigned" in name.lower() or "build" in name.lower():
                        content = z.read(name).decode('utf-8', errors='ignore')
                        lines = content.splitlines()
                        
                        # Let's filter out progress/spinning chars if any
                        clean_lines = []
                        for l in lines:
                            # remove backspaces and carriage returns
                            if '\r' in l:
                                parts = l.split('\r')
                                l = parts[-1]
                            clean_lines.append(l)

                        # Print last 100 lines
                        print(f"\n--- LOG CONTENT FOR {name} (last 100 lines) ---")
                        for l in clean_lines[-100:]:
                            print(l)
                            
                        # Scan for explicit errors
                        print("\n--- DETECTED ERRORS/FAILURES ---")
                        for idx, l in enumerate(clean_lines):
                            if "error" in l.lower() or "failed" in l.lower() or "fatal" in l.lower() or "xcrun:" in l.lower():
                                # Print line with some context around it
                                start = max(0, idx - 2)
                                end = min(len(clean_lines), idx + 3)
                                print(f"Lines {start+1}-{end}:")
                                for context_line in clean_lines[start:end]:
                                    print(f"  {context_line}")
                                print("-" * 40)
    except Exception as e:
        print(f"Failed to download/parse logs: {e}")

if __name__ == "__main__":
    get_latest_run_logs()
