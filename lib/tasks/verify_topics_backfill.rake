# frozen_string_literal: true

# 모든 published Topic의 인용 조문 일괄 검증·기록.
# BlogLegalVerifier를 활용해 law/decree/rule_content + commentary의
# "<법령명> 제X조" 패턴을 법제처 API로 교차검증하고 결과를 stdout으로 보고.
# Topic.law_verified_at / law_base_date를 모두 갱신해 E-E-A-T 메타 신선도 확보.
namespace :verify do
  desc "모든 published Topic의 인용 조문 일괄 검증·law_verified_at 갱신"
  task topics_backfill: :environment do
    puts "🔍 silmu 법령 검증 백필 시작 (#{Topic.published.count}건)"
    puts ""

    verifier = BlogLegalVerifier.new
    issue_topics = []
    today = Time.zone.today.strftime("%Y.%m.%d")

    Topic.published.find_each do |t|
      text = [ t.law_content, t.decree_content, t.rule_content, t.commentary ]
              .map(&:to_s).reject(&:blank?).join("\n\n")
      if text.blank?
        puts "[#{t.slug}] (콘텐츠 비어있음 — 검증 스킵)"
        next
      end

      result = verifier.verify(text)

      # callbacks 우회 + updated_at 갱신 안 하기 (콘텐츠 변경 아님)
      t.update_columns(
        law_verified_at: Time.current,
        law_base_date: today
      )

      flag = result[:valid] ? "✅" : "⚠️"
      puts "#{flag} [#{t.slug}] valid=#{result[:valid]} issues=#{result[:issue_count]}"
      next if result[:valid]

      issue_topics << { slug: t.slug, name: t.name, issues: result[:issues] }
    end

    puts ""
    puts "—" * 60
    puts "📊 백필 완료: #{Topic.published.count}건 검증"
    puts "   law_verified_at NULL 잔여: #{Topic.where(law_verified_at: nil).count}"
    puts ""

    if issue_topics.any?
      puts "⚠️  이슈 발견 토픽 #{issue_topics.size}건:"
      issue_topics.each do |it|
        puts "   • #{it[:slug]} (#{it[:name]})"
        it[:issues].first(3).each do |iss|
          puts "     - [#{iss[:type]}] found: #{iss[:found].to_s.truncate(60)}"
          puts "       expected: #{iss[:correct].to_s.truncate(60)}" if iss[:correct].present?
          puts "       source:   #{iss[:source]}"
        end
      end
      puts ""
      puts "💡 위 이슈는 콘텐츠 검토 후 수동 수정 필요 (자동 수정 비활성)"
    else
      puts "🎉 모든 토픽 인용 조문 정합성 통과"
    end
  end
end
