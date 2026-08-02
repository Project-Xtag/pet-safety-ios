#!/usr/bin/env bash
# senra-status.sh — v3. Derives the board instead of restating it.
#
# Home: pet-safety-ios/scripts/senra-status.sh — tracked on the active redesign branch; merges to main with it.
# Every ✅/❌ below is computed live from the repos, the server, and the code.
# Nothing here is a claim you have to trust — it is a claim you can re-derive
# in 20 seconds.
#
# RULE (docs/PROTOCOL.md §1): if an item cannot be expressed as a check here,
# it is either
#   (a) a DECISION  -> the plan's Locked decisions / gaps register, or
#   (b) NOT READY   -> we don't yet know what would resolve it. Say so.
# Nothing else goes on a board. There are no other boards.

set -uo pipefail

IOS="${IOS:-$HOME/pet-safety-ios}"
AND="${AND:-$HOME/pet-safety-android}"
DL="${DL:-$HOME/senra-deeplink}"

PLAN="$IOS/docs/SENRA-MOBILE-REDESIGN.md"
BRANCH="${BRANCH:-feat/mobile-redesign-phase1}"
APPKT="$AND/app/src/main/java/com/petsafety/app/ui/PetSafetyApp.kt"
QRS="$AND/app/src/main/java/com/petsafety/app/ui/screens/QrScannerScreen.kt"

RED=0
pass()  { printf '  \033[32m✅\033[0m %s\n' "$1"; }
fail()  { printf '  \033[31m❌\033[0m %s\n' "$1"; RED=$((RED+1)); }
warn()  { printf '  \033[33m⚠️ \033[0m %s\n' "$1"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# ─────────────────────────────────────────────────────────────
head_ "1. App Links / deep links (server-side truth)"

AASA=$(curl -fsS https://senra.pet/.well-known/apple-app-site-association 2>/dev/null)
if [ -z "$AASA" ]; then
  fail "AASA unreachable at senra.pet"
else
  for p in '/t/*' '/qr/*' '/*/qr/*' '/*/t/*'; do
    if printf '%s' "$AASA" | jq -e --arg p "$p" '.applinks.details[0].paths | index($p)' >/dev/null 2>&1; then
      pass "AASA claims $p"
    else
      fail "AASA MISSING $p   (fix: add to the paths[] array, server-side — 1 line)"
    fi
  done
fi

WWW=$(curl -sI https://www.senra.pet/.well-known/apple-app-site-association 2>/dev/null | head -1)
case "$WWW" in
  *200*)    pass "www AASA serves 200" ;;
  *30[12]*) fail "www AASA is a REDIRECT ($WWW) — iOS does not follow it. applinks:www.senra.pet is dead." ;;
  *)        warn "www AASA: unexpected ($WWW)" ;;
esac

# ─────────────────────────────────────────────────────────────
head_ "2. iOS deep-link delivery (the PR #39 bug)"
# Checks the branch you are ON. The fix (56db26f) lives on fix/deeplink-root-handler
# until merged — EXPECTED RED on feat/mobile-redesign-phase1 until then.

APP="$IOS/PetSafety/PetSafety/App/PetSafetyApp.swift"
CV="$IOS/PetSafety/PetSafety/App/ContentView.swift"
N=$(grep -hc 'onOpenURL' "$APP" "$CV" 2>/dev/null | awk '{s+=$1} END{print s+0}')
ROOT=$(awk '/WindowGroup/,/^        }/' "$APP" 2>/dev/null | grep -c 'onOpenURL')

if [ "$N" -eq 1 ] && [ "$ROOT" -eq 1 ]; then
  pass "exactly one .onOpenURL, at the WindowGroup root — cold-launch links land"
else
  fail "found $N .onOpenURL handler(s); expected 1 at the WindowGroup root. Cold-launch tag links dropped during the splash. (Expected until fix/deeplink-root-handler merges.)"
fi

if grep -q 'ZStack' "$APP" 2>/dev/null; then
  pass "WindowGroup root is a ZStack (a Group compiles fine and silently kills the crossfade)"
else
  warn "no ZStack at the WindowGroup root — if the hoist has landed, check it wasn't rewritten to a Group"
fi

