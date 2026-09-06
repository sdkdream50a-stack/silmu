# 잔여 §77 문맥 판정 스캐너 (context-aware)
#
# contains("제77조") 만으로 판정하지 않는다. 다섯 축을 함께 본다:
#   ARTICLE         §77 / §77①③ … 인용 위치
#   CONTRACT_TYPE   문장이 스스로 유형을 말하면 그것, 아니면 **레코드(토픽/감사사례) 범위**
#   CLAIM_KIND      ground(근거 주장) vs locator(조문 위치 표기)
#   CLAIM_STRENGTH  absolute(절대·금액무관·언제나) / conditional / citation
#   POLARITY        그 문장이 §77 의 적용범위를 **한정하거나 부정**하는가
#
# POLARITY 가 없으면 "물품·용역에 §77 은 적용되지 않습니다" 같은 **옳은 문장**이 결함으로 잡힌다
# (실제로 6건 났다). 범위를 넓히면 음성을 다시 재야 한다.
#
# 문맥은 문장만으로 정해지지 않는다. 운영 콘텐츠는 레코드 단위로 제공되므로 그 문장이 어느
# 토픽 안에 있는지가 독자의 실제 문맥이다. ±N자 창은 두 방향으로 틀린다 — ±600 은 결정 불가를,
# ±2500 은 어느 파일에서든 "공사"를 주워 온다.
import os, re, json, subprocess
from datetime import datetime, timezone

# 스캔 대상 트리는 바꿔 끼울 수 있다(정정 전 트리를 «같은 계측기»로 재려면 필요하다).
# git blob 대조는 언제나 실제 저장소에서 읽는다 — 추출된 트리는 git repo 가 아니다.
ROOT = os.environ.get("S77_SCAN_ROOT") or \
    os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), *[os.pardir] * 4))
GIT_ROOT = os.environ.get("S77_GIT_ROOT") or ROOT
assert os.path.isdir(os.path.join(ROOT, "app")) and os.path.isdir(os.path.join(ROOT, "db", "seeds")), \
    f"ROOT 오산정: {ROOT} — 스캔 대상 0 파일이면 0건은 증거가 아니다"

DIRS = ["app", "db/seeds", "config", "lib"]
EXT = (".rb", ".erb", ".yml")

# §14 — R2 판단 엔진·규칙집은 동결이다. 판정 대상이 아니라 **별도 버킷**으로 센다.
# (조용히 VALID 로 섞으면 "정당한 인용 50건"이 실제보다 부풀어 보인다)
R2_CORE = ("app/services/contract_decision/", "config/contract_decision_rules.yml",
           "config/contract_thresholds.yml")

# 정정 시드는 «치환표»다 — old 문자열로 정정 전 문구를 **반드시** 들고 있어야 한다.
# 그걸 결함으로 세면 고칠수록 숫자가 늘어난다(실제로 AFTER 0 → 13 이 됐다).
# 사용자에게 나가는 콘텐츠가 아니므로 별도 버킷으로 뺀다.
CORRECTIVE_SEEDS = ("db/seeds/topic_s77_scope_fix_2026_09_06.rb",
                    "db/seeds/topic_legacy_semantic_alignment_2026_09_06.rb")

S77 = re.compile(r"(?:제77조(?:제\d항)?(?:제\d호)?(?:[가-힣]목)?|§\s*77(?:제\d항)?)")
SENT = re.compile(r"(?<=[.。!?])\s+|\n")
# 줄바꿈을 넘기면 Ruby heredoc 마커(<<~CONTENT)가 태그 시작이 되어 다음 '>' 까지 본문을
# 통째로 지운다 — 그 구간의 §77 진술이 검사에서 사라진다. 한 줄 안으로 제한한다.
TAG  = re.compile(r"<[^>\n]+>")

