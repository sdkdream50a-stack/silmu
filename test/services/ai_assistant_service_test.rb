require "test_helper"
require "ostruct"

class AiAssistantServiceTest < ActiveSupport::TestCase
  setup do
    @service_guest = AiAssistantService.new
    @service_user  = AiAssistantService.new(user: users(:one))
  end

  # --- 한도 관리 (define_singleton_method으로 :null_store 캐시 우회) ---

  test "게스트 3회 미만은 한도 초과 아님" do
    @service_guest.define_singleton_method(:current_usage) { |_| 2 }
    refute @service_guest.limit_exceeded?("1.2.3.4")
  end

  test "게스트 3회 도달 시 한도 초과" do
    @service_guest.define_singleton_method(:current_usage) { |_| 3 }
    assert @service_guest.limit_exceeded?("1.2.3.5")
  end

  test "로그인 사용자 19회는 한도 미초과" do
    @service_user.define_singleton_method(:current_usage) { |_| 19 }
    refute @service_user.limit_exceeded?(users(:one).id.to_s)
  end

  test "로그인 사용자 20회 도달 시 한도 초과" do
    @service_user.define_singleton_method(:current_usage) { |_| 20 }
    assert @service_user.limit_exceeded?(users(:one).id.to_s)
  end

  test "remaining_count 잔여 횟수 정확히 반환" do
    @service_guest.define_singleton_method(:current_usage) { |_| 2 }
    assert_equal 1, @service_guest.remaining_count("1.2.3.6")
  end

  test "로그인 사용자 remaining_count 초기값 20" do
    @service_user.define_singleton_method(:current_usage) { |_| 0 }
    assert_equal 20, @service_user.remaining_count(users(:two).id.to_s)
  end

  # --- answer 메서드 ---

  test "API 키 미설정 시 에러 반환" do
    original = ENV.delete("ANTHROPIC_API_KEY")
    service = AiAssistantService.new
    result = service.answer("테스트 질문")
    assert result[:error].present?
  ensure
    ENV["ANTHROPIC_API_KEY"] = original if original
  end

  test "answer 정상 응답 시 text 반환" do
    original_key = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = "test-key"
    service = AiAssistantService.new

    stub_text = "수의계약은 경쟁 없이 계약하는 방식입니다."
    stub_response = OpenStruct.new(content: [ OpenStruct.new(text: stub_text) ])
    # Anthropic SDK 1.x: client.messages.create(...) 패턴
    stub_messages = Object.new
    stub_messages.define_singleton_method(:create) { |**_| stub_response }
    stub_client = Object.new
    stub_client.define_singleton_method(:messages) { stub_messages }

    original_new = Anthropic::Client.method(:new)
    Anthropic::Client.define_singleton_method(:new) { |**_| stub_client }
    begin
      result = service.answer("수의계약이란?")
      assert result[:text].present?
    ensure
      Anthropic::Client.define_singleton_method(:new, original_new)
      ENV["ANTHROPIC_API_KEY"] = original_key
    end
  end

  test "answer API 오류 시 error 반환" do
    error_client = Object.new
    error_messages = Object.new
    error_messages.define_singleton_method(:create) { |**_| raise "API 연결 실패" }
    error_client.define_singleton_method(:messages) { error_messages }

    original_new = Anthropic::Client.method(:new)
    Anthropic::Client.define_singleton_method(:new) { |**_| error_client }
    begin
      result = @service_guest.answer("테스트 질문")
      assert result[:error].present?
    ensure
      Anthropic::Client.define_singleton_method(:new, original_new)
    end
  end

  # --- P3 Sprint 2 — 공통표준용어 후처리 ---

  test "answer 응답에 StandardTermCorrector 후처리 적용 (term_changes·compliance_rate 키 포함)" do
    StandardTerm.expire_synonym_index!
    term = StandardTerm.find_or_create_by!(term_korean: "계약상대자") { |t| t.synonyms = [ "계약 상대자" ] }

    original_key = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = "test-key"
    service = AiAssistantService.new

    stub_text = "계약 상대자에게 통보합니다."
    stub_response = OpenStruct.new(content: [ OpenStruct.new(text: stub_text) ])
    stub_messages = Object.new
    stub_messages.define_singleton_method(:create) { |**_| stub_response }
    stub_client = Object.new
    stub_client.define_singleton_method(:messages) { stub_messages }

    original_new = Anthropic::Client.method(:new)
    Anthropic::Client.define_singleton_method(:new) { |**_| stub_client }
    begin
      result = service.answer("질문")
      assert_equal "계약상대자에게 통보합니다.", result[:text]
      assert_equal stub_text, result[:original_text]
      assert_equal 1, result[:term_changes].size
      # "계약 상대자에게 통보합니다." 어절 3개 / 변경 1개 → 1 - 1/3 = 0.667
      assert_in_delta 0.667, result[:term_compliance_rate], 0.001
    ensure
      Anthropic::Client.define_singleton_method(:new, original_new)
      ENV["ANTHROPIC_API_KEY"] = original_key
      term.destroy
      StandardTerm.expire_synonym_index!
    end
  end

  test "answer 변경 없으면 changes 빈 배열 + compliance_rate 1.0" do
    StandardTerm.expire_synonym_index!

    original_key = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = "test-key"
    service = AiAssistantService.new

    stub_text = "특별히 치환할 단어가 없는 문장입니다."
    stub_response = OpenStruct.new(content: [ OpenStruct.new(text: stub_text) ])
    stub_messages = Object.new
    stub_messages.define_singleton_method(:create) { |**_| stub_response }
    stub_client = Object.new
    stub_client.define_singleton_method(:messages) { stub_messages }

    original_new = Anthropic::Client.method(:new)
    Anthropic::Client.define_singleton_method(:new) { |**_| stub_client }
    begin
      result = service.answer("질문")
      assert_equal stub_text, result[:text]
      assert_equal stub_text, result[:original_text]
      assert_equal [], result[:term_changes]
      assert_equal 1.0, result[:term_compliance_rate]
    ensure
      Anthropic::Client.define_singleton_method(:new, original_new)
      ENV["ANTHROPIC_API_KEY"] = original_key
    end
  end
end
