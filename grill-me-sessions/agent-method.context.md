# Agent Method — Decision Context

Companion to `agent-method.grill.md`. The grill file captures *what was decided*. This file captures *why those decisions were chosen over alternatives*, what was reframed during the discussion, and which risks were accepted with eyes open vs. resolved. A remote agent picking up this work should read both.

## How to use this file

If you find yourself questioning a decision in the grill file, look here for the alternatives that were considered and the reason they were rejected. If your question isn't covered, the rationale was probably implicit and you should treat it as a live question rather than re-litigated ground.

---

## Framing shifts that happened during design

These are reframings that changed how subsequent decisions were made. Decisions made before these shifts may need re-examination if the shifts are reversed.

### "Autonomy" was reframed as "correctness with less human time"

The user initially asked for "as autonomous as possible." This was reframed: autonomy isn't the goal — *correctness with less human time* is. Autonomy that produces broken output costs more, not less. Every "replace human with agent" decision was made under this lens: not "can we remove a human," but "can we replace this human with a cheaper-but-still-real check." This is why adversarial agents were chosen over removing checks entirely.

### "The method" vs. "the orchestrator" — recipe vs. kitchen

Mid-discussion, it became clear the user was conflating the *method* (the conceptual recipe — Gherkin → signatures → distribute → implement → combine) with the *orchestrator* (the actual software that runs that recipe: Temporal workflows, prompt dispatch, retry routing, fan-out coordination). The recipe is mostly designed. The kitchen is unbuilt. This distinction matters because "another agent will build it" is a non-answer for the kitchen — it's substantial software work that has to exist before any experiment can run.

### Architecture phase: not optional, just implicit-or-explicit

The architecture phase was initially presented as "an idea, possibly a distraction." This was rejected. Architectural decisions (shared types, FC/IS shell skeleton, module boundaries, composition graph) are *required* by the method whether or not you name a phase for them. Without a phase, they happen silently inside signature generation with no scrutiny. The choice isn't "have architecture or not" — it's "have it explicitly and reviewably, or have it tangled with translation and unaccountable."

### Bar B = spec compliance, NOT real-world correctness

Bar B (independent test suite from same Gherkin) was chosen, but this is a deliberately narrower claim than "method produces correct software." If the Gherkin is ambiguous or wrong, both the pipeline and the independent suite share the same flaws and will agree on a wrong answer. The experiment writeup must say so explicitly. Conclusions that overclaim correctness will be wrong.

---

## Alternatives considered and rejected

### Tests authored by implementing agents themselves
**Rejected.** "Agent grades own homework" — agents will trivially write tests their code passes. Real TDD requires the tests to come from outside the implementer. So tests are authored upstream by a dedicated test-generation agent (or alongside the architecture phase) and handed to the implementer as part of its contract.

### Single human review gate
**Rejected.** Reviewing only at the end means the parallel implementation budget has already been burned on potentially wrong contracts. Reviewing only at the start means trusting implementation agents not to drift collectively. At least two adversarial gates are needed (post-architecture and post-composition). The user chose to use adversarial agents at *all four* gates instead.

### Folding failure attribution into the adversarial reviewer
**Rejected.** Critique and attribution are different jobs. Folding them risks degrading both. Attribution is now a distinct fifth-then-seventh agent role.

### Monolithic shell agent (one writer for all impure code)
**Rejected.** The shell is where most real-system bugs live (race conditions, transactional boundary errors, partial-failure cleanup, auth edges, retry logic, serialization). A method that applies parallel-agent rigor to the easy part (pure functions) and single-agent treatment to the hard part (shell) has its rigor inverted. The shell is now parallelized identically to the core.

### Bar A (pipeline passes its own generated tests)
**Rejected as circular.** The pipeline produced the tests; "passing" them measures internal consistency, not correctness. Bar B (independent test suite) is the chosen alternative.

### Single experimental run
**Rejected.** LLMs are probabilistic. One run = one number that could be noise. Five runs gives a distribution and a defensible signal: median, range, and per-run triaged pass rates. Cost was acknowledged and accepted.

### "Just describe the method, the agent will figure out the orchestrator"
**Rejected as wishful thinking.** Building Temporal workflows, 7 agent prompts, Gherkin product, step-def skeletons, triage tooling, and cost monitoring is substantial software work — likely 5–10× the effort of the method design itself. Treating it as a side-errand was the user's most consequential misjudgment going into this session, and surfacing it was probably the most useful outcome.

### Skipping the dry-run / infrastructure-validation phase
**Rejected.** Bugs in the orchestrator look identical to bugs in the method. Without a small-scale dry-run on a tiny Gherkin first, infrastructure failures will be misattributed as method failures and the experiment results will be uninterpretable.