CONSTRUCTION = re.compile(r"공사|구조물|공종|공구|시공|설계서|펜스|현장설명")
GOODS        = re.compile(r"물품|용역|사무용품|간행물|도서|구매|제조")
# "명시적으로 금지"는 조문 원문의 서술이지 강도 부풀리기가 아니다 — 뺐다.
# 남긴 것은 근거보다 강한 표현뿐이다(§77①단서·예규 5.라 단서가 분할을 허용한다).
ABSOLUTE     = re.compile(r"절대\s*금지|금액과\s*무관|언제나\s*금지|무조건\s*금지|어떤 경우에도")
CONDITIONAL  = re.compile(r"부당|회피(할|하려|를)?\s*목적|한도[를]?\s*맞추|단일\s*사업|각\s*호|다만|예외|허용")
# 적용범위를 한정·부정하거나 두 트랙을 갈라 적는 문장 = 옳은 문장이다
SCOPE_LIMIT  = re.compile(r"적용되지\s*않|적용을\s*받지\s*않|인용\s*금지|근거로\s*대지\s*않|공사\s*조항|"
                          r"공사\s*한정|공사에\s*한정|범위를\s*넘|잘못\s*인용|아닙니다|한정한다")
# 맨 "예규"만 보면 «기획재정부 회계예규»·«조달청 예규»(국가계약 계열 오인용)까지 두 트랙으로
# 착각한다 — 실제로 2건이 그렇게 통과했다. 행안부 집행기준을 가리킬 때만 인정한다.
TWO_TRACK    = re.compile(r"제7조제2호|§\s*7제2호|집행기준\s*제?1?장|행안부\s*예규|행정안전부\s*예규")

GROUND = re.compile(r"금지|위반|근거|따라|적용|해당|규정하|봅니다|됩니다|한다|해야")
LOCATOR_SHAPE = re.compile(r"^\s*(?:#|source_locator|locator|laws|note|basis)\b"
                           r"|^\s*[-*]?\s*[ㄱ-힝\w ()·,]{0,40}(?:제77조|§\s*77)[ㄱ-힝\w ()·,]{0,25}$")
SLUG = re.compile(r"""(?:slug:\s*['"]([a-z0-9\-]+)['"]|["']([a-z0-9\-]+)["']\s*=>|topic_slug\s*=\s*['"]([a-z0-9\-]+)['"]|\bslug\s*=\s*['"]([a-z0-9\-]+)['"])""")


def enclosing_slug(text, pos):
    last = None
    for m in SLUG.finditer(text, 0, pos):
        last = next(g for g in m.groups() if g)
    return last


def sentence_at(text, pos):
    lo, hi = max(0, pos - 600), min(len(text), pos + 600)
    # 태그로 «자르면» <strong>제77조제3항</strong> 이 그 자체로 한 문장이 되어 조문번호만 보고
    # 강도·유형을 재게 된다. 그래서 같은 길이의 공백으로 지운다 — 오프셋이 보존된다.
    chunk = TAG.sub(lambda m: " " * len(m.group(0)), text[lo:hi])
    rel, idx, parts = pos - lo, 0, []
    for p in SENT.split(chunk):
        if p is None:
            continue
        s = chunk.find(p, idx)
        if s < 0:
            continue
        idx = s + len(p)
        parts.append((s, s + len(p), p))
    for s, e, p in parts:
        if s <= rel < e and p.strip():
            return p.strip()
    return chunk[max(0, rel - 120): rel + 120].strip()


def record_bounds(text, pos):
    """이 위치를 감싸는 레코드 구간(슬러그 → 다음 슬러그)."""
    starts = [m.start() for m in SLUG.finditer(text)]
    lo = max([s for s in starts if s <= pos], default=0)
    hi = min([s for s in starts if s > pos], default=len(text))
    return text[lo:hi]


def scope_of(chunk):
    c, g = bool(CONSTRUCTION.search(chunk)), bool(GOODS.search(chunk))
    if c and not g: return "construction"
    if g and not c: return "goods_service"
    if c and g:     return "mixed"
    return "general"


def type_hint(sentence, record):
    s = scope_of(sentence)
    if s in ("construction", "goods_service"):
        return s, "sentence"
    return scope_of(record), "record"


def strength(s):
    if ABSOLUTE.search(s):    return "absolute"
    if CONDITIONAL.search(s): return "conditional"
    return "citation"


