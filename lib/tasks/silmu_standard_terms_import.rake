# P3 Sprint 2 — 공통표준용어 CSV 전체 적재 (13,176건)
#
# 출처: 행정안전부 「공공데이터 공통표준용어」 (data.go.kr 15156379, 8차 2025-11)
# 입력: db/seeds/standard_terms.csv (UTF-8 with BOM)
#
# 정책:
#   - 행 단위 find_or_initialize_by(term_korean) → meta 필드 CSV 우선 덮어쓰기
#   - synonyms는 기존 ∪ CSV (union) — silmu sample 수작업 synonyms 보존
#   - "개정구분명" == "폐기" 행은 skip
#   - 1,000건 batch 트랜잭션 + 1,000건마다 진행 로그
#   - 멱등 — 재실행 시 동일 결과 (timestamp만 갱신)
#
# 사용:
#   bin/rails standard_terms:import                # 적재
#   bin/rails standard_terms:import DRY_RUN=1      # 카운트만 확인
#   bin/rails standard_terms:import LIMIT=100      # 처음 100건만 적재 (디버그)
require "csv"

namespace :standard_terms do
  desc "공공데이터 공통표준용어 CSV 전체 적재 (db/seeds/standard_terms.csv)"
  task import: :environment do
    csv_path = Rails.root.join("db/seeds/standard_terms.csv")
    unless File.exist?(csv_path)
      puts "[ERROR] CSV 파일이 없음: #{csv_path}"
      exit 1
    end

    dry_run = ENV["DRY_RUN"].present?
    limit   = ENV["LIMIT"].to_i # 0 → 무제한
    batch   = (ENV["BATCH"] || 1_000).to_i

    started_at  = Time.current
    total       = 0
    inserted    = 0
    updated     = 0
    skipped     = 0
    abolished   = 0
    syn_merged  = 0

    accumulator = []

    flush = lambda do
      next if accumulator.empty?
      StandardTerm.transaction do
        accumulator.each do |row|
          term = StandardTerm.find_or_initialize_by(term_korean: row[:term_korean])
          is_new = term.new_record?

          existing_syn = Array(term.synonyms)
          merged_syn   = (existing_syn + row[:synonyms]).map { |s| s.to_s.strip }.uniq.reject(&:blank?)
          syn_merged  += 1 if !is_new && existing_syn.sort != merged_syn.sort

          term.assign_attributes(
            term_english:           row[:term_english],
            description:            row[:description],
            domain_classification:  row[:domain_classification],
            agency_name:            row[:agency_name],
            revision_round:         row[:revision_round],
            data_type:              row[:data_type],
            max_length:             row[:max_length],
            synonyms:               merged_syn
          )
          term.save!

          if is_new
            inserted += 1
          else
            updated += 1
          end
        end
      end
      accumulator.clear
    end

    CSV.foreach(csv_path, headers: true, encoding: "bom|utf-8") do |csv_row|
      total += 1
      break if limit.positive? && total > limit

      revision_type = csv_row["개정구분명(폐기 또는 변경)"].to_s.strip
      if revision_type == "폐기"
        abolished += 1
        next
      end

      term_korean = csv_row["공통표준용어명"].to_s.strip
      if term_korean.blank?
        skipped += 1
        next
      end

      raw_syn = csv_row["용어 이음동의어 목록"].to_s
      synonyms = raw_syn.split(",").map { |s| s.strip }.reject(&:blank?)

      data_type = csv_row["저장 형식"].to_s.strip.presence
      max_length =
        if data_type && (m = data_type.match(/(\d+)\s*자리/))
          m[1].to_i
        end

      accumulator << {
        term_korean:           term_korean,
        term_english:          csv_row["공통표준용어영문약어명"].to_s.strip.presence,
        description:           csv_row["공통표준용어설명"].to_s.strip.presence,
        domain_classification: csv_row["공통표준도메인명"].to_s.strip.presence,
        agency_name:           csv_row["소관기관명"].to_s.strip.presence,
        revision_round:        csv_row["제정차수"].to_s.strip.presence,
        data_type:             data_type,
        max_length:            max_length,
        synonyms:              synonyms
      }

      if accumulator.size >= batch && !dry_run
        flush.call
        print "  적재 #{(inserted + updated).to_s.rjust(6)}/#{total} (insert=#{inserted} update=#{updated} skip=#{skipped} abolished=#{abolished})\r"
      end
    end

    if dry_run
      puts "[DRY_RUN] 총 #{total}건 / 폐기 #{abolished}건 / 빈 행 #{skipped}건 / 실제 적재 대상 #{total - abolished - skipped}건"
      next
    end

    flush.call
    puts ""

    StandardTerm.expire_synonym_index!

    elapsed = (Time.current - started_at).round(1)
    puts "─" * 70
    puts "표준용어 CSV 적재 완료 (#{elapsed}초)"
    puts "  insert     : #{inserted}건"
    puts "  update     : #{updated}건"
    puts "  synonyms 병합 변경: #{syn_merged}건"
    puts "  폐기 skip  : #{abolished}건"
    puts "  빈 행 skip : #{skipped}건"
    puts "  전체 처리  : #{total}건"
    puts "  DB 총 레코드: #{StandardTerm.count}건"
    puts "  synonym_index 캐시 무효화 완료"
    puts "─" * 70
  end
end