# ─────────────────────────────────────────────────────────────
head_ "3. Owner-scans-own-tag (G-owner) — the best standalone fix on the board"

DLS="$IOS/PetSafety/PetSafety/Services/DeepLinkService.swift"
if [ ! -f "$DLS" ]; then
  warn "DeepLinkService.swift not found — cannot check G-owner"
elif ! grep -q 'isOwner' "$DLS"; then
  fail "lookup.isOwner not present at all in DeepLinkService — regressed or moved"
else
  BRANCHED=$(grep -n 'isOwner' "$DLS" | grep -vc 'print\|debugPrint\|log')
  if [ "$BRANCHED" -gt 0 ]; then
    pass "lookup.isOwner is branched on"
  else
    fail "lookup.isOwner is parsed but only LOGGED — owners scanning their own tag get the public finder page + a false 'your pet was scanned' alert"
  fi
fi

# ─────────────────────────────────────────────────────────────
head_ "4. Auth gate not bypassed in production (iOS)"

BAD=$(grep -rn 'AuthViewModel(' "$IOS/PetSafety/PetSafety" --include='*.swift' 2>/dev/null \
      | grep -v '/PetSafetyTests/' | grep -v 'AuthViewModel()' | wc -l | tr -d ' ')
if [ "$BAD" -eq 0 ]; then
  pass "no production AuthViewModel(...) with injected seams — the four defaulted seams are test-only"
else
  fail "$BAD production call site(s) inject AuthViewModel seams — the auth gate can be bypassed"
fi

# ─────────────────────────────────────────────────────────────
head_ "5. Android seam invariants"

if [ ! -f "$APPKT" ]; then
  warn "PetSafetyApp.kt not found — skipping seam checks"
else
  # G11: savedQrCode must be cleared in exactly ONE place (onQrCodeHandled).
  # A second clear site strands the logged-out pending scan that C4 is going to
  # consume. A unit test cannot guard this — you cannot test the absence of code.
  CLR=$(grep -c 'savedQrCode = null' "$APPKT")
  if [ "$CLR" -eq 1 ]; then
    pass "savedQrCode cleared in exactly 1 place (G11 stays recoverable for C4)"
  else
    fail "savedQrCode cleared in $CLR place(s), expected 1 — the logged-out pending scan C4 needs is being dropped"
  fi

  # The seam must be the SOLE authority. Old flags gone from live code.
  OLD=$(grep -E 'showOrderTagsScreen|showRegisterScreen|val screenKey' "$APPKT" | grep -vc '^\s*//')
  if [ "$OLD" -eq 0 ]; then
    pass "no live references to the retired routing flags (comments excluded)"
  else
    fail "$OLD live reference(s) to showOrderTagsScreen/showRegisterScreen/screenKey — the seam is not the sole authority"
  fi

  # Rule 1 corollary: grep the CALLEE, not the retired name. AuthScreen must be
  # reachable from exactly one place — the seam.
  CALLS=$(grep -rn 'AuthScreen(' "$AND/app/src/main" --include='*.kt' 2>/dev/null | grep -vc 'fun AuthScreen(')
  if [ "$CALLS" -eq 1 ]; then
    pass "AuthScreen has exactly 1 call site (the seam)"
  else
    fail "AuthScreen has $CALLS call site(s), expected 1 — something outside the seam can route to login"
  fi

  # Two exits. A back closure with no UI affordance is the C1 dead-end, twice shipped.
  for f in AuthScreen RegisterScreen; do
    SRC="$AND/app/src/main/java/com/petsafety/app/ui/$f.kt"
    if grep -q 'onBack' "$SRC" 2>/dev/null && grep -q 'R.string.back' "$SRC" 2>/dev/null; then
      pass "$f has an onBack AND a real back affordance"
    else
      fail "$f is missing onBack or its chevron — the landing becomes a one-way door (the C1 dead-end)"
    fi
  done

  # ── C4b (G11 seeded-scan close): behaviour guards no test can give (PROTOCOL §6) ──
  # LandingScreen's pendingQrCode/onQrCodeHandled are DEFAULTED (so C2's two-arg
  # routing test still compiles). A chunk whose LANDING arm never passes them
  # compiles, runs, passes every test (RootRoutingComposeTest RELIES on the
  # defaults), and the checks above stay green (they count the clear literal, 1
  # either way). The wiring would be INERT with nothing to notice until a device
  # gate. So grep the behaviour, not the file (G12b corollary).
  SEED=$(grep -c 'pendingQrCode = savedQrCode' "$APPKT")
  if [ "$SEED" -eq 2 ]; then
    pass "pendingQrCode = savedQrCode wired at 2 sites (MAIN + LANDING) — C4b seeded scan LIVE"
  else
    fail "pendingQrCode = savedQrCode at $SEED site(s), expected 2 (MAIN + LANDING) — C4b INERT: the logged-out seeded scan is unwired and no test catches it. (RED until C4b is built — expected.)"
  fi

  if [ -f "$QRS" ]; then
    # One-line grep of the whole guarded expression: proves the guard AND what it
    # guards, not merely that 'pendingQrCode == null' exists somewhere (Rule 1).
    GUARD=$(grep -c 'if (pendingQrCode == null) permissionLauncher.launch' "$QRS")
    if [ "$GUARD" -eq 1 ]; then
      pass "seeded-path permission guard present and guarding the launch — C4b carve-out #2"
    else
      fail "one-line guard 'if (pendingQrCode == null) permissionLauncher.launch' count=$GUARD, expected 1 — carve-out #2 gone; the gratuitous camera prompt returns on the seeded path. (RED until C4b is built — expected.)"
    fi
  else
    warn "QrScannerScreen.kt not found — cannot check C4b carve-out #2"
  fi
