from __future__ import annotations

import importlib


def test_dashboard_demo(monkeypatch):
    monkeypatch.setenv("MINDLINK_DATA_MODE", "demo")
    module = importlib.import_module("dashboard.app")
    client = module.app.test_client()

    health = client.get("/api/health")
    assert health.status_code == 200
    assert health.get_json()["mode"] == "demo"

    response = client.get("/api/dashboard")
    payload = response.get_json()
    assert response.status_code == 200
    assert payload["mode"] == "demo"
    assert payload["kpis"]["internacoes"] == 3305
    assert payload["predictions"] == []


def test_select_ai_disabled_in_demo(monkeypatch):
    monkeypatch.setenv("MINDLINK_DATA_MODE", "demo")
    module = importlib.import_module("dashboard.app")
    client = module.app.test_client()
    response = client.post("/api/select-ai", json={"pergunta": "Qual a pressão?"})
    assert response.status_code == 503