def claim_kind(s):
    s = s.strip()
    if LOCATOR_SHAPE.search(s): return "locator"
    return "ground" if GROUND.search(s) else "locator"


def polarity(s):
    if SCOPE_LIMIT.search(s): return "scope_limiting"
    if TWO_TRACK.search(s):   return "two_track"
    return "assertive"


COMMENT = re.compile(r"^\s*(?:#|//|<!--)")

# 사람이 문맥을 읽고 내린 판정. 자동 규칙이 문장 단위라 못 보는 것을 여기서 뒤집는다.
# 프로즈에 적지 않고 도구에 둔다 — 그래야 다음 실행에서도 같은 판정이 재현된다.
MANUAL_OVERRIDES = [
    ("db/seeds/audit_cases/contract_method_violations.rb", "단일 사업을 분할하여 금액 기준을 낮추는 행위는",
     "VALID_CONSTRUCTION_SCOPE",
     "같은 절 앞 문장이 «총 공사금액 3억 4,700만원 … 전문공사 기준 2억원 초과»다. 사건 자체가 공사다"),
    ("db/seeds/audit_cases/topic_audit_cases_batch_01.rb", "ac.issue = '□□도 ○○교육지원청에서 실내환경 개선사업",
     "CONTEXT_AMBIGUOUS",
     "실내환경 개선(LED 교체·환기 설비·도색)이 공사인지 물품·용역 혼합인지 확정 불가. "
     "게다가 사건이 적은 «수의계약 한도 5천만원»은 공사 한도(4억/2억/1.6억)와 맞지 않는다 — 추가 근거 필요"),
    ("db/seeds/audit_cases/topic_audit_cases_batch_01.rb", "'계약 분할 금지 조항(시행령 제77조) 위반 여부",
     "CONTEXT_AMBIGUOUS", "위와 같은 사건의 체크포인트. 계약유형이 확정되지 않는다"),
    ("app/views/tools/split_contract_checker.html.erb", None, "VALID_CONSTRUCTION_SCOPE",
     "R2 도구의 공사 트랙(#construction-track) 내부 UI 라벨. 물품·용역 트랙은 §7제2호로 분리돼 있다"),
    ("app/models/exam_questions.rb", None, "VALID_CONSTRUCTION_SCOPE",
     "퀴즈 보기/정답. 같은 문항 해설이 «공사의 분할계약 금지»로 범위를 밝힌다"),
    ("db/seeds/topic_fence_installation.rb", None, "VALID_CONSTRUCTION_SCOPE",
     "펜스 설치 = 공사 토픽. §77 인용이 적용범위와 일치한다"),
    ("db/seeds/topic_national_vs_local.rb", None, "VALID_CONSTRUCTION_SCOPE",
     "국가/지방 조문번호 대비표. 적용범위를 주장하지 않는 위치 표기다"),
    ("app/views/guides/audit_frequent_issues.html.erb", None, "VALID_CONSTRUCTION_SCOPE",
     "R04 로 두 트랙 병기 완료. ERB 다중행 인자라 문장 추출이 비어 나온다"),
    ("db/seeds/topic_estimated_amount.rb", "### ③ 분할계약 금지 (공사 = 시행령 §77", "VALID_CONSTRUCTION_SCOPE",
     "R07 로 두 트랙 병기 완료. heredoc 경계에서 문장 추출이 어긋난다"),
]


def apply_override(rel, line_text, ctx, auto):
    for f, anchor, v, why in MANUAL_OVERRIDES:
        if rel != f:
            continue
        if anchor is None or anchor in ctx or anchor in line_text:
            return v, why
    return auto, None


