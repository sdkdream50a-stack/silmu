# frozen_string_literal: true

# Sprint #5-A — Topic 초안 자동 발행 (Coursera + Editorial Ops 권위자)
#
# Flow:
#   1. lib/tasks/draft_topic.rake 가 tmp/topic_drafts/{slug}.json 생성
#   2. 본 rake가 그 JSON을 읽어 Topic.create
#   3. BlogLegalVerifier로 자동 검증
#   4. issues=0 → published: true (즉시 silmu.kr 노출)
#   5. issues>0 → published: false + STDOUT 보고 (사용자 수동 검토)
namespace :draft do
  desc "토픽 초안 JSON을 검증·발행 — rails draft:topic_publish[<slug>]"
  task :topic_publish, [ :slug ] => :environment do |_, args|
    slug = args[:slug]
    if slug.blank?
      puts "사용법: rails draft:topic_publish[<slug>]"
      exit 1
    end

    json_path = Rails.root.join("tmp", "topic_drafts", "#{slug}.json")
    unless json_path.exist?
      puts "❌ 초안 파일 없음: #{json_path}"
      puts "   먼저 rails draft:topic[#{slug},<category>,<name>] 으로 생성"
      exit 1
    end

    if Topic.exists?(slug: slug)
      puts "❌ 이미 같은 slug의 토픽 존재: #{slug} — 별도 처리 필요"
      exit 1
    end

    draft = JSON.parse(File.read(json_path))

    # BlogLegalVerifier 사전 검증 (DB 저장 전)
    verify_text = [ draft["law_content"], draft["decree_content"], draft["rule_content"], draft["commentary"] ]
                    .map(&:to_s).reject(&:blank?).join("\n\n")
    verifier_result = BlogLegalVerifier.new.verify(verify_text)

    publishable = verifier_result[:valid] && verifier_result[:issue_count].zero?
    today = Time.zone.today.strftime("%Y.%m.%d")

    topic_attrs = {
      slug: slug,
      name: draft["name"],
      summary: draft["summary"],
      keywords: draft["keywords"],
      category: draft["category"],
      law_content: draft["law_content"],
      decree_content: draft["decree_content"],
      rule_content: draft["rule_content"],
      commentary: draft["commentary"],
      faqs: draft["faqs"],
      howto_steps: draft["howto_steps"],
      quick_stats: draft["quick_stats"],
      published: publishable,
      law_verified_at: Time.current,
      law_base_date: today,
      view_count: 0
    }

    topic = Topic.create!(topic_attrs)

    puts ""
    if publishable
      puts "✅ [#{slug}] 검증 통과 + 즉시 발행 (#{topic.id})"
      puts "   https://silmu.kr/topics/#{slug}"
    else
      puts "⚠️  [#{slug}] 검증 실패 — published=false (#{topic.id})"
      puts "   사용자 수동 검토 후 admin/topics 에서 published=true 처리 필요"
      puts ""
      puts "   이슈 #{verifier_result[:issue_count]}건:"
      verifier_result[:issues].each do |iss|
        puts "   - [#{iss[:type]}] #{iss[:found].to_s.truncate(80)}"
        puts "     expected: #{iss[:correct].to_s.truncate(80)}" if iss[:correct].present?
        puts "     source:   #{iss[:source]}"
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "❌ Topic 생성 실패: #{e.message}"
    exit 1
  rescue JSON::ParserError => e
    puts "❌ JSON 파싱 실패: #{e.message}"
    exit 1
  end

  desc "토픽 초안 일괄 발행 — tmp/topic_drafts/*.json 모두 처리"
  task topic_publish_all: :environment do
    drafts_dir = Rails.root.join("tmp", "topic_drafts")
    unless drafts_dir.exist?
      puts "❌ #{drafts_dir} 폴더 없음"
      exit 1
    end

    files = Dir.glob(drafts_dir.join("*.json")).reject { |f| File.basename(f).start_with?("_") }
    puts "📚 일괄 발행 시작 (#{files.size}건)"
    files.each do |f|
      slug = File.basename(f, ".json")
      Rake::Task["draft:topic_publish"].reenable
      Rake::Task["draft:topic_publish"].invoke(slug)
    end
  end
end