### "SOLID" as the design slogan
**Soft-rejected.** SOLID is mostly about classes and modules. For pure functions, only SRP applies cleanly; OCP/LSP/ISP/DIP are awkward without object boundaries. The grill file deferred this as a risk: replace the slogan with concrete verifiable properties (functions do one thing, ports follow ISP, shell composition uses DIP) so the adversarial reviewer can actually check them.

---

## Tradeoffs accepted with eyes open

These are choices where a downside was named and the user chose to accept it rather than mitigate. They are NOT settled — they are deliberate.

### More dedicated agents → more coordination surface area
Adding the failure-attribution agent and parallelizing the shell pushed the pipeline to 7 agent roles. Each role is a place the method can fail. The user prefers dedicated agents over overloaded ones; the additional handoff complexity is acceptable for this experiment but is a real cost.

### Architecture phase is a serial bottleneck on a parallel method
The pipeline's parallelism win is gated on a serial architecture phase. If architecture takes a long time or fails repeatedly, no implementation parallelism happens. Accepted because alternatives (silent architecture, no architecture) are worse.

### Late-gate failures cascade — architecture retries invalidate downstream work
If the composition gate reveals an architecture-level flaw (e.g., shared type mismatch across functions), retrying the architecture invalidates every implementation built against the old types. There is no clever way to "patch" an architecture change while preserving downstream work. The blast radius is real and unavoidable. Mitigation: strong upstream gates to make architecture failures rare, and small architecture retry budget so failure escalates to human early.

### Bar B is narrower than "produces correct software"
See "Framing shifts" above. Acknowledged in writeup planning.

### No budget cap during testing, soft cap of $50 during dry-run
The user chose not to set a hard budget for the full experiment, only for dry-runs. Risk: a runaway loop in the real experiment could burn significantly. Mitigation lives in the layered kill switches (no-progress detection, oscillation detection, wall-clock cap, total-call cap) — these are believed to catch runaway behavior before money becomes the limiting factor. Worth revisiting after the dry-run produces real cost data.

---

## Risk areas not fully resolved

These are surfaced concerns that were noted but not fully resolved. A remote agent should treat them as live.

### Per-gate red-team semantics
"Adversarial = critic + red-team" is settled in principle. Concrete red-team semantics for the architecture gate (what does "construct a counterexample" mean when the artifact is a type system + module boundary?) is hand-wavy. Without concretization, upstream gates produce vague critique rather than counterexamples and become weaker than intended.

### Prompts as a hidden source of method failures
The agent prompts (7 of them) are *where the method actually lives*. The orchestrator is wiring. A bug in the architect prompt looks identical to a methodology flaw in early runs. The recommended sequencing (iterate prompts standalone before wiring into Temporal) addresses this, but only if it's actually followed.

### Ambiguity-handling is two-stage but the second stage is human-loaded
Triage of failures into method-failure / spec-ambiguity / step-def-bug / environment requires human judgment per failed scenario, per run, across 5 runs. At hundreds of scenarios, this is a real time cost. If the user later tries to automate triage, that re-introduces the "agents grading agents" problem.

### Generalization claim limits
The test product is a financial valuations Gherkin. If its shell is genuinely thin (load CSV, compute, write CSV), this experiment doesn't validate the method for fat-shell systems (multi-endpoint API, persistence, auth, concurrency). Even a strong Bar B result needs to be reported with this caveat.

### Recursion / dogfooding the method on itself
Briefly considered: could the method build its own orchestrator? Not chosen for this experiment (orchestrator is assumed infrastructure). But the question of whether the method scales to its own complexity is implicitly an open one — answered "no" by exclusion in this experiment, not by evidence.

---

## Things the user explicitly committed to (preferences worth preserving)

- **When in doubt, prefer a dedicated agent over overloading an existing one.** Stylistic preference, accepted complexity tradeoff.
- **Maximum autonomy in the middle of the pipeline.** Humans only at Gherkin-in and final acceptance-out. Adversarial agents replace human review at every intermediate gate.
- **Correctness is essential even though this isn't a production deliverable.** The whole experiment is meaningless if the method's "success" is measured against a flawed bar.

---

## Open meta-question

The user described this as testing "a new development method." In practice, the experiment tests one specific instantiation: 7 specific agent roles, a specific orchestration pattern, a specific success bar, against a specific Gherkin product. A successful experiment validates *that instantiation*, not "the method" in general. If the next step after success is "use this on real projects," the gap between "passed Bar B on this Gherkin" and "this method is suitable for X kind of work" should be reckoned with explicitly. This was not discussed during the grill but is worth surfacing.
