#!/usr/bin/env python3
"""silmu.kr 콘텐츠 감사 분류기 (read-only).

입력: extracted.json / badges.json / guide_badges.json (crawl 산출물)
출력: CONTENT_AUDIT.csv + audit_summary.json

분류 규칙은 모두 결정적(deterministic)이며 규칙 ID를 reason에 남긴다.
"""
import json, re, csv, sys
from collections import Counter, defaultdict

rows = json.load(open("extracted.json"))
badges = json.load(open("badges.json"))
gbadges = json.load(open("guide_badges.json"))

CUT = re.compile(r'menu_book 관련 법령 가이드|auto_awesome 유사 감사사례|list 목차|arrow_back 감사사례 목록|이 페이지가 도움이 되었나요')
APPLY = re.compile(r'적용 대상|적용대상|적용 범위|적용범위|누구에게 적용')
NAT = re.compile(r'국가계약법|국가를 당사자로 하는 계약|국가재정법|국가공무원법|국가공무원 복무규정')
LOC = re.compile(r'지방계약법|지방자치단체를 당사자로 하는 계약|지방재정법|지방회계법|지방공무원법|지방공무원 복무규정')
ART = re.compile(r'제\s?\d+\s?조|§\s?\d+')
MON = re.compile(r'\d{1,3}(?:,\d{3})+원|\d+\s?(?:억원|만원|천만원)')
EDU = re.compile(r'교육청|학교|교육지원청|교육공무직|교비|교육비특별회계')
LOCGOV = re.compile(r'도청|시청|군청|구청|시·군·구|지방자치단체 본청')

# 도메인 매핑: 현재 category → 제안 도메인(신 IA 15 도메인)
DOMAIN = {
    "계약": "05_계약조달", "예산/결산": "04_예산회계", "지출": "04_예산회계",
    "복무": "02_복무", "급여/수당": "03_보수수당", "여비/출장": "02_복무",
    "보조금": "07_보조금위탁", "공유재산": "06_재산물품", "기타": "99_미분류",
}
SLUG_DOMAIN = [
    (re.compile(r'travel|trip|출장|여비'), "02_복무"),
    (re.compile(r'leave|annual-leave|sick|duty|overtime|concurrent|reinstatement|position-suspension'), "02_복무"),
    (re.compile(r'salary|allowance|pay|pension|bonus|severance|수당|보수'), "03_보수수당"),
    (re.compile(r'budget|accounting|expense|fund|cash|settlement|fiscal'), "04_예산회계"),
    (re.compile(r'bid|contract|quote|procure|tender|price|estimate|inspection|subcontract'), "05_계약조달"),
    (re.compile(r'property|asset|goods|물품|재산'), "06_재산물품"),
    (re.compile(r'subsidy|보조금|위탁'), "07_보조금위탁"),
    (re.compile(r'disclosure|정보공개'), "09_정보공개"),
    (re.compile(r'privacy|record|개인정보|기록물'), "10_개인정보기록물"),
    (re.compile(r'audit|integrity|discipline|감사|청렴|징계'), "11_감사청렴"),
    (re.compile(r'construction|facility|safety|시설|안전'), "13_시설안전"),
]

def domain_of(section, slug, cat):
    if cat in DOMAIN and DOMAIN[cat] != "99_미분류":
        return DOMAIN[cat]
    for pat, d in SLUG_DOMAIN:
        if pat.search(slug):
            return d
    return "99_미분류"

# 중복 클러스터 (제목 정규화 키)
def tkey(t):
    t = re.sub(r'\s*\|\s*실무\.kr', '', t)
    t = re.sub(r'—.*$', '', t)
    return tuple(sorted(set(re.findall(r'[가-힣]{2,}', t)))[:6])

clusters = defaultdict(list)
for r in rows:
    if r["section"] in ("topics", "guides", "audit-cases"):
        clusters[tkey(r["title"])].append(r["slug"])
dup_slugs = {s for k, v in clusters.items() if len(v) > 1 for s in v}

exact_title = defaultdict(list)
for r in rows:
    exact_title[r["title"]].append(r["slug"])
exact_dup = {s for t, v in exact_title.items() if len(v) > 1 for s in v}

inbound = Counter()
for r in rows:
    for l in set(r["internal_links"]):
        inbound[l] += 1

topic_basis = json.load(open("topic_basis.json"))

def ac_source_class(s):
    if s is None:
        return "NO_BADGE"
    if s.startswith("silmu 자체 시드") or "특정 실사례 아님" in s or "일반화" in s:
        return "RECONSTRUCTED_DISCLOSED"
    if re.match(r'^(GOE|SEN|BAI|MOE)\s*\d{4}', s) or "감사보고서" in s:
        return "NAMED_AUDIT_REPORT"
    if re.search(r'commit|batch|lawId|mcp|spot check|OPEN API|dashboard|Phase A', s, re.I):
        return "INTERNAL_ENGINEERING_METADATA"
    return "OTHER"

