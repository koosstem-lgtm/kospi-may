#!/usr/bin/env bash
# KOSPI Calendar — 자동 배포 스크립트
# 사용법: ./deploy.sh [커밋메시지]
#   - 인자 없으면: "Update YYYY-MM-DD HH:MM" 자동 생성
#   - gh CLI 인증 필요. 최초 1회: gh auth login

set -euo pipefail

cd "$(dirname "$0")"

REPO_URL="https://github.com/koosstem-lgtm/kospi-may.git"
DEFAULT_BRANCH="main"
COMMIT_MSG="${1:-Update $(date +'%Y-%m-%d %H:%M')}"

echo "▶ KOSPI Calendar 배포 시작"
echo "  repo: $REPO_URL"
echo "  msg : $COMMIT_MSG"
echo ""

# 1. git 초기화 (최초 1회)
if [[ ! -d .git ]]; then
  echo "[1/5] git 저장소 초기화"
  git init -q
  git branch -M "$DEFAULT_BRANCH"
  git remote add origin "$REPO_URL"
  # macOS Keychain 사용 (한 번 PAT 입력하면 그 다음부터 자동)
  git config --local credential.helper osxkeychain
else
  echo "[1/5] git 저장소 이미 존재 — 건너뜀"
  git remote set-url origin "$REPO_URL" 2>/dev/null || git remote add origin "$REPO_URL"
  git config --local credential.helper osxkeychain
fi

# 2. 변경사항 확인 + 커밋
echo "[2/5] 변경사항 스테이징"
git add -A
if git diff --cached --quiet; then
  echo "  → 새 변경사항 없음 (이미 커밋된 상태)"
else
  echo "[3/5] 커밋 생성"
  git -c user.email="osstemswai@gmail.com" -c user.name="koosstem-lgtm" commit -q -m "$COMMIT_MSG"
fi

# 푸시 필요한지 검사: upstream 미설정이거나 로컬에 unpushed 커밋이 있으면 푸시
NEED_PUSH=false
if ! git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  NEED_PUSH=true   # upstream 미설정 (한번도 push 안 함)
elif [[ -n "$(git log @{u}..HEAD 2>/dev/null)" ]]; then
  NEED_PUSH=true   # 로컬에 push 안 된 커밋 존재
fi

if [[ "$NEED_PUSH" != "true" ]]; then
  echo "  → 푸시할 커밋도 없음. 종료."
  exit 0
fi

# 4. 푸시
echo "[4/5] GitHub로 푸시"
if command -v gh >/dev/null 2>&1; then
  # gh 인증 사용 (가장 안정적)
  if gh auth status >/dev/null 2>&1; then
    gh auth setup-git >/dev/null 2>&1 || true
    git push -u origin "$DEFAULT_BRANCH"
  else
    echo "  ⚠️  gh 미인증. 'gh auth login' 한 번 실행해주세요."
    echo "  fallback: git push (사용자 자격증명 사용)"
    git push -u origin "$DEFAULT_BRANCH"
  fi
else
  echo "  ℹ️  gh 없음 — git push 사용 (자격증명 매니저)"
  git push -u origin "$DEFAULT_BRANCH"
fi

# 5. Pages URL 안내
echo "[5/5] 완료 ✅"
echo ""
echo "🌐 배포 URL (1~2분 후 접속 가능):"
echo "   https://koosstem-lgtm.github.io/kospi-may/"
echo ""
echo "💡 GitHub Pages가 아직 활성화되지 않았으면:"
echo "   https://github.com/koosstem-lgtm/kospi-may/settings/pages"
echo "   → Source: 'Deploy from a branch' → Branch: main / (root) → Save"