fi

# ─────────────────────────────────────────────────────────────
head_ "5b. Landing device-bought behaviours (C3/C4/C4b) — guards on the files C5/C6 + Phase 2 edit"
# Every green-expected literal below is PINNED in spec §E C5/C6 (Board guards
# block): a rename false-reds BY DESIGN so check and contract cannot disagree.
# Landed 2026-07-21, BEFORE C5 — these files are exactly what C5/C6 and the
# Phase-2 destination chunks edit next.

LSK="$AND/app/src/main/java/com/petsafety/app/ui/screens/LandingScreen.kt"
LVW="$IOS/PetSafety/PetSafety/Views/Landing/LandingView.swift"
CVW="$IOS/PetSafety/PetSafety/App/ContentView.swift"

lguard() {
  # $1 file, $2 fixed-string pattern, $3 expected count, $4 label
  # Missing subject = FAIL, not warn: a §5b guard whose subject is absent is a
  # failure, not a skip — otherwise a file move/rename/typo silently evaporates
  # every guard at once, likeliest during exactly the work they exist for.
  if [ ! -f "$1" ]; then fail "$4 — SUBJECT FILE MISSING ($1); absence is a defect in §5b, not a skip"; return; fi
  N=$(grep -cF "$2" "$1")
  if [ "$N" -eq "$3" ]; then
    pass "$4"
  else
    fail "$4 — count=$N, expected $3 (device-bought behaviour dropped or renamed; names pinned in spec §E C5/C6)"
  fi
}

lguard "$LSK" 'BackHandler { showScanner = false }'                          1 "AND: scanner BackHandler (C4 FIX 2)"
lguard "$LSK" 'BackHandler { showFoundStray = false }'                       1 "AND: found-stray BackHandler (C4 FIX 2)"
lguard "$LSK" 'onTagNotUsable = { message -> reportPrompt = message }'       1 "AND: onTagNotUsable -> report card (C4 FIX 3)"
lguard "$LSK" 'onNavigateToActivation = { reportPrompt = notLinkedMessage }' 1 "AND: onNavigateToActivation -> report card (C4 FIX 3)"
lguard "$LSK" 'onClose = { showScanner = false }'                            1 "AND: close-overlay binding at the presentation site"
lguard "$LSK" 'onClick = onClose'                                            1 "AND: close-overlay render end consumes onClose"
lguard "$LSK" 'onDismissRequest = { reportPrompt = null }'                   1 "AND: report-card scrim dismiss"
lguard "$LSK" 'TextButton(onClick = { reportPrompt = null })'                1 "AND: report-card Try Again dismiss"
lguard "$LVW" 'Button { showScanner = false }'                               1 "iOS: scanner close overlay (C3 §9.14)"
lguard "$LVW" 'if wants { showScanner = false }'                             1 "iOS: deep-link yield expression (§9.15)"

