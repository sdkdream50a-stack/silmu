# Created: 2026-02-18 20:00
# 계약 카테고리 추가 토픽 8개

topics = [
  {
    slug: "advance-payment",
    name: "선금(선급금)",
    category: "contract",
    published: true,
    summary: "계약 이행 전 미리 지급하는 선금(선급금)의 지급 요건, 요율, 정산 절차를 안내합니다. 공사·용역·물품 계약별 선금 한도와 사용 제한, 환수 기준까지 실무 중심으로 정리합니다.",
    keywords: "선금,선급금,선금지급,선금요율,선금정산,선금환수,계약선금,공사선금",
    law_content: <<~CONTENT,
      ## 지방계약법 제17조 (선금)

      **지방계약법 제17조 (선금)**

      <div style="background:#dbeafe;padding:12px;border-radius:8px;margin:8px 0;">
      ① 지방자치단체의 장 또는 계약담당자는 공사·제조·용역 등의 계약에서 계약상대자의 계약이행을 지원하기 위하여 필요한 경우에는 계약금액의 범위에서 선금을 지급할 수 있다.

      ② 선금의 지급 비율·방법 및 정산 등에 필요한 사항은 대통령령으로 정한다.
      </div>

      <div style="background:#eff6ff;padding:12px;border-radius:8px;margin:8px 0;">
      ■ 위임 체계
      법률은 "선금을 지급할 수 있다"는 재량 규정으로, 구체적인 지급 비율·방법·정산은 시행령에 위임합니다. 강제 의무가 아닌 지방자치단체장의 재량으로 운영됩니다.
      </div>

      <div style="background:#f3f4f6;padding:12px;border-radius:8px;margin:8px 0;">
      ※ 관련 법령: 지방계약법 시행령 제63조~제65조, 시행규칙 제56조~제58조
      </div>
    CONTENT
    decree_content: <<~CONTENT,
      ## 지방계약법 시행령 제63조~제65조 (선금 지급 기준)

      **지방계약법 시행령 제63조 (선금 지급 비율)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      ① 선금 지급 비율 (계약금액 대비)

      | 계약 유형 | 선금 지급 한도 |
      |-----------|---------------|
      | 공사 계약 | 계약금액의 70% 이내 |
      | 제조·구매 | 계약금액의 70% 이내 |
      | 용역 계약 | 계약금액의 70% 이내 |
      | 학술·연구 | 계약금액의 50% 이내 |

      ② 선금 지급은 계약담당자가 계약상대자의 신청에 의하여 지급하며, 계약상대자는 선금보증서를 제출하여야 한다.
      </div>

      **지방계약법 시행령 제64조 (선금 사용 제한)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      선금은 해당 계약의 이행에만 사용하여야 하며, 다음 각 호의 용도에 우선 사용하여야 한다.
      1. 노임 지급
      2. 자재 구입
      3. 외주비 지급
      4. 그 밖에 계약 이행에 직접 필요한 경비
      </div>

      **지방계약법 시행령 제65조 (선금 정산)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      ① 선금은 기성금(기성대가) 지급 시 정산하되, 정산 비율은 지급된 선금 비율 이상으로 한다.
      ② 계약이 해제·해지되거나 이행이 불가능한 경우에는 선금 잔액을 즉시 반환하여야 한다.
      ③ 선금 미사용 잔액에 대하여는 약정이자를 반환하여야 한다.
      </div>
    CONTENT
    rule_content: <<~CONTENT,
      ## 지방자치단체 입찰 및 계약집행기준 (선금 실무)

      ### 선금보증서 제출 요건

      선금 지급 전 계약상대자는 다음 중 하나를 선금보증서로 제출해야 합니다.

      | 보증기관 | 보증서 종류 |
      |----------|------------|
      | 서울보증보험 | 이행(선금) 보증증권 |
      | 건설공제조합 | 선금이행보증서 |
      | 전문건설공제조합 | 선금이행보증서 |
      | 기타 공제조합 | 선금이행보증서 |

      ### 선금 정산 방법

      - **기성 청구 시**: 선금 지급 비율만큼 차감 후 지급
      - **예시**: 선금 30% 지급 → 기성 청구액의 30% 차감
      - **최종 기성**: 선금 잔액 전액 정산 후 지급

      ### 선금 지급 절차

      1. 계약상대자 선금 지급 신청서 제출
      2. 선금보증서 확인 (보증액 = 선금 지급액)
      3. 지급 결의 → 선금 지급
      4. 기성 청구 시 정산(차감)
      5. 준공 전 선금 전액 정산 완료
    CONTENT
    faqs: [
      { question: "선금을 반드시 지급해야 하나요?", answer: "아닙니다. 선금은 의무가 아닌 재량입니다. 다만, 계약상대자가 신청하고 계약담당자가 인정하는 경우 지급합니다. 소규모 계약이나 단기 계약은 통상 선금을 지급하지 않습니다." },
      { question: "선금보증서를 제출하지 않으면?", answer: "선금보증서 없이 선금을 지급해서는 안 됩니다. 보증서 없이 지급하면 감사 지적 사항이 됩니다. 계약상대자가 보증기관에서 발급받은 선금이행보증서를 제출한 후 지급합니다." },
      { question: "선금을 다른 공사에 유용하면?", answer: "선금은 해당 계약 이행에만 사용해야 합니다. 타 공사 유용, 대표자 개인 사용 등은 계약 해지 사유이며, 선금 전액 즉시 반환 의무가 생깁니다. 형사 처벌 대상이 될 수도 있습니다." },
      { question: "선금 정산은 어떻게 하나요?", answer: "기성금 청구 시 선금 지급 비율만큼 차감합니다. 예를 들어 계약금액 1억원에 선금 30%(3천만원)를 지급했다면, 기성금 청구 시마다 청구액의 30%를 차감 지급합니다." }
    ].to_json,
    practical_tips: <<~HTML,
      <div class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">payments</span>
            선금 지급 한도 요약
          </h4>
          <table class="w-full text-sm mt-2">
            <thead>
              <tr class="border-b border-blue-200">
                <th class="text-left py-1 text-blue-700">계약 유형</th>
                <th class="text-left py-1 text-blue-700">최대 선금 비율</th>
              </tr>
            </thead>
            <tbody class="text-blue-600">
              <tr><td class="py-1">공사·제조·용역</td><td>계약금액의 70%</td></tr>
              <tr><td class="py-1">학술·연구용역</td><td>계약금액의 50%</td></tr>
            </tbody>
          </table>
        </div>
        <div class="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <h4 class="font-bold text-amber-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">warning</span>
            감사 지적 주요 사례
          </h4>
          <ul class="text-amber-700 text-sm space-y-1 mt-2">
            <li>· 선금보증서 없이 선금 지급</li>
            <li>· 선금 지급 후 정산 누락 (기성에서 미차감)</li>
            <li>· 계약 해지 후 선금 환수 지연</li>
            <li>· 선금 지급액이 계약금액 70% 초과</li>
          </ul>
        </div>
      </div>
    HTML
  },
  {
    slug: "bid-qualification",
    name: "적격심사",
    category: "contract",
    published: true,
    summary: "경쟁입찰에서 최저가 입찰자가 아닌 가격·이행능력·신인도를 종합 평가하여 낙찰자를 결정하는 적격심사 방법을 안내합니다. 공사·물품·용역별 평가 기준과 낙찰하한율을 정리합니다.",
    keywords: "적격심사,낙찰자결정,낙찰하한율,적격심사기준,최저가입찰,이행능력평가,신인도평가,종합심사낙찰제",
    law_content: <<~CONTENT,
      ## 지방계약법 제13조 (낙찰자의 결정)

      **지방계약법 제13조 (낙찰자의 결정)**

      <div style="background:#dbeafe;padding:12px;border-radius:8px;margin:8px 0;">
      ① 지방자치단체의 장 또는 계약담당자는 경쟁입찰에서 예정가격 이하로서 최저가격으로 입찰한 자를 낙찰자로 한다. 다만, 계약의 목적·성질·규모 등을 고려하여 필요하다고 인정되는 경우에는 대통령령으로 정하는 바에 따라 미리 적격심사 기준을 정하고, 그 기준에 맞는 자 중에서 최저가격으로 입찰한 자를 낙찰자로 할 수 있다.

      ② 제1항에 따른 낙찰자 결정에 관한 기준 및 절차 등에 필요한 사항은 대통령령으로 정한다.
      </div>

      <div style="background:#eff6ff;padding:12px;border-radius:8px;margin:8px 0;">
      ■ 위임 체계
      원칙은 최저가 낙찰이지만, 계약의 성질·규모에 따라 "적격심사제"를 적용할 수 있습니다. 구체적인 심사 기준과 절차는 시행령으로 위임합니다.
      </div>

      <div style="background:#f3f4f6;padding:12px;border-radius:8px;margin:8px 0;">
      ※ 관련 법령: 지방계약법 시행령 제42조~제46조, 지방자치단체 입찰 시 낙찰자 결정기준
      </div>
    CONTENT
    decree_content: <<~CONTENT,
      ## 지방계약법 시행령 제42조~제46조 (적격심사 기준)

      **지방계약법 시행령 제42조 (적격심사)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      ① 다음 각 호의 계약은 적격심사 방법으로 낙찰자를 결정한다.

      | 계약 유형 | 적용 기준 |
      |-----------|----------|
      | 공사 | 추정가격 300억원 미만 |
      | 물품·용역 | 추정가격 2억원 이상 (해당 요건 충족 시) |
      | 전문공사 | 추정가격 10억원 미만 |

      ② 적격심사는 이행능력(시공능력, 경영상태), 가격, 신인도를 종합 평가한다.
      </div>

      **지방계약법 시행령 제44조 (적격심사 기준)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      적격심사는 다음 항목을 평가한다.

      **공사 적격심사 배점:**
      - 이행능력 (시공경험, 기술인력, 시공평가결과): 30~40점
      - 입찰가격: 50~60점
      - 신인도 (사회적 책임, 계약이행 실적): ±5점

      **물품·용역 적격심사:**
      - 이행실적, 납품능력, 신용도 평가
      - 해당 분야 납품·용역 수행 실적 확인

      낙찰하한율: 공사 87.745%~88%(추정가격 구간별 상이)
      </div>
    CONTENT
    rule_content: <<~CONTENT,
      ## 지방자치단체 입찰 시 낙찰자 결정기준 (행정안전부 고시)

      ### 공사 적격심사 낙찰하한율

      | 추정가격 구간 | 낙찰하한율 |
      |--------------|----------|
      | 10억원 미만 | 87.745% |
      | 10억~50억원 미만 | 87.745%~88% |
      | 50억~300억원 미만 | 88% |

      ### 적격심사 절차

      1. 최저가 입찰자부터 순위별 심사
      2. 적격심사 서류 제출 요청
      3. 이행능력·가격·신인도 종합 평가
      4. 85점 이상(공사) 또는 낙찰하한율 이상 → 낙찰
      5. 미달 시 차순위자 심사

      ### 자주 혼동하는 개념

      - **최저가낙찰제**: 예정가격 이하 최저가 → 낙찰 (단순)
      - **적격심사제**: 최저가 입찰자의 능력·실적 심사 후 낙찰
      - **종합심사낙찰제(종심제)**: 300억원 이상 대형 공사 적용 (가격·공사수행능력·사회적가치 종합)
    CONTENT
    faqs: [
      { question: "낙찰하한율이 뭔가요?", answer: "예정가격 대비 낙찰 가능한 최저 비율입니다. 예를 들어 낙찰하한율 87.745%라면, 예정가격 1억원 공사에서 87,745,000원 이상 입찰해야 낙찰이 가능합니다. 이보다 낮은 금액으로 입찰하면 낙찰 불가입니다." },
      { question: "적격심사에서 탈락하면?", answer: "적격심사 점수 미달(공사 85점 미만) 또는 낙찰하한율 미만이면 다음 순위 입찰자를 심사합니다. 모든 입찰자 탈락 시 유찰 처리됩니다." },
      { question: "물품 구매에도 적격심사가 있나요?", answer: "추정가격 2억원 이상 물품·용역은 적격심사 대상이 될 수 있습니다. 이행실적, 납품능력, 신용도 등을 평가합니다." },
      { question: "종합심사낙찰제(종심제)는 언제 쓰나요?", answer: "추정가격 300억원 이상 대형 공사에 적용됩니다. 가격뿐 아니라 공사수행능력(시공계획, 품질관리 등)과 사회적가치(고용, 안전 등)까지 종합 평가합니다." }
    ].to_json,
    practical_tips: <<~HTML,
      <div class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">fact_check</span>
            낙찰자 결정 방식 비교
          </h4>
          <table class="w-full text-sm mt-2">
            <thead>
              <tr class="border-b border-blue-200">
                <th class="text-left py-1 text-blue-700">방식</th>
                <th class="text-left py-1 text-blue-700">적용 대상</th>
              </tr>
            </thead>
            <tbody class="text-blue-600">
              <tr><td class="py-1">최저가낙찰제</td><td>소액 물품·용역</td></tr>
              <tr><td class="py-1">적격심사제</td><td>공사(300억 미만), 2억 이상 물품</td></tr>
              <tr><td class="py-1">종합심사낙찰제</td><td>공사 300억원 이상</td></tr>
              <tr><td class="py-1">협상에 의한 계약</td><td>전문성 요구 용역</td></tr>
            </tbody>
          </table>
        </div>
      </div>
    HTML
  },
  {
    slug: "bid-deposit",
    name: "입찰보증금",
    category: "contract",
    published: true,
    summary: "경쟁입찰 참가 시 납부하는 입찰보증금의 요율, 납부 방법, 면제 요건, 귀속 처리 절차를 안내합니다. 낙찰 후 계약 미체결 시 귀속 기준과 반환 절차를 실무 중심으로 정리합니다.",
    keywords: "입찰보증금,입찰보증,보증금납부,입찰보증금귀속,입찰보증금면제,입찰보증금반환,입찰참가보증",
    law_content: <<~CONTENT,
      ## 지방계약법 제9조 (입찰보증금)

      **지방계약법 제9조 (입찰)**

      <div style="background:#dbeafe;padding:12px;border-radius:8px;margin:8px 0;">
      ① 지방자치단체의 장 또는 계약담당자는 입찰에 참가하려는 자에게 입찰보증금을 납부하게 할 수 있다.

      ② 입찰보증금의 금액·납부방법 및 귀속에 관하여 필요한 사항은 대통령령으로 정한다.

      ③ 낙찰자가 정당한 이유 없이 계약을 체결하지 아니하는 경우에는 해당 입찰보증금은 지방자치단체에 귀속된다.
      </div>

      <div style="background:#eff6ff;padding:12px;border-radius:8px;margin:8px 0;">
      ■ 위임 체계
      법률은 입찰보증금 납부 권한과 귀속 원칙을 규정하고, 구체적인 금액·납부방법은 시행령에 위임합니다.
      </div>

      <div style="background:#f3f4f6;padding:12px;border-radius:8px;margin:8px 0;">
      ※ 관련 법령: 지방계약법 시행령 제34조~제37조
      </div>
    CONTENT
    decree_content: <<~CONTENT,
      ## 지방계약법 시행령 제34조~제37조 (입찰보증금)

      **지방계약법 시행령 제34조 (입찰보증금 납부)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      ① 입찰보증금은 입찰금액의 **5% 이상**을 납부하여야 한다.
      ② 납부 방법:
      - 현금 또는 국채·공채
      - 금융기관 보증서
      - 보증기관(서울보증보험 등) 보증서
      - 보험증권
      </div>

      **지방계약법 시행령 제35조 (입찰보증금 면제)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      다음의 경우 입찰보증금을 면제할 수 있다.
      1. 국가기관, 지방자치단체와의 계약
      2. 중소기업자 단체(중기협동조합) 계약
      3. 입찰금액이 **2천만원 이하**인 경우
      4. 나라장터 전자입찰에서 전자보증서로 대체한 경우
      </div>

      **지방계약법 시행령 제37조 (입찰보증금 귀속)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      낙찰자가 정당한 이유 없이 계약을 체결하지 아니한 경우 입찰보증금은 지방자치단체에 귀속된다. 다만, 천재지변 등 불가피한 사유가 있는 경우에는 반환할 수 있다.
      </div>
    CONTENT
    rule_content: <<~CONTENT,
      ## 지방자치단체 입찰 및 계약집행기준 (입찰보증금 실무)

      ### 입찰보증금 납부 실무

      | 구분 | 기준 |
      |------|------|
      | 납부 비율 | 입찰금액의 5% 이상 |
      | 납부 시기 | 입찰서 제출 시 (전자입찰: 전자보증서) |
      | 반환 시기 | 입찰 결과 확정 후 (낙찰자는 계약 체결 후) |

      ### 귀속 vs 반환 판단 기준

      **귀속 사유 (몰수):**
      - 낙찰 후 정당한 이유 없이 계약 미체결
      - 입찰 담합 적발

      **반환 사유:**
      - 낙찰되지 않은 입찰자 전원
      - 천재지변, 불가항력으로 계약 불가 낙찰자
      - 발주기관 귀책으로 계약 미체결

      ### 전자입찰 시 보증 처리

      나라장터(G2B) 전자입찰의 경우:
      - 보증기관에서 전자보증서 발급
      - G2B 시스템에 자동 연동
      - 낙찰 확정 후 자동 반환/귀속 처리
    CONTENT
    faqs: [
      { question: "입찰보증금은 얼마나 내나요?", answer: "입찰금액의 5% 이상입니다. 예를 들어 1억원으로 입찰한다면 500만원 이상을 입찰보증금으로 납부해야 합니다. 전자입찰의 경우 보증기관에서 발급한 전자보증서로 대체할 수 있습니다." },
      { question: "낙찰됐는데 계약 안 하면?", answer: "정당한 이유 없이 계약을 체결하지 않으면 입찰보증금 전액이 지방자치단체에 귀속(몰수)됩니다. 또한 부정당업자 제재(입찰 참가자격 제한) 처분을 받을 수 있습니다." },
      { question: "2천만원 이하 소액 입찰도 보증금을 내야 하나요?", answer: "입찰금액이 2천만원 이하인 경우 입찰보증금을 면제할 수 있습니다. 면제 여부는 발주기관의 재량이므로 입찰공고문을 확인해야 합니다." },
      { question: "낙찰 안 된 사람은 보증금을 돌려받나요?", answer: "네. 낙찰되지 않은 입찰자의 입찰보증금은 낙찰자 결정 후 즉시 반환됩니다. 전자보증서의 경우 G2B 시스템에서 자동으로 처리됩니다." }
    ].to_json,
    practical_tips: <<~HTML,
      <div class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">lock</span>
            입찰보증금 요약
          </h4>
          <ul class="text-blue-700 text-sm space-y-1 mt-2">
            <li>· 납부 비율: 입찰금액의 <strong>5% 이상</strong></li>
            <li>· 2천만원 이하: 면제 가능</li>
            <li>· 전자입찰: 전자보증서 대체</li>
            <li>· 낙찰 후 미계약: <strong>전액 귀속(몰수)</strong></li>
          </ul>
        </div>
      </div>
    HTML
  },
  {
    slug: "long-term-contract",
    name: "장기계속계약",
    category: "contract",
    published: true,
    summary: "수년에 걸쳐 이행되는 공사·용역을 연도별로 분할하여 체결하는 장기계속계약의 개념, 계속비계약과의 차이, 체결 방법과 연차별 계약 절차를 안내합니다.",
    keywords: "장기계속계약,계속비계약,연차계약,다년도계약,장기계약,연도별계약,분할계약,장기공사",
    law_content: <<~CONTENT,
      ## 지방계약법 제21조 (장기계속계약 및 계속비계약)

      **지방계약법 제21조 (장기계속계약 및 계속비계약)**

      <div style="background:#dbeafe;padding:12px;border-radius:8px;margin:8px 0;">
      ① 각 연도 예산 범위에서 계약을 체결하는 경우로서 이행 기간이 수 년도에 걸치는 경우에는 대통령령으로 정하는 바에 따라 장기계속계약을 체결할 수 있다.

      ② 지방의회의 의결을 거친 경비로 이행에 수 년도가 걸리는 경우에는 대통령령으로 정하는 바에 따라 계속비계약을 체결할 수 있다.
      </div>

      <div style="background:#eff6ff;padding:12px;border-radius:8px;margin:8px 0;">
      ■ 장기계속계약 vs 계속비계약
      - **장기계속계약**: 총 공사비를 확보하지 않고, 연도별 예산 범위 내에서 차년도 계약을 체결
      - **계속비계약**: 지방의회 의결로 총사업비를 확보하고, 전체를 1개 계약으로 체결
      </div>

      <div style="background:#f3f4f6;padding:12px;border-radius:8px;margin:8px 0;">
      ※ 관련 법령: 지방계약법 시행령 제65조~제67조
      </div>
    CONTENT
    decree_content: <<~CONTENT,
      ## 지방계약법 시행령 제65조~제67조 (장기계속계약)

      **지방계약법 시행령 제65조 (장기계속계약)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      ① 장기계속계약을 체결할 때에는 계약서에 다음 사항을 명시하여야 한다.
      1. 총 계약금액
      2. 총 이행기간
      3. 각 연도별 계약금액 및 이행기간

      ② 각 연도별 계약은 해당 연도 예산이 확정된 후 체결한다.
      ③ 장기계속계약의 차년도 계약은 전년도 계약 이행 상황을 확인한 후 체결한다.
      </div>

      **지방계약법 시행령 제66조 (계속비계약)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      계속비계약은 지방의회의 의결을 거친 계속비 예산이 확보된 경우에 총 공사금액과 총 이행기간을 1개의 계약으로 체결한다.
      </div>
    CONTENT
    rule_content: <<~CONTENT,
      ## 지방자치단체 입찰 및 계약집행기준 (장기계속계약 실무)

      ### 장기계속계약 vs 계속비계약 비교

      | 구분 | 장기계속계약 | 계속비계약 |
      |------|------------|----------|
      | 예산 확보 | 연도별 예산 범위 | 총액 일괄 확보 |
      | 의회 의결 | 불필요 (연도별 예산) | 필요 (계속비 예산) |
      | 계약 횟수 | 연도별 분할 체결 | 1회 체결 |
      | 적용 사례 | 일반 다년도 공사 | 대규모 확정 공사 |

      ### 장기계속계약 체결 절차

      1. **1차년도**: 총 공사 입찰·낙찰 → 1차년도분 계약 체결 (총액 부기)
      2. **2차년도**: 예산 확정 → 2차년도분 계약 체결
      3. **3차년도~**: 동일 반복

      ### 주의 사항

      - 총 계약금액은 입찰 시 결정된 금액으로 고정
      - 차년도 예산 미확보 시 계약 이행 중단 가능
      - 설계변경은 총액 기준으로 관리
      - 물가변동 적용도 총액 기준으로 산정
    CONTENT
    faqs: [
      { question: "장기계속계약과 계속비계약의 차이는?", answer: "장기계속계약은 연도별 예산 범위에서 분할 체결하며, 지방의회 의결이 불필요합니다. 계속비계약은 지방의회가 총사업비를 의결한 계속비 예산으로 1개 계약을 체결합니다. 일반 다년도 공사는 대부분 장기계속계약입니다." },
      { question: "차년도 예산이 안 잡히면?", answer: "장기계속계약에서 차년도 예산이 확보되지 않으면 해당 연도 계약을 체결할 수 없습니다. 공사가 중단될 수 있으므로, 계약서에 차년도 계약 의사 통보 기한 등을 명시하는 것이 중요합니다." },
      { question: "1차년도 계약서에 총액을 써야 하나요?", answer: "네. 1차년도 계약서에는 총 계약금액과 총 이행기간을 부기(附記)해야 합니다. 이것이 장기계속계약의 핵심으로, 차년도 계약의 법적 근거가 됩니다." },
      { question: "장기계속계약에서 설계변경은 어떻게 하나요?", answer: "설계변경은 총 계약금액 기준으로 합니다. 변경금액을 산출한 후 잔여 연차에 반영하며, 이미 이행 완료된 연차분은 소급 변경하지 않습니다." }
    ].to_json,
    practical_tips: <<~HTML,
      <div class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">event_repeat</span>
            장기계속계약 핵심 포인트
          </h4>
          <ul class="text-blue-700 text-sm space-y-1 mt-2">
            <li>· 1차년도 계약서에 <strong>총액 부기</strong> 필수</li>
            <li>· 차년도 계약 = 예산 확정 후 별도 체결</li>
            <li>· 입찰은 1회, 계약은 연도별 분할</li>
            <li>· 설계변경·물가변동 → 총액 기준 관리</li>
          </ul>
        </div>
        <div class="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <h4 class="font-bold text-amber-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">warning</span>
            자주 하는 실수
          </h4>
          <ul class="text-amber-700 text-sm space-y-1 mt-2">
            <li>· 1차년도 계약서에 총액 미기재</li>
            <li>· 차년도 예산 확보 전 계약 체결</li>
            <li>· 장기계속계약인데 1개 계약처럼 총액 계약</li>
          </ul>
        </div>
      </div>
    HTML
  },
  {
    slug: "unit-price-contract",
    name: "단가계약",
    category: "contract",
    published: true,
    summary: "품목별 단가를 미리 계약하고 필요 시 수량을 정해 납품·이행하는 단가계약의 요건, 체결 절차, 이행 관리 방법을 안내합니다. 총액계약과의 차이와 수요기관 발주 절차도 포함합니다.",
    keywords: "단가계약,단가계약체결,단가계약이행,물품단가계약,용역단가계약,수요기관,총액계약,단가산정",
    law_content: <<~CONTENT,
      ## 지방계약법 제22조 (단가계약)

      **지방계약법 제22조 (단가계약)**

      <div style="background:#dbeafe;padding:12px;border-radius:8px;margin:8px 0;">
      ① 일정 기간 계속하여 제조·수리·가공·매매·공급·사용 등의 계약을 할 필요가 있을 때에는 단가에 의한 계약을 체결할 수 있다.

      ② 단가계약을 체결하는 경우에는 계약 단가의 적정성, 예정 수량 등을 고려하여 계약금액의 상한을 정하여야 한다.
      </div>

      <div style="background:#eff6ff;padding:12px;border-radius:8px;margin:8px 0;">
      ■ 위임 체계
      법률은 단가계약의 허용 요건과 상한금액 설정 의무를 규정합니다. 구체적인 절차는 시행령과 운영기준으로 위임합니다.
      </div>

      <div style="background:#f3f4f6;padding:12px;border-radius:8px;margin:8px 0;">
      ※ 관련 법령: 지방계약법 시행령 제69조~제71조
      </div>
    CONTENT
    decree_content: <<~CONTENT,
      ## 지방계약법 시행령 제69조~제71조 (단가계약)

      **지방계약법 시행령 제69조 (단가계약 체결)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      ① 단가계약은 다음 각 호의 경우에 체결할 수 있다.
      1. 품목의 성질상 미리 수량을 확정하기 곤란한 경우
      2. 같은 품목을 여러 수요기관이 이용할 경우
      3. 계속적으로 소량씩 발주할 필요가 있는 경우

      ② 단가계약 기간은 **1년 이내**를 원칙으로 하되, 부득이한 경우 2년 이내로 할 수 있다.
      </div>

      **지방계약법 시행령 제70조 (이행 요청)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      ① 수요기관은 단가계약에 따른 납품(이행)을 요청할 때에는 발주서를 발행하여야 한다.
      ② 발주서에는 품목, 수량, 납품 장소 및 기한을 명시하여야 한다.
      ③ 계약 상한금액 이내에서 수요기관별로 발주한다.
      </div>
    CONTENT
    rule_content: <<~CONTENT,
      ## 지방자치단체 입찰 및 계약집행기준 (단가계약 실무)

      ### 단가계약 vs 총액계약 비교

      | 구분 | 단가계약 | 총액계약 |
      |------|----------|----------|
      | 수량 확정 | 계약 시 미확정 | 계약 시 확정 |
      | 금액 기준 | 단가 × 발주 수량 | 전체 계약금액 |
      | 적합 물품 | 소모품, 반복 발주 | 단일 프로젝트 |
      | 이행 방식 | 발주서별 이행 | 계약 일괄 이행 |

      ### 단가계약 적합 품목

      - **소모성 물품**: 복사지, 사무용품, 청소용품
      - **반복 서비스**: 시설 유지보수, 청소용역
      - **다빈도 수리**: 차량 수리, 장비 유지

      ### 이행 절차

      1. 단가계약 체결 (품목별 단가 확정)
      2. 수요기관 발주서 발행
      3. 계약상대자 납품·이행
      4. 검수·검사
      5. 대금 지급 (발주서별)
    CONTENT
    faqs: [
      { question: "단가계약 기간은 최대 얼마인가요?", answer: "원칙적으로 1년 이내입니다. 부득이한 경우 2년 이내로 연장할 수 있습니다. 1년이 지나면 재입찰·재계약이 필요합니다." },
      { question: "단가계약인데 수량이 예상보다 많으면?", answer: "계약서에 명시된 상한금액 범위 내에서만 발주할 수 있습니다. 상한금액을 초과하면 추가 계약을 체결하거나 재입찰을 해야 합니다. 상한금액 없이 무제한 발주는 위법입니다." },
      { question: "여러 수요기관이 같이 쓸 수 있나요?", answer: "네. 단가계약의 장점 중 하나가 여러 수요기관이 공동으로 이용할 수 있다는 점입니다. 교육청이 단가계약을 체결하면 산하 각 학교가 발주서로 발주할 수 있습니다." },
      { question: "발주서 없이 납품 요청하면 안 되나요?", answer: "단가계약에서는 반드시 발주서를 발행해야 합니다. 구두로 납품 요청하고 나중에 발주서를 작성하는 것은 계약 위반이며 감사 지적 대상입니다." }
    ].to_json,
    practical_tips: <<~HTML,
      <div class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">price_change</span>
            단가계약 핵심 요건
          </h4>
          <ul class="text-blue-700 text-sm space-y-1 mt-2">
            <li>· 계약 기간: <strong>1년 이내</strong> (최대 2년)</li>
            <li>· 상한금액 설정 <strong>필수</strong></li>
            <li>· 이행 요청: <strong>발주서</strong> 발행 필수</li>
            <li>· 수요기관 공동 이용 가능</li>
          </ul>
        </div>
      </div>
    HTML
  },
  {
    slug: "spec-price-split-bid",
    name: "규격가격 분리입찰",
    category: "contract",
    published: true,
    summary: "물품 구매 시 규격(기술) 심사와 가격 입찰을 분리하여 진행하는 규격가격 분리입찰의 적용 요건, 규격심의위원회 구성, 절차를 안내합니다. 담합 방지와 기술 중심 구매의 핵심 제도입니다.",
    keywords: "규격가격분리입찰,규격심의,규격심의위원회,분리입찰,기술심의,가격입찰분리,물품구매,기술평가",
    law_content: <<~CONTENT,
      ## 지방계약법 제9조의2 (규격가격 분리입찰)

      **지방계약법 제9조 (입찰) 및 관련 규정**

      <div style="background:#dbeafe;padding:12px;border-radius:8px;margin:8px 0;">
      지방자치단체의 장 또는 계약담당자는 물품 구매 시 규격과 가격을 분리하여 입찰하게 할 수 있다. 이 경우 규격심의위원회를 구성하여 기술 규격의 적정성을 심사한 후 가격 입찰을 실시한다.
      </div>

      <div style="background:#eff6ff;padding:12px;border-radius:8px;margin:8px 0;">
      ■ 제도 취지
      - 특정 업체 규격으로 인한 경쟁 제한 방지
      - 불필요한 고급 규격 요구 차단
      - 기술 중심의 공정한 구매 실현
      - 담합 가능성 차단 (규격심사와 가격입찰 분리)
      </div>

      <div style="background:#f3f4f6;padding:12px;border-radius:8px;margin:8px 0;">
      ※ 관련 법령: 지방계약법 시행령 제43조, 지방자치단체 물품계약 운용요령
      </div>
    CONTENT
    decree_content: <<~CONTENT,
      ## 지방계약법 시행령 제43조 (규격가격 분리입찰)

      **지방계약법 시행령 제43조**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      ① 추정가격 **1억원 이상** 물품 구매 시 규격가격 분리입찰을 적용할 수 있다.

      ② 규격심의위원회는 다음과 같이 구성한다.
      - 위원 수: 5명 이상
      - 전문가 위원: 해당 분야 전문가 2/3 이상
      - 내부 위원: 소속 공무원 포함 가능

      ③ 규격심의위원회는 제출된 규격서를 심사하여 적정 규격을 확정한다.
      </div>

      **절차:**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      1. 구매 수요 파악 → 규격 초안 작성
      2. 규격심의위원회 개최 → 규격 확정
      3. 확정된 규격으로 입찰공고
      4. 규격 심사 통과 업체만 가격 입찰 참가
      5. 최저가 업체 낙찰
      </div>
    CONTENT
    rule_content: <<~CONTENT,
      ## 지방자치단체 물품계약 운용요령 (규격심의 실무)

      ### 적용 대상

      | 구분 | 기준 |
      |------|------|
      | 의무 적용 | 추정가격 2억원 이상 물품 (행안부 기준) |
      | 임의 적용 | 1억원 이상 물품 (지자체 재량) |
      | 면제 가능 | 규격이 단순·명확한 소모품 |

      ### 규격심의위원회 운영

      - **구성**: 외부전문가 3명 이상 + 내부위원
      - **심의 내용**: 특정 업체 규격 여부, 기술 과잉 여부, 성능 기준 적정성
      - **결과**: 규격 승인 / 수정 후 승인 / 반려

      ### 분리입찰의 효과

      - 특정 브랜드 규격 차단 → 경쟁 촉진
      - 과도한 스펙 요구 방지 → 예산 절감
      - 규격·가격 분리 → 담합 차단
    CONTENT
    faqs: [
      { question: "규격가격 분리입찰이 왜 필요한가요?", answer: "특정 업체 제품만 납품 가능하도록 규격을 짜는 '맞춤 발주'를 막기 위한 제도입니다. 규격심의위원회가 규격의 적정성을 먼저 심사하고, 심사를 통과한 규격으로만 입찰을 진행합니다." },
      { question: "규격심의위원회를 꼭 열어야 하나요?", answer: "추정가격 2억원 이상 물품 구매는 원칙적으로 규격심의위원회를 운영해야 합니다. 단순 소모품(복사지, 사무용품 등)은 규격이 명확하므로 면제 가능합니다." },
      { question: "규격심사 결과 반려되면?", answer: "규격심의위원회가 규격을 반려하면 해당 규격을 수정하거나 재심의를 요청해야 합니다. 반려된 규격으로 입찰공고를 내면 위법입니다." },
      { question: "규격 심사 통과 안 된 업체는?", answer: "제출한 규격서가 심사를 통과하지 못한 업체는 가격 입찰에 참가할 수 없습니다. 규격 적합 업체만 가격 입찰에 참가합니다." }
    ].to_json,
    practical_tips: <<~HTML,
      <div class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">call_split</span>
            분리입찰 흐름
          </h4>
          <ol class="text-blue-700 text-sm space-y-1 mt-2">
            <li>1. 규격 초안 작성</li>
            <li>2. 규격심의위원회 → 규격 확정</li>
            <li>3. 확정 규격으로 입찰공고</li>
            <li>4. 업체 규격서 제출 → 규격 심사</li>
            <li>5. 합격 업체만 가격 입찰 참가</li>
            <li>6. 최저가 낙찰</li>
          </ol>
        </div>
      </div>
    HTML
  },
  {
    slug: "performance-guarantee",
    name: "이행보증",
    category: "contract",
    published: true,
    summary: "계약 체결 후 계약상대자가 제출하는 이행보증(계약이행보증서)의 요율, 보증기관, 면제 요건, 보증금 청구 절차를 안내합니다. 계약보증금과의 차이점도 함께 정리합니다.",
    keywords: "이행보증,계약이행보증,이행보증서,이행보증금,보증금납부,보증기관,이행보증면제,계약보증",
    law_content: <<~CONTENT,
      ## 지방계약법 제12조 (계약보증금)

      **지방계약법 제12조 (계약보증금)**

      <div style="background:#dbeafe;padding:12px;border-radius:8px;margin:8px 0;">
      ① 지방자치단체의 장 또는 계약담당자는 계약을 체결할 때 계약상대자에게 계약금액의 100분의 10 이상에 해당하는 금액을 계약보증금으로 납부하게 하여야 한다.

      ② 계약보증금은 현금 또는 보증기관의 보증서 등으로 납부하게 할 수 있다.

      ③ 계약상대자가 계약상의 의무를 이행하지 아니할 때에는 해당 계약보증금은 지방자치단체에 귀속된다.
      </div>

      <div style="background:#eff6ff;padding:12px;border-radius:8px;margin:8px 0;">
      ■ 이행보증 vs 계약보증금
      - **계약보증금**: 계약 불이행 시 귀속되는 금전 (납부 방식)
      - **이행보증서**: 보증기관이 계약 불이행 시 대신 이행하거나 금전을 지급하는 보증 (보증서 방식)
      실무에서는 대부분 이행보증서(보증기관 발급)로 대체합니다.
      </div>

      <div style="background:#f3f4f6;padding:12px;border-radius:8px;margin:8px 0;">
      ※ 관련 법령: 지방계약법 시행령 제50조~제53조
      </div>
    CONTENT
    decree_content: <<~CONTENT,
      ## 지방계약법 시행령 제50조~제53조 (계약보증금)

      **지방계약법 시행령 제50조 (계약보증금 납부)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      ① 계약보증금 납부 비율

      | 계약 유형 | 보증금 비율 |
      |-----------|-----------|
      | 일반 계약 | 계약금액의 10% 이상 |
      | 협상계약 | 계약금액의 10% 이상 |
      | 소액 계약 | 면제 가능 (2천만원 이하) |

      ② 납부 방법: 현금, 보증서(서울보증보험·공제조합), 국채·공채
      </div>

      **지방계약법 시행령 제51조 (계약보증금 면제)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      다음의 경우 계약보증금 전부 또는 일부를 면제할 수 있다.
      1. 계약금액이 2천만원 이하
      2. 국가·지방자치단체와의 계약
      3. 계약이행 실적이 우수한 업체 (규칙으로 정하는 기준)
      4. 단가계약에서 1회 발주금액이 소액인 경우
      </div>

      **지방계약법 시행령 제52조 (보증금 귀속)**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      계약상대자가 계약을 이행하지 아니한 때에는 계약보증금을 지방자치단체에 귀속시킨다. 다만, 천재지변 등 불가피한 사유가 있는 경우에는 그러하지 아니하다.
      </div>
    CONTENT
    rule_content: <<~CONTENT,
      ## 지방자치단체 입찰 및 계약집행기준 (이행보증 실무)

      ### 이행보증서 발급 기관

      | 보증기관 | 보증서 종류 |
      |----------|-----------|
      | 서울보증보험 | 이행(계약) 보증증권 |
      | 건설공제조합 | 계약이행보증서 |
      | 전문건설공제조합 | 계약이행보증서 |
      | 엔지니어링공제조합 | 계약이행보증서 |
      | 대한전문건설협회 | 계약이행보증서 |

      ### 보증금 청구 절차

      계약상대자 이행 포기 또는 계약 해지 시:
      1. 계약 해지(해제) 통보
      2. 보증기관에 보증금 청구
      3. 보증기관 조사·확인
      4. 보증금 지급 (또는 대체 이행)
      5. 재입찰 또는 수의계약으로 잔여분 이행

      ### 면제 판단 기준

      - 2천만원 이하: 면제 가능 (재량)
      - 국가·지자체 계약: 면제 가능
      - 단가계약 소액 발주: 면제 가능
    CONTENT
    faqs: [
      { question: "이행보증서와 계약보증금의 차이는?", answer: "실질적으로 같은 목적(계약 이행 담보)이지만 납부 방식이 다릅니다. 계약보증금은 현금이나 국채를 납부하는 방식이고, 이행보증서는 보증기관(서울보증보험 등)이 발급한 보증서로 대체하는 방식입니다. 실무에서는 대부분 이행보증서를 사용합니다." },
      { question: "이행보증금은 몇 %인가요?", answer: "계약금액의 10% 이상입니다. 예를 들어 1억원 계약이면 1천만원 이상의 이행보증서를 제출해야 합니다. 보증서는 보증기관에서 소액의 보증료를 내고 발급받습니다." },
      { question: "2천만원 이하 계약도 이행보증서 내야 하나요?", answer: "2천만원 이하 소액 계약은 계약보증금을 면제할 수 있습니다. 다만 면제는 의무가 아닌 재량이므로, 기관의 계약 관리 규정을 확인하세요." },
      { question: "계약상대자가 이행을 포기하면?", answer: "계약을 해지하고 보증기관에 보증금 청구를 합니다. 보증기관은 조사 후 보증금을 지급하거나 잔여 공사를 대체 이행합니다. 부정당업자 제재도 병행됩니다." }
    ].to_json,
    practical_tips: <<~HTML,
      <div class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">verified</span>
            이행보증 핵심 정리
          </h4>
          <ul class="text-blue-700 text-sm space-y-1 mt-2">
            <li>· 납부 비율: 계약금액의 <strong>10% 이상</strong></li>
            <li>· 2천만원 이하: 면제 가능</li>
            <li>· 실무: 보증기관 이행보증서로 대체</li>
            <li>· 계약 불이행 시: 보증금 귀속 + 제재</li>
          </ul>
        </div>
      </div>
    HTML
  },
  {
    slug: "multiple-price",
    name: "복수예비가격",
    category: "contract",
    published: true,
    summary: "경쟁입찰에서 예정가격 산정의 객관성을 확보하기 위해 15개 예비가격을 만들어 4개를 추첨하고 평균하는 복수예비가격 제도를 안내합니다. 기초금액 작성부터 예정가격 확정까지 절차를 정리합니다.",
    keywords: "복수예비가격,예비가격,예정가격,기초금액,예비가격추첨,예정가격산정,입찰예정가격,나라장터예비가격",
    law_content: <<~CONTENT,
      ## 지방계약법 제9조의2 (예정가격의 결정)

      **지방계약법 제9조의2 (예정가격)**

      <div style="background:#dbeafe;padding:12px;border-radius:8px;margin:8px 0;">
      ① 지방자치단체의 장 또는 계약담당자는 계약을 체결하려는 경우 미리 예정가격을 작성하여 봉인한 후 개찰 전까지 개봉하여서는 아니 된다.

      ② 예정가격의 결정 방법 등에 필요한 사항은 대통령령으로 정한다.
      </div>

      <div style="background:#eff6ff;padding:12px;border-radius:8px;margin:8px 0;">
      ■ 예정가격 vs 추정가격 vs 기초금액
      - **추정가격**: 입찰공고 전 발주기관이 내부적으로 파악한 시장가격 (VAT 제외)
      - **기초금액**: 복수예비가격 산출의 기준이 되는 금액
      - **예정가격**: 낙찰 여부 판단의 기준이 되는 실제 가격 (예비가격 추첨 결과)
      </div>

      <div style="background:#f3f4f6;padding:12px;border-radius:8px;margin:8px 0;">
      ※ 관련 법령: 지방계약법 시행령 제33조, 예정가격 작성기준(행안부 고시)
      </div>
    CONTENT
    decree_content: <<~CONTENT,
      ## 지방계약법 시행령 제33조 (예정가격 작성)

      **지방계약법 시행령 제33조**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      ① 예정가격은 다음 각 호의 방법으로 결정한다.
      1. 거래 실례가격
      2. 원가계산에 의한 가격
      3. 감정가격
      4. 유사 사례의 계약단가
      5. 복수예비가격 추첨

      ② 입찰에 붙이는 경우로서 대통령령으로 정하는 경우에는 **복수예비가격**으로 예정가격을 결정한다.
      </div>

      **복수예비가격 산출 방법:**

      <div style="background:#dcfce7;padding:12px;border-radius:8px;margin:8px 0;">
      1. 기초금액 결정 (원가계산·거래실례가 기준)
      2. 기초금액의 ±2% 범위에서 15개 예비가격 작성
      3. 입찰자 대표가 4개 추첨
      4. 추첨된 4개의 평균 → 예정가격 확정
      </div>
    CONTENT
    rule_content: <<~CONTENT,
      ## 예정가격 작성기준 (행정안전부 고시)

      ### 복수예비가격 산출 절차

      | 단계 | 내용 |
      |------|------|
      | 1단계 | 기초금액 결정 (원가계산 또는 거래실례가격) |
      | 2단계 | 기초금액 ±2% 범위에서 15개 예비가격 작성 |
      | 3단계 | G2B 시스템에 15개 예비가격 등록 (봉인) |
      | 4단계 | 개찰 시 입찰자 대표 4명이 각 1개씩 추첨 |
      | 5단계 | 추첨된 4개 예비가격의 산술평균 → 예정가격 |
      | 6단계 | 예정가격 이하 최저가 업체 → 낙찰 심사 |

      ### 적용 범위

      - **의무 적용**: 나라장터 전자입찰 (대부분의 경쟁입찰)
      - **면제**: 수의계약, 원가계산 방식 사용 계약

      ### 예비가격 예시

      기초금액 1억원이면:
      - 예비가격 범위: 9,800만원 ~ 1억 200만원
      - 15개 예비가격을 이 범위 내에서 균등 간격으로 생성
      - 4개 추첨 → 평균으로 예정가격 결정
    CONTENT
    faqs: [
      { question: "복수예비가격을 왜 쓰나요?", answer: "예정가격을 하나로 고정하면 담합·유출 위험이 큽니다. 15개를 만들어 추첨으로 4개를 고르면 어느 업체도 예정가격을 미리 알 수 없어 공정한 입찰이 가능합니다." },
      { question: "기초금액은 어떻게 결정하나요?", answer: "원가계산(재료비+노무비+경비+일반관리비+이윤) 또는 거래 실례가격(시중가격) 조사를 통해 결정합니다. 기초금액이 예정가격의 기준이 되므로 정확한 산출이 중요합니다." },
      { question: "추첨에 참여 못하면?", answer: "입찰자 수가 4명 미만인 경우 입찰자 전원이 추첨합니다. 입찰자가 없으면 발주기관 담당자가 대신 추첨합니다. 전자입찰의 경우 G2B 시스템이 자동으로 추첨 처리합니다." },
      { question: "예정가격보다 낮게 입찰하면 무조건 낙찰인가요?", answer: "예정가격 이하여야 낙찰 가능하지만, 적격심사가 있는 경우 낙찰하한율(87~88%) 이상이어야 합니다. 예정가격보다 낮더라도 낙찰하한율 미만이면 낙찰될 수 없습니다." }
    ].to_json,
    practical_tips: <<~HTML,
      <div class="space-y-4">
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
          <h4 class="font-bold text-blue-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">format_list_numbered</span>
            복수예비가격 흐름
          </h4>
          <ol class="text-blue-700 text-sm space-y-1 mt-2">
            <li>1. 기초금액 결정</li>
            <li>2. ±2% 범위 15개 예비가격 작성</li>
            <li>3. G2B 등록(봉인)</li>
            <li>4. 개찰 시 4개 추첨</li>
            <li>5. 4개 평균 = 예정가격</li>
            <li>6. 예정가격 이하 최저가 → 낙찰심사</li>
          </ol>
        </div>
        <div class="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <h4 class="font-bold text-amber-800 flex items-center gap-2 mb-2">
            <span class="material-symbols-outlined">warning</span>
            자주 혼동하는 개념
          </h4>
          <ul class="text-amber-700 text-sm space-y-1 mt-2">
            <li>· 추정가격 ≠ 예정가격 (추정가격으로 공고, 예정가격으로 낙찰)</li>
            <li>· 기초금액 = 예비가격 산출의 기준 금액</li>
            <li>· 예정가격 = 추첨 후 확정되는 실제 상한 금액</li>
          </ul>
        </div>
      </div>
    HTML
  }
]

topics.each do |attrs|
  faqs = attrs.delete(:faqs)
  practical_tips = attrs.delete(:practical_tips)

  topic = Topic.find_or_initialize_by(slug: attrs[:slug])
  topic.assign_attributes(attrs)
  topic.faqs = faqs if faqs
  topic.practical_tips = practical_tips if practical_tips
  topic.view_count ||= 0

  if topic.save
    puts "✅ #{topic.name} (#{topic.slug}) — #{topic.new_record? ? '생성' : '업데이트'}"
  else
    puts "❌ #{attrs[:slug]} 오류: #{topic.errors.full_messages.join(', ')}"
  end
end

puts "\n완료: #{topics.size}개 토픽 처리"
