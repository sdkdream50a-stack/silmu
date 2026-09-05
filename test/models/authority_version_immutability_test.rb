# frozen_string_literal: true

require "test_helper"

# P1.5 §8·§46 — AuthorityVersion 은 IMMUTABLE 이다.
# 이 불변성이 깨지면 "그때 무엇을 보고 검증했는가"를 되짚을 수 없고 현행화 이력 전체가 무의미해진다.
class AuthorityVersionImmutabilityTest < ActiveSupport::TestCase
  include AuthorityTestHelper

  setup do
    @document = create_document
    detector_with(build_success_result).check(@document)
    @version = @document.reload.authority_versions.first
  end

  test "POSITIVE CONTROL — 생성은 정상 동작한다 (불변성 테스트가 무의미하지 않음을 보인다)" do
    assert @version.persisted?
    assert_equal Date.new(2026, 6, 3), @version.effective_at
    assert_equal 64, @version.content_hash.length
  end

  test "저장된 버전은 수정할 수 없다" do
    assert_raises(AuthorityVersion::ImmutableError) { @version.update!(effective_at: Date.current) }
    assert_raises(AuthorityVersion::ImmutableError) { @version.update!(normalized_content: "변조") }
    assert_raises(AuthorityVersion::ImmutableError) { @version.update!(content_hash: "x" * 64) }
  end

  test "버전을 개별 삭제할 수 없다" do
    assert_raises(AuthorityVersion::ImmutableError) { @version.destroy }
    assert AuthorityVersion.exists?(@version.id)
  end

  test "문서를 삭제하면 버전도 함께 제거된다 (연관 삭제는 허용)" do
    id = @version.id
    @document.destroy
    refute AuthorityVersion.exists?(id)
  end

  test "개정은 덮어쓰기가 아니라 새 버전 추가다" do
    detector_with(build_success_result(revision_number: "99999")).check(@document.reload)
    versions = @document.reload.authority_versions.order(:fetched_at)
    assert_equal 2, versions.count
    assert_equal "36338", versions.first.revision_number, "이전 버전이 덮어써졌다"
    assert_equal "99999", versions.last.revision_number
  end

  test "hash 는 정규화된 본문에서 계산된다" do
    assert_equal AuthorityVersion.digest(@version.normalized_content), @version.content_hash
  end
end
