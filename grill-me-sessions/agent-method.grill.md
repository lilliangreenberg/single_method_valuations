# Grill Session: agent-method

Started: 2026-04-29
Last updated: 2026-04-29
Status: complete (with deferred items noted as open risks)
Domain: Software development methodology / agentic process design

## Summary

A proposed development method where Gherkin requirements are translated into a shared architecture (types, FC/IS shell, module boundaries, composition graph) plus method signatures + tests, distributed one signature/test bundle per implementation agent. Each agent implements a single pure/side-effectless function in red→green TDD against the supplied tests. Functions are then composed into a working product. Adversarial agents replace human review at intermediate gates. The method is being evaluated as a methodology test, not for production output.

## Decision Log

### DECIDED: Explicit architecture phase before signature fan-out
- **Decision**: Insert a phase that produces shared types, FC/IS shell skeleton, module boundaries, and composition graph before parallel implementation begins.
- **Rationale**: These decisions are required regardless; making them implicit means they happen inside the signature-generation step with no scrutiny. Explicit phase = reviewable.
- **Date**: 2026-04-29

### DECIDED: Tests authored upstream, not by implementing agents
- **Decision**: Tests for each function are generated at the architecture/translation phase and handed to the implementing agent as part of its contract. Implementing agent does red→green against given tests.
- **Rationale**: Agents writing their own tests grade their own homework. Real TDD requires the tests to come from outside the implementer.
- **Date**: 2026-04-29

### DECIDED: Adversarial agents replace human review at intermediate gates
- **Decision**: Use adversarial review agents to validate architecture output and intermediate artifacts. No human gates between Gherkin-in and acceptance-out.
- **Rationale**: Goal is autonomous operation; user is testing the method's ability to operate without human intervention in the middle.
- **Date**: 2026-04-29

### DECIDED: Humans only at Gherkin-in and final acceptance-out
- **Decision**: Gherkin is human-authored and human-reviewed. Final composed product is human-validated for acceptance. Everything between is autonomous.
- **Date**: 2026-04-29

### DECIDED: This is a methodology test, not a production deliverable
- **Decision**: The output is a validation of the method itself. Code produced will not be used in production. Correctness against the Gherkin spec still matters because it is the success criterion for the method.
- **Date**: 2026-04-29

### DECIDED: Adversarial review at all four gates
- **Decision**: Architecture output, signature/test bundles, individual implementations, and final composition all receive adversarial review.
- **Date**: 2026-04-29

### DECIDED: Adversarial agents combine critic + red-team modes
- **Decision**: Each adversarial pass both critiques (lists problems) and red-teams (constructs counterexamples). Per-gate definition of "counterexample" still needs to be specified.
- **Open follow-up**: Concrete red-team semantics per gate (especially architecture gate).
- **Date**: 2026-04-29

### DECIDED: Hierarchical retry with budget per phase + human escalation
- **Decision**: Each gate has a retry budget. Cheapest retries (implementation) get the largest budget; most expensive (architecture) get the smallest. Retry N+1 receives the adversarial critique from retry N. Exhausting budget escalates to human with all artifacts and critiques attached.
- **Open follow-up**: Concrete numeric budgets per gate.
- **Date**: 2026-04-29

### DECIDED: Distinct failure-attribution agent
- **Decision**: A dedicated agent reads failure traces and routes the fix to the responsible phase. Distinct from adversarial reviewers — different role, different prompt.
- **Rationale**: Attribution is a different job from critique; folding them risks degrading both.
- **Date**: 2026-04-29

### DECIDED: Pipeline now has five agent roles
- **Decision**: (1) Architect, (2) Signature/test generator, (3) Implementer, (4) Adversarial reviewer, (5) Failure-attribution agent.
- **Date**: 2026-04-29

### DECIDED: Shell vs. core classification is its own phase + agent
- **Decision**: A classifier agent reads Gherkin and partitions scenarios (or steps) into shell-relevant and core-relevant. Output drives downstream architecture and shell phases.
- **Date**: 2026-04-29

### DECIDED: Dedicated shell agent writes the imperative shell
- **Decision**: A separate agent role writes the impure coordinator code (I/O, persistence, external calls, time, IDs, logging) that wires pure functions into a working product.
- **Date**: 2026-04-29