# iOS three-flag coverage: the yield's source property must OR ALL THREE deep-link
# flags (LandingView:66-70). Pinned PER OR-MEMBER by line shape — the '|| deepLinkService.'
# prefix can only match inside an OR chain, so each check reds if its member leaves
# the OR even while the flag is still read elsewhere in the file. (A file-wide
# aggregate count false-greens in exactly that case — review condition (c).)
lguard "$LVW" 'deepLinkService.showScannedPetProfile'  1 "iOS: yield OR member 1 — showScannedPetProfile (§9.15)"
lguard "$LVW" '|| deepLinkService.showTagActivation'   1 "iOS: yield OR member 2 — showTagActivation (§9.15)"
lguard "$LVW" '|| deepLinkService.showPromoClaimFlow'  1 "iOS: yield OR member 3 — showPromoClaimFlow (§9.15)"

# ── Zone-3 ship-gate (plan §2: Zone 3 ships in v1) — RED UNTIL WIRED, by design ──
# Whitespace-tolerant regex: an expected-0 check false-GREENS on a rename (the
# unsafe direction). OBLIGATION: when phase-2-spec.md names the destination
# handlers, RE-POINT both to positive handler greps (expect 1, red-until-wired)
# — the obligation is recorded in spec §E C5/C6's Board-guards block.
if [ -f "$APPKT" ]; then
  DEADCTA=$(grep -Ec 'onNavigate *= *\{[[:space:]]*\}' "$APPKT")
  if [ "$DEADCTA" -eq 0 ]; then
    pass "AND: Zone-3 onNavigate is bound to a real handler"
  else
    fail "AND: Zone-3 onNavigate is a swallowed empty lambda — both community cards are LIVE DEAD CTAs. (RED until Phase 2 wires 2.3/2.4 — the plan §2 v1 ship-gate.)"
  fi
else
  fail "AND: Zone-3 ship-gate SUBJECT MISSING ($APPKT) — the gate must not evaporate silently; 6 expected reds reading as 4 would look like progress"
fi
if [ -f "$CVW" ]; then
  INERT=$(grep -Ec 'Zone-3 intent emitted|handler lands in Phase 2' "$CVW")
  if [ "$INERT" -eq 0 ]; then
    pass "iOS: Zone-3 onNavigate handler is live (inert marker gone)"
  else
    fail "iOS: Zone-3 onNavigate is the log-only inert closure — both community cards are LIVE DEAD CTAs. (RED until Phase 2 wires 2.3/2.4 — the plan §2 v1 ship-gate.)"
  fi
else
  fail "iOS: Zone-3 ship-gate SUBJECT MISSING ($CVW) — the gate must not evaporate silently; 6 expected reds reading as 4 would look like progress"
fi

# ── C2 routing seam — derivation guard (RULED 2026-07-26; PROTOCOL §6 owns the boundary) ──
# Growth is additive (new AuthOverlay member + when arm + assigning binding =
# the seam doing its job); derivation is untouchable. These pins make a rewrite
# disguised as growth read RED here, not in review: the resolver has exactly one
# app-wide definition and every PRE-EXISTING arm is still present. A Phase-2
# chunk ADDING arms leaves all of these green. (lguard's fail text cites spec
# §E C5/C6 generically; for THESE pins the owner is PROTOCOL §6's C2-seam entry.)
RRKT="$AND/app/src/main/java/com/petsafety/app/ui/RootRoute.kt"
if [ -d "$AND/app/src/main" ]; then
  RESOLVER_DEFS=$(grep -rF 'fun resolveRootRoute' "$AND/app/src/main" | wc -l | tr -d ' ')
  if [ "$RESOLVER_DEFS" -eq 1 ]; then
    pass "AND: resolveRootRoute defined app-wide exactly once (C2 seam — derivation untouchable)"
  else
    fail "AND: resolveRootRoute definition count=$RESOLVER_DEFS, expected 1 app-wide — a second definition or a removal is a derivation change (PROTOCOL §6)"
  fi
