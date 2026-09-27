PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS ci_runs (
    run_id INTEGER PRIMARY KEY,
    workflow TEXT NOT NULL,
    workflow_id INTEGER,
    head_sha TEXT,
    head_branch TEXT,
    event TEXT,
    conclusion TEXT,
    run_attempt INTEGER NOT NULL DEFAULT 1,
    created_at TEXT,
    updated_at TEXT,
    duration_seconds REAL,
    html_url TEXT
);

CREATE TABLE IF NOT EXISTS ci_jobs (
    job_id INTEGER PRIMARY KEY,
    run_id INTEGER NOT NULL,
    workflow TEXT NOT NULL,
    name TEXT NOT NULL,
    conclusion TEXT,
    started_at TEXT,
    completed_at TEXT,
    duration_seconds REAL,
    html_url TEXT,
    FOREIGN KEY (run_id) REFERENCES ci_runs(run_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS memory_entries (
    kind TEXT NOT NULL,
    memory_key TEXT NOT NULL,
    summary TEXT NOT NULL,
    metadata_json TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    expires_at TEXT,
    PRIMARY KEY (kind, memory_key)
);

CREATE INDEX IF NOT EXISTS idx_ci_runs_updated
    ON ci_runs(updated_at);
CREATE INDEX IF NOT EXISTS idx_ci_runs_workflow_conclusion
    ON ci_runs(workflow, conclusion);
CREATE INDEX IF NOT EXISTS idx_ci_jobs_run
    ON ci_jobs(run_id);
CREATE INDEX IF NOT EXISTS idx_ci_jobs_workflow_conclusion
    ON ci_jobs(workflow, conclusion);
CREATE INDEX IF NOT EXISTS idx_memory_updated
    ON memory_entries(updated_at);
