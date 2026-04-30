# frozen_string_literal: true
# silmu 5단계 법령 검증 게이트 — 자동 lint
# 운영 방식: 로컬·CI 환경에서 `bin/rake silmu:legal_lint` 실행
# 메모리 참조: project_legal_validation_gate.md
#
# 검증 항목:
# 1. 폐지 조문 블랙리스트 (KNOWN_REPEALED) 인용 0건
# 2. 표준값 위반 (지체상금 30%, 낙찰하한율 87.745% 등) 0건
# 3. 명백한 부정확 매핑 (예: 시행령 §11 "예정가격작성기준" 등)

namespace :silmu do
  desc "silmu 5단계 법령 검증 게이트 — 폐지 조문·표준값·부정확 매핑 lint"
  task :legal_lint do
    # 폐지·삭제된 조문 블랙리스트 (운영 mcp 프록시 검증 결과)
    repealed_articles = {
      "지방계약법 시행령 제42조의2" => {
        repealed: "2022년 삭제",
        replacement: "지방계약법 시행령 제42조 + 행안부 예규 「지방자치단체 입찰 및 계약 집행기준」"
      }
    }

    # 표준값 위반 패턴 (silmu 콘텐츠에서 잘못된 값이 자주 발견된 경우)
    standard_value_violations = [
      {
        pattern: /지체상금[^.\n]{0,80}30\s*%|30\s*%[^.\n]{0,40}지체상금/,
        rule: "지체상금 한도 = 10% (지방계약법 시행규칙 §75 단서). 30% 인용 금지",
        exclude_files: %w[home_quiz_controller.js].freeze
      },
      {
        # 87.745%만 단독 언급 (범위형 87.745~89.745% 표기 + 사례 본문 "당시 적용된" 묘사 제외)
        pattern: /낙찰하한율[^.\n]{0,30}예정가격의\s*87\.745\s*%(?![~\s\-]*89)/,
        rule: "낙찰하한율 = 89.745% (2026.1.2 시행, 추정가격 2~300억). 단독 87.745% 인용 금지 (범위형 87.745%~89.745% 표기는 허용)",
        # 사례 본문(2026.1.2 이전 사실 묘사)은 시점 정확하므로 exclude
        exclude_files: %w[contract_topic_audit_cases.rb].freeze
      }
    ]

    # 부정확 매핑 패턴 (메모리 권고 부정확 13건 + 누적 발견 패턴화)
    incorrect_mappings = [
      {
        pattern: /시행령 제11조[^,)\n]{0,30}예정가격작성기준|예정가격작성기준[^,)\n]{0,30}시행령 제11조/,
        rule: "지방계약법 시행령 §11 = 입찰방법 (예정가격작성기준 아님). 정확: §9·§10 + 시행규칙 §11의2"
      },
      {
        pattern: /공무원연금법[^,)\n]{0,30}제64조[^,)\n]{0,30}퇴직수당|제64조[^,)\n]{0,30}퇴직수당/,
        rule: "공무원연금법 §64 = 진단 불응 시의 급여 제한. 퇴직수당 본조는 §62"
      },
      {
        pattern: /시행령 제50조[^,)\n]{0,30}계약보증금률|시행령 제37조[^,)\n]{0,30}계약보증금률/,
        rule: "지방계약법 시행령 §50 = 계약서 작성의 생략 / §37 = 입찰보증금. 계약보증금률은 §51 (계약의 이행보증)"
      },
      {
        pattern: /시행령 제65조[^,)\n]{0,30}기성검사|시행령 제68조[^,)\n]{0,30}기성검사|시행령 제65조[^,)\n]{0,30}기성부분/,
        rule: "지방계약법 시행령 §65 = 검사조서 작성의 생략 / §68 = 대가 지급 지연 이자. 기성검사 본조는 §67 ⑥항"
      },
      {
        pattern: /시행령 제70조[^,)\n]{0,30}하자담보|시행령 제78조[^,)\n]{0,30}하자(담보|보수)/,
        rule: "국가시행령 §70 = 개산계약 / 지방시행령 §78 = 장기계속계약. 하자담보: 국가 §60 (공사 하자담보책임기간) / 지방 §71 (하자보수보증금)"
      },
      {
        pattern: /지방재정법[^,)\n]{0,30}제48조[^,)\n]{0,30}이월/,
        rule: "지방재정법 §48 = 예산 절약에 따른 성과금. 이월 본조는 §50 (세출예산의 이월)"
      },
      {
        pattern: /보조금[^,)\n]{0,40}제30조[^,)\n]{0,30}정산|국고보조금법[^,)\n]{0,30}제30조/,
        rule: "보조금법 §30 = 교부 결정 취소 / 정확한 명칭: 「보조금 관리에 관한 법률」 / 정산보고서 본조는 §27"
      },
      {
        # 시급 #1 후속: 지체상금 3,000만원 (1억 × 30%) → 1,000만원 (1억 × 10%)
        pattern: /지체상금[^.\n]{0,80}3,?000만원|3,?000만원[^.\n]{0,40}지체상금|지체상금[^.\n]{0,80}3천만원/,
        rule: "지체상금 1억 기준 최대 = 1,000만원 (10%, 시행규칙 §75 단서). 3,000만원/3천만원 인용 금지"
      },
      {
        # 지방재정법 회계조문 → 지방회계법 (별도 법령 분리)
        pattern: /지방재정법[^,)\n]{0,30}제(38|71|96)조/,
        rule: "지방재정법 §38·§71·§96 = 회계조문은 「지방회계법」으로 분리됨. 정확한 법령명 사용"
      },
      {
        # §50을 계약서 작성 본조로 인용 (실제 §49) — A3-#3 사례 / "작성 생략"은 §50 정확이라 제외
        pattern: /계약서[^,)\n]{0,20}작성[^,)\n]{0,5}의무[^,)\n]{0,30}제50조|초과[^,)\n]{0,30}계약서[^,)\n]{0,10}작성[^,)\n]{0,30}제50조/,
        rule: "지방계약법 시행령 §50 = 계약서 작성의 생략 등. 작성 의무 본조는 §49 (5천만원 이하 생략은 §50 정확)"
      },
      {
        # 양법 혼동: silmu 페르소나(지방)에 국가계약법 §44의2 인용 (H10 사례)
        pattern: /국가계약법[^,)\n]{0,30}제44조의2|국가를 당사자로 하는 계약에 관한 법률[^,)\n]{0,40}제44조의2/,
        rule: "국가계약법 §44의2 = 품질등에 의한 낙찰자 결정. 종합심사낙찰제 정확: 지방계약법 시행령 §42의3 (silmu 페르소나는 지방 우선)",
        exclude_files: %w[exam_questions.rb exam_curriculum].freeze
      }
    ]

    # 스캔 대상 경로
    target_globs = %w[
      app/views/**/*.erb
      app/services/**/*.rb
      app/models/exam_questions.rb
      app/models/exam_keyword_details.rb
      app/models/exam_curriculum/**/*.rb
      db/seeds/topics.rb
      db/seeds/topic_*.rb
      db/seeds/audit_cases.rb
      db/seeds/audit_cases/**/*.rb
      db/seeds/suui_contract_series.rb
      config/contract_thresholds.yml
    ]

    failures = []

    target_globs.each do |glob|
      Dir[Rails.root.join(glob)].each do |path|
        rel = path.sub("#{Rails.root}/", "")
        content = File.read(path)

        # 1. 폐지 조문 검사
        repealed_articles.each do |article, info|
          if content.include?(article)
            failures << { kind: :repealed, file: rel, match: article, info: info }
          end
        end

        # 2. 표준값 위반 검사
        standard_value_violations.each do |viol|
          next if Array(viol[:exclude_files]).any? { |ex| rel.end_with?(ex) }
          if content.match?(viol[:pattern])
            failures << { kind: :standard_value, file: rel, rule: viol[:rule] }
          end
        end

        # 3. 부정확 매핑 검사
        incorrect_mappings.each do |mapping|
          if content.match?(mapping[:pattern])
            failures << { kind: :incorrect_mapping, file: rel, rule: mapping[:rule] }
          end
        end
      end
    end

    if failures.empty?
      puts "[OK] silmu 5단계 게이트 — 법령 인용 정합성 통과"
      puts "  - 폐지 조문 블랙리스트 0건"
      puts "  - 표준값 위반 0건"
      puts "  - 부정확 매핑 0건"
      exit 0
    end

    puts "[FAIL] silmu 5단계 게이트 위반 #{failures.size}건"
    failures.group_by { |f| f[:kind] }.each do |kind, items|
      puts "\n## #{kind} (#{items.size}건)"
      items.first(20).each do |f|
        puts "  - #{f[:file]}"
        puts "    match: #{f[:match]}" if f[:match]
        puts "    rule: #{f[:rule] || f.dig(:info, :replacement)}"
      end
    end
    puts "\n참조: /Users/seong/.claude/projects/-Users-seong-project-silmu/memory/project_legal_validation_gate.md"
    exit 1
  end
end