else
  fail "AND: C2-seam derivation guard SUBJECT MISSING ($AND/app/src/main) — the guard must not evaporate silently"
fi
lguard "$APPKT" 'RootRoute.MAIN -> MainTabScaffold'          1 "AND: root when arm MAIN present (C2 seam)"
lguard "$APPKT" 'RootRoute.ORDER_TAGS -> OrderMoreTagsScreen' 1 "AND: root when arm ORDER_TAGS present (C2 seam)"
lguard "$APPKT" 'RootRoute.REGISTER -> RegisterScreen'        1 "AND: root when arm REGISTER present (C2 seam)"
lguard "$APPKT" 'RootRoute.LOGIN -> AuthScreen'               1 "AND: root when arm LOGIN present (C2 seam)"
lguard "$APPKT" 'RootRoute.LANDING -> LandingScreen'          1 "AND: root when arm LANDING present (C2 seam)"

# ── F-G6 — dormant-screen quarantine, keyed on SYMBOLS, not on the filename ──
# PROTOCOL §6 forbids wiring AlertsScreens.kt. A guard that names the FILE guards
# NOTHING: G12b forbade wiring ScannedPetView, nobody wired it, and logged-out
# delivery shipped on iOS anyway through a live component one branch over. So pin the
# symbols instead.
#
# Two things are guarded, because 2.3b-Android is the live hazard:
#   1. The two non-private composables must have ZERO references outside their own
#      file. They are the whole public surface of the quarantined screen.
#   2. ReportSightingDialog must stay `private`. 2.3b LIFTS from it; the moment it
#      loses `private` it is one import away from being CALLED, which is the lift
#      quietly becoming a call — the exact G12b shape, one file over.
#
# This lands BEFORE the 2.3b chunk on purpose, so wiring reads RED here rather than
# in review. Measured 0/0/private at android 931b51b, so it lands GREEN — the plan's
# "AlertsScreens.kt has 1 external caller" is stale (control: MainTabScaffold, 4 files).
#
# SCOPE IS SPLIT, AND THE SPLIT IS THE POINT — the two mechanisms have different
# false-positive exposure, so they get different frames.
#
#   * The two composables are scanned across ALL of app/src, TEST SOURCES INCLUDED.
#     Measured at android 931b51b: MissingAlertsScreen and FoundAlertsScreen have
#     test+androidTest = 0, so widening costs nothing today and closes the real
#     resurrection path — a Compose test that RENDERS either screen re-animates a
#     dormant surface, and under a main-only scan that reads green.
#
#   * ReportSightingDialog is NOT in the zero-callers check at all. It is guarded by
#     the `private` pin below, a different mechanism, and that is where the only
#     false-red risk lives: app/src/test/java/com/petsafety/app/ui/screens/
#     ReportSightingValidationTest.kt names it and does readSource("AlertsScreens.kt"),
#     reading the file as TEXT to assert the validators are wired. That is a
#     source-reading test, not a call. Counting it as an external caller would be a
#     permanent false RED — so it is not counted, because `private` already makes the
#     call impossible.
#
# Earlier revision scanned main only for all three and justified it with the dialog's
# test reference. That generalised one symbol's exposure across two that do not share
# it, and left the composables' resurrection path green. Corrected in review.
ALERTSKT="$AND/app/src/main/java/com/petsafety/app/ui/screens/AlertsScreens.kt"
if [ -f "$ALERTSKT" ] && [ -d "$AND/app/src" ]; then
  for sym in MissingAlertsScreen FoundAlertsScreen; do
    EXT=$(grep -rF "$sym" "$AND/app/src" --include='*.kt' 2>/dev/null | grep -vc 'AlertsScreens\.kt')
    if [ "$EXT" -eq 0 ]; then
      pass "AND: $sym has 0 external callers across app/src incl. tests (F-G6 quarantine)"
    else
      fail "AND: $sym has $EXT external reference(s) in app/src — AlertsScreens.kt is dormant under PROTOCOL §6; wiring it, or rendering it from a test, is a boundary breach, not a chunk"
    fi
  done
  if grep -qE '^[[:space:]]*private fun ReportSightingDialog' "$ALERTSKT"; then
    pass "AND: ReportSightingDialog still private (F-G6 — 2.3b lifts from it, must never call it)"
  else
    fail "AND: ReportSightingDialog is no longer private — 2.3b can now CALL it instead of lifting from it (PROTOCOL §6, the G12b shape)"
  fi
