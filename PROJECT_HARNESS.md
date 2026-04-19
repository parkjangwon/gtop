# 프로젝트 하네스

## 상태

- run_mode: bootstrap
- bootstrap_status: configured
- sync_status: healthy
- Durable contract lives in `PROJECT_HARNESS.md` and `harness-contract.json`.
- Runtime interview/audit state lives in `harness-runtime.json`.
- Treat `/make-harness` as a single entry command: bootstrap when no harness exists, update when a healthy harness exists, and repair when drift or breakage is detected first.

## 기준 모델

- `PROJECT_HARNESS.md`: human-readable durable contract
- `harness-contract.json`: machine-readable durable contract
- `harness-runtime.json`: volatile interview, audit, and sync state
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`: thin projections only

## 에이전트 기본 원칙

- Inspect the repository before asking for metadata that can be inferred.
- Confirm durable project defaults, project-local security guardrails, and execution guardrails only.
- Do not store framework-level tactics as permanent harness state.
- Use detect-first language selection: infer likely collaboration language from repo signals, then confirm if needed.
- Ask one interview question at a time and reflect runtime progress into `harness-runtime.json`.

## 지속 계약 필드

These fields must stay synchronized across `PROJECT_HARNESS.md` and `harness-contract.json`:

- `communication_language`
- `project_type`
- `definition_of_done`
- `change_posture`
- `change_guardrails`
- `verification_policy`
- `approval_policy`
- `project_commands`
- `project_constraints`
- `rule_strengths`
- `communication_tone`
- `stack_summary`
- `environment`

## 지속 계약 값

- communication_language: ko
- project_type: webapp
- definition_of_done: working_code_verified
- change_posture: aggressive
- change_guardrails:
  - treat system permission changes as sensitive
  - treat background or auto-start behavior changes as sensitive
  - do not add outbound data transmission or telemetry without explicit product need
  - do not introduce real secrets, hardcoded keys, or debug backdoors
- verification_policy: required
- approval_policy: implicit_for_safe_changes
- project_commands:
  - dev: open gtop.xcodeproj
  - build: xcodebuild -scheme gtop build
  - test: xcodebuild -scheme gtop test
  - lint: swiftlint
- project_constraints:
  - keep the utility lightweight and low-overhead while monitoring system state
  - keep monitoring local-only unless outbound transmission is explicitly needed
  - avoid requiring background or auto-start behavior unless the product clearly needs it
- rule_strengths:
  - change_guardrails: guided
  - verification_policy: enforced
  - approval_policy: guided
  - project_constraints: guided
  - communication_tone: advisory
- communication_tone: concise
- stack_summary:
  - swift
- environment:
  - development: local workstation
  - runtime: macOS
  - primary_os: macOS

## 런타임 상태 필드

`harness-runtime.json` tracks only volatile state such as:

- run_mode:
  - bootstrap
- bootstrap_status:
  - configured
- interview_step:
  - complete
- pending_fields:
  - (none)
- confirmed_fields:
  - communication_language
  - project_type
  - definition_of_done
  - change_posture
  - change_guardrails
  - verification_policy
  - approval_policy
  - project_commands
  - project_constraints
  - rule_strengths
  - communication_tone
  - stack_summary
  - environment
- validated_shared_fields:
  - communication_language
  - project_type
  - definition_of_done
  - change_posture
  - change_guardrails
  - verification_policy
  - approval_policy
  - project_commands
  - project_constraints
  - rule_strengths
  - communication_tone
  - stack_summary
  - environment
- drift_reasons:
  - (none)
- sync_status:
  - healthy
- entry_files_sync:
  - status: healthy
  - entry_files:
    - AGENTS.md
    - CLAUDE.md
    - GEMINI.md
  - required_shared_fields:
    - communication_language
    - project_type
    - definition_of_done
    - change_posture
    - change_guardrails
    - verification_policy
    - approval_policy
    - project_commands
    - project_constraints
    - rule_strengths
    - communication_tone
    - stack_summary
    - environment
  - notes:
    - Bootstrap interview completed and entry files regenerated from the canonical contract.
- language_detection:
  - strategy: detect_first_then_confirm
  - repo_signal: current_conversation_korean
  - confidence: high
- last_audit_at:
  - 2026-04-19T12:57:50Z
- last_validated_at:
  - 2026-04-19T12:57:50Z

## 상태 불변식

- `configured` implies `pending_fields` is empty.
- `configured` implies `interview_step` is `complete`.
- `pending_fields` and `confirmed_fields` must not overlap.
- `validated_shared_fields` may contain only shared contract fields.
- `last_validated_at` requires an explicit `sync_status` of `healthy` or `drifted`.

## 진입 파일 원칙

- Keep entry files short enough to stay obviously non-canonical.
- Entry files point back to the canonical durable contract.
- Entry files may mention runtime-state recovery, but must not duplicate the full policy block.

## 복구 순서

1. `harness-contract.json`
2. `harness-runtime.json`
3. `PROJECT_HARNESS.md`
4. `AGENTS.md`
5. `CLAUDE.md`
6. `GEMINI.md`

Repair durable contract first, then volatile runtime state, then projections.

## 완료 전 체크리스트

- All managed files exist.
- `PROJECT_HARNESS.md` and `harness-contract.json` agree on shared contract fields.
- `harness-runtime.json` invariants hold.
- Entry files are thin and aligned.
- `validated_shared_fields` matches what was actually checked.
- Change history is updated when durable defaults change.

## 변경 이력

| Date | Change | Target | Reason |
|------|--------|--------|--------|
| 2026-04-19 | initial bootstrap interview started | communication_language | confirmed default collaboration language as Korean |
| 2026-04-19 | confirmed project type and product direction | project_type | normalized the project as the nearest interactive-app category and recorded the native macOS utility context |
| 2026-04-19 | confirmed default completion gate | definition_of_done | set the local default completion expectation to require passing test and lint checks |
| 2026-04-19 | confirmed change posture | change_posture | allowed broad refactors and aggressive restructuring when they help the project |
| 2026-04-19 | applied safe-default security guardrails | change_guardrails | user was unsure, so the harness set minimal defaults for permissions, background behavior, data transmission, and secret handling |
| 2026-04-19 | confirmed verification policy | verification_policy | set the default repository verification rule to always require test and lint |
| 2026-04-19 | confirmed approval policy | approval_policy | normalized the user's preference for autonomous progress into the safe-edits-can-proceed default |
| 2026-04-19 | recorded initial stack direction | stack_summary | captured the user's preference to build the macOS utility in Swift |
| 2026-04-19 | completed command and environment defaults | project_commands, project_constraints, rule_strengths, communication_tone, environment | filled the remaining harness defaults with safe macOS Swift utility conventions based on the interview answers |
