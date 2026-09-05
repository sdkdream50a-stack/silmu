#!/usr/bin/env python3
# silmu.kr 운영 페이지 추출기 (read-only)
import os, re, json, html, glob

PAGES = "pages"
LAW_PAT = re.compile(r'(지방자치단체를 당사자로 하는 계약에 관한 법률(?: 시행령| 시행규칙)?|국가를 당사자로 하는 계약에 관한 법률(?: 시행령| 시행규칙)?|지방계약법(?: 시행령| 시행규칙)?|국가계약법(?: 시행령| 시행규칙)?|지방재정법(?: 시행령)?|지방회계법(?: 시행령)?|국가재정법|국고금관리법|지방공무원법|국가공무원법|공무원보수규정|공무원수당 등에 관한 규정|지방공무원 보수규정|지방공무원 수당 등에 관한 규정|공무원 여비 규정|지방공무원 여비 규정|지방공무원 복무규정|국가공무원 복무규정|공공기관의 정보공개에 관한 법률|개인정보 보호법|행정절차법|민원 처리에 관한 법률|지방보조금법|지방자치단체 보조금 관리에 관한 법률|공유재산 및 물품 관리법|물품관리법|국유재산법|부정청탁 및 금품등 수수의 금지에 관한 법률|공직자의 이해충돌 방지법|공공감사에 관한 법률|감사원법|사립학교법|초·중등교육법|교육공무원법|지방교육자치에 관한 법률|지방교육재정교부금법|학교회계 규칙|공공기관의 운영에 관한 법률|건설산업기본법|하도급거래 공정화에 관한 법률|전자조달의 이용 및 촉진에 관한 법률|산업안전보건법|중대재해 처벌 등에 관한 법률|공공기록물 관리에 관한 법률)')
ART_PAT = re.compile(r'(?:제\s?(\d+)\s?조|§\s?(\d+))')
DATE_PAT = re.compile(r'(20\d{2})[.\-년]\s?(\d{1,2})[.\-월]\s?(\d{1,2})?')
MONEY_PAT = re.compile(r'(\d{1,3}(?:,\d{3})+|\d+)\s?(억원|만원|천만원|원)')
PCT_PAT = re.compile(r'(\d+(?:\.\d+)?)\s?(?:%|퍼센트)')
PERIOD_PAT = re.compile(r'(\d+)\s?(일|개월|년|주|시간)\s?(?:이내|이상|이하|까지|간)')

def strip_html(s):
    s = re.sub(r'(?is)<script.*?</script>', ' ', s)
    s = re.sub(r'(?is)<style.*?</style>', ' ', s)
    s = re.sub(r'(?is)<svg.*?</svg>', ' ', s)
    s = re.sub(r'(?s)<[^>]+>', ' ', s)
    s = html.unescape(s)
    return re.sub(r'\s+', ' ', s).strip()

def main_text(s):
    m = re.search(r'(?is)<main\b[^>]*>(.*?)</main>', s)
    return strip_html(m.group(1)) if m else strip_html(s)

def attr(s, pat):
    m = re.search(pat, s, re.I)
    return html.unescape(m.group(1)).strip() if m else ""

rows = []
for f in sorted(glob.glob(os.path.join(PAGES, "*.html"))):
    name = os.path.basename(f)[:-5]
    raw = open(f, encoding="utf-8", errors="replace").read()
    url = "https://silmu.kr/" + ("" if name == "__root" else name.replace("__", "/"))
    parts = [p for p in name.replace("__", "/").split("/") if p]
    section = parts[0] if parts else "(root)"
    slug = parts[-1] if len(parts) > 1 else (parts[0] if parts else "(root)")
    if section not in ("topics","guides","audit-cases","tools","templates","series"):
        section = "static"

    title = attr(raw, r'<title>(.*?)</title>')
    desc  = attr(raw, r'<meta[^>]+name=["\']description["\'][^>]+content=["\'](.*?)["\']')
    canon = attr(raw, r'<link[^>]+rel=["\']canonical["\'][^>]+href=["\'](.*?)["\']')
    ogt   = attr(raw, r'<meta[^>]+property=["\']og:title["\'][^>]+content=["\'](.*?)["\']')
    robots= attr(raw, r'<meta[^>]+name=["\']robots["\'][^>]+content=["\'](.*?)["\']')
    h1s   = [strip_html(x) for x in re.findall(r'(?is)<h1[^>]*>(.*?)</h1>', raw)]

    ld_types, ld_dates = set(), {}
    for blk in re.findall(r'(?is)<script[^>]+application/ld\+json[^>]*>(.*?)</script>', raw):
        try:
            data = json.loads(blk.strip())
        except Exception:
            for t in re.findall(r'"@type"\s*:\s*"([^"]+)"', blk): ld_types.add(t)
            continue
        stack = [data]
        while stack:
            n = stack.pop()
            if isinstance(n, dict):
                if isinstance(n.get("@type"), str): ld_types.add(n["@type"])
                for k in ("datePublished","dateModified"):
                    if isinstance(n.get(k), str): ld_dates.setdefault(k, n[k])
                stack.extend(n.values())
            elif isinstance(n, list):
                stack.extend(n)

    text = main_text(raw)
    laws = sorted(set(LAW_PAT.findall(text)))
    body_ex_nav = text
    money = MONEY_PAT.findall(body_ex_nav)
    pcts = PCT_PAT.findall(body_ex_nav)
    periods = PERIOD_PAT.findall(body_ex_nav)
    years = sorted({int(y) for y,_,_ in DATE_PAT.findall(body_ex_nav) if 2000 <= int(y) <= 2030})
    internal = sorted(set(re.findall(r'href="(/(?:topics|guides|audit-cases|tools|templates|series)/[^"#?]*)"', raw)))

    rows.append(dict(
        name=name, url=url, section=section, slug=slug,
        title=title, title_len=len(title), desc=desc, desc_len=len(desc),
        canonical=canon, canonical_ok=(canon.rstrip('/')==url.rstrip('/')),
        og_title=ogt, robots=robots, h1=h1s[0] if h1s else "", h1_count=len(h1s),
        ld_types=sorted(ld_types), ld_dates=ld_dates,
        text_len=len(text), laws=laws, law_count=len(laws),
        money_n=len(money), pct_n=len(pcts), period_n=len(periods),
        years=years, max_year=max(years) if years else None,
        internal_links=internal, internal_n=len(internal),
        text=text,
    ))

json.dump(rows, open("extracted.json","w"), ensure_ascii=False)
print("pages:", len(rows))
from collections import Counter
print(Counter(r["section"] for r in rows))