else
  fail "AND: F-G6 quarantine SUBJECT MISSING ($ALERTSKT) — the guard must not evaporate silently"
fi

# ─────────────────────────────────────────────────────────────
head_ "6. Declared contracts vs. the code (drift detector)"
# v1 grepped PROSE that appeared ZERO times and false-fired against CORRECT code.
# A check that cries wolf trains you to skim past red. Contracts are DECLARED in
# the plan as `<!-- CONTRACT: <key> = <value> -->` and compared to source.

check_contract() {
  local key="$1" actual="$2" src="$3" declared
  declared=$(grep -o "CONTRACT: *${key} *= *[^ ]*" "$PLAN" 2>/dev/null | sed 's/.*= *//')
  if [ -z "$declared" ]; then
    fail "no contract declared for '$key' — add to the plan §10: <!-- CONTRACT: $key = $actual -->"
  elif [ "$declared" = "$actual" ]; then
    pass "$key = $actual (code and plan agree)"
  else
    fail "DRIFT — code says $key=$actual ($src); the plan declares $declared. One of them is lying."
  fi
}

# A `[ -n "$X" ] && check_contract …` silently SKIPS when the grep finds nothing —
# a renamed file or a renamed constant evaporates the drift check instead of failing
# it, which is the §5b/lguard failure mode (:192) and the ship-gate one (:234) in a
# third place. Absence is a defect here too, so say so out loud.
# Exactly-one-match is part of the contract. Two matches concatenate into a
# multi-line $X, which check_contract then compares against the single declared
# value and reports as DRIFT — a confusing failure that points at the plan when the
# defect is the pattern. Count with `grep -o | wc -l`, never `grep -c`, which counts
# LINES not occurrences (that miscount has already burned a bundle grep here).
IOS_SPLASH="$IOS/PetSafety/PetSafety/Views/SplashScreenView.swift"
IOS_PAT='holdDuration[^=]*= *[0-9.]*'
IOS_HITS=$(grep -o "$IOS_PAT" "$IOS_SPLASH" 2>/dev/null | wc -l | tr -d ' ')
if [ "$IOS_HITS" -eq 1 ]; then
  check_contract "ios.splash.holdDuration" "$(grep -o "$IOS_PAT" "$IOS_SPLASH" | grep -o '[0-9.]*$')" "SplashScreenView.swift"
elif [ "$IOS_HITS" -eq 0 ]; then
  fail "ios.splash.holdDuration SUBJECT MISSING ($IOS_SPLASH, or the constant was renamed) — the drift check must not evaporate silently"
else
  fail "ios.splash.holdDuration AMBIGUOUS — $IOS_HITS matches in $IOS_SPLASH, need exactly 1. Narrow the pattern or pin the constant; do not let it read as DRIFT."
fi

AND_SPLASH="$AND/app/src/main/java/com/petsafety/app/ui/screens/SplashScreen.kt"
AND_PAT='HOLD_DURATION_MS[^=]*= *[0-9_]*'
AND_HITS=$(grep -o "$AND_PAT" "$AND_SPLASH" 2>/dev/null | wc -l | tr -d ' ')
if [ "$AND_HITS" -eq 1 ]; then
  check_contract "android.splash.holdDurationMs" "$(grep -o "$AND_PAT" "$AND_SPLASH" | grep -o '[0-9_]*$' | tr -d '_')" "SplashScreen.kt"
elif [ "$AND_HITS" -eq 0 ]; then
  fail "android.splash.holdDurationMs SUBJECT MISSING ($AND_SPLASH, or the constant was renamed) — the drift check must not evaporate silently"
else
  fail "android.splash.holdDurationMs AMBIGUOUS — $AND_HITS matches in $AND_SPLASH, need exactly 1. Narrow the pattern or pin the constant; do not let it read as DRIFT."
fi

