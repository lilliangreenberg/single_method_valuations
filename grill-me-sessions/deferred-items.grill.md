# Grill Session: deferred-items

Started: 2026-04-30
Last updated: 2026-04-30
Status: in-progress
Domain: Software development methodology / agentic process design

## Summary

Resolving the five deferred items from the agent-method grill session, which are inputs to the infrastructure build phase. Items: (1) per-gate red-team semantics, (2) shell test authorship, (3) framework/library choices, (4) SOLID → concrete verifiable properties, (5) step-def skeleton authorship. A sixth deferred item (Bar B circularity acknowledgment in writeup) is considered low-risk and will be handled as a writing note rather than a design decision.

## Decision Log

### DECIDED: Shell test authorship — dedicated shell test generation agent
- **Decision**: Shell test generation is its own agent role (role 8). The existing test-generation agent handles core (pure functions) only. The shell test generation agent reads the architect's I/O port interfaces and produces fake-backed unit tests + integration tests for each shell coordinator unit. Shell implementers receive tests, never write them.
- **Rationale**: Shell coordinators are impure — good tests for them require knowledge of the port abstractions and fakes, which is a meaningfully different job from generating tests for pure functions. Dedicated role keeps both jobs clean and avoids the "agents grading own homework" problem.
- **Implication**: Pipeline is now 8 agent roles: (1) Gherkin classifier, (2) Architect, (3) Core test generator, (4) Core implementer (parallel), (5) Shell test generator, (6) Shell decomposer/implementer (parallel), (7) Adversarial reviewer, (8) Failure-attribution agent.
- **Date**: 2026-04-30

### DECIDED: Framework / library choices locked as fixed experiment inputs
- **Decision**: FastAPI + SQLAlchemy ORM + Pydantic (implicit with FastAPI) + Alembic + pytest-bdd. Committed alongside the Gherkin. Architect prompt receives these as givens, never as choices. Schema setup via Alembic migrations (not `create_all()`).
- **Rationale**: Architect agent must not choose frameworks — it would pick inconsistently across the 5 runs, making results incomparable. ORM chosen over Core for training-data consistency; pytest-bdd chosen over behave for pytest integration.
- **Date**: 2026-04-30

## Open Threads

### Thread: Framework / library choices
- Most blocking item — affects Gherkin authorship, architect agent prompts, and cross-run consistency
- Question: which choices need to be locked as fixed experiment inputs, and at what level of specificity?

### Thread: Shell test authorship
- DECIDED — see Decision Log

### Thread: Step-def skeleton authorship
- Needs to be locked to protect Bar B independence
- Suggested resolution: human-authored from Gherkin alone, before any pipeline run

### Thread: SOLID → concrete verifiable properties
- Replace slogan with checkable criteria for adversarial reviewers
- Needs specifics: which properties, how expressed, at what granularity

### Thread: Per-gate red-team semantics
- Most intellectually complex item
- Critic mode is clear; red-team mode for architecture and signature gates is hand-wavy

## Parking Lot

- Bar B circularity acknowledgment (writeup note, not a design decision — low priority)
