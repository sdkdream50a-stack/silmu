require "json"
AREAS = {
  "정보공개" => %w[정보공개 비공개 부분공개 청구인 이의신청],
  "개인정보" => %w[개인정보 영상정보 CCTV 파기 유출],
  "기록물"   => %w[기록물 문서보존 이관 편철 보존기간],
  "민원"     => %w[민원 고충 반복민원 특이민원 처리기한],
  "행정절차·법무" => %w[행정절차 사전통지 청문 의견제출 행정심판 소송],
  "시설·안전"  => %w[안전점검 시설물 산업안전 중대재해 소방],
  "문서·보고·위원회" => %w[위원회 회의록 기안 결재 공문],
  "디지털행정" => %w[정보시스템 홈페이지 전자결재 클라우드 공공데이터],
  "재산·물품" => %w[공유재산 물품관리 불용 대부 취득],
  "감사·청렴" => %w[청렴 이해충돌 김영란 부패 감사수감]
}
out = {}
AREAS.each do |area, kws|
  rows = kws.map do |kw|
    t = Topic.published.where("name ILIKE ? OR keywords ILIKE ? OR summary ILIKE ?", "%#{kw}%","%#{kw}%","%#{kw}%").pluck(:slug)
    g = Guide.published.where("title ILIKE ? OR summary ILIKE ?", "%#{kw}%","%#{kw}%").pluck(:slug)
    a = AuditCase.published.where("title ILIKE ? OR issue ILIKE ?", "%#{kw}%","%#{kw}%").count
    { kw: kw, topics: t, guides: g.first(4), guide_n: g.size, audits: a }
  end
  out[area] = { rows: rows,
                topic_slugs: rows.flat_map { |r| r[:topics] }.uniq,
                guide_n: rows.sum { |r| r[:guide_n] },
                audit_n: rows.sum { |r| r[:audits] } }
end
puts JSON.pretty_generate(out)
