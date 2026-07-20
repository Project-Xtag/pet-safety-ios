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
head_ "5. Android C2 seam invariants"

if [ ! -f "$APPKT" ]; then
  warn "PetSafetyApp.kt not found — skipping C2 seam checks"
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

IOS_HOLD=$(grep -o 'holdDuration[^=]*= *[0-9.]*' "$IOS/PetSafety/PetSafety/Views/SplashScreenView.swift" 2>/dev/null | grep -o '[0-9.]*$')
[ -n "$IOS_HOLD" ] && check_contract "ios.splash.holdDuration" "$IOS_HOLD" "SplashScreenView.swift"

AND_HOLD=$(grep -o 'HOLD_DURATION_MS[^=]*= *[0-9_]*' "$AND/app/src/main/java/com/petsafety/app/ui/screens/SplashScreen.kt" 2>/dev/null | grep -o '[0-9_]*$' | tr -d '_')
[ -n "$AND_HOLD" ] && check_contract "android.splash.holdDurationMs" "$AND_HOLD" "SplashScreen.kt"

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
# FEATURE SOURCE. Touching feature source is SUFFICIENT, not exclusive: a commit that
# edits a source file AND the CODEMAP in one go is still a chunk and must still cite
# itself. Mixed commits are not forbidden — they just have to log themselves. A commit
# touching only docs/** or scripts/** is a log commit, not a chunk, and is ignored.
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
