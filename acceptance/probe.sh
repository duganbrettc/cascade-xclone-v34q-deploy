#!/usr/bin/env bash
set -euo pipefail

HOST_PORT="${HOST_PORT:-8080}"
BASE_URL="${BASE_URL:-http://localhost:${HOST_PORT}}"

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; exit 1; }

# Step 1: Signup alice → 201 + session_token
echo "=== Step 1: Signup alice ==="
ALICE_RESP=$(curl -sf -X POST "${BASE_URL}/api/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"pass"}' \
  -w "\n%{http_code}" 2>/dev/null)
ALICE_CODE=$(echo "$ALICE_RESP" | tail -1)
ALICE_BODY=$(echo "$ALICE_RESP" | head -n -1)
[ "$ALICE_CODE" = "201" ] || fail "Step 1: expected 201, got $ALICE_CODE"
ALICE_TOKEN=$(echo "$ALICE_BODY" | grep -o '"session_token":"[^"]*"' | cut -d'"' -f4)
[ -n "$ALICE_TOKEN" ] || fail "Step 1: no session_token in response"
pass "Step 1: alice signed up, token=${ALICE_TOKEN:0:8}..."

# Step 2: GET / returns HTML with alice's username or nav
echo "=== Step 2: GET / ==="
HOME_HTML=$(curl -sf "${BASE_URL}/" -H "Authorization: Bearer $ALICE_TOKEN" 2>/dev/null)
echo "$HOME_HTML" | grep -qi 'alice\|nav\|<html' || fail "Step 2: / did not return expected HTML"
pass "Step 2: GET / returned HTML"

# Step 3: GET /post returns HTML with textarea[name=body] and submit
echo "=== Step 3: GET /post ==="
POST_HTML=$(curl -sf "${BASE_URL}/post" -H "Authorization: Bearer $ALICE_TOKEN" 2>/dev/null)
echo "$POST_HTML" | grep -qi 'textarea\|name.*body\|submit' || fail "Step 3: /post did not contain textarea/submit"
pass "Step 3: GET /post returned HTML with form"

# Step 4: POST /api/posts {body:'alice-said-hello'} → 201
echo "=== Step 4: alice posts ==="
APOST_CODE=$(curl -sf -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/posts" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d '{"body":"alice-said-hello"}' 2>/dev/null)
[ "$APOST_CODE" = "201" ] || fail "Step 4: expected 201, got $APOST_CODE"
pass "Step 4: alice posted"

# Step 5: Signup bob → 201; bob posts 'bob-said-hello' → 201
echo "=== Step 5: Signup bob and post ==="
BOB_RESP=$(curl -sf -X POST "${BASE_URL}/api/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{"username":"bob","password":"pass"}' \
  -w "\n%{http_code}" 2>/dev/null)
BOB_CODE=$(echo "$BOB_RESP" | tail -1)
BOB_BODY=$(echo "$BOB_RESP" | head -n -1)
[ "$BOB_CODE" = "201" ] || fail "Step 5: signup bob expected 201, got $BOB_CODE"
BOB_TOKEN=$(echo "$BOB_BODY" | grep -o '"session_token":"[^"]*"' | cut -d'"' -f4)
[ -n "$BOB_TOKEN" ] || fail "Step 5: no session_token for bob"
BPOST_CODE=$(curl -sf -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/posts" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -d '{"body":"bob-said-hello"}' 2>/dev/null)
[ "$BPOST_CODE" = "201" ] || fail "Step 5: bob post expected 201, got $BPOST_CODE"
pass "Step 5: bob signed up and posted"

# Step 6: GET /users returns HTML listing bob
echo "=== Step 6: GET /users ==="
USERS_HTML=$(curl -sf "${BASE_URL}/users" -H "Authorization: Bearer $ALICE_TOKEN" 2>/dev/null)
echo "$USERS_HTML" | grep -qi 'bob' || fail "Step 6: /users did not list bob"
pass "Step 6: GET /users lists bob"

# Step 7: POST /api/follow/bob with alice's token → 201
echo "=== Step 7: alice follows bob ==="
FOLLOW_CODE=$(curl -sf -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/api/follow/bob" \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  2>/dev/null)
[ "$FOLLOW_CODE" = "201" ] || fail "Step 7: expected 201, got $FOLLOW_CODE"
pass "Step 7: alice follows bob"

# Step 8: GET /api/timeline with alice's token → contains 'bob-said-hello'
echo "=== Step 8: alice's timeline contains bob's post ==="
TIMELINE=$(curl -sf "${BASE_URL}/api/timeline" \
  -H "Authorization: Bearer $ALICE_TOKEN" 2>/dev/null)
echo "$TIMELINE" | grep -q 'bob-said-hello' || fail "Step 8: timeline does not contain 'bob-said-hello'"
pass "Step 8: timeline contains bob-said-hello"

# Step 9: GET /users/bob returns HTML with bob's profile + posts
echo "=== Step 9: GET /users/bob ==="
BOB_PROFILE=$(curl -sf "${BASE_URL}/users/bob" -H "Authorization: Bearer $ALICE_TOKEN" 2>/dev/null)
echo "$BOB_PROFILE" | grep -qi 'bob' || fail "Step 9: /users/bob did not return bob's profile"
pass "Step 9: GET /users/bob returned profile HTML"

# Step 10: GET /profile returns HTML with editable display_name and password fields
echo "=== Step 10: GET /profile ==="
PROFILE_HTML=$(curl -sf "${BASE_URL}/profile" -H "Authorization: Bearer $ALICE_TOKEN" 2>/dev/null)
echo "$PROFILE_HTML" | grep -qi 'display_name\|displayname\|password' || fail "Step 10: /profile missing display_name/password fields"
pass "Step 10: GET /profile has editable fields"

# Step 11: PATCH /api/users/me {display_name:'Alice Updated',bio:'Hello world'} → 200
echo "=== Step 11: PATCH /api/users/me ==="
PATCH_CODE=$(curl -sf -o /dev/null -w "%{http_code}" -X PATCH "${BASE_URL}/api/users/me" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d '{"display_name":"Alice Updated","bio":"Hello world"}' 2>/dev/null)
[ "$PATCH_CODE" = "200" ] || fail "Step 11: expected 200, got $PATCH_CODE"
pass "Step 11: PATCH /api/users/me succeeded"

# Step 12: GET /api/users/me → display_name='Alice Updated', bio='Hello world'
echo "=== Step 12: GET /api/users/me shows updated profile ==="
ME_RESP=$(curl -sf "${BASE_URL}/api/users/me" \
  -H "Authorization: Bearer $ALICE_TOKEN" 2>/dev/null)
echo "$ME_RESP" | grep -q 'Alice Updated' || fail "Step 12: display_name not updated"
echo "$ME_RESP" | grep -q 'Hello world' || fail "Step 12: bio not updated"
pass "Step 12: /api/users/me shows Alice Updated + Hello world"

# Step 13: DELETE /api/follow/bob with alice's token → 204
echo "=== Step 13: alice unfollows bob ==="
UNFOLLOW_CODE=$(curl -sf -o /dev/null -w "%{http_code}" -X DELETE "${BASE_URL}/api/follow/bob" \
  -H "Authorization: Bearer $ALICE_TOKEN" 2>/dev/null)
[ "$UNFOLLOW_CODE" = "204" ] || fail "Step 13: expected 204, got $UNFOLLOW_CODE"
pass "Step 13: alice unfollowed bob"

# Step 14: GET /api/timeline with alice's token → does NOT contain 'bob-said-hello'
echo "=== Step 14: timeline no longer shows bob's post ==="
TIMELINE2=$(curl -sf "${BASE_URL}/api/timeline" \
  -H "Authorization: Bearer $ALICE_TOKEN" 2>/dev/null)
echo "$TIMELINE2" | grep -q 'bob-said-hello' && fail "Step 14: timeline still contains 'bob-said-hello' after unfollow" || true
pass "Step 14: bob-said-hello no longer in timeline"

echo ""
echo "=== All 14 steps PASSED ==="