### DECIDED: Shell is tested; tests reviewed by critic agent
- **Decision**: Shell code receives tests (integration-level). Adversarial/critic agent reviews shell + tests.
- **Open follow-up**: Who *writes* the shell tests — test-generation agent, shell agent itself, or a separate test agent? "Tested by critic" is ambiguous between authoring and reviewing.
- **Date**: 2026-04-29

### DECIDED: Default to dedicated agents when role boundary is unclear
- **Decision**: User preference: when in doubt, split work into a dedicated agent rather than overloading an existing one.
- **Tradeoff acknowledged**: More agent roles = more coordination surface area and more handoff points where bugs can hide. Acceptable for this experiment.
- **Date**: 2026-04-29

### DECIDED: Pipeline now has seven agent roles
- **Decision**: (1) Gherkin classifier, (2) Architect, (3) Signature/test generator, (4) Implementer (parallel), (5) Shell agent, (6) Adversarial reviewer, (7) Failure-attribution agent.
- **Date**: 2026-04-29

### DECIDED: Shell phase is parallelized like the core
- **Decision**: The shell is decomposed into discrete coordinator units (per use case / endpoint / command), each assigned to a parallel implementation agent with upstream-authored tests, adversarial review, and retry/attribution machinery — same rigor as core.
- **Implication**: Architecture phase scope expands to include I/O abstractions / ports (DB, HTTP client, clock, ID generator, etc.) so shell coordinators can be tested against fakes. Test-generation phase must produce both real-call tests and fake-backed unit tests for shell units.
- **Implication**: The "shell agent" role is now a *coordinator/decomposer* (analogous to architect for the shell layer) that produces shell unit signatures + tests for fan-out — not a monolithic writer.
- **Date**: 2026-04-29

### DECIDED: Success criterion is Bar B (independent test suite)
- **Decision**: Method "works" if the composed product satisfies an independent acceptance test suite derived from the Gherkin. Bar B = spec compliance, not real-world correctness — limitation acknowledged.
- **Date**: 2026-04-29

### DECIDED: Independent suite mechanics
- **Decision**: Gherkin scenarios + step-definition skeleton (signatures + docstrings, no implementation) are committed before the pipeline runs. After pipeline produces code, a cold-start agent (no pipeline context, fresh session, separate prompts) fills in the step definitions to call the produced API. Run behave/pytest-bdd. Pass/fail per scenario.
- **Date**: 2026-04-29

### DECIDED: Two-stage handling of ambiguous-Gherkin failures
- **Decision**: (1) Pre-experiment ambiguity gate — adversarial agent reviews Gherkin for vague terms, unstated preconditions, multi-interpretation scenarios; flagged items rewritten until clean. (2) Post-failure triage — failures classified as method failure / residual spec ambiguity / step-def bug / environment flake. Report both raw pass rate and triaged pass rate.
- **Date**: 2026-04-29

### DECIDED: Pass threshold = 95%
- **Decision**: Method considered to have worked if triaged pass rate ≥ 95% per run. At hundreds of scenarios across 10 files, this leaves meaningful room (e.g., ~15 failures tolerated at N=300).
- **Date**: 2026-04-29

### DECIDED: 5 runs to control for probabilistic noise
- **Decision**: Run the full pipeline 5 times against the same Gherkin. Report median, range, and per-run triaged pass rates. Single-run results would not provide a defensible signal given LLM probabilistic behavior.
- **Cost acknowledged**: 5× pipeline execution cost; 5× triage burden.
- **Date**: 2026-04-29

### DECIDED: Test product is hundreds of scenarios across 10 Gherkin files
- **Decision**: At this N, 95% threshold leaves meaningful room for noise (~15 failures tolerated at N=300).
- **Date**: 2026-04-29

### DECIDED: Orchestrator built on Temporal
- **Decision**: Temporal workflows orchestrate the 7-role pipeline. Durable execution, parallel fan-out, retry policies, and resumability come for free.
- **Implication**: Building Temporal workflows correctly is real engineering work, not a nominal task. Orchestrator + 7 agent prompts + Gherkin product + step-def skeletons + cold-start step-def-filler + triage tooling are all unbuilt infrastructure that must exist before experiment #1.
- **Date**: 2026-04-29

