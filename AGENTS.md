# Agent Entry

Read `PROJECT_HARNESS.md` first.
Read `harness-contract.json` for durable defaults.
Read `harness-runtime.json` only for current interview/runtime state.

현재 기본값 요약:
- 언어: ko
- 기본 검증: xcodebuild -scheme gtop test, swiftlint, xcodebuild -scheme gtop build
- 승인 규칙: 안전한 수정은 바로 진행, 위험한 변경은 별도 확인

- Treat `PROJECT_HARNESS.md` and `harness-contract.json` as canonical.
- If `bootstrap_status` is not `configured`, inspect first and continue the setup interview.
- Detect likely collaboration language from repo signals first; confirm it if unclear.
- Keep this file thin and preserve any user-authored content outside the harness-managed block.
