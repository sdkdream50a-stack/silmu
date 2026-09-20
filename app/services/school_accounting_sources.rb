# frozen_string_literal: true

# P4 §8·§9 (2026-09-20) — 학교회계 공식 source 정규화.
#
# 푸는 문제
#   P3 는 법률 1건 + 시·도 교육규칙 17건을 **한 번** 수집해 `config/school_accounting_rules.yml`
#   에 넣었다. 그 파일은 기한 계산에는 충분하지만 «이 값이 어디서 왔고 언제 받았고
#   그 뒤에 바뀌었는가» 를 말하지 못한다. 규칙이 개정되면 화면이 조용히 낡는다.
#
# 설계 — 새 DB 0 · 새 daemon 0
#   · **선언**(무엇인가: 층·출처 종류·관할·제목·일련번호·공포/시행일)은 YAML 이 소유한다.
#   · **시점**(언제 받았나·해시·이전 판본·확인자)은 기존 `authority_*` 테이블이 소유한다.
#   · 이 서비스는 둘을 **조인만** 한다. 어느 쪽도 복제하지 않는다.
#   · DB 에 짝이 없으면 값을 지어내지 않고 `UNTRACKED` 로 말한다.
#
# §9 — 층을 섞지 않는다
#   NATIONAL_CORE 는 전국 기한, REGIONAL_RULE 은 균일할 때만 기한, ANNUAL_GUIDELINE 은 기한이 아니다.
#   `majority_rule_value` 는 **다수 현황 설명**이지 법적 전국 기준이 아니다 — `authority_for(layer)`
#   가 그 구분을 값으로 돌려준다(주석이 아니라 코드로).
class SchoolAccountingSources
  CONFIG_PATH = Rails.root.join("config", "school_accounting_rules.yml")

  LAYERS = {
    "NATIONAL_CORE"    => "법률 — 전국 공통",
    "REGIONAL_RULE"    => "시·도 교육규칙 — 교육청별",
    "ANNUAL_GUIDELINE" => "교육감 예산편성 기본지침 — 연 1회·교육청별"
  }.freeze

  # 각 층이 «기한» 으로 쓰일 수 있는 권위를 갖는가. 화면·테스트가 이 값을 읽는다.
  #   DEADLINE           : 그대로 법정 기한으로 쓴다
  #   DEADLINE_IF_UNIFORM: 17개가 같을 때만 기한. 갈리면 분기를 그대로 적는다
  #   REFERENCE_ONLY     : 기한으로 쓰지 않는다
  AUTHORITY = {
    "NATIONAL_CORE" => "DEADLINE",
    "REGIONAL_RULE" => "DEADLINE_IF_UNIFORM",
    "ANNUAL_GUIDELINE" => "REFERENCE_ONLY"
  }.freeze

  UNTRACKED = "UNTRACKED"

  ORDIN_URL = "https://www.law.go.kr/LSW/ordinInfoP.do?ordinSeq=%s"
  LAW_URL   = "https://www.law.go.kr/법령/%s"

  # §8 이 요구한 최소 metadata 한 건.
  # 값이 없으면 nil 이 아니라 UNTRACKED — «안 물어봤다» 와 «물어봤는데 없다» 를 섞지 않는다.
  Record = Struct.new(:key, :layer, :authority, :source_type, :jurisdiction, :region,
                      :title, :source_url, :official_identifier, :effective_date,
                      :promulgated_date, :fetched_at, :verified_at, :version_hash,
                      :supersedes, :status, :tracked, keyword_init: true) do
    def tracked? = tracked == true
    def layer_label = LAYERS.fetch(layer)
    def deadline_authority? = authority == "DEADLINE"
  end

  class << self
    def all = national_core + regional_rules + annual_guidelines

    def national_core
      config.fetch("national_core", []).map do |raw|
        build(raw, title: raw["title"], source_url: format(LAW_URL, raw["title"].to_s.delete(" ")),
                   identifier: raw["law_mst"].to_s)
      end
    end

    def regional_rules
      config.fetch("rules", []).map do |raw|
        build(raw.merge("layer" => "REGIONAL_RULE", "source_type" => "STRUCTURED_API",
                        "jurisdiction" => "EDU_OFFICE", "region" => raw["code"],
                        "status" => raw["status"] || "ACTIVE",
                        "key" => ordin_key(raw["code"])),
              title: raw["rule_name"], source_url: format(ORDIN_URL, raw["ordin_seq"]),
              identifier: raw["ordin_seq"].to_s)
      end
    end

    def annual_guidelines
      config.fetch("annual_guidelines", []).map do |raw|
        build(raw, title: raw["title"], source_url: nil, identifier: nil)
      end
    end

    # AuthorityDocument key 규약 — seed 와 이 서비스가 **같은 규약 하나**를 쓴다.
    def ordin_key(code) = "school_accounting_rule_#{code}"

    def layer_summary
      all.group_by(&:layer).transform_values do |rs|
        { count: rs.size, tracked: rs.count(&:tracked?), authority: AUTHORITY.fetch(rs.first.layer) }
      end
    end

    def config
      @config ||= YAML.safe_load(File.read(CONFIG_PATH), permitted_classes: [ Date ]) || {}
    rescue Errno::ENOENT, Psych::SyntaxError => e
      Rails.logger.warn "[SchoolAccountingSources] 등록부 읽기 실패: #{e.message}"
      {}
    end

    def reset! = (@config = nil)

    private

    def build(raw, title:, source_url:, identifier:)
      layer = raw.fetch("layer")
      doc = tracking_document(raw["key"])
      version = doc&.current_version

      Record.new(
        key: raw["key"], layer: layer, authority: AUTHORITY.fetch(layer),
        source_type: raw["source_type"], jurisdiction: raw["jurisdiction"], region: raw["region"],
        title: title, source_url: source_url, official_identifier: identifier,
        effective_date: date_of(raw["effective"]), promulgated_date: date_of(raw["promulgated"]),
        status: raw["status"] || "ACTIVE", tracked: doc.present?,
        # 아래 4개는 **DB 가 소유**한다. 짝이 없으면 지어내지 않는다.
        fetched_at:   version&.fetched_at || UNTRACKED,
        verified_at:  verified_at_for(doc) || UNTRACKED,
        version_hash: version&.content_hash || UNTRACKED,
        supersedes:   supersedes_for(doc, version) || UNTRACKED
      )
    end

    # DB 가 없거나(테이블 미생성·CI) 조회가 실패해도 등록부 자체는 읽혀야 한다 —
    # 이 서비스의 1차 책임은 «선언» 이고 추적은 보강이다.
    def tracking_document(key)
      return nil if key.blank?

      AuthorityDocument.find_by(key: key)
    rescue ActiveRecord::ActiveRecordError, NameError
      nil
    end

    def verified_at_for(doc)
      return nil if doc.nil?

      AuthorityVerificationEvent.where(content_type: "AuthorityDocument", content_id: doc.id)
                                .maximum(:reviewed_at)
    rescue ActiveRecord::ActiveRecordError, NameError
      nil
    end

    # 직전 판본의 식별자. «무엇을 대체했는가» 는 판본 이력에서 파생한다(별도 컬럼을 만들지 않는다).
    def supersedes_for(doc, version)
      return nil if doc.nil? || version.nil?

      prev = doc.authority_versions.where.not(id: version.id).order(fetched_at: :desc).first
      prev&.version_identifier || prev&.content_hash
    rescue ActiveRecord::ActiveRecordError, NameError
      nil
    end

    # 법제처 포맷 "YYYYMMDD". 달력에 없는 날짜는 만들지 않는다(P3 R1 수리와 같은 규율).
    def date_of(value)
      s = value.to_s
      return nil unless s.match?(/\A\d{8}\z/)

      Date.strptime(s, "%Y%m%d")
    rescue Date::Error
      nil
    end
  end
end