### DECIDED: Project sequencing — four phases
- **Decision**: (a) Method design (this session), (b) Infrastructure build (orchestrator + prompts + Gherkin + tooling), (c) Infrastructure validation via dry-run on a small Gherkin (5–10 scenarios, exercises all 7 roles + retry + attribution + escalation), (d) Real experiment (5 runs against the full Gherkin).
- **Rationale**: Phase (b) is much bigger than (a). Going from (a) directly to (d) makes infrastructure bugs indistinguishable from method failures.
- **Date**: 2026-04-29

### DECIDED: Layered kill-switch design
- **Decision**:
  - L1 — Per-call wall-clock timeout (~5 min per agent call, ~15 min for parallel collection)
  - L2 — Per-phase retry budget (architecture: 2, signature/test gen: 2, implementation per function: 3, composition: 2)
  - L3 — No-progress detection: hash failure signatures (failing test names + error types); 2 consecutive same-signature retries on the same phase → abort
  - L4 — Cross-phase oscillation detection: attribution routing between the same two phases >3 times in one run → abort
  - L5 — Per-run wall-clock cap: 6 hours for dry runs, revisit for real runs
  - L6 — Per-run total-call cap: 500 invocations for dry runs, scale up for real runs
  - L7 — Per-run cost cap: $50 hard abort during dry-run / infrastructure validation; revisit before real runs (likely $200–$500/run at full Gherkin scale)
- **Date**: 2026-04-29

## Open Threads

(all major branches resolved)

## Deferred / Open Risks

### DEFERRED: Per-gate red-team semantics
- **Reason**: Concrete definition of "what does red-team mean for the architecture gate" was deferred. Critic mode is well-defined; red-team mode is well-defined for implementation gates (generate adversarial inputs). For architecture and signature gates, "construct a counterexample" is hand-wavy.
- **Risk if ignored**: Adversarial agents at upstream gates produce vague critique rather than concrete counterexamples. Upstream gates become weaker than intended.
- **Suggested resolution**: During infrastructure build, write per-gate adversarial agent prompts with concrete counterexample-construction instructions (e.g., for architecture: "find a Gherkin scenario whose state cannot be expressed in the produced type system" or "find two functions whose contracts contradict on a shared type").

### DEFERRED: Shell test authorship
- **Reason**: User said shell is tested and reviewed by critic. Unclear whether the test-generation agent authors shell tests, or the shell decomposer agent does, or a separate agent.
- **Risk if ignored**: Same circularity as before — if shell-implementer authors shell tests, agents grade their own homework.
- **Suggested resolution**: Test-generation agent authors shell unit tests (using fakes for I/O ports defined in architecture phase) and integration tests, just as it does for the core. Shell implementer agents only consume tests, never write them.

### DEFERRED: Framework / library decisions
- **Reason**: Where does "we use FastAPI vs. Flask, SQLAlchemy vs. raw psycopg2, pytest vs. unittest" get decided? Not surfaced as a phase.
- **Risk if ignored**: Architect agent picks inconsistently across runs, or shell decomposer makes decisions architect should have. Inconsistency makes 5-run comparison harder.
- **Suggested resolution**: Lock framework choices as fixed inputs to the experiment (committed alongside Gherkin: "this experiment uses FastAPI + SQLAlchemy + pytest + behave"), so they don't vary across runs and don't drift between agents.

### DEFERRED: SOLID at function level
- **Reason**: User mentioned SOLID at the start; we never drilled into it. SOLID is largely about classes/modules. For pure functions, only SRP cleanly applies; OCP/LSP/ISP/DIP are awkward without object boundaries.
- **Risk if ignored**: "Follows SOLID" remains a slogan rather than a verifiable property. The adversarial reviewer can't check it.
- **Suggested resolution**: Replace "follows SOLID" with concrete verifiable properties: pure functions have single responsibility (named clearly, do one thing), I/O abstractions follow ISP (small focused ports), shell composition uses DIP (depends on ports, not concrete I/O). Drop the SOLID slogan and use the specific properties as adversarial-reviewer checks.