# ─────────────────────────────────────────────────────────────
head_ "7. Is the log behind the code?  (this is what 'no missed logs' means)"
# C1 sat unlogged for two days. Under this check it could not have.
#
# Keys on CHUNK COMMITS, not on the branch tip.
#
# Why not the tip: §9 requires the plan be TRACKED on the build branch. Once it is,
# logging the tip needs a commit on that branch — which MOVES the tip — so the new
# tip is, by construction, absent from the file it just committed. The tip-keyed
# version could therefore only go green on an UNCOMMITTED plan edit (it greps $PLAN
# from the working tree, and §8 counts only '??', never a modified tracked file).
# It passed most reliably when the log was not committed at all — the exact thing it
# exists to prevent. Verified by experiment 2026-07-17, not by reading.
#
# A CHUNK is any non-merge commit on $BRANCH, not yet on origin/main, that TOUCHES
# FEATURE SOURCE.
#
# FEATURE SOURCE IS A POSITIVE ALLOWLIST — it is NOT "anything that is not docs".
# The code below is the definition: iOS = paths matching ^PetSafety/ , Android =
# paths matching ^app/src/ (the $SRC regex). A commit is a chunk only if at least one
# of its paths matches that prefix. EVERYTHING else is a log commit and is ignored —
# docs/**, scripts/**, and also .gitignore, CI workflows, Gradle files, *.pbxproj,
# README, and anything at the repo root.
#
# Read as a denylist ("not docs/ and not scripts/") it OVER-COUNTS and reports a false
# RED: a .gitignore-only commit gets classified as an unlogged chunk. That misreading
# cost a review pass on 2026-08-02 — fd7b567 (.gitignore + docs/ + scripts/ only) was
# reported as an unlogged 10th iOS chunk when the board correctly counted 9.
#
# Touching feature source is SUFFICIENT, not exclusive: a commit that edits a source
# file AND the CODEMAP in one go is still a chunk and must still cite itself. Mixed
# commits are not forbidden — they just have to log themselves.
# Merge commits are ignored: they carry no chunk of their own.
#
# EXPECTED: a transient RED between the chunk commit and its log commit. That is not a
# defect — there genuinely IS an unlogged chunk on the branch at that moment, and this
# check's one job is to force the pause. The loop is:
#     chunk commit -> RED -> log commit -> GREEN -> next chunk
# It now forces that honestly, instead of going green on a dirty working tree.
#
# Failures name the SHA and its subject, so the fix is "log this one", never
# "something's unlogged somewhere".

for repo in "$IOS" "$AND"; do
  [ -d "$repo/.git" ] || continue
  name=$(basename "$repo")
  git -C "$repo" rev-parse --verify "$BRANCH" >/dev/null 2>&1 || continue
  if ! git -C "$repo" rev-parse --verify origin/main >/dev/null 2>&1; then
    warn "$name: no origin/main to compare against — fetch, then re-run §7"
    continue
  fi

  # Feature source per platform. Keyed on the variable, not on the directory name,
  # so a relocated checkout (IOS=/elsewhere) still classifies correctly.
  if [ "$repo" = "$IOS" ]; then SRC='^PetSafety/'; else SRC='^app/src/'; fi

  MISSING=0
  CHUNKS=0
  # No pipe into this loop: fail() increments RED in the current shell.
  for c in $(git -C "$repo" rev-list --no-merges origin/main.."$BRANCH"); do
    git -C "$repo" show --name-only --format='' "$c" | grep -qE "$SRC" || continue
    CHUNKS=$((CHUNKS+1))
    SHORT=$(git -C "$repo" rev-parse --short "$c")
    if ! grep -q "$SHORT" "$PLAN" 2>/dev/null; then
      fail "$name chunk $SHORT has NO CODEMAP entry — log it before the next chunk: $(git -C "$repo" log -1 --format='%s' "$c")"
      MISSING=$((MISSING+1))
    fi
  done

  if [ "$CHUNKS" -eq 0 ]; then
    pass "$name: no unmerged chunk commits on $BRANCH — nothing to log"
  elif [ "$MISSING" -eq 0 ]; then
    pass "$name: all $CHUNKS chunk commit(s) on $BRANCH are logged in the CODEMAP"
  fi
done

