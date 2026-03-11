import os
import time

import requests
from flask import Flask, jsonify, request


DOWNSTREAM_URL = os.getenv(
    "DOWNSTREAM_URL",
    "http://demo-downstream.test-app.svc.cluster.local:8080/slow",
)

if base := os.getenv("DOWNSTREAM_BASE_URL"):
    DOWNSTREAM_BASE_URL = base
else:
    DOWNSTREAM_BASE_URL = DOWNSTREAM_URL.rsplit("/", 1)[0]


app = Flask(__name__)


def _call(url: str, method: str = "GET", json_body=None, timeout: float = 5.0):
    start = time.time()
    try:
        if method == "POST":
            response = requests.post(url, json=json_body, timeout=timeout)
        else:
            response = requests.get(url, timeout=timeout)

        duration = time.time() - start
        data = {
            "ok": True,
            "status_code": response.status_code,
            "body": response.json(),
            "duration_seconds": round(duration, 3),
        }
        status = 200
    except Exception as exc:  # noqa: BLE001
        duration = time.time() - start
        data = {
            "ok": False,
            "error": str(exc),
            "duration_seconds": round(duration, 3),
        }
        status = 502

    return data, status


@app.route("/")
def index():
    return (
        "KubChaos Python demo-api\n"
        "Key endpoints:\n"
        "- GET  /api/call            (single slow downstream call)\n"
        "- GET  /api/read-heavy      (many small reads)\n"
        "- POST /api/write-heavy     (many writes)\n"
        "- GET  /api/fanout          (fan-out to multiple downstream endpoints)\n"
        "- GET  /api/call-resilient  (single call with simple retries)\n"
    )


@app.route("/api/call")
def call_downstream():
    data, status = _call(DOWNSTREAM_URL)
    data["scenario"] = "single_call"
    return jsonify(data), status


@app.route("/api/call-resilient")
def call_downstream_resilient():
    attempts = int(request.args.get("retries", "3"))
    backoff_ms = int(request.args.get("backoff_ms", "200"))
    history = []

    for attempt in range(1, attempts + 1):
        result, status = _call(DOWNSTREAM_URL)
        result["attempt"] = attempt
        history.append(result)
        if result.get("ok"):
            break
        time.sleep(backoff_ms / 1000.0)

    final = {
        "scenario": "single_call_with_retries",
        "attempts": len(history),
        "calls": history,
    }
    final_status = 200 if history[-1].get("ok") else 502
    return jsonify(final), final_status


@app.route("/api/read-heavy")
def read_heavy():
    count = int(request.args.get("n", "20"))
    successes = 0
    failures = 0
    calls = []
    start_all = time.time()

    for i in range(count):
        url = f"{DOWNSTREAM_BASE_URL}/item/{i}"
        result, _ = _call(url, timeout=2.0)
        result["index"] = i
        calls.append(result)
        if result.get("ok"):
            successes += 1
        else:
            failures += 1

    total_duration = time.time() - start_all
    summary = {
        "scenario": "read_heavy",
        "requested_reads": count,
        "successes": successes,
        "failures": failures,
        "total_duration_seconds": round(total_duration, 3),
        "average_duration_seconds": round(total_duration / max(count, 1), 3),
        "sample_calls": calls[:5],
    }
    return jsonify(summary), 200


@app.route("/api/write-heavy", methods=["POST"])
def write_heavy():
    count = int(request.args.get("n", "10"))
    payload_template = request.get_json(silent=True) or {"source": "demo-api"}
    successes = 0
    failures = 0
    calls = []
    start_all = time.time()

    for i in range(count):
        payload = {**payload_template, "sequence": i}
        url = f"{DOWNSTREAM_BASE_URL}/write"
        result, _ = _call(url, method="POST", json_body=payload, timeout=5.0)
        result["index"] = i
        calls.append(result)
        if result.get("ok"):
            successes += 1
        else:
            failures += 1

    total_duration = time.time() - start_all
    summary = {
        "scenario": "write_heavy",
        "requested_writes": count,
        "successes": successes,
        "failures": failures,
        "total_duration_seconds": round(total_duration, 3),
        "average_duration_seconds": round(total_duration / max(count, 1), 3),
        "sample_calls": calls[:5],
    }
    return jsonify(summary), 200


@app.route("/api/fanout")
def fanout():
    endpoints = [
        f"{DOWNSTREAM_BASE_URL}/slow",
        f"{DOWNSTREAM_BASE_URL}/item/1",
        f"{DOWNSTREAM_BASE_URL}/item/2",
        f"{DOWNSTREAM_BASE_URL}/item/3",
    ]
    results = []
    start_all = time.time()

    for url in endpoints:
        result, _ = _call(url, timeout=5.0)
        result["url"] = url
        results.append(result)

    total_duration = time.time() - start_all
    summary = {
        "scenario": "fanout",
        "calls": results,
        "total_duration_seconds": round(total_duration, 3),
    }
    return jsonify(summary), 200


@app.route("/healthz")
def healthz():
    return "ok", 200


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5678"))
    app.run(host="0.0.0.0", port=port)


