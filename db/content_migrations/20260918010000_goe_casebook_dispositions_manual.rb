# 경기도교육청 감사사례집 재구성 사례 — 자동 매칭 미달 12건 처분 절 수기 대조 정정 (2026-09-17 전수감사 G-13)
#
# 20260918000000 은 설명문 2-gram 일치 0.5 이상 50건만 고쳤다. 나머지 12건은 사례집 원문 줄을 직접 읽어 처분을 확정했다
# (goe.txt 행 번호: 괄호). 한 silmu 사례가 사례집의 여러 항목을 합친 경우 항목별 처분을 함께 적는다.

dispositions = {
  "goe-2021-accounting-disorder-construction" => "담당자 주의, 관리자 경고", # L3235
  "goe-2021-condolence-money-improper" => "담당자 주의, 부당집행액 회수 조치", # L3271
  "goe-2021-deemed-budget-violation" => "관련자 주의", # L2917
  "goe-2021-football-team-extension-contract" => "관련자 경고(요구)", # L4046
  "goe-2021-overtime-allowance-mispayment" => "관련자 주의, 부당지급액 회수(근무일수 감액·방과후 수당 중복) / 관련자 주의(요구)(초과근무확인대장)", # L5363·L5383
  "goe-2021-public-property-occupation-violation" => "관련자 주의(농작물 경작 방치) / 관련자(행정실장) 경고, 업무담당자 및 학교장 주의, 변상금 세입조치(구조물·대부료·무단점유)", # L5586·L5596
  "goe-2021-special-duty-allowance-mispayment" => "현지조치, 과소지급액 추가 지급 및 과다지급액 회수", # L5301
  "goe-2021-split-after-school-program" => "관련자 주의, 관리자(교장) 경고", # L3929
  "goe-2021-split-care-trip-copier-paint" => "관련자 주의", # L3956
  "goe-2021-supplies-selection-committee" => "관련자 주의", # L4170
  "goe-2021-suspension-pay-deduction" => "관련자 주의, 과소지급액 추가지급 및 과다지급액 회수", # L5168
  "goe-2021-temporary-building-violation" => "관련자 주의 및 기관주의(가설건축물) / 기관경고(타 건 병합)(직속기관 건축물)" # L5677·L5687
}

note = lambda do |disposition|
  "- 사례집 원문 처분: «#{disposition}» (경기도교육청 감사사례집, 2021)\n" \
    "- 사례집은 사례를 재구성·편집해 처분 내용·대상자·수위가 실제와 다를 수 있다고 밝히고 있습니다. 이 밖의 징계·고발·변상 서술은 원문에 없습니다.\n"
end

section = /(^\#{2,3} 처분(?: 결과)?[ \t]*\n)(.*?)(?=^\#{1,3} |\z)/m
year_head = /(^\#\# 사건 개요[ \t]*\n\s*)20\d\d년[^,\n]{0,25}, /

dry_run = ENV["DRY_RUN"] == "1"
changed = 0

ActiveRecord::Base.transaction do
  dispositions.each do |slug, disposition|
    record = AuditCase.find_by!(slug: slug)
    detail = record.detail.to_s
    raise "DISPOSITION_SECTION_NOT_FOUND #{slug}" unless detail.match?(section)

    updated = detail.sub(section) { "#{Regexp.last_match(1)}#{note.call(disposition)}\n" }
    updated = updated.sub(year_head, '\1')
    next if updated == detail

    record.update_columns(detail: updated, updated_at: Time.current) unless dry_run
    changed += 1
  end
  puts "  [g13-goe-manual] #{dry_run ? 'DRY_RUN ' : ''}changes=#{changed}"
  raise ActiveRecord::Rollback if dry_run
end
