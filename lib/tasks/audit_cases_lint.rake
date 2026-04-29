# frozen_string_literal: true

namespace :audit_cases do
  desc "감사사례 시드/DB 실명(학교명·학교법인·지역 교육지원청) 잔존 검사"
  task lint: :environment do
    seed_dir = Rails.root.join("db/seeds/audit_cases")

    school_pattern = /[가-힣]{2,4}(고등학교|중학교|초등학교|대학교|학원)/
    # 위협 모델: 지역 교육지원청(피감독 학교 위치 식별 가능). 광역시·도교육청(공개문 발행처)은 제외.
    edu_office_pattern = /(서울특별시|경기도|부산광역시|대구광역시|인천광역시|광주광역시|대전광역시|울산광역시|세종특별자치시|강원특별자치도|충청북도|충청남도|전북특별자치도|전라남도|경상북도|경상남도|제주특별자치도)[가-힣]{2,8}교육지원청/

    generic_terms = %w[고등학교 중학교 초등학교 대학교 학원]
    seed_skip_lines = [
      "destroy_all",
      "기존에 실명",
      "익명화 정책"
    ]

    failures = []

    Dir.glob(seed_dir.join("*.rb")).sort.each do |path|
      File.foreach(path).with_index(1) do |line, lineno|
        next if seed_skip_lines.any? { |kw| line.include?(kw) }

        line.scan(school_pattern) do
          full = Regexp.last_match(0)
          next if generic_terms.include?(full)
          failures << { file: path.to_s.sub(Rails.root.to_s + "/", ""), line: lineno, match: full, kind: "school" }
        end

        line.scan(edu_office_pattern) do
          full = Regexp.last_match(0)
          failures << { file: path.to_s.sub(Rails.root.to_s + "/", ""), line: lineno, match: full, kind: "edu_office" }
        end
      end
    end

    db_failures = []
    AuditCase.where(published: true).find_each do |ac|
      blob = [ac.title, ac.legal_basis, ac.issue, ac.detail, ac.lesson].compact.join("\n")
      blob.scan(school_pattern) do
        full = Regexp.last_match(0)
        next if generic_terms.include?(full)
        db_failures << { slug: ac.slug, match: full, kind: "school" }
      end
      blob.scan(edu_office_pattern) do
        full = Regexp.last_match(0)
        db_failures << { slug: ac.slug, match: full, kind: "edu_office" }
      end
    end

    if failures.empty? && db_failures.empty?
      puts "[OK] audit_cases 실명 잔존 0건 (시드 #{Dir.glob(seed_dir.join('*.rb')).size}개 + DB published #{AuditCase.where(published: true).count}건 검사)"
      exit 0
    end

    if failures.any?
      puts "\n[FAIL:SEED] 실명 잔존 #{failures.size}건"
      failures.first(50).each do |f|
        puts "  - #{f[:file]}:#{f[:line]} (#{f[:kind]}) → #{f[:match]}"
      end
    end

    if db_failures.any?
      puts "\n[FAIL:DB] 실명 잔존 #{db_failures.size}건"
      db_failures.first(50).each do |f|
        puts "  - AuditCase[#{f[:slug]}] (#{f[:kind]}) → #{f[:match]}"
      end
    end

    exit 1
  end
end
