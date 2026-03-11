import os
import random
import time

from flask import Flask, abort, jsonify, request


app = Flask(__name__)


def _get_delay_seconds() -> float:
    base_delay = float(os.getenv("DEMO_DELAY_SECONDS", "0.2"))
    jitter = float(os.getenv("DEMO_DELAY_JITTER", "0.3"))
    extra = random.random() * jitter
    return base_delay + extra


def _maybe_fail():
    error_rate = float(os.getenv("DEMO_ERROR_RATE", "0.0"))
    if error_rate <= 0:
        return
    if random.random() < error_rate:
        abort(500, description="simulated downstream error")


def _maybe_cpu_spike():
    spike_seconds = float(os.getenv("DEMO_CPU_SPIKE_SECONDS", "0.0"))
    if spike_seconds <= 0:
        return

    end_time = time.time() + spike_seconds
    x = 0
    while time.time() < end_time:
        x += 1  # burn some CPU


@app.route("/slow")
def slow():
    delay = _get_delay_seconds()
    time.sleep(delay)
    _maybe_fail()

    return jsonify(
        {
            "service": "demo-downstream",
            "endpoint": "/slow",
            "delay_seconds": round(delay, 3),
        }
    )


@app.route("/item/<int:item_id>")
def get_item(item_id: int):
    # fast-ish read, still with a bit of jitter and optional errors
    delay = _get_delay_seconds() * 0.3
    time.sleep(delay)
    _maybe_fail()

    return jsonify(
        {
            "service": "demo-downstream",
            "endpoint": "/item",
            "item_id": item_id,
            "value": f"item-{item_id}",
            "delay_seconds": round(delay, 3),
        }
    )


@app.route("/write", methods=["POST"])
def write():
    delay = _get_delay_seconds()
    time.sleep(delay)
    _maybe_cpu_spike()
    _maybe_fail()

    payload = request.get_json(silent=True) or {}

    return jsonify(
        {
            "service": "demo-downstream",
            "endpoint": "/write",
            "stored": True,
            "delay_seconds": round(delay, 3),
            "payload_size": len(str(payload)),
        }
    )


@app.route("/healthz")
def healthz():
    return "ok", 200


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)