out = []
for r in rows:
    sec, slug = r["section"], r["slug"]
    if sec == "static" or slug in ("topics", "guides", "audit-cases", "tools", "templates", "series"):
        continue
    path = r["url"].replace("https://silmu.kr", "")
    body = CUT.split(r["text"])[0]
    b = badges.get(r["name"], {})
    reasons, status, authority, risk, prio = [], None, None, "LOW", "P3"
    recommended = []

    has_apply = bool(APPLY.search(body))
    mixed = bool(NAT.search(body) and LOC.search(body)) and not has_apply

    if sec == "audit-cases":
        cls = ac_source_class(b.get("src"))
        if cls == "INTERNAL_ENGINEERING_METADATA":
            authority, status, risk, prio = "UNVERIFIED", "UPDATE", "HIGH", "P0"
            reasons.append("R-AC1 검토출처에 내부 엔지니어링 메타데이터(커밋/배치/lawId) 노출")
            recommended.append("출처 필드를 사례 출처로 교체하고 검증방법은 별도 필드로 분리")
        elif cls == "RECONSTRUCTED_DISCLOSED":
            authority, status, risk, prio = "SILMU_RECONSTRUCTED_CASE", "UPDATE", "MEDIUM", "P0"
            reasons.append("R-AC2 재구성 사례인데 '5단계 정합성 검증 완료' 배지가 사례 검증으로 오독됨")
            recommended.append("provenance=SILMU_RECONSTRUCTED_CASE 라벨을 제목/상단에 명시, 배지 문구를 '법령근거 검증'으로 한정")
        elif cls == "NAMED_AUDIT_REPORT":
            authority, status, risk, prio = "OFFICIAL_PARTIAL", "UPDATE", "MEDIUM", "P1"
            reasons.append("R-AC3 실제 감사보고서 출처이나 원문 URL·페이지·처분 미기재, 내부 backlog 문구 공개 노출")
            recommended.append("original_document_url·page·disposition 채우고 backlog 문구 제거")
            if LOCGOV.search(body) and not EDU.search(body):
                authority, risk, prio = "UNVERIFIED", "HIGH", "P0"
                reasons.append("R-AC4 출처(교육청 감사보고서)와 본문 문맥(지자체 본청) 불일치")
                recommended.append("출처 재확인 후 정정하거나 재구성 사례로 재분류")
        else:
            authority, status, risk, prio = "UNVERIFIED", "UPDATE", "MEDIUM", "P1"
            reasons.append("R-AC5 검증/출처 표면 없음")
            recommended.append("provenance 4분류 중 하나로 확정")
        if MON.search(body) and not ART.search(body):
            risk = "HIGH"; prio = "P0"
            reasons.append("R-G1 금액이 있으나 조문 근거 표기 없음(fake precision)")
            recommended.append("금액마다 근거 조문·기준일 병기")
        if mixed:
            reasons.append("R-C1 국가/지방 규정 동시 언급 + 적용 대상 미명시")
            recommended.append("적용 대상(기관유형) 명시")
            if prio == "P3": prio = "P1"

    elif sec == "topics":
        authority, status, risk, prio = "OFFICIAL_VERIFIED", "KEEP", "LOW", "P3"
        reasons.append("R-T0 법제처 딥링크 + 검증배지 + 조문 근거 보유")
        if mixed:
            authority, status, risk, prio = "OFFICIAL_PARTIAL", "UPDATE", "MEDIUM", "P1"
            reasons.append("R-C1 국가/지방 규정 동시 언급 + 적용 대상 미명시")
            recommended.append("Agency Rule Layer(COMMON_RULE + OVERRIDE)로 기관별 분기 제공")
        if b.get("rev") and b["rev"] < "2026-06-01":
            if status == "KEEP": status = "UPDATE"
            reasons.append(f"R-B1 검토일 {b['rev']} — 3개월 이상 경과")
            recommended.append("재검증 주기 정책 적용")
            if prio == "P3": prio = "P2"

    elif sec == "guides":
        gb = gbadges.get(slug, {})
        if not gb.get("pill"):
            authority, status, risk, prio = "UNVERIFIED", "UPDATE", "MEDIUM", "P1"
            reasons.append("R-GD1 검증 표면 없음(검증배지·검토일 부재)")
            recommended.append("guides에도 authority metadata 표면 적용")
        else:
            authority, status, risk, prio = "SECONDARY_SOURCE", "UPDATE", "LOW", "P2"
            reasons.append(f"R-GD2 검토일 {gb.get('rev')} 표기 있으나 1차 출처 미표기")
            recommended.append("official_source_url 채우기")
        if r["law_count"] == 0:
            risk = "MEDIUM"; prio = "P1"
            reasons.append("R-GD3 본문에 식별 가능한 법령명 없음")

    elif sec == "tools":
        authority, status, risk, prio = "SILMU_INTERPRETATION", "UPDATE", "MEDIUM", "P1"
        reasons.append("R-TL1 계산·판단 결과에 기준일/근거 버전 표기 없음")
        recommended.append("도구에 기준일·근거조문·개정 반영일 표면 추가")
        if not re.search(r'참고용|법률자문이 아|법적 효력', r["text"]):
            risk = "HIGH"; prio = "P0"
            reasons.append("R-TL2 면책·한계 문구 없음 (금액·기한 산출 도구)")
            recommended.append("면책 문구 및 '기안 전 근거 재확인' 안내 추가")

    elif sec == "templates":
        authority, status, risk, prio = "UNVERIFIED", "UPDATE", "LOW", "P2"
        reasons.append("R-TP1 본문 얇음(<800자)·메타 description 부재")
        recommended.append("서식별 근거·작성요령·관련 토픽 링크 보강")

    elif sec == "series":
        authority, status, risk, prio = "SECONDARY_SOURCE", "KEEP", "LOW", "P3"
        reasons.append("R-SR1 시리즈 랜딩")

    if slug in exact_dup:
        status = "MERGE"
        reasons.append("R-I1 <title> 완전 중복 — 검색 카니벌라이제이션")
        recommended.append("제목 차별화 또는 통합")
        if prio in ("P3",): prio = "P2"
    elif slug in dup_slugs:
        if status == "KEEP": status = "MERGE"
        reasons.append("R-I2 유사 주제 클러스터 — 통합 검토")
        if prio == "P3": prio = "P2"

    if inbound.get(path, 0) == 0:
        reasons.append("R-S1 내부링크 인바운드 0 (고아 페이지)")
        recommended.append("허브(토픽/카테고리)에서 링크 연결")
        if prio == "P3": prio = "P2"

    if r["desc_len"] < 70:
        reasons.append("R-S2 meta description 부재/과단")
    if r["text_len"] < 800:
        reasons.append("R-S3 thin content")

    cat = topic_basis.get(slug, {}).get("cat", "") if sec == "topics" else ""
    out.append(dict(
        content_id=f"{sec}:{slug}",
        url=path,
        title=re.sub(r'\s*\|\s*실무\.kr$', '', r["title"]),
        content_type=sec,
        current_category=cat,
        proposed_domain=domain_of(sec, slug, cat),
        target_agency=("EDUCATION_OFFICE|PUBLIC_SCHOOL" if EDU.search(body) and not LOCGOV.search(body)
                       else "LOCAL_GOVERNMENT" if LOCGOV.search(body) and not EDU.search(body)
                       else "UNSPECIFIED"),
        jurisdiction=("BOTH" if NAT.search(body) and LOC.search(body)
                      else "NATIONAL" if NAT.search(body)
                      else "LOCAL" if LOC.search(body) else "UNSPECIFIED"),
        authority_status=authority,
        audit_status=status,
        risk_level=risk,
        verified_at=(b.get("rev") or gbadges.get(slug, {}).get("rev") or ""),
        official_source_link_count=sum(1 for l in r["internal_links"] if False) or r.get("off_link_n", 0),
        inbound_links=inbound.get(path, 0),
        text_len=r["text_len"],
        reason=" ; ".join(reasons),
        recommended_action=" ; ".join(recommended) or "현행 유지",
        priority=prio,
    ))

out.sort(key=lambda x: (x["priority"], x["content_type"], x["url"]))
fields = list(out[0].keys())
with open("CONTENT_AUDIT.csv", "w", newline="", encoding="utf-8-sig") as f:
    w = csv.DictWriter(f, fieldnames=fields)
    w.writeheader(); w.writerows(out)

summary = dict(
    total=len(out),
    by_type=dict(Counter(o["content_type"] for o in out)),
    by_audit_status=dict(Counter(o["audit_status"] for o in out)),
    by_authority=dict(Counter(o["authority_status"] for o in out)),
    by_risk=dict(Counter(o["risk_level"] for o in out)),
    by_priority=dict(Counter(o["priority"] for o in out)),
    by_domain=dict(Counter(o["proposed_domain"] for o in out)),
    by_jurisdiction=dict(Counter(o["jurisdiction"] for o in out)),
    by_target_agency=dict(Counter(o["target_agency"] for o in out)),
)
json.dump(summary, open("audit_summary.json", "w"), ensure_ascii=False, indent=1)
print(json.dumps(summary, ensure_ascii=False, indent=1))
