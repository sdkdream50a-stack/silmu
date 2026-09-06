# 잔여 §77 과확장 실측 (이번 세션에서 **고치지 않은** 것을 세기 위한 도구)
#
# 결함의 모양 = 범위 표시 없이 §77 을 일반 "분할계약 금지" 조문으로 드는 것.
# 그러면 물품·용역 화면에서도 그대로 읽힌다. 판정축 = **같은 문장 안에 공사 한정 표지가 있는가**.
# (문장이 아니라 ±200자 창으로 재면 파일 어딘가의 "공사"가 걸려 전건이 통과한다 — 실제로 0 이 나왔다.)
#
# 대조는 저장소의 실제 문장을 쓴다. 합성 문장만으로 증명하면 실데이터의 0 이
# "결함 없음"인지 "탐지기 못 잡음"인지 구별되지 않는다.
import os, re, json
from datetime import datetime, timezone

# docs/silmu-p2/r2-align/_measure/<this> → 다섯 단계 위가 repo root.
# (네 단계로 잘못 세면 ROOT 가 docs/ 가 되어 스캔 대상이 0 파일이 되고, 그 0 이 '결함 없음'처럼 보인다)
ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), *[os.pardir] * 4))
assert os.path.isdir(os.path.join(ROOT, 'app')) and os.path.isdir(os.path.join(ROOT, 'db', 'seeds')), \
    f'ROOT 오산정: {ROOT} — 스캔 대상 0 파일이면 0건은 증거가 아니다'
DIRS = ["app", "db/seeds", "config", "lib"]
S77 = re.compile(r"(?:제77조|§77)")
SCOPE = re.compile(r"공사")
SPLIT = re.compile(r"(?<=[.。!?])\s+|\n|<[^>]+>|\|")

# 세지 않는 것 — 각각 이유가 있다
EXCLUDE = {
    "app/services/contract_decision/": "R2 판단 엔진 — 두 트랙으로 이미 갈라져 있다",
    "app/views/tools/split_contract_checker": "R2 도구 — §77 은 공사 트랙에만 붙는다",
    "app/models/exam_questions.rb": "시험문제 은행 — 정답 해설이 공사 한정을 명시한다",
    "app/models/exam_curriculum": "시험 커리큘럼 — 국가/지방 조문 대비표",
    "config/contract_decision_rules.yml": "R2 규칙집 — source_locator 는 조문 위치 표기지 진술이 아니다",
    "db/seeds/topic_legacy_semantic_alignment_2026_09_06.rb": "이번 정정 시드의 헤더 주석",
    "db/seeds/topic_fence_installation.rb": "펜스=공사. 토픽 전체가 공사 문맥이라 문장 단위로만 잡힌다(오검출)",
}

def scan_text(t):
    return [s for s in SPLIT.split(t) if S77.search(s) and not SCOPE.search(s)]

POS = ("안 됩니다. 수의계약 한도나 입찰 방식을 회피하려고 단일 사업을 여러 건으로 쪼개는 분할계약은 "
       "시행령 §77로 금지됩니다.")                                    # topic_estimated_amount.rb 실제 문장
NEG = "**지방계약법 시행령 제77조 (공사의 분할계약 금지):**"              # topic_split_contract.rb 실제 문장
assert scan_text(POS), "양성 대조 실패 — 범위 없는 §77 인용을 못 잡는다"
assert not scan_text(NEG), "음성 대조 실패 — 공사 한정 인용을 결함으로 센다"

hits = []
for d in DIRS:
    for dp, _, fns in os.walk(os.path.join(ROOT, d)):
        for fn in fns:
            if not fn.endswith((".rb", ".erb", ".yml")):
                continue
            rel = os.path.relpath(os.path.join(dp, fn), ROOT)
            if any(rel.startswith(k) for k in EXCLUDE):
                continue
            t = open(os.path.join(dp, fn), encoding="utf-8").read()
            for s in scan_text(t):
                s = re.sub(r"\s+", " ", s).strip()
                if s:
                    hits.append({"file": rel, "sentence": s[:220]})

files = {}
for h in hits:
    files[h["file"]] = files.get(h["file"], 0) + 1
print(json.dumps({"scanned_at": datetime.now(timezone.utc).isoformat(),
                  "count": len(hits), "files": dict(sorted(files.items())),
                  "excluded": EXCLUDE, "hits": hits}, ensure_ascii=False, indent=1))