# ─────────────────────────────────────────────────────────────
head_ "8. Landmines — untracked files a 'git add -A' would sweep onto a code branch"

for repo in "$IOS" "$AND"; do
  [ -d "$repo/.git" ] || continue
  name=$(basename "$repo")
  JUNK=$(git -C "$repo" status --porcelain 2>/dev/null | grep '^??' \
         | grep -Ei '\.(diff|patch|md)$|build-derived|^\?\? docs/' | wc -l | tr -d ' ')
  if [ "$JUNK" -eq 0 ]; then
    pass "$name: no untracked docs/diffs in the working tree"
  else
    fail "$name: $JUNK untracked doc/diff file(s) — 'git add -A' would commit them onto the code branch"
  fi
done

# ─────────────────────────────────────────────────────────────
head_ "9. Doc home — the governing docs must be readable from the branch you build on"

for f in docs/SENRA-MOBILE-REDESIGN.md docs/phase-1-spec.md docs/PROTOCOL.md docs/HANDOVER.md scripts/senra-status.sh; do
  if git -C "$IOS" ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    pass "tracked: $f"
  else
    fail "NOT TRACKED on this branch: $f — someone will 'git show' an untracked copy into the tree again"
  fi
done

# ─────────────────────────────────────────────────────────────
head_ "10. Merge hazard — the deep-link fix vs. the redesign branch"

if git -C "$IOS" rev-parse --verify origin/fix/deeplink-root-handler >/dev/null 2>&1; then
  if git -C "$IOS" merge-tree --write-tree --name-only "$BRANCH" origin/fix/deeplink-root-handler >/dev/null 2>&1; then
    warn "the deep-link fix merges CLEANLY into $BRANCH — so NO ONE IS FORCED TO LOOK. The merged WindowGroup+ContentView pairing has never run on a device. QA case: cold launch while LOGGED IN (route flips .landing->.main inside the 0.4s crossfade)."
  else
    warn "the deep-link fix CONFLICTS with $BRANCH. Resolve by hand, then DEVICE-VERIFY the crossfade — a clean build proves nothing here."
  fi
else
  warn "origin/fix/deeplink-root-handler not found — fetch, or it has already merged"
fi

# ─────────────────────────────────────────────────────────────
head_ "11. Branch tips (never trust a summary)"

for repo in "$IOS" "$AND" "$DL"; do
  [ -d "$repo/.git" ] || continue
  printf '  %-20s %s  %s\n' "$(basename "$repo")" \
    "$(git -C "$repo" rev-parse --short HEAD)" \
    "$(git -C "$repo" rev-parse --abbrev-ref HEAD)"
done

# ─────────────────────────────────────────────────────────────
head_ "12. Tests (cache-proof — --rerun-tasks, never 'up-to-date')"

if [ -d "$AND" ]; then
  if (cd "$AND" && ./gradlew testDebugUnitTest --rerun-tasks -q >/dev/null 2>&1); then
    pass "Android unit suite green (forced re-run)"
  else
    fail "Android unit suite RED — see app/build/reports/tests/testDebugUnitTest/index.html"
  fi
fi

# ─────────────────────────────────────────────────────────────
head_ "13. NOT MECHANISABLE — yours, and they stay until you say otherwise"

warn "Deep-link cold start: real device, real tag, cold-kill. Before AND after. The simulator cannot do it."
warn "The MERGED WindowGroup (deep-link fix + C1) — device look. Cold launch while LOGGED IN. See §10."
warn "RELEASE build: the whole suite is testDebugUnitTest. C1/C2 have never run under R8. Release is what ships."
warn "Android crossfade handoff on a LOW-END device (C0's true gate moved first composition into the 400ms fade)"
warn "Dark-mode mark strokes (the mark is not recolored for dark on either platform)"
warn "Android system-splash icon suppression on Samsung / Xiaomi"

# ─────────────────────────────────────────────────────────────
echo
if [ "$RED" -eq 0 ]; then
  printf '\033[32m%s\033[0m\n' "BOARD GREEN — 0 failing checks. The ⚠️ items above are still yours."
else
  printf '\033[31m%s\033[0m\n' "BOARD RED — $RED failing check(s). Fix or explain each before the next chunk."
fi
echo
exit 0