def verdict(rel, hint, strength_, kind, pol):
    """판정 규칙 — 코드로 고정한다.

    §77 은 공사 전용이다. 따라서 §77 을 근거로 든 진술이 공사로 한정되지 않았으면 과확장이다
    — mixed·general 은 '모르겠다'가 아니라 '한정하지 않았다'이다.
    CONTEXT_AMBIGUOUS 는 근거 주장이 아니라 **조문 위치 표기**여서 적용범위를 말하지 않는
    경우에만 쓴다(그 표기가 라벨인지 매핑 주장인지는 사람이 봐야 한다).
    """
    if rel.startswith(R2_CORE):
        return "R2_CORE_FROZEN"
    if rel.startswith(CORRECTIVE_SEEDS):
        return "CORRECTIVE_SEED_TABLE"
    if pol in ("scope_limiting", "two_track"):
        return "VALID_CONSTRUCTION_SCOPE"       # 적용범위를 한정하거나 근거를 갈라 적은 옳은 문장
    if strength_ == "absolute":
        return "LEGACY_OVERGENERALIZATION"      # 근거보다 강한 표현
    if kind == "locator":
        return "VALID_CONSTRUCTION_SCOPE" if hint == "construction" else "CONTEXT_AMBIGUOUS"
    return "VALID_CONSTRUCTION_SCOPE" if hint == "construction" else "LEGACY_OVERGENERALIZATION"


def analyze(text, pos, rel):
    s = sentence_at(text, pos)
    th, src = type_hint(s, record_bounds(text, pos))
    st, kd, pol = strength(s), claim_kind(s), polarity(s)
    auto = verdict(rel, th, st, kd, pol)
    # 소스 주석은 사용자에게 나가지 않는다. 결함과 섞어 세지 않는다.
    if auto not in ("R2_CORE_FROZEN", "CORRECTIVE_SEED_TABLE") and COMMENT.match(s):
        auto = "NO_ACTION_INTERNAL"
    ctx = text[max(0, pos - 400): pos + 400]
    final, why = apply_override(rel, s, ctx, auto)
    out = {"contract_type_hint": th, "hint_source": src, "claim_strength": st,
           "claim_kind": kd, "polarity": pol, "auto_verdict": auto, "verdict": final,
           "text": re.sub(r"\s+", " ", s)[:240]}
    if why:
        out["override_reason"] = why
    return out


rows = []
for d in DIRS:
    for dp, _, fns in os.walk(os.path.join(ROOT, d)):
        for fn in sorted(fns):
            if not fn.endswith(EXT):
                continue
            path = os.path.join(dp, fn)
            rel = os.path.relpath(path, ROOT)
            try:
                t = open(path, encoding="utf-8").read()
            except Exception:
                continue
            for m in S77.finditer(t):
                r = analyze(t, m.start(), rel)
                r.update({"file": rel, "line": t[:m.start()].count("\n") + 1,
                          "article": m.group(0), "slug": enclosing_slug(t, m.start()),
                          "context": re.sub(r"\s+", " ", t[max(0, m.start() - 200): m.end() + 260])[:460]})
                rows.append(r)

# ── 대조 — 합성 문자열이 아니라 저장소 실제 파일/커밋의 실제 위치에서 같은 코드경로로 돌린다 ──
def probe_file(rel, needle):
    t2 = open(os.path.join(ROOT, rel), encoding="utf-8").read()
    m = S77.search(t2, t2.index(needle))
    assert m, f"{rel}: 표본 이후에서 §77 을 못 찾는다"
    return analyze(t2, m.start(), rel)

def probe_blob(commit, rel, needle):
    """정정 전 문구는 워킹트리에 더 이상 없다. 커밋된 blob 에서 읽는다 — 이것도 실제 저장소 텍스트다."""
    t2 = subprocess.run(["git", "-C", GIT_ROOT, "show", f"{commit}:{rel}"],
                        capture_output=True, text=True, check=True).stdout
    i = t2.index(needle)
    m = S77.search(t2, i)
    # 그 문구 자체에 §77 이 없으면 문구 위치로 직접 분석한다
    return analyze(t2, m.start() if m and m.start() - i < 800 else i, rel)