### DEFERRED: Step-definition skeleton authorship
- **Reason**: Locked decision says skeleton (signatures + docstrings, no implementation) is committed before pipeline runs. Unclear whether human or agent authors the skeleton.
- **Risk if ignored**: If a pipeline-context-aware agent authors the skeleton, "independent" suite leaks pipeline assumptions back into the test.
- **Suggested resolution**: Human authors skeleton from Gherkin alone, before any pipeline run. Cold-start agent fills implementations *after* pipeline produces code.

### DEFERRED: Bar B circularity acknowledgment in writeup
- **Reason**: Bar B tests spec compliance, not real-world correctness. Worth naming explicitly in the experiment writeup so conclusions don't overclaim.
- **Risk if ignored**: Conclusions read as "method produces correct software" when actually "method produces code that satisfies the supplied Gherkin."

## Parking Lot

(none — all surfaced topics resolved or deferred with notes)

## Recommended Next Steps

Build sequence in priority order. Each step has a clear "if this fails, will I know whether it's the method, the prompt, or the infrastructure?" answer — moving faster than this loses that property.

### 1. Resolve the deferred items first
The deferreds are inputs to the build, not afterthoughts. Resolve before starting infrastructure:
- Lock framework/library choices (FastAPI vs. Flask, SQLAlchemy vs. psycopg2, pytest, behave vs. pytest-bdd) as fixed experiment inputs so they don't vary across the 5 runs.
- Write per-gate adversarial-agent semantics — concrete counterexample-construction instructions per gate (especially architecture).
- Replace "SOLID" with the specific verifiable properties the adversarial reviewer will actually check.
- Lock step-def skeleton authorship as human, from Gherkin only.
- Lock shell test authorship: test-generation agent uses fakes for I/O ports defined by architect; shell implementer never writes its own tests.
- Run the existing Gherkin through the pre-experiment ambiguity gate even though it was previously human-reviewed.

Estimated effort: half-day of writing.

### 2. Author and iterate the agent prompts in isolation
The prompts are where the method lives; the orchestrator is wiring. Iterate prompts standalone before paying for infrastructure.
- Start with a tiny Gherkin (3–5 scenarios).
- Run each role's prompt manually, eyeball output, iterate.
- Find prompt issues here that would otherwise masquerade as orchestrator bugs later.

### 3. Build a minimum viable pipeline before the full 7-role choreography
Not all 7 prompts at once. Build the smallest end-to-end path:
- classifier + architect + signature/test gen + one implementer + one reviewer + composition
- Run on 2–3 Gherkin scenarios end-to-end (still by hand or with a tiny script — no Temporal yet).
- Confirms the *shape* of the method works before sinking effort into the full pipeline. If the minimum pipeline is incoherent, the full one will be too.

### 4. Build the Temporal orchestrator with stub agents first
Don't wire real LLM calls until the workflow shape is right. Stubs return canned data.
- Verify fan-out parallelizes
- Verify retries route to the right phase
- Verify attribution-routing acts on attribution agent output
- Force stubs to repeatedly "fail" and confirm L3 no-progress detection fires
- Verify escalation produces the artifacts you need

Catches Temporal-shape bugs without burning tokens.

### 5. Wire real prompts into the validated orchestrator and run the dry-run
- Small Gherkin (5–10 scenarios)
- Watch for: prompt failures the manual phase missed, integration issues between agents, cost surprises, kill-switch behavior under real load
- Iterate until clean

### 6. Build triage + cost monitoring tooling (in parallel with 4–5)
- Triage UI/script: per-failed-scenario presentation of Gherkin + produced code + step def + failure trace, accepts classification
- Cost monitoring: per-run token + dollar tracking, hard abort at $50 during dry-run phase
- Aggregate reporter: median pass rate, per-run distribution, raw vs. triaged

### 7. Real experiment
- 5 runs against the full Gherkin
- Triage each run
- Writeup with raw + triaged pass rates, plus explicit Bar-B circularity acknowledgment
- Revisit cost cap before starting (likely $200–$500/run at full scale)

### Discipline check
At each step: "if this fails, will I know whether it's the method, the prompt, or the infrastructure?" If the answer is no, slow down and add isolation before proceeding.
