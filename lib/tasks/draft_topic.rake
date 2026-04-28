# frozen_string_literal: true

# Sprint #4-A — Topic 초안 생성 rake task
# 권위자 검증: Coursera + Editorial Ops — silmu 콘텐츠 양적 확장의 진입점
# claude-haiku로 토픽 초안(law/decree/rule/commentary/summary/keywords/faqs/howto_steps/quick_stats) 생성
# 사용자가 tmp/topic_drafts/{slug}.json 검토 후 db/seeds로 정식 입력
namespace :draft do
  desc "토픽 초안 생성 — rails draft:topic[slug,category,name]"
  task :topic, [ :slug, :category, :name ] => :environment do |_, args|
    slug = args[:slug]
    category = args[:category]
    name = args[:name]

    if slug.blank? || category.blank? || name.blank?
      puts "사용법: rails draft:topic[<slug>,<category>,<name>]"
      puts "예시:   rails draft:topic[subsidy-application,subsidy,보조금 교부 신청]"
      puts ""
      puts "category: contract / budget / expense / salary / subsidy / property / travel / duty / other"
      exit 1
    end

    unless ENV["ANTHROPIC_API_KEY"].present?
      puts "❌ ANTHROPIC_API_KEY 환경변수가 필요합니다."
      exit 1
    end

    if Topic.exists?(slug: slug)
      puts "❌ 이미 같은 slug의 토픽이 존재합니다: #{slug}"
      exit 1
    end

    puts "📝 [#{slug}] #{name} 초안 생성 중..."
    draft = generate_topic_draft(slug: slug, category: category, name: name)
    if draft.nil?
      puts "❌ 초안 생성 실패"
      exit 1
    end

    out_dir = Rails.root.join("tmp", "topic_drafts")
    FileUtils.mkdir_p(out_dir)
    out_file = out_dir.join("#{slug}.json")
    File.write(out_file, JSON.pretty_generate(draft))

    puts "✅ 초안 저장: #{out_file}"
    puts ""
    puts "📋 다음 단계:"
    puts "   1. #{out_file} 파일 열어 사용자 검토 (법령 정확성·표현·금액)"
    puts "   2. 검토 후 db/seeds/topic_drafts.rb에 추가하거나 admin Topic 신규 작성 form에 입력"
    puts "   3. 입력 후 BlogLegalVerifier 검증: rails verify:topics_backfill"
  end
end

def generate_topic_draft(slug:, category:, name:)
  prompt = build_topic_prompt(slug: slug, category: category, name: name)
  json_text = call_claude_haiku(prompt)
  return nil if json_text.blank?

  # ```json … ``` fence 제거
  cleaned = json_text.gsub(/\A```(?:json)?\s*/m, "").gsub(/\s*```\s*\z/m, "").strip
  JSON.parse(cleaned)
rescue JSON::ParserError => e
  Rails.logger.warn "[draft:topic] JSON 파싱 실패: #{e.message}"
  puts "❌ AI 응답이 JSON 형식이 아닙니다. tmp/topic_drafts/_raw_#{slug}.txt 저장됨."
  File.write(Rails.root.join("tmp", "topic_drafts", "_raw_#{slug}.txt"), json_text.to_s)
  nil
end

def build_topic_prompt(slug:, category:, name:)
  category_label = Topic::CATEGORIES[category] || category
  <<~PROMPT
    당신은 silmu.kr (한국 공무원 실무 법령 가이드 사이트)의 콘텐츠 에디터입니다.
    아래 토픽의 초안을 JSON 형식으로 작성해주세요.

    토픽: #{name}
    slug: #{slug}
    category: #{category} (#{category_label})

    출력 형식 (JSON, ```json fence 없이 순수 JSON만):
    {
      "name": "토픽 이름",
      "slug": "#{slug}",
      "category": "#{category}",
      "summary": "1~2문장 요약 (100자 이내, 검색 의도 매칭형)",
      "keywords": "쉼표로 구분된 5~10개 키워드",
      "law_content": "관련 법률 조문 인용 (원문 또는 정확한 의역)",
      "decree_content": "관련 시행령 조문 인용",
      "rule_content": "관련 시행규칙 조문 인용 (없으면 빈 문자열)",
      "commentary": "실무 해설 800~1500자 (자주 하는 실수·감사 지적 포인트·실무 팁 포함)",
      "faqs": [{"question": "...", "answer": "..."}, ... 5~8개],
      "howto_steps": [{"name": "1단계 — ...", "text": "..."}, ... 5~7단계, 절차형이 아니면 빈 배열],
      "quick_stats": [{"label": "...", "value": "...", "note": "..."}, ... 3개, 핵심 수치/금액/한도]
    }

    필수 사항:
    - 인용 조문은 「법령명」 제X조 제Y항 제Z호 형식
    - 한국 지방·국가공무원 대상, 2026년 기준 최신 법령
    - 환각 방지: 확실하지 않으면 빈 문자열
    - 금액은 "2,000만원", "4억원", "200만원" 형식
    - JSON 외 다른 텍스트 출력 금지
  PROMPT
end

def call_claude_haiku(prompt)
  require "net/http"
  require "json"
  uri = URI("https://api.anthropic.com/v1/messages")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 90

  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request["x-api-key"] = ENV["ANTHROPIC_API_KEY"]
  request["anthropic-version"] = "2023-06-01"
  request.body = {
    model: "claude-haiku-4-5-20251001",
    max_tokens: 4000,
    messages: [ { role: "user", content: prompt } ]
  }.to_json

  response = http.request(request)
  unless response.is_a?(Net::HTTPSuccess)
    Rails.logger.warn "[draft:topic] Anthropic API #{response.code}: #{response.body[0, 200]}"
    return nil
  end
  data = JSON.parse(response.body)
  data.dig("content", 0, "text")
rescue => e
  Rails.logger.warn "[draft:topic] API 호출 오류: #{e.class} #{e.message}"
  nil
end