CONTROLS = {
    # P1 물품·용역이 섞인 토픽의 §77 일반화 → 잡혀야 한다.
    # 정정 후에는 워킹트리에 이 문구가 없다 — 정정 전 커밋의 blob 에서 읽는다.
    # (양성 대조를 «지금 남아 있는 결함»으로만 세우면, 다 고친 순간 대조가 사라져
    #  탐지기가 죽어도 0건이 나온다. 고친 결함의 대조는 히스토리에 남겨야 한다)
    "P1_goods_overgeneralization": probe_blob(
        "1ccf310", "db/seeds/topic_estimated_amount.rb",
        "수의계약 한도나 입찰 방식을 회피하려고 단일 사업을 여러 건으로 쪼개는 분할계약은 시행령 §77로 금지됩니다"),
    # P2 공사 문맥의 정당한 인용 → 잡히면 안 된다
    "P2_valid_construction": probe_file(
        "db/seeds/topic_split_contract.rb", "**지방계약법 시행령 제77조 (공사의 분할계약 금지):**"),
    # P3 근거보다 강한 표현 → 잡혀야 한다 (정정 전 blob = 실제 저장소 텍스트)
    "P3_stronger_than_source": probe_blob(
        "93c4fd0", "db/seeds/subtopics.rb", "분할계약 절대 금지!"),
    # P4 요건부(회피 목적) 진술 → conditional 이어야 한다
    "P4_conditional_ok": probe_file(
        "app/views/tools/split_contract_checker.html.erb", "제77조제3항</strong>은 그 경우에도"),
    # P5 적용범위를 한정한 옳은 문장 → 잡히면 안 된다 (POLARITY 축의 음성 대조)
    "P5_scope_limiting_ok": probe_file(
        "app/views/guides/contract_flow.html.erb", "공사 분할금지 조문인 시행령 제77조는 물품·용역에 적용되지 않습니다"),
}

assert CONTROLS["P1_goods_overgeneralization"]["verdict"] == "LEGACY_OVERGENERALIZATION", \
    f"P1 실패: {CONTROLS['P1_goods_overgeneralization']}"
assert CONTROLS["P2_valid_construction"]["verdict"] == "VALID_CONSTRUCTION_SCOPE", \
    f"P2 실패: {CONTROLS['P2_valid_construction']}"
assert CONTROLS["P3_stronger_than_source"]["claim_strength"] == "absolute", \
    f"P3 실패: {CONTROLS['P3_stronger_than_source']}"
assert CONTROLS["P4_conditional_ok"]["claim_strength"] == "conditional", \
    f"P4 실패: {CONTROLS['P4_conditional_ok']}"
assert CONTROLS["P5_scope_limiting_ok"]["verdict"] == "VALID_CONSTRUCTION_SCOPE", \
    f"P5 실패 — 적용범위를 한정한 옳은 문장을 결함으로 센다: {CONTROLS['P5_scope_limiting_ok']}"

by_file = {}
for r in rows:
    by_file.setdefault(r["file"], {}).setdefault(r["verdict"], 0)
    by_file[r["file"]][r["verdict"]] += 1

VERDICTS = ("VALID_CONSTRUCTION_SCOPE", "LEGACY_OVERGENERALIZATION", "CONTEXT_AMBIGUOUS",
            "R2_CORE_FROZEN", "NO_ACTION_INTERNAL", "CORRECTIVE_SEED_TABLE")
print(json.dumps({
    "scanned_at": datetime.now(timezone.utc).isoformat(),
    "total_mentions": len(rows),
    "controls": CONTROLS,
    "by_type": {k: sum(1 for r in rows if r["contract_type_hint"] == k)
                for k in ("construction", "goods_service", "mixed", "general")},
    "by_strength": {k: sum(1 for r in rows if r["claim_strength"] == k)
                    for k in ("absolute", "conditional", "citation")},
    "by_polarity": {k: sum(1 for r in rows if r["polarity"] == k)
                    for k in ("scope_limiting", "two_track", "assertive")},
    "by_verdict": {k: sum(1 for r in rows if r["verdict"] == k) for k in VERDICTS},
    "manual_overrides_applied": sum(1 for r in rows if "override_reason" in r),
    "by_file": dict(sorted(by_file.items())),
    "rows": rows,
}, ensure_ascii=False, indent=1))
