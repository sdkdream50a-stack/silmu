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
    stub_client = Object.new
    stub_client.define_singleton_method(:messages) { |**_| stub_response }

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
    error_client.define_singleton_method(:messages) { |**_| raise "API 연결 실패" }

    original_new = Anthropic::Client.method(:new)
    Anthropic::Client.define_singleton_method(:new) { |**_| error_client }
    begin
      result = @service_guest.answer("테스트 질문")
      assert result[:error].present?
    ensure
      Anthropic::Client.define_singleton_method(:new, original_new)
    end
  end
end
