# 감사사례 F3 — 출처가 있는 «재구성» 사례 본문 꼬리 문구 정정 (2026-10-05 AdSense readiness audit)
#
# 문제: 색인 대상 재구성 사례(예: goe-2021-*) 본문 끝에
#   "※ 본 사례는 경기도교육청 「2021 감사사례집」(p.76) 패턴을 기반으로 학습용으로 재구성한 **가상 시나리오**입니다.
#    특정 학교의 실제 사례가 아니며 학습·실무 적용을 위한 교육용 자료입니다."
#   가 남아 있다. 공개 사례집의 실제 지적을 재구성한 사례라 «가상 시나리오»는 사실과 다르고(가상 = SIMULATED·noindex),
#   머리의 «재구성» 표시와도 모순된다.
# 정정: "※ 본 사례는 경기도교육청 「2021 감사사례집」(p.76) 공개 사례를 기반으로 재구성한 사례입니다.
#        기관·인물·금액 등 일부는 각색했습니다."
#   규칙 = AuditCaseProvenance.normalize_reconstruction_tail (화면 렌더와 같은 함수). 출처 인용 「…」(…p.N…) 이 바로 앞에 있을
#   때만 바꾸고, 페이지 번호는 본문에 이미 있는 값을 그대로 둔다(새로 만들지 않는다). 뒤따르는 «현행 법령 기준일» 문장은 보존.
#
# 대상: source_type = SILMU_RECONSTRUCTED_CASE 의 issue·detail·lesson 만. 가상(SILMU_SIMULATED_CASE)은 «가상 시나리오»가
#   사실이므로 건드리지 않는다. slug·title·view_count·source_type·verification_* 불변.
#   분류기(AuditCaseProvenanceClassifier)는 새 문구 «공개 사례를 기반으로 재구성한 사례» 도 재구성 표식으로 읽는다 —
#   재분류해도 ACTUAL_AUDIT 로 다시 올라가지 않는다(같은 PR).
#
# DRY_RUN=1 이면 쓰지 않고 레코드별 fields_to_change 와 바뀔 문장만 출력한다. 멱등: 두 번째 실행은 changes=0.
# 적용 시 원래 값을 tmp/content_migration_backups/ 에 JSON 으로 남기고 stdout 에도 원문 문장을 찍는다(롤백 근거).
#
# 운영 적용(배포 후 · 사람이 실행):
#   bin/kamal app exec --reuse 'DRY_RUN=1 bin/rails runner "load Rails.root.join(%q{db/content_migrations/20261005120000_audit_reconstructed_tail_wording.rb})"'
#   → 기대: rows ≤ 52 (repo seed 기준 출처 인용이 있는 꼬리 문구 52개 — 운영 RECONSTRUCTED 중 실제 남은 수만큼) ·
#           "가상 시나리오" 를 품은 RECONSTRUCTED 잔여 행은 아래 [residual] 로 따로 출력(자동 수정 안 함, 사람 검토)
#   bin/kamal app exec --reuse 'bin/rails silmu:content_migrate'   (적용 + 캐시 무효화)
# 롤백: 백업 JSON 의 필드 값을 update_columns 로 되돌린다.

dry = ENV["DRY_RUN"] == "1"
tag = "[audit-reconstructed-tail]"
fields = %w[issue detail lesson]
rows = 0
changes = 0
backup = []

ActiveRecord::Base.transaction(requires_new: true) do
  AuditCase.where(source_type: "SILMU_RECONSTRUCTED_CASE").order(:id).find_each do |ac|
    to_write = {}
    fields.each do |field|
      original = ac.read_attribute(field).to_s
      next if original.blank?

      value = AuditCaseProvenance.normalize_reconstruction_tail(original)
      next if value == original

      original.scan(AuditCaseProvenance::RECONSTRUCTION_TAIL_PATTERN) { puts "  #{tag} #{ac.slug}/#{field} OLD: #{Regexp.last_match[0]}" }
      to_write[field] = value
      changes += 1
    end

    residual = fields.select { |f| (to_write[f] || ac.read_attribute(f)).to_s.include?("가상 시나리오") }
    puts "  #{tag} [residual] #{ac.slug} #{residual.join(',')} — 출처 인용 없는 «가상 시나리오» 문구(사람 검토)" if residual.any?
    next if to_write.empty?

    rows += 1
    backup << { slug: ac.slug, id: ac.id, original: to_write.keys.index_with { |f| ac.read_attribute(f) } }
    puts "  #{tag} AuditCase/#{ac.slug} fields_to_change=#{to_write.keys.join(',')}"
    ac.update_columns(to_write.merge("updated_at" => Time.current)) unless dry
  end
end

if !dry && backup.any?
  dir = Rails.root.join("tmp/content_migration_backups")
  FileUtils.mkdir_p(dir)
  path = dir.join("20261005120000_audit_reconstructed_tail_wording-#{Time.current.strftime('%Y%m%d%H%M%S')}.json")
  File.write(path, JSON.pretty_generate(backup))
  puts "  #{tag} backup=#{path}"
end
puts "  #{tag} #{"DRY_RUN " if dry}rows=#{rows} changes=#{changes}"
