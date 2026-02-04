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
      <strong>지방계약법 시행령 제30조 (수의계약의 방법)</strong>

      ① 수의계약을 체결하려는 경우에는 계약담당자가 계약의 목적·성질·규모 등을 고려하여 필요하다고 인정하면 <mark>2인 이상으로부터 견적서를 받아</mark> 견적가격이 적정한지를 비교하여야 한다.

      ② 견적서를 받은 경우에는 <mark>예정가격 이하로서 최저가격으로 견적한 자</mark>를 계약상대자로 한다.
    LAW
    decree_content: <<~DECREE,
      <strong>지방자치단체 입찰 및 계약집행기준 제74조 (수의시담)</strong>

      ① 계약담당자가 제70조에 따른 견적서를 받은 경우에는 그 견적가격이 적정한지를 비교하여야 한다.

      ② 계약담당자는 견적가격이 <strong>예정가격을 초과</strong>하거나 가격이 적정하지 아니하다고 인정하는 경우에는 <mark>수의시담에 응할 것을 요청</mark>할 수 있다.

      ③ 수의시담에 응한 자 중 <strong>예정가격 이하의 최저가격 견적자</strong>를 계약상대자로 결정한다.
    DECREE
    rule_content: <<~RULE,
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
    RULE
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
          <p class="text-amber-700">"부가세 포함 5,500만원" 기준이 아닙니다!<br><strong>"부가세 별도 5,000만원"</strong> 기준입니다.</p>
        </div>
      </div>
    TIPS
    faqs: [
      { question: '수의계약 금액은 부가세 포함인가요, 별도인가요?', answer: '수의계약 금액 기준은 부가세 별도(추정가격) 기준입니다. 부가세 포함 금액으로 판단하면 안 됩니다.' },
      { question: '부가세 포함 5,500만원이면 수의계약이 가능한가요?', answer: '네, 가능합니다. 부가세 포함 5,500만원 ÷ 1.1 = 약 5,000만원(추정가격)이므로 물품·용역 수의계약 한도 이내입니다.' }
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
      <strong>지방계약법 시행령 제25조 제1항 제1호</strong>

      <div style="background:#dbeafe; padding:16px; border-radius:8px; margin-top:12px;">
        <strong>【소액 수의계약 (추정가격 기준)】</strong>

        추정가격이 다음 금액 이하인 계약은 수의계약으로 할 수 있다:

        <ul style="margin-top:12px; line-height:2;">
          <li>가. 공사: <strong style="font-size:1.1em;">2억원</strong></li>
          <li>나. 물품의 제조·구매: <strong style="font-size:1.1em;">5천만원</strong></li>
          <li>다. 용역: <strong style="font-size:1.1em;">5천만원</strong></li>
        </ul>
      </div>

      <div style="background:#f3f4f6; padding:12px; border-radius:8px; margin-top:16px;">
        <strong>📌 참고:</strong> 소액수의 = 금액 기준에 따른 수의계약 (특명수의와 구분됨)
      </div>
    LAW
    decree_content: <<~DECREE,
      <strong>소액수의 vs 특명수의 비교</strong>

      <table style="width:100%; border-collapse:collapse; margin-top:12px;">
        <tr style="background:#1e3a5f; color:white;">
          <th style="border:1px solid #374151; padding:12px;">구분</th>
          <th style="border:1px solid #374151; padding:12px;">소액수의</th>
          <th style="border:1px solid #374151; padding:12px;">특명수의</th>
        </tr>
        <tr>
          <td style="border:1px solid #d1d5db; padding:12px; font-weight:bold;">근거</td>
          <td style="border:1px solid #d1d5db; padding:12px;">시행령 §25①<strong>1</strong>호</td>
          <td style="border:1px solid #d1d5db; padding:12px;">시행령 §25①<strong>2~6</strong>호</td>
        </tr>
        <tr style="background:#f9fafb;">
          <td style="border:1px solid #d1d5db; padding:12px; font-weight:bold;">조건</td>
          <td style="border:1px solid #d1d5db; padding:12px;">추정가격이 일정 금액 이하</td>
          <td style="border:1px solid #d1d5db; padding:12px;">특수 사유 (긴급, 특허 등)</td>
        </tr>
        <tr>
          <td style="border:1px solid #d1d5db; padding:12px; font-weight:bold;">견적</td>
          <td style="border:1px solid #d1d5db; padding:12px;">금액에 따라 1인/2인</td>
          <td style="border:1px solid #d1d5db; padding:12px;">사유에 따라 1인 가능</td>
        </tr>
      </table>
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
