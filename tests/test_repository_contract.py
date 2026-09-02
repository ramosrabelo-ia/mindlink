from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_canonical_artifacts_exist() -> None:
    expected = [
        "src/mindlink_etl_sprint3_oracle.py",
        "dags/mindlink_primeira_dag.py",
        "sql/01_ddl_mindlink_sprint3.sql",
        "sql/02_dml_mindlink_sprint3.sql",
        "docs/ARCHITECTURE.md",
        "docs/STATUS.md",
        "docs/EVIDENCE.md",
    ]

    for relative in expected:
        assert (ROOT / relative).is_file(), f"Artefato ausente: {relative}"


def test_no_credentials_are_versioned() -> None:
    forbidden_names = {".env", "tnsnames.ora", "cwallet.sso", "ewallet.p12"}
    tracked_candidates = {
        path.name.lower()
        for path in ROOT.rglob("*")
        if path.is_file() and ".git" not in path.parts
    }

    assert forbidden_names.isdisjoint(tracked_candidates)


def test_pending_dml_is_explicit_and_not_executable() -> None:
    dml_path = ROOT / "sql/02_dml_mindlink_sprint3.sql"
    content = dml_path.read_text(encoding="utf-8").upper()

    assert "PENDENTE" in content
    executable_tokens = ("INSERT INTO", "MERGE INTO", "UPDATE ", "DELETE FROM")
    assert not any(token in content for token in executable_tokens)


def test_documentation_does_not_claim_pending_dml_as_delivered() -> None:
    documentation = "\n".join(
        (ROOT / relative).read_text(encoding="utf-8")
        for relative in (
            "README.md",
            "docs/STATUS.md",
            "docs/EVIDENCE.md",
            "docs/AUDITORIA_FASE04.md",
            "sql/README.md",
        )
    ).lower()

    forbidden_claims = (
        "dml da carga oracle | sim | sim na entrega",
        "registra a carga utilizada na entrega",
        "carga documentada está em `sql/02_dml_mindlink_sprint3.sql`",
    )
    assert not any(claim in documentation for claim in forbidden_claims)
