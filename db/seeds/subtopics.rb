# 수의계약 서브토픽 데이터 생성

# 부모 토픽 찾기
parent = Topic.find_by(slug: 'private-contract')

unless parent
  puts "부모 토픽(private-contract)을 찾을 수 없습니다."
  exit
end

subtopics_data = [
  {
    name: '수의계약',
    slug: 'private-contract-overview',
    summary: '경쟁입찰 없이 특정인을 선정하여 체결하는 계약',
    keywords: '수의계약,수의,특명수의,소액수의,계약',
    category: 'contract',
    law_content: <<~LAW,
      <strong>지방계약법 제9조 (수의계약)</strong>

      지방자치단체의 장 또는 계약담당자는 계약의 목적ㆍ성질ㆍ규모 및 지역특수성 등을 고려하여 필요하다고 인정되면 대통령령으로 정하는 바에 따라 수의계약을 할 수 있다.
    LAW
    decree_content: <<~DECREE,
      <strong>지방계약법 시행령 제25조 (수의계약에 의할 수 있는 경우)</strong>

      ① 다음 각 호의 어느 하나에 해당하는 경우에는 수의계약에 의할 수 있다.

      <strong>1. 추정가격이 다음 금액 이하인 경우</strong>
      • 공사: 종합공사 4억원, 전문공사 2억원, 기타공사 1.6억원
      • 물품 제조·구매: 2천만원 (소기업·소상공인 1억원, 특례 기업 5천만원)
      • 용역: 2천만원 (소기업·소상공인 1억원, 특례 기업 5천만원)

      <strong>2. 특정인의 기술이 필요한 경우</strong>

      <strong>3. 입찰에 부쳐도 낙찰자가 없는 경우</strong>

      <strong>4. 천재지변, 긴급한 행사 등의 경우</strong>

      <strong>5. 국가유공자 등과 계약하는 경우</strong>
    DECREE
    rule_content: <<~RULE,
      <strong>수의계약 유형</strong>

      <table style="width:100%; border-collapse: collapse;">
        <tr style="background:#f3f4f6;">
          <th style="border:1px solid #ddd; padding:8px;">유형</th>
          <th style="border:1px solid #ddd; padding:8px;">근거</th>
          <th style="border:1px solid #ddd; padding:8px;">금액/조건</th>
        </tr>
        <tr>
          <td style="border:1px solid #ddd; padding:8px;">소액수의</td>
          <td style="border:1px solid #ddd; padding:8px;">시행령 §25①1</td>
          <td style="border:1px solid #ddd; padding:8px;">물품·용역 2천만원(특례 1억원), 종합공사 4억원</td>
        </tr>
        <tr>
          <td style="border:1px solid #ddd; padding:8px;">특명수의</td>
          <td style="border:1px solid #ddd; padding:8px;">시행령 §25①2~6</td>
          <td style="border:1px solid #ddd; padding:8px;">특수 사유 충족 시</td>
        </tr>
        <tr>
          <td style="border:1px solid #ddd; padding:8px;">긴급수의</td>
          <td style="border:1px solid #ddd; padding:8px;">시행령 §25①4</td>
          <td style="border:1px solid #ddd; padding:8px;">천재지변, 긴급 행사 등</td>
        </tr>
      </table>
    RULE
    practical_tips: <<~TIPS,
      <div class="space-y-4">
        <div class="bg-red-50 border border-red-200 rounded-xl p-4">
          <h4 class="font-bold text-red-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">warning</span>
            주의해야 할 점
          </h4>
          <ul class="space-y-2 text-red-700">
            <li>• <strong>분할계약 금지</strong> - 하나의 사업을 쪼개서 수의계약 금액 이하로 만드는 것은 위법</li>
            <li>• <strong>견적서 사전 징구</strong> - 반드시 계약 전에 견적서를 받아야 함</li>
            <li>• <strong>예정가격 작성</strong> - 수의계약도 예정가격 작성 필수</li>
          </ul>
        </div>

        <div class="bg-green-50 border border-green-200 rounded-xl p-4">
          <h4 class="font-bold text-green-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">check_circle</span>
            체크리스트
          </h4>
          <ul class="space-y-1 text-green-700">
            <li>☐ 수의계약 대상 금액 확인</li>
            <li>☐ 견적서 징구 (1인/2인)</li>
            <li>☐ 예정가격 작성</li>
            <li>☐ 수의계약 사유서 작성</li>
            <li>☐ 계약서 작성 및 날인</li>
          </ul>
        </div>
      </div>
    TIPS
    interpretation_content: <<~INTERP,
## 수의계약 관련 유권해석

### Q. 수의계약과 경쟁입찰의 선택 기준

**A:** 추정가격이 수의계약 한도 이하라도 경쟁입찰을 진행할 수 있습니다. 수의계약은 "할 수 있다"는 선택 규정이므로, 경쟁을 통해 더 유리한 조건을 얻을 수 있다면 경쟁입찰이 권장됩니다.

---

### Q. 수의계약 시 계약보증금 면제 기준

**A:** 추정가격 **5천만원 이하**(공사 1억원 이하)인 경우 계약보증금 납부를 면제할 수 있습니다.

---

### Q. 수의계약 시 하자보증금 기준

**A:** 수의계약도 하자보증금 규정이 동일하게 적용됩니다. 계약금액의 2~5%를 하자담보책임 기간 동안 보관합니다.
    INTERP
    audit_cases: <<~AUDIT,
## 수의계약 관련 감사사례

### 사례 1: 수의계약 사유서 미작성
**지적사항:** 수의계약 체결 시 수의계약 사유서를 작성하지 않음
**관련근거:** 지방계약법 시행규칙 제26조
**조치내용:** 관련자 주의

> 소액수의계약이라도 수의계약 사유서는 반드시 작성해야 함

---

### 사례 2: 예정가격 미작성
**지적사항:** 1천만원 물품 구매 시 예정가격 조서 미작성
**관련근거:** 지방계약법 시행령 제9조
**조치내용:** 관련자 주의

> 금액과 관계없이 예정가격 조서 작성은 필수

---

### 사례 3: 견적서 사후 징구
**지적사항:** 계약 체결 후 견적서를 소급하여 작성
**관련근거:** 지방계약법 시행령 제30조
**조치내용:** 관련자 중징계

> 견적서는 반드시 계약 체결 전에 징구해야 함
    AUDIT
    qa_content: <<~QA,
## 수의계약 질의답변

### Q1. 수의계약이란 무엇인가요?

**A:** 경쟁입찰 없이 특정인을 상대로 체결하는 계약입니다. 추정가격이 일정 금액 이하이거나, 특수한 사유가 있을 때 가능합니다.

---

### Q2. 수의계약의 장단점은?

**A:**
**장점:**
- 신속한 계약 체결 가능
- 행정 절차 간소화
- 특정 기술/품질이 필요할 때 적합

**단점:**
- 경쟁 부재로 가격 상승 가능
- 특정 업체 유착 우려
- 감사 시 주의 필요

---

### Q3. 수의계약 시 필수 서류는?

**A:** 다음 서류를 반드시 작성해야 합니다:
1. 수의계약 사유서
2. 예정가격 조서
3. 견적서 (1인 또는 2인 이상)
4. 계약서 (5천만원 초과 시)
5. 사업자등록증 사본
    QA
    faqs: [
      { question: '수의계약과 일반경쟁입찰의 차이는?', answer: '일반경쟁입찰은 불특정 다수가 참여하여 최저가 낙찰자와 계약하는 방식이고, 수의계약은 특정인을 선정하여 계약하는 방식입니다.' },
      { question: '수의계약 시에도 계약서를 작성해야 하나요?', answer: '네, 수의계약도 원칙적으로 계약서를 작성해야 합니다. 다만, 추정가격 5천만원(공사 1억원) 이하인 경우 계약서 작성을 생략할 수 있습니다.' }
    ].to_json,
    published: true
  },
  {
    name: '수의시담',
    slug: 'price-negotiation',
    summary: '수의계약 시 계약상대자와의 가격 협상 절차',
    keywords: '수의시담,가격협상,협상절차,시담,단가협상',
    category: 'contract',
    law_content: <<~LAW,
지방계약법
제9조 (수의계약)

지방자치단체의 장 또는 계약담당자는 계약의 목적·성질·규모 및 지역특수성 등을 고려하여 필요하다고 인정되면 대통령령으로 정하는 바에 따라 <mark>수의계약</mark>을 할 수 있다.

※ 수의시담은 수의계약 시 견적가격이 예정가격을 초과하는 경우 가격 협상을 통해 계약을 체결하는 절차입니다.
    LAW
    decree_content: <<~DECREE,
지방계약법 시행령
제30조 (수의계약의 방법)

① 수의계약을 체결하려는 경우에는 계약담당자가 계약의 목적·성질·규모 등을 고려하여 필요하다고 인정하면 <mark>2인 이상으로부터 견적서를 받아</mark> 견적가격이 적정한지를 비교하여야 한다.

② 견적서를 받은 경우에는 <mark>예정가격 이하로서 최저가격으로 견적한 자</mark>를 계약상대자로 한다.

③ 제1항 및 제2항에 따라 견적서를 제출받아 계약상대자를 결정하는 경우 견적가격이 예정가격을 초과하면 <mark>수의시담</mark>을 할 수 있다.
    DECREE
    rule_content: <<~RULE,
지방자치단체 입찰 및 계약집행기준
제74조 (수의시담)

① 계약담당자가 제70조에 따른 견적서를 받은 경우에는 그 견적가격이 적정한지를 비교하여야 한다.

② 계약담당자는 견적가격이 **예정가격을 초과**하거나 가격이 적정하지 아니하다고 인정하는 경우에는 __수의시담에 응할 것을 요청__할 수 있다.

③ 수의시담에 응한 자 중 **예정가격 이하의 최저가격 견적자**를 계약상대자로 결정한다.

④ 수의시담은 **1회에 한하여** 실시할 수 있다.
    RULE
    regulation_content: <<~REGULATION,
      <strong>수의시담 진행 절차</strong>

      <div style="background:#f0f9ff; padding:16px; border-radius:8px; margin-top:12px;">
        <ol style="margin:0; padding-left:20px;">
          <li style="margin-bottom:8px;"><strong>1단계:</strong> 견적가격이 예정가격 초과 확인</li>
          <li style="margin-bottom:8px;"><strong>2단계:</strong> 계약상대자에게 수의시담 요청</li>
          <li style="margin-bottom:8px;"><strong>3단계:</strong> 시담 일시/장소 통보</li>
          <li style="margin-bottom:8px;"><strong>4단계:</strong> 시담 진행 및 시담조서 작성</li>
          <li><strong>5단계:</strong> 재견적서 징구 (1회에 한함)</li>
        </ol>
      </div>

      <div style="background:#fef3c7; padding:12px; border-radius:8px; margin-top:12px;">
        <strong>⚠️ 주의:</strong> 수의시담은 <u>1회에 한해</u> 가능합니다.
      </div>
    REGULATION
    practical_tips: <<~TIPS,
      <div class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">tips_and_updates</span>
            수의시담 핵심 포인트
          </h4>
          <ul class="space-y-2 text-blue-700">
            <li>• 수의시담은 <strong>가격협상</strong>입니다 (규격/조건 변경 불가)</li>
            <li>• 시담은 <strong>1회</strong>에 한해 가능</li>
            <li>• 시담 전 <strong>예정가격 비밀 유지</strong> 필수</li>
            <li>• <strong>시담조서</strong>는 반드시 작성하여 보관</li>
          </ul>
        </div>

        <div class="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <h4 class="font-bold text-amber-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">warning</span>
            주의사항
          </h4>
          <ul class="space-y-1 text-amber-700">
            <li>• 시담 후에도 예정가격 초과 시 → <strong>유찰 처리</strong> 또는 재공고</li>
            <li>• 예정가격 공개 → <strong>감사 지적 사유</strong></li>
          </ul>
        </div>
      </div>
    TIPS
    interpretation_content: <<~INTERP,
## 행정안전부 유권해석

### 수의시담 관련 질의회신

**Q. 수의시담 후 재견적서 제출 시 최초 견적가격보다 높은 가격 제출 가능 여부**

A. 수의시담은 견적가격이 예정가격을 초과하는 경우 가격협상을 통해 예정가격 이하로 낮추기 위한 절차이므로, 재견적서는 최초 견적가격 이하로 제출하여야 합니다.

---

**Q. 수의시담 시 예정가격을 알려줄 수 있는지 여부**

A. 수의시담 시에도 예정가격은 비밀로 유지하여야 합니다. 예정가격을 공개하는 것은 계약의 공정성을 해치는 행위로 감사 지적 대상입니다.

---

**Q. 2인 견적 중 1인만 수의시담에 응한 경우 처리방법**

A. 2인 이상 견적 대상에서 1인만 수의시담에 응한 경우, 해당 업체의 재견적가격이 예정가격 이하이면 계약 체결이 가능합니다.
    INTERP
    audit_cases: <<~AUDIT,
## 수의시담 관련 감사사례

### 사례 1: 수의시담 2회 실시
**지적사항:** 수의시담을 2회 실시하여 계약 체결
**관련근거:** 지방자치단체 입찰 및 계약집행기준 제74조 제4항
**조치내용:** 관련자 주의, 제도개선

> 수의시담은 1회에 한하여 실시할 수 있음에도 불구하고, 1차 시담 후 예정가격 초과 시 2차 시담을 실시하여 계약을 체결한 사례

---

### 사례 2: 예정가격 사전 공개
**지적사항:** 수의시담 전 예정가격을 업체에 알려줌
**관련근거:** 지방계약법 시행령 제10조
**조치내용:** 관련자 경고, 변상 판단

> 계약담당자가 수의시담 전에 "이 금액 이하로 내야 계약이 된다"고 언급하여 예정가격을 간접 공개한 사례

---

### 사례 3: 시담조서 미작성
**지적사항:** 수의시담 진행 후 시담조서를 작성하지 않음
**관련근거:** 지방자치단체 입찰 및 계약집행기준 제74조
**조치내용:** 관련자 주의

> 수의시담을 구두로만 진행하고 시담조서를 작성하지 않아 절차 이행 여부 확인 불가
    AUDIT
    qa_content: <<~QA,
## 수의시담 질의답변

### Q1. 수의시담은 반드시 대면으로 해야 하나요?

**A:** 아니요. 수의시담은 대면, 유선, 서면 등 다양한 방법으로 진행할 수 있습니다. 다만, 어떤 방법이든 **시담조서를 반드시 작성**하여 기록으로 남겨야 합니다.

---

### Q2. 수의시담 후에도 예정가격을 초과하면?

**A:** 해당 건은 **유찰 처리**됩니다. 이후 다음 중 하나를 선택할 수 있습니다:
- 예정가격 재산정 후 재공고
- 설계변경 등을 통한 사업 범위 조정
- 사업 취소

---

### Q3. 1인 견적 대상에서도 수의시담이 가능한가요?

**A:** 네, 가능합니다. 1인 견적이든 2인 이상 견적이든, 견적가격이 예정가격을 초과하면 수의시담을 진행할 수 있습니다.

---

### Q4. 수의시담에서 가격 외에 다른 조건도 협상할 수 있나요?

**A:** 아니요. 수의시담은 **가격협상만** 가능합니다. 규격, 수량, 납품조건 등을 변경하는 것은 수의시담의 범위를 벗어납니다. 조건 변경이 필요하면 재공고해야 합니다.
    QA
    faqs: [
      { question: '수의시담은 몇 회까지 가능한가요?', answer: '수의시담은 1회에 한하여 가능합니다. 시담 후에도 예정가격을 초과하면 유찰 처리하거나 재공고해야 합니다.' },
      { question: '수의시담 시 예정가격을 공개해도 되나요?', answer: '아니요. 예정가격은 수의시담 시에도 비밀을 유지해야 합니다. 예정가격 공개는 감사 지적 사유입니다.' }
    ].to_json,
    published: true
  },
  {
    name: '1인견적',
    slug: 'single-quote',
    summary: '1인 견적에 의한 수의계약 (소액 수의계약)',
    keywords: '1인견적,단일견적,소액수의,견적서,1인수의',
    category: 'contract',
    law_content: <<~LAW,
      <strong>지방계약법 시행령 제25조 제1항 제1호</strong>

      추정가격이 다음 각 목의 금액 이하인 경우 수의계약 가능:
      <ul style="margin-top:8px;">
        <li>가. 공사: <strong>5천만원</strong></li>
        <li>나. 물품의 제조·구매, 용역: <strong>5천만원</strong></li>
      </ul>

      <hr style="margin:16px 0;">

      <strong>지방계약법 시행령 제30조 제2항</strong>

      다음 각 호의 경우에는 <mark>1인 견적에 의한 수의계약</mark> 가능:
      <ol style="margin-top:8px;">
        <li>1. 추정가격이 물품구매·용역·공사 <strong>2천만원 이하</strong>인 경우 (특례 기업 5천만원 이하)</li>
      </ol>
    LAW
    decree_content: <<~DECREE,
      <strong>지방자치단체 입찰 및 계약집행기준 제69조 (1인 견적)</strong>

      다음 각 호의 경우에는 <mark>1인의 견적서</mark>만으로 수의계약 가능:

      <div style="background:#f0fdf4; padding:16px; border-radius:8px; margin-top:12px;">
        <strong>1. 추정가격 기준</strong>
        <table style="width:100%; margin-top:8px; border-collapse:collapse;">
          <tr style="background:#dcfce7;">
            <th style="border:1px solid #86efac; padding:8px;">계약종류</th>
            <th style="border:1px solid #86efac; padding:8px;">1인 견적 한도</th>
          </tr>
          <tr>
            <td style="border:1px solid #86efac; padding:8px;">물품 구매</td>
            <td style="border:1px solid #86efac; padding:8px; font-weight:bold;">2천만원 이하</td>
          </tr>
          <tr>
            <td style="border:1px solid #86efac; padding:8px;">용역</td>
            <td style="border:1px solid #86efac; padding:8px; font-weight:bold;">2천만원 이하</td>
          </tr>
          <tr>
            <td style="border:1px solid #86efac; padding:8px;">공사</td>
            <td style="border:1px solid #86efac; padding:8px; font-weight:bold;">5,000만원 이하</td>
          </tr>
        </table>
      </div>

      <div style="margin-top:12px;">
        <strong>2. 그 외 1인 견적 가능 사유</strong>
        <ul style="margin-top:8px;">
          <li>• 특정인의 기술·품질이 필요한 경우</li>
          <li>• 국가유공자 등 우선구매 대상</li>
          <li>• 긴급한 재해복구 등</li>
        </ul>
      </div>
    DECREE
    rule_content: <<~RULE,
      <strong>1인 견적 수의계약 금액 기준 (지방계약법 시행령 제30조)</strong>

      <table style="width:100%; border-collapse:collapse; margin-top:12px;">
        <tr style="background:#dbeafe;">
          <th style="border:1px solid #93c5fd; padding:12px;">계약종류</th>
          <th style="border:1px solid #93c5fd; padding:12px;">1인 견적 한도</th>
          <th style="border:1px solid #93c5fd; padding:12px;">비고</th>
        </tr>
        <tr>
          <td style="border:1px solid #93c5fd; padding:12px;">물품 구매</td>
          <td style="border:1px solid #93c5fd; padding:12px; font-weight:bold; color:#1d4ed8;">2천만원 이하</td>
          <td style="border:1px solid #93c5fd; padding:12px; color:#6b7280;">특례기업 5천만원</td>
        </tr>
        <tr>
          <td style="border:1px solid #93c5fd; padding:12px;">용역</td>
          <td style="border:1px solid #93c5fd; padding:12px; font-weight:bold; color:#1d4ed8;">2천만원 이하</td>
          <td style="border:1px solid #93c5fd; padding:12px; color:#6b7280;">특례기업 5천만원</td>
        </tr>
        <tr>
          <td style="border:1px solid #93c5fd; padding:12px;">공사</td>
          <td style="border:1px solid #93c5fd; padding:12px; font-weight:bold; color:#1d4ed8;">2천만원 이하</td>
          <td style="border:1px solid #93c5fd; padding:12px; color:#6b7280;">특례기업 5천만원</td>
        </tr>
      </table>

      <div style="background:#e0f2fe; padding:12px; border-radius:8px; margin-top:16px;">
        <strong>📌 특례기업:</strong> 청년창업·여성·장애인기업 등은 5천만원 이하까지 1인 견적 가능
      </div>
    RULE
    practical_tips: <<~TIPS,
      <div class="space-y-4">
        <div class="bg-green-50 border border-green-200 rounded-xl p-4">
          <h4 class="font-bold text-green-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">check_circle</span>
            1인 견적 체크리스트
          </h4>
          <ul class="space-y-1 text-green-700">
            <li>☐ 추정가격이 기준금액 이하인가?</li>
            <li>☐ 견적서에 사업자등록번호 기재되었는가?</li>
            <li>☐ 견적서에 대표자 직인이 날인되었는가?</li>
            <li>☐ 예정가격 이하 금액인가?</li>
            <li>☐ 분할계약에 해당하지 않는가?</li>
          </ul>
        </div>

        <div class="bg-red-50 border border-red-200 rounded-xl p-4">
          <h4 class="font-bold text-red-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">gavel</span>
            감사 주의사항
          </h4>
          <ul class="space-y-1 text-red-700">
            <li>• <strong>동일업체 반복계약</strong> 주의 (유착 의심)</li>
            <li>• <strong>견적일자</strong>가 계약 전인지 확인</li>
            <li>• <strong>사업자등록증</strong> 유효기간 확인</li>
          </ul>
        </div>
      </div>
    TIPS
    interpretation_content: <<~INTERP,
## 1인 견적 관련 유권해석

### Q. 2천만원 이하 물품 구매 시 반드시 1인 견적으로 해야 하나요?

**A:** 아니요. 2천만원 이하는 1인 견적이 **가능**하다는 것이지 **의무**는 아닙니다. 2인 이상 견적을 받아도 됩니다. 오히려 경쟁을 통해 더 낮은 가격을 받을 수 있습니다.

---

### Q. 특례기업(청년창업, 여성기업 등) 5천만원 적용 시 증빙서류는?

**A:** 해당 기업이 특례 대상임을 증명하는 서류가 필요합니다:
- 청년창업기업: 중소벤처기업부 확인서
- 여성기업: 여성기업확인서
- 장애인기업: 장애인기업확인서
- 사회적기업: 사회적기업 인증서

---

### Q. 1인 견적 시 지정업체에만 견적을 요청해도 되나요?

**A:** 1인 견적이 가능한 금액이라도 특정 업체를 지정하여 견적을 받는 것은 바람직하지 않습니다. 가급적 공개적으로 견적을 요청하거나, 선정 사유를 명확히 기록해야 합니다.
    INTERP
    audit_cases: <<~AUDIT,
## 1인 견적 관련 감사사례

### 사례 1: 분할계약으로 1인 견적 적용
**지적사항:** 5천만원 물품을 2건으로 분할하여 각각 1인 견적으로 계약
**관련근거:** 지방계약법 시행령 제25조
**조치내용:** 변상판정, 관련자 중징계

> 동일 물품을 수량을 나누어 2,500만원씩 2건으로 분할계약하여 2인 이상 견적 의무를 회피한 사례

---

### 사례 2: 동일업체 반복 1인 견적 계약
**지적사항:** 특정 업체와 1년간 20회 이상 1인 견적 계약 반복
**관련근거:** 지방계약법 제5조(계약의 원칙)
**조치내용:** 관련자 경고, 업무개선

> 경쟁 없이 특정 업체와 반복적으로 수의계약을 체결하여 유착 의심

---

### 사례 3: 견적일자 소급 작성
**지적사항:** 계약 체결 후 견적서 일자를 소급하여 작성
**관련근거:** 지방계약법 시행령 제30조
**조치내용:** 관련자 중징계

> 이미 납품이 완료된 후 사후에 견적서를 징구하고 일자를 소급 기재
    AUDIT
    qa_content: <<~QA,
## 1인 견적 질의답변

### Q1. 1인 견적 수의계약도 계약서를 작성해야 하나요?

**A:** 추정가격 **5천만원 이하**(공사 1억원 이하)인 경우 계약서 작성을 생략할 수 있습니다. 다만, 청구서, 납품서 등으로 계약 내용을 확인할 수 있어야 합니다.

---

### Q2. 1인 견적도 예정가격을 작성해야 하나요?

**A:** **네, 반드시 작성해야 합니다.** 1인 견적이라도 예정가격 조서 작성은 필수입니다. 예정가격 미작성은 감사 지적 대상입니다.

---

### Q3. 견적서를 이메일로 받아도 되나요?

**A:** 네, 가능합니다. 다만 다음 사항을 확인하세요:
- 사업자등록번호 기재 여부
- 대표자 또는 권한 있는 자의 서명/날인
- 견적 유효기간

---

### Q4. 1인 견적 시 최저가가 아닌 업체와 계약해도 되나요?

**A:** 1인 견적이므로 비교 대상이 없어 "최저가" 개념이 적용되지 않습니다. 다만, **예정가격 이하**이어야 하며, 가격의 적정성을 검토해야 합니다.
    QA
    faqs: [
      { question: '1인 견적 한도는 얼마인가요?', answer: '물품·용역·공사 모두 2천만원 이하입니다. 단, 청년창업·여성·장애인기업 등 특례 대상은 5천만원 이하까지 1인 견적이 가능합니다.' },
      { question: '1인 견적 시에도 예정가격 작성이 필요한가요?', answer: '네, 1인 견적이라도 예정가격 조서 작성은 필수입니다. 예정가격 미작성은 감사 지적 사유입니다.' }
    ].to_json,
    published: true
  },
  {
    name: '2인견적',
    slug: 'dual-quote',
    summary: '2인 이상 견적에 의한 수의계약',
    keywords: '2인견적,복수견적,견적비교,2인이상,비교견적',
    category: 'contract',
    law_content: <<~LAW,
      <strong>지방계약법 시행령 제30조 제1항</strong>

      수의계약을 체결하려는 경우에는 계약담당자가 계약의 목적·성질·규모 등을 고려하여 필요하다고 인정하면 <mark>2인 이상</mark>으로부터 견적서를 받아 견적가격이 적정한지를 비교하여야 한다.

      <hr style="margin:16px 0;">

      <strong>지방계약법 시행령 제30조 제2항</strong>

      <strong>2인 이상 견적 필수 대상:</strong>
      <ul style="margin-top:8px;">
        <li>• 물품·용역: <strong>2천만원 초과 ~ 수의계약 한도</strong> (소기업 1억원, 특례 5천만원)</li>
        <li>• 공사: <strong>2천만원 초과 ~ 수의계약 한도</strong> (종합 4억, 전문 2억)</li>
      </ul>
    LAW
    decree_content: <<~DECREE,
      <strong>지방자치단체 입찰 및 계약집행기준 제70조 (2인 이상 견적)</strong>

      ① 계약담당자는 다음 각 호의 경우 <mark>2인 이상</mark>으로부터 견적서를 받아야 한다.

      <table style="width:100%; border-collapse:collapse; margin:12px 0;">
        <tr style="background:#e0e7ff;">
          <th style="border:1px solid #a5b4fc; padding:10px;">계약종류</th>
          <th style="border:1px solid #a5b4fc; padding:10px;">2인 이상 견적 대상</th>
        </tr>
        <tr>
          <td style="border:1px solid #a5b4fc; padding:10px;">물품 구매·용역</td>
          <td style="border:1px solid #a5b4fc; padding:10px; font-weight:bold;">2천만원 초과 ~ 5천만원</td>
        </tr>
        <tr>
          <td style="border:1px solid #a5b4fc; padding:10px;">공사</td>
          <td style="border:1px solid #a5b4fc; padding:10px; font-weight:bold;">5천만원 초과 ~ 2억원</td>
        </tr>
      </table>

      ② 견적서를 받은 경우 <strong>예정가격 이하 최저가 견적자</strong>를 계약상대자로 한다.

      <div style="background:#dbeafe; padding:12px; border-radius:8px; margin-top:12px;">
        ③ <strong>중요:</strong> 2인 이상에게 견적서 제출을 요청하였으나 <u>1인만 제출</u>한 경우에도 그 견적가격이 적정하다고 인정되면 <mark>계약 체결 가능</mark>
      </div>
    DECREE
    rule_content: <<~RULE,
      <strong>2인 이상 견적 수의계약 금액 기준</strong>

      <table style="width:100%; border-collapse:collapse; margin-top:12px;">
        <tr style="background:#fef3c7;">
          <th style="border:1px solid #fcd34d; padding:12px;">계약종류</th>
          <th style="border:1px solid #fcd34d; padding:12px;">2인 이상 견적 대상</th>
        </tr>
        <tr>
          <td style="border:1px solid #fcd34d; padding:12px;">물품 구매</td>
          <td style="border:1px solid #fcd34d; padding:12px; font-weight:bold;">2천만원 초과 ~ 5천만원</td>
        </tr>
        <tr>
          <td style="border:1px solid #fcd34d; padding:12px;">용역</td>
          <td style="border:1px solid #fcd34d; padding:12px; font-weight:bold;">2천만원 초과 ~ 5천만원</td>
        </tr>
        <tr>
          <td style="border:1px solid #fcd34d; padding:12px;">공사</td>
          <td style="border:1px solid #fcd34d; padding:12px; font-weight:bold;">5천만원 초과 ~ 2억원</td>
        </tr>
      </table>

      <div style="background:#d1fae5; padding:12px; border-radius:8px; margin-top:16px;">
        <strong>💡 핵심:</strong> 견적<strong>요청</strong>은 2인 이상, 견적<strong>제출</strong>은 1인이어도 가능!
      </div>
    RULE
    practical_tips: <<~TIPS,
      <div class="space-y-4">
        <div class="bg-indigo-50 border border-indigo-200 rounded-xl p-4">
          <h4 class="font-bold text-indigo-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">check_circle</span>
            2인 견적 체크리스트
          </h4>
          <ul class="space-y-1 text-indigo-700">
            <li>☐ 2개 업체 이상에 견적 요청했는가?</li>
            <li>☐ 견적 요청 시 동일한 조건을 제시했는가?</li>
            <li>☐ 견적 마감일시를 명확히 통보했는가?</li>
            <li>☐ 모든 견적서를 마감일 전에 받았는가?</li>
            <li>☐ 예정가격 이하 최저가 업체를 선정했는가?</li>
          </ul>
        </div>

        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">lightbulb</span>
            실무 팁
          </h4>
          <ul class="space-y-1 text-blue-700">
            <li>• <strong>견적요청서 발송 기록</strong> 보관 필수</li>
            <li>• 이메일/팩스 발송 시 발송 증빙 첨부</li>
            <li>• 1개 업체만 제출해도 계약 가능 <strong>(요청 증빙 필수)</strong></li>
          </ul>
        </div>
      </div>
    TIPS
    interpretation_content: <<~INTERP,
## 2인 견적 관련 유권해석

### Q. 2인 이상 견적 요청했으나 1인만 제출 시 계약 가능 여부

**A:** 2인 이상에게 견적서 제출을 **요청한 증빙**(이메일, 팩스 발송 기록 등)이 있으면 1인만 제출하더라도 계약 체결이 가능합니다. 단, 해당 견적가격이 적정하다고 인정되어야 합니다.

---

### Q. 동일 대표자가 운영하는 2개 업체 견적서로 2인 견적 가능 여부

**A:** 불가합니다. 실질적으로 동일인이 운영하는 업체의 견적은 1인 견적으로 간주됩니다. 사업자등록번호가 다르더라도 대표자가 동일하면 인정되지 않습니다.

---

### Q. 견적서 제출 후 가격 수정 요청 가능 여부

**A:** 견적 마감 전이라면 수정 제출이 가능합니다. 다만, 마감 후에는 수정이 불가하며, 예정가격 초과 시에만 **수의시담**을 통해 가격 협상이 가능합니다.
    INTERP
    audit_cases: <<~AUDIT,
## 2인 견적 관련 감사사례

### 사례 1: 견적 요청 증빙 없이 1인 견적 처리
**지적사항:** 2인 이상 견적 대상임에도 견적 요청 증빙 없이 1인 견적으로 계약
**관련근거:** 지방계약법 시행령 제30조
**조치내용:** 관련자 경고

> 4천만원 물품 구매 시 2인 이상 견적을 요청했다고 주장하나, 이메일/팩스 발송 기록 등 증빙자료가 없어 1인 견적으로 처리한 것으로 간주

---

### 사례 2: 형식적 2인 견적 (담합 의심)
**지적사항:** 2개 업체 견적가격이 동일하고 견적서 양식도 동일
**관련근거:** 지방계약법 제6조
**조치내용:** 수사기관 통보, 관련자 중징계

> A업체와 B업체의 견적가격이 원 단위까지 동일하고, 견적서 서식과 오타까지 같아 담합 의심

---

### 사례 3: 견적 마감 전 예정가격 정보 유출
**지적사항:** 특정 업체에게만 예정가격 정보를 알려줌
**관련근거:** 지방계약법 시행령 제10조
**조치내용:** 관련자 중징계, 변상 판단

> 2인 견적 진행 중 특정 업체에게 "○○만원 이하로 써야 된다"고 알려준 정황 확인
    AUDIT
    qa_content: <<~QA,
## 2인 견적 질의답변

### Q1. 꼭 2개 업체여야 하나요? 3개 이상도 가능한가요?

**A:** 2개 이상이면 됩니다. 3개, 4개 업체에서 견적을 받아도 문제없습니다. 오히려 더 많은 견적을 받으면 경쟁이 활성화되어 유리한 가격을 받을 수 있습니다.

---

### Q2. 2인 견적 시 예정가격 이하 업체가 없으면?

**A:** 예정가격 이하 견적자가 없으면 **수의시담**을 진행하거나, 예정가격을 재검토 후 **재공고**해야 합니다. 예정가격 초과 업체와 그냥 계약하면 안 됩니다.

---

### Q3. 견적서에 꼭 직인이 있어야 하나요?

**A:** 원칙적으로 대표자 또는 권한 있는 자의 **서명 또는 날인**이 필요합니다. 전자서명도 인정됩니다. 다만, 소액건의 경우 기관 내규에 따라 간소화할 수 있습니다.

---

### Q4. 견적 요청은 어떤 방법으로 해야 하나요?

**A:** 다음 방법 중 선택 가능합니다:
- 이메일 발송 (발송 기록 보관)
- 팩스 발송 (전송 확인서 보관)
- 우편 발송 (등기 우편 권장)
- 문자/카카오톡 (발송 기록 캡처 보관)
    QA
    faqs: [
      { question: '2인 이상 견적 요청했는데 1인만 제출하면 어떻게 하나요?', answer: '2인 이상에게 견적서 제출을 요청한 증빙이 있으면 1인만 제출하더라도 계약 체결이 가능합니다. 단, 견적 요청 발송 기록을 반드시 보관해야 합니다.' },
      { question: '동일 업체에서 두 개의 견적서를 제출받으면 2인 견적으로 인정되나요?', answer: '아니요. 서로 다른 2개 업체 이상에서 견적서를 받아야 합니다. 동일 업체의 복수 견적은 1인 견적으로 간주됩니다.' }
    ].to_json,
    published: true
  },
  {
    name: '수의계약 한도',
    slug: 'private-contract-limit',
    summary: '수의계약 체결이 가능한 추정가격 한도 기준',
    keywords: '수의계약한도,수의한도,금액기준,추정가격,기준금액',
    category: 'contract',
    law_content: <<~LAW,
      <strong>지방계약법 시행령 제25조 제1항 제1호 (수의계약 한도)</strong>

      추정가격이 다음 각 목의 금액 이하인 경우 수의계약 가능:

      <div style="background:#eff6ff; padding:16px; border-radius:8px; margin-top:12px;">
        <ul style="margin:0; line-height:2;">
          <li>가. 공사: <strong style="color:#1d4ed8; font-size:1.2em;">종합 4억원, 전문 2억원, 기타 1.6억원 이하</strong></li>
          <li>나. 물품의 제조·구매: <strong style="color:#1d4ed8; font-size:1.2em;">2천만원 이하</strong> (특례: 소기업 1억, 기타 5천만)</li>
          <li>다. 용역: <strong style="color:#1d4ed8; font-size:1.2em;">2천만원 이하</strong> (특례: 소기업 1억, 기타 5천만)</li>
        </ul>
      </div>

      <div style="background:#fef2f2; padding:12px; border-radius:8px; margin-top:16px;">
        <strong>⚠️ 주의:</strong> 동일 구조물의 공사, 동일 품목의 물품, 동일 성격의 용역은 <u>1건으로 보아</u> 추정가격을 산정하여야 함 <strong>(분할계약 금지)</strong>
      </div>
    LAW
    decree_content: <<~DECREE,
      <strong>수의계약 금액 기준 종합표</strong>

      <table style="width:100%; border-collapse:collapse; margin-top:12px;">
        <tr style="background:#1e3a5f; color:white;">
          <th style="border:1px solid #374151; padding:12px;">계약종류</th>
          <th style="border:1px solid #374151; padding:12px;">수의한도</th>
          <th style="border:1px solid #374151; padding:12px;">1인견적</th>
          <th style="border:1px solid #374151; padding:12px;">2인견적</th>
        </tr>
        <tr>
          <td style="border:1px solid #d1d5db; padding:12px; font-weight:bold;">물품구매</td>
          <td style="border:1px solid #d1d5db; padding:12px; color:#1d4ed8;">2천만원 (특례 1억)</td>
          <td style="border:1px solid #d1d5db; padding:12px;">2천만원 이하</td>
          <td style="border:1px solid #d1d5db; padding:12px;">2천만원 초과</td>
        </tr>
        <tr style="background:#f9fafb;">
          <td style="border:1px solid #d1d5db; padding:12px; font-weight:bold;">용역</td>
          <td style="border:1px solid #d1d5db; padding:12px; color:#1d4ed8;">2천만원 (특례 1억)</td>
          <td style="border:1px solid #d1d5db; padding:12px;">2천만원 이하</td>
          <td style="border:1px solid #d1d5db; padding:12px;">2천만원 초과</td>
        </tr>
        <tr>
          <td style="border:1px solid #d1d5db; padding:12px; font-weight:bold;">공사 (종합)</td>
          <td style="border:1px solid #d1d5db; padding:12px; color:#1d4ed8;">4억원</td>
          <td style="border:1px solid #d1d5db; padding:12px;">2천만원 이하</td>
          <td style="border:1px solid #d1d5db; padding:12px;">2천만~4억원</td>
        </tr>
      </table>
    DECREE
    rule_content: <<~RULE,
      <strong>추정가격 산정 시 포함/불포함 항목</strong>

      <div style="display:flex; gap:16px; margin-top:12px;">
        <div style="flex:1; background:#d1fae5; padding:16px; border-radius:8px;">
          <strong style="color:#065f46;">【포함】</strong>
          <ul style="margin-top:8px; color:#047857;">
            <li>• 물품가격, 용역대가, 공사비</li>
            <li>• 부가가치세 (부가세 포함 계약 시)</li>
          </ul>
        </div>
        <div style="flex:1; background:#fee2e2; padding:16px; border-radius:8px;">
          <strong style="color:#991b1b;">【불포함】</strong>
          <ul style="margin-top:8px; color:#dc2626;">
            <li>• 부가가치세 (부가세 별도 계약 시)</li>
            <li>• 관급자재비</li>
            <li>• 지급자재비</li>
          </ul>
        </div>
      </div>

      <div style="background:#fef3c7; padding:12px; border-radius:8px; margin-top:16px; text-align:center;">
        <strong>📌 추정가격 = 부가세 제외 금액</strong>
      </div>
    RULE
    practical_tips: <<~TIPS,
      <div class="space-y-4">
        <div class="bg-navy-50 border border-navy-200 rounded-xl p-4" style="background:#eff6ff;">
          <h4 class="font-bold text-navy-800 flex items-center gap-2 mb-3" style="color:#1e3a5f;">
            <span class="material-symbols-outlined">pin</span>
            핵심 금액 기준 (부가세 별도)
          </h4>
          <div class="grid grid-cols-2 gap-4">
            <div class="bg-white rounded-lg p-3 border">
              <div class="text-sm text-gray-500">물품/용역</div>
              <div class="text-lg font-bold text-blue-600">수의한도: 2천만원</div>
              <div class="text-xs text-gray-400 mt-1">특례: 소기업 1억, 기타 5천만</div>
            </div>
            <div class="bg-white rounded-lg p-3 border">
              <div class="text-sm text-gray-500">공사</div>
              <div class="text-lg font-bold text-blue-600">수의한도: 2억원</div>
              <div class="text-xs text-gray-400 mt-1">1인: 5천만원 / 2인: ~2억원</div>
            </div>
          </div>
        </div>

        <div class="bg-red-50 border border-red-200 rounded-xl p-4">
          <h4 class="font-bold text-red-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">dangerous</span>
            분할계약 절대 금지!
          </h4>
          <p class="text-red-700">1건의 계약을 2개 이상으로 분할하면 <strong>감사 1순위 지적 대상</strong>입니다.</p>
        </div>
      </div>
    TIPS
    interpretation_content: <<~INTERP,
## 수의계약 한도 관련 유권해석

### Q. 부가세 포함 5,500만원 물품, 수의계약 가능 여부

**A:** 가능합니다. 추정가격은 부가세를 제외한 금액으로 산정합니다.
- 부가세 포함 5,500만원 ÷ 1.1 = **5,000만원** (추정가격)
- 소기업·소상공인 대상 특례 적용 시 1억원까지 수의계약 가능

---

### Q. 연간 단가계약 시 수의계약 한도 적용 기준

**A:** 연간 단가계약의 경우 **연간 총 예정금액**으로 수의계약 한도를 판단합니다. 1회 발주금액이 아닌 전체 계약금액 기준입니다.

---

### Q. 종합공사와 전문공사 구분 기준

**A:** 건설산업기본법에 따릅니다:
- **종합공사:** 종합적인 계획·관리·조정이 필요한 공사 (4억원 이하)
- **전문공사:** 특정 분야의 전문기술이 필요한 공사 (2억원 이하)
    INTERP
    audit_cases: <<~AUDIT,
## 수의계약 한도 관련 감사사례

### 사례 1: 수의계약 한도 초과 계약
**지적사항:** 추정가격 5,500만원(부가세 별도) 물품을 수의계약으로 체결
**관련근거:** 지방계약법 시행령 제25조
**조치내용:** 계약 취소, 관련자 중징계

> 일반 물품(소기업 아님)의 수의계약 한도는 2천만원(특례 5천만원)인데, 5,500만원 물품을 수의계약으로 체결

---

### 사례 2: 추정가격 산정 오류
**지적사항:** 부가세 포함 금액을 추정가격으로 잘못 산정
**관련근거:** 지방계약법 시행령 제8조
**조치내용:** 관련자 주의

> 부가세 포함 2,100만원을 추정가격으로 보아 2인 이상 견적을 받았으나, 실제 추정가격은 약 1,909만원으로 1인 견적도 가능했음

---

### 사례 3: 특례기업 확인 없이 특례 적용
**지적사항:** 소기업 확인 없이 1억원 한도 적용
**관련근거:** 지방계약법 시행령 제25조
**조치내용:** 관련자 경고

> 업체가 소기업임을 확인하는 서류(중소기업확인서 등) 없이 1억원 한도 적용
    AUDIT
    qa_content: <<~QA,
## 수의계약 한도 질의답변

### Q1. 수의계약 한도는 부가세 포함인가요?

**A:** 아니요. **부가세 별도** 금액(추정가격)입니다.
- 예: 부가세 포함 2,200만원 = 추정가격 2,000만원 → 수의계약 가능

---

### Q2. 물품과 설치용역을 함께 발주하면 합산해야 하나요?

**A:** 물품과 용역이 **불가분의 관계**이면 합산합니다. 별개로 분리 가능하면 각각 계약할 수 있습니다.
- 합산 예: 에어컨 구매 + 설치용역
- 분리 예: 사무용품 구매 + 별도 청소용역

---

### Q3. 특례기업(소기업 등) 확인은 어떻게 하나요?

**A:** 다음 서류로 확인합니다:
- **중소기업확인서** (중소기업현황정보시스템)
- **소상공인확인서** (소상공인시장진흥공단)
- 유효기간 내 서류인지 반드시 확인

---

### Q4. 동일 사업인데 연도가 다르면 별개로 수의계약 가능한가요?

**A:** 아니요. 동일한 목적의 사업을 **연차별로 분리**하여 수의계약 한도 이하로 만드는 것은 **분할계약**에 해당합니다.
    QA
    faqs: [
      { question: '수의계약 한도 금액에 부가세가 포함되나요?', answer: '아니요. 수의계약 한도 금액은 부가세를 제외한 추정가격 기준입니다. 예를 들어 물품 구매 시 부가세 별도 4,500만원은 수의계약 가능합니다.' },
      { question: '설계용역과 공사를 합산해서 수의계약 한도를 산정하나요?', answer: '아니요. 설계용역과 공사는 별개의 계약이므로 각각 한도를 적용합니다. 단, 동일 용역을 분할하면 안 됩니다.' }
    ].to_json,
    published: true
  },
  {
    name: '수의계약 금액',
    slug: 'private-contract-amount',
    summary: '수의계약 금액 기준 및 견적 방법 총정리',
    keywords: '수의계약금액,금액기준,견적기준,계약금액,수의기준',
    category: 'contract',
    law_content: <<~LAW,
      <strong>지방계약법 시행령 제25조, 제30조 종합</strong>

      <div style="background:#eff6ff; padding:16px; border-radius:8px; margin-top:12px;">
        <strong>【수의계약 가능 금액】</strong> (추정가격 기준, 부가세 별도)
        <ul style="margin-top:8px;">
          <li>1. 물품 구매·용역: <strong style="color:#1d4ed8;">2천만원 이하</strong> (특례: 소기업 1억, 기타 5천만)</li>
          <li>2. 공사 (종합): <strong style="color:#1d4ed8;">4억원 이하</strong></li>
          <li>3. 공사 (전문): <strong style="color:#1d4ed8;">2억원 이하</strong></li>
          <li>4. 공사 (기타): <strong style="color:#1d4ed8;">1.6억원 이하</strong></li>
        </ul>
      </div>

      <div style="background:#f0fdf4; padding:16px; border-radius:8px; margin-top:16px;">
        <strong>【견적 방법별 금액 기준】</strong>

        <div style="margin-top:12px;">
          <strong>1. 1인 견적</strong>
          <ul>
            <li>• 물품·용역·공사: <mark>2천만원 이하</mark> (특례기업 5천만원)</li>
          </ul>
        </div>

        <div style="margin-top:12px;">
          <strong>2. 2인 이상 견적</strong>
          <ul>
            <li>• 물품·용역: <mark>2천만원 초과 ~ 수의계약 한도</mark></li>
            <li>• 공사: <mark>2천만원 초과 ~ 수의계약 한도</mark></li>
          </ul>
        </div>
      </div>
    LAW
    decree_content: <<~DECREE,
      <strong>금액별 계약 방법 결정 플로우</strong>

      <div style="margin-top:16px;">
        <strong style="color:#4f46e5;">📦 [물품/용역]</strong>
        <div style="background:#eef2ff; padding:16px; border-radius:8px; margin-top:8px; font-family:monospace;">
          ├─ 200만원 미만 → <strong>카드결제</strong> (계약서 생략 가능)<br>
          ├─ 200만원 ~ 2천만원 → <strong>1인 견적</strong> 수의계약<br>
          ├─ 2천만원 초과 ~ 한도 → <strong>2인 이상 견적</strong> 수의계약<br>
          └─ 한도 초과 → <strong>경쟁입찰</strong><br>
          (한도: 일반 2천만원, 특례 5천만원~1억원)
        </div>
      </div>

      <div style="margin-top:16px;">
        <strong style="color:#059669;">🏗️ [공사 - 종합공사 기준]</strong>
        <div style="background:#ecfdf5; padding:16px; border-radius:8px; margin-top:8px; font-family:monospace;">
          ├─ 200만원 미만 → <strong>카드결제</strong> (계약서 생략 가능)<br>
          ├─ 200만원 ~ 2천만원 → <strong>1인 견적</strong> 수의계약<br>
          ├─ 2천만원 ~ 4억원 → <strong>2인 이상 견적</strong> 수의계약<br>
          └─ 4억원 초과 → <strong>경쟁입찰</strong>
        </div>
      </div>
    DECREE
    rule_content: '',
    practical_tips: <<~TIPS,
      <div class="space-y-4">
        <div class="bg-purple-50 border border-purple-200 rounded-xl p-4">
          <h4 class="font-bold text-purple-800 flex items-center gap-2 mb-3">
            <span class="material-symbols-outlined">calculate</span>
            금액 판단 실무 예시
          </h4>

          <div class="space-y-3">
            <div class="bg-white rounded-lg p-3 border-l-4 border-green-500">
              <div class="font-medium text-green-700">Q. 부가세 포함 2,100만원 물품 구매, 1인 견적 가능?</div>
              <div class="text-green-600 mt-1">A. <strong>가능!</strong> 추정가격 = 2,100 ÷ 1.1 = 약 1,909만원 (2천만원 이하)</div>
            </div>

            <div class="bg-white rounded-lg p-3 border-l-4 border-red-500">
              <div class="font-medium text-red-700">Q. 부가세 포함 2,300만원 물품 구매, 1인 견적 가능?</div>
              <div class="text-red-600 mt-1">A. <strong>불가!</strong> 추정가격 = 2,300 ÷ 1.1 = 약 2,090만원 (2천만원 초과) → 2인 이상 견적 필요</div>
            </div>
          </div>
        </div>

        <div class="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <h4 class="font-bold text-amber-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">warning</span>
            주의
          </h4>
          <p class="text-amber-700">"부가세 포함 5천만원" 기준이 아닙니다!<br><strong>"부가세 별도 5,000만원"</strong> 기준입니다.</p>
        </div>
      </div>
    TIPS
    interpretation_content: <<~INTERP,
## 수의계약 금액 관련 유권해석

### Q. 부가세 포함/별도 구분 기준

**A:** 수의계약 금액 기준은 항상 **부가세 별도**(추정가격)입니다.
- 부가세 포함 금액 ÷ 1.1 = 추정가격
- 예: 부가세 포함 2,200만원 → 추정가격 2,000만원

---

### Q. 옵션 포함 시 금액 산정

**A:** 옵션이 **필수**인 경우 본체+옵션 합산 금액으로 산정합니다. 선택 옵션은 별도 계약 가능합니다.

---

### Q. 운반비, 설치비 포함 여부

**A:** 물품 구매 시 **운반비, 설치비**가 불가분인 경우 합산하여 추정가격을 산정합니다.
    INTERP
    audit_cases: <<~AUDIT,
## 수의계약 금액 관련 감사사례

### 사례 1: 추정가격 계산 오류로 계약방법 잘못 적용
**지적사항:** 부가세 포함 금액을 추정가격으로 착오하여 계약방법 결정
**관련근거:** 지방계약법 시행령 제8조
**조치내용:** 관련자 주의

> 부가세 포함 2,500만원을 추정가격으로 보아 2인 이상 견적을 받았으나, 실제 추정가격은 약 2,273만원임

---

### 사례 2: 금액 조정을 통한 수의계약 전환
**지적사항:** 입찰 대상 사업을 수의계약 한도 이하로 조정하여 수의계약 체결
**관련근거:** 지방계약법 제9조
**조치내용:** 관련자 경고, 업무개선

> 당초 6천만원으로 설계된 용역을 4,900만원으로 축소하여 수의계약으로 전환
    AUDIT
    qa_content: <<~QA,
## 수의계약 금액 질의답변

### Q1. 금액별 계약방법을 간단히 알려주세요

**A:** 물품/용역 기준 (부가세 별도):
| 금액 | 계약방법 |
|------|----------|
| 200만원 미만 | 카드결제 가능 |
| 2천만원 이하 | 1인 견적 |
| 2천만원 초과~한도 | 2인 이상 견적 |
| 한도 초과 | 경쟁입찰 |

---

### Q2. 200만원 미만이면 계약서 없이 결제해도 되나요?

**A:** 네, **카드결제**가 가능하고 계약서 작성을 생략할 수 있습니다. 다만, 청구서/납품서 등 증빙은 보관해야 합니다.

---

### Q3. 추정가격이 정확히 2천만원이면 1인 견적인가요?

**A:** 네, **2천만원 이하**이므로 1인 견적이 가능합니다. "이하"는 해당 금액을 포함합니다.
    QA
    faqs: [
      { question: '수의계약 금액은 부가세 포함인가요, 별도인가요?', answer: '수의계약 금액 기준은 부가세 별도(추정가격) 기준입니다. 부가세 포함 금액으로 판단하면 안 됩니다.' },
      { question: '부가세 포함 5천만원이면 수의계약이 가능한가요?', answer: '네, 가능합니다. 부가세 포함 5천만원 ÷ 1.1 = 약 5,000만원(추정가격)이므로 물품·용역 수의계약 한도 이내입니다.' }
    ].to_json,
    published: true
  },
  {
    name: '소액수의',
    slug: 'small-amount-contract',
    summary: '소액 수의계약 (추정가격 기준 수의계약)',
    keywords: '소액수의,소액수의계약,추정가격,금액기준,소액',
    category: 'contract',
    law_content: <<~LAW,
      <strong>지방계약법 제9조 (수의계약)</strong>

      <div style="background:#dbeafe; padding:16px; border-radius:8px; margin-top:12px;">
        지방자치단체의 장 또는 계약담당자는 계약의 목적·성질·규모 등을 고려하여 필요하다고 인정되면 <strong>대통령령으로 정하는 바에 따라</strong> 수의계약을 할 수 있다.
      </div>

      <div style="background:#f3f4f6; padding:12px; border-radius:8px; margin-top:16px;">
        <strong>📌 위임 사항:</strong> 구체적인 수의계약 금액 기준은 <strong>시행령 제25조</strong>에서 규정
      </div>
    LAW
    decree_content: <<~DECREE,
      <strong>지방계약법 시행령 제25조 (수의계약의 범위)</strong>

      <div style="background:#dbeafe; padding:16px; border-radius:8px; margin-top:12px;">
        <strong>제1항 제1호 【소액 수의계약 기본 한도】</strong>

        <p style="margin-top:8px;">추정가격이 다음 금액 이하인 계약:</p>

        <table style="width:100%; border-collapse:collapse; margin-top:12px;">
          <tr style="background:#1e3a5f; color:white;">
            <th style="border:1px solid #374151; padding:12px;">구분</th>
            <th style="border:1px solid #374151; padding:12px;">금액</th>
          </tr>
          <tr>
            <td style="border:1px solid #d1d5db; padding:12px;">공사</td>
            <td style="border:1px solid #d1d5db; padding:12px;"><strong style="color:#2563eb;">2억원 이하</strong></td>
          </tr>
          <tr style="background:#f9fafb;">
            <td style="border:1px solid #d1d5db; padding:12px;">물품·용역</td>
            <td style="border:1px solid #d1d5db; padding:12px;"><strong style="color:#2563eb;">5천만원 이하</strong></td>
          </tr>
        </table>
      </div>

      <div style="background:#fef3c7; padding:16px; border-radius:8px; margin-top:16px;">
        <strong>2025~2026년 한시적 특례</strong>

        <table style="width:100%; border-collapse:collapse; margin-top:12px;">
          <tr style="background:#92400e; color:white;">
            <th style="border:1px solid #d97706; padding:12px;">구분</th>
            <th style="border:1px solid #d97706; padding:12px;">특례 금액</th>
          </tr>
          <tr>
            <td style="border:1px solid #fcd34d; padding:12px;">공사</td>
            <td style="border:1px solid #fcd34d; padding:12px;"><strong style="color:#b45309;">4억원 이하</strong></td>
          </tr>
          <tr style="background:#fef9c3;">
            <td style="border:1px solid #fcd34d; padding:12px;">물품·용역</td>
            <td style="border:1px solid #fcd34d; padding:12px;"><strong style="color:#b45309;">1억원 이하</strong></td>
          </tr>
        </table>
      </div>

      <div style="background:#f3f4f6; padding:12px; border-radius:8px; margin-top:16px;">
        <strong>📌 소액수의 vs 특명수의</strong>
        <ul style="margin-top:8px; line-height:1.8;">
          <li><strong>소액수의:</strong> 금액 기준 → 시행령 §25①<strong>1</strong>호</li>
          <li><strong>특명수의:</strong> 특수 사유 (긴급, 특허 등) → 시행령 §25①<strong>2~6</strong>호</li>
        </ul>
      </div>
    DECREE
    rule_content: '',
    practical_tips: <<~TIPS,
      <div class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">checklist</span>
            소액수의 체크리스트
          </h4>

          <div class="space-y-3 mt-3">
            <div>
              <strong class="text-blue-700">1. 추정가격 산정</strong>
              <ul class="text-blue-600 text-sm mt-1">
                <li>☐ 부가세 별도 금액으로 산정했는가?</li>
                <li>☐ 관급자재비 제외했는가?</li>
                <li>☐ 분할계약에 해당하지 않는가?</li>
              </ul>
            </div>

            <div>
              <strong class="text-blue-700">2. 견적 방법 결정</strong>
              <ul class="text-blue-600 text-sm mt-1">
                <li>☐ 1인 견적 대상인가? (물품·용역 2천만원, 공사 5천만원)</li>
                <li>☐ 2인 견적 대상인가? (그 이상)</li>
              </ul>
            </div>

            <div>
              <strong class="text-blue-700">3. 서류 구비</strong>
              <ul class="text-blue-600 text-sm mt-1">
                <li>☐ 수의계약 사유서 작성</li>
                <li>☐ 예정가격 조서 작성</li>
                <li>☐ 견적서 징구</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    TIPS
    interpretation_content: <<~INTERP,
## 소액수의 관련 유권해석

### Q. 소액수의와 특명수의의 차이

**A:**
- **소액수의:** 추정가격이 일정 금액 이하 → 시행령 제25조 제1항 **제1호**
- **특명수의:** 특수 사유(긴급, 특허 등) → 시행령 제25조 제1항 **제2~6호**

---

### Q. 소액수의 시 사유서에 기재할 내용

**A:** 다음과 같이 기재합니다:
> "지방계약법 시행령 제25조 제1항 제1호에 따라 추정가격 ○○만원으로 소액수의계약 체결"

---

### Q. 소액수의도 계약보증금이 필요한가요?

**A:** 추정가격 **5천만원 이하**(공사 1억원 이하)인 경우 계약보증금 납부를 면제할 수 있습니다.
    INTERP
    audit_cases: <<~AUDIT,
## 소액수의 관련 감사사례

### 사례 1: 소액수의 사유서 미작성
**지적사항:** 소액수의계약 시 수의계약 사유서를 작성하지 않음
**관련근거:** 지방계약법 시행규칙 제26조
**조치내용:** 관련자 주의

> 2천만원 이하 물품 구매 시에도 수의계약 사유서는 반드시 작성해야 함

---

### 사례 2: 소액 분할계약
**지적사항:** 8천만원 물품을 4건(각 2천만원)으로 분할하여 소액수의 적용
**관련근거:** 지방계약법 시행령 제25조
**조치내용:** 변상판정, 관련자 중징계

> 동일 품목을 의도적으로 분할하여 소액수의 한도 이하로 만든 사례
    AUDIT
    qa_content: <<~QA,
## 소액수의 질의답변

### Q1. 소액수의 범위는 어떻게 되나요?

**A:** 추정가격(부가세 별도) 기준:
- **물품/용역:** 2천만원 이하 (1인 견적), 5천만원 이하 (2인 견적, 특례)
- **공사:** 2천만원 이하 (1인 견적), 2억원 이하 (2인 견적)

---

### Q2. 소액수의도 예정가격 조서를 작성해야 하나요?

**A:** **네, 반드시 작성해야 합니다.** 금액과 관계없이 예정가격 조서 작성은 필수입니다.

---

### Q3. 소액수의 시 계약서 생략이 가능한가요?

**A:** 추정가격 **5천만원 이하**(공사 1억원 이하)인 경우 계약서 작성을 생략할 수 있습니다. 다만, 청구서/납품서 등 증빙 보관은 필수입니다.
    QA
    faqs: [
      { question: '소액수의와 특명수의의 차이점은 무엇인가요?', answer: '소액수의는 추정가격이 일정 금액 이하일 때 가능한 수의계약이고, 특명수의는 긴급, 특허, 국가유공자 등 특수한 사유가 있을 때 가능한 수의계약입니다.' },
      { question: '소액수의도 수의계약 사유서를 작성해야 하나요?', answer: '네, 소액수의도 수의계약 사유서를 작성해야 합니다. 사유서에는 "지방계약법 시행령 제25조 제1항 제1호에 따른 소액수의"라고 기재합니다.' }
    ].to_json,
    published: true
  },
  {
    name: '긴급수의',
    slug: 'emergency-contract',
    summary: '긴급한 사유로 인한 수의계약 (특명수의)',
    keywords: '긴급수의,긴급계약,특명수의,재해복구,긴급',
    category: 'contract',
    law_content: <<~LAW,
      <strong>지방계약법 시행령 제25조 제1항 제4호</strong>

      다음 각 목의 경우에는 수의계약을 할 수 있다:

      <div style="background:#fef2f2; padding:16px; border-radius:8px; margin-top:12px;">
        <strong>가.</strong> <mark>천재지변</mark>, 작전상의 병력이동, <mark>긴급한 행사</mark>, 원자재의 가격급등 그 밖에 이에 준하는 경우로서 <strong>경쟁에 부칠 여유가 없는 경우</strong>

        <br><br>

        <strong>나.</strong> 국가기관, 다른 지방자치단체와 계약을 하는 경우

        <br><br>

        <strong>다.</strong> 특정인의 기술, 용역 또는 특정위치에 있는 물건 등이 계약의 목적 달성에 필수적인 경우
      </div>
    LAW
    decree_content: <<~DECREE,
      <strong>긴급수의 인정 사례</strong>

      <div style="display:flex; gap:16px; margin-top:12px;">
        <div style="flex:1; background:#d1fae5; padding:16px; border-radius:8px;">
          <strong style="color:#065f46;">✓ 인정되는 경우</strong>
          <ul style="margin-top:8px; color:#047857;">
            <li>• 자연재해(태풍, 지진, 폭우 등) 복구</li>
            <li>• 긴급 행사 개최 (국가적 행사 등)</li>
            <li>• 시설물 긴급 보수 (안전사고 우려)</li>
            <li>• 감염병 대응 물품 긴급 구매</li>
          </ul>
        </div>
        <div style="flex:1; background:#fee2e2; padding:16px; border-radius:8px;">
          <strong style="color:#991b1b;">✗ 인정되지 않는 경우</strong>
          <ul style="margin-top:8px; color:#dc2626;">
            <li>• 단순한 업무 지연으로 인한 긴급</li>
            <li>• 예산 집행 시한 촉박</li>
            <li>• 사전에 예측 가능한 행사</li>
            <li>• 담당자 변경으로 인한 지연</li>
          </ul>
        </div>
      </div>
    DECREE
    rule_content: <<~RULE,
      <strong>긴급수의 계약 절차</strong>

      <div style="background:#fef3c7; padding:16px; border-radius:8px; margin-top:12px;">
        <ol style="margin:0; padding-left:20px; line-height:2;">
          <li><strong>1단계:</strong> 긴급 사유 발생 확인
            <ul style="color:#92400e; font-size:0.9em;">
              <li>- 객관적으로 긴급성 입증 가능해야 함</li>
            </ul>
          </li>
          <li><strong>2단계:</strong> 수의계약 사유서 작성
            <ul style="color:#92400e; font-size:0.9em;">
              <li>- 긴급 사유 상세 기재</li>
              <li>- 경쟁입찰 불가 사유 명시</li>
            </ul>
          </li>
          <li><strong>3단계:</strong> 견적서 징구
            <ul style="color:#92400e; font-size:0.9em;">
              <li>- 긴급 시 1인 견적 가능</li>
              <li>- 단, 가능한 경우 2인 이상 권장</li>
            </ul>
          </li>
          <li><strong>4단계:</strong> 계약 체결
            <ul style="color:#92400e; font-size:0.9em;">
              <li>- 신속하게 진행</li>
              <li>- 서류는 사후 보완 가능 (단, 계약 전 결재 필수)</li>
            </ul>
          </li>
        </ol>
      </div>
    RULE
    practical_tips: <<~TIPS,
      <div class="space-y-4">
        <div class="bg-red-50 border border-red-200 rounded-xl p-4">
          <h4 class="font-bold text-red-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">gavel</span>
            긴급수의 감사 대비 체크리스트
          </h4>
          <ul class="space-y-1 text-red-700">
            <li>☐ 긴급 사유가 객관적으로 입증 가능한가?</li>
            <li>☐ 긴급 사유 발생 일시를 기록했는가?</li>
            <li>☐ 경쟁입찰로 진행할 수 없는 이유가 명확한가?</li>
            <li>☐ 긴급 사유 관련 증빙자료(공문, 보도자료 등)가 있는가?</li>
            <li>☐ 결재는 계약 체결 전에 받았는가?</li>
          </ul>
        </div>

        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">lightbulb</span>
            실무 팁
          </h4>
          <ul class="space-y-1 text-blue-700">
            <li>• <strong>"긴급"</strong>이라는 단어만으로는 부족</li>
            <li>• 왜 <strong>경쟁입찰이 불가능한지</strong> 구체적으로 기재</li>
            <li>• 사전 예측 가능했던 업무는 <strong>긴급수의 불인정</strong></li>
          </ul>
        </div>
      </div>
    TIPS
    interpretation_content: <<~INTERP,
## 긴급수의 관련 유권해석

### Q. "긴급"의 판단 기준

**A:** 다음 요건을 모두 충족해야 합니다:
1. **예측 불가능성:** 사전에 예측할 수 없었던 상황
2. **시간적 긴박성:** 경쟁입찰을 진행할 시간적 여유가 없음
3. **객관적 증명:** 긴급성을 객관적으로 입증할 수 있어야 함

---

### Q. 코로나19 등 감염병 대응 물품 구매 시 긴급수의 가능 여부

**A:** 가능합니다. 감염병 확산 방지를 위한 긴급한 물품 구매는 긴급수의 사유에 해당합니다. 다만, 사유서에 긴급성을 구체적으로 기재해야 합니다.

---

### Q. 긴급수의 시 금액 제한이 있나요?

**A:** 긴급수의는 금액 제한 없이 가능합니다. 다만, 긴급성이 인정되어야 하며, 금액이 클수록 긴급성 입증이 더욱 중요합니다.
    INTERP
    audit_cases: <<~AUDIT,
## 긴급수의 관련 감사사례

### 사례 1: 예산 마감 임박을 긴급 사유로 주장
**지적사항:** 예산 집행 시한 촉박을 이유로 긴급수의 체결
**관련근거:** 지방계약법 시행령 제25조
**조치내용:** 관련자 경고, 업무개선

> 예산 마감은 사전에 예측 가능한 사항으로 긴급수의 사유 불인정

---

### 사례 2: 담당자 변경으로 인한 업무 지연
**지적사항:** 담당자 휴직으로 업무가 지연되어 긴급수의 체결
**관련근거:** 지방계약법 시행령 제25조
**조치내용:** 관련자 주의

> 내부 사정에 의한 지연은 긴급수의 사유로 인정되지 않음

---

### 사례 3: 정당한 긴급수의 (적정 사례)
**내용:** 태풍 피해 복구를 위한 긴급 자재 구매
**관련근거:** 지방계약법 시행령 제25조 제1항 제4호
**결과:** 적정 처리

> 자연재해 복구는 긴급수의의 정당한 사유에 해당
    AUDIT
    qa_content: <<~QA,
## 긴급수의 질의답변

### Q1. 긴급수의로 인정되는 사유는?

**A:** 대표적인 긴급수의 인정 사유:
- 천재지변(태풍, 지진, 폭우 등) 복구
- 긴급한 국가/지자체 행사
- 시설물 안전사고 우려 시 긴급 보수
- 감염병 대응 물품 긴급 구매
- 작전상 병력 이동

---

### Q2. 긴급수의로 인정되지 않는 사유는?

**A:** 다음은 긴급수의 불인정:
- 담당자 업무 지연/태만
- 예산 집행 시한 촉박
- 사전 예측 가능한 정기 행사
- 단순한 업무 편의

---

### Q3. 긴급수의 시 결재는 언제 받아야 하나요?

**A:** **반드시 계약 체결 전**에 결재를 받아야 합니다. 서류 일부는 사후 보완이 가능하나, 결재 없이 계약 체결은 불가합니다.

---

### Q4. 긴급수의도 예정가격 작성이 필요한가요?

**A:** **네, 필수입니다.** 다만, 시간적 여유가 없는 경우 간략하게 작성하고 사후 보완할 수 있습니다.
    QA
    faqs: [
      { question: '예산 집행 마감이 임박하면 긴급수의가 가능한가요?', answer: '아니요. 예산 집행 마감 임박은 긴급수의 사유로 인정되지 않습니다. 이는 사전에 예측 가능한 상황이므로 일반적인 계약 절차를 진행해야 합니다.' },
      { question: '긴급수의 시에도 예정가격 작성이 필요한가요?', answer: '네, 긴급수의라도 예정가격 조서 작성은 필수입니다. 다만, 시간적 여유가 없는 경우 간략하게 작성하고 사후 보완할 수 있습니다.' }
    ].to_json,
    published: true
  }
]

subtopics_data.each do |data|
  topic = Topic.find_or_initialize_by(slug: data[:slug])
  topic.assign_attributes(data.merge(parent_id: parent.id))
  topic.save!
  puts "✓ 서브토픽 생성/업데이트: #{topic.name}"
end

puts "\n총 #{subtopics_data.count}개의 서브토픽이 생성/업데이트되었습니다."
