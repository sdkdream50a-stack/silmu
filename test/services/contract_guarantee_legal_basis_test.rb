# frozen_string_literal: true

require "test_helper"

# P4 §11 — 계약보증금 계산기가 **실제로 계산하는 것**과 화면 근거가 맞는가.
#
# 기대값을 피검 대상(tool_trust.yml)에서 읽지 않는다 — 조문 목록은 이 파일이 직접 적는다.
# 근거 = 법제처 원문 대조 2026-09-20(법 MST 253973 · 영 286149 · 규칙 287365 · 인지세법 276139).
class ContractGuaranteeLegalBasisTest < ActiveSupport::TestCase
  S = ContractGuaranteeService

  LOCAL = "지방자치단체를 당사자로 하는 계약에 관한 법률"

  # [계산하는 것] => [ [법령 정식명, 조문], … ]
  # ⚠️ 문자열 부분일치로 재면 «제5조» 가 «제51조» 에 걸린다. 법령별 조문 목록으로 **정확히** 본다.
  COMPUTED = {
    "계약보증금"        => [ [ LOCAL, "제15조" ], [ "#{LOCAL} 시행령", "제51조" ], [ "#{LOCAL} 시행령", "제53조" ] ],
    "하자보수보증금"    => [ [ LOCAL, "제21조" ], [ "#{LOCAL} 시행령", "제71조" ], [ "#{LOCAL} 시행규칙", "제70조" ] ],
    "담보책임 존속기간" => [ [ LOCAL, "제20조" ], [ "#{LOCAL} 시행령", "제69조" ], [ "#{LOCAL} 시행규칙", "제68조" ],
                            [ "건설산업기본법 시행령", "제30조" ] ],
    "지연배상금"        => [ [ "#{LOCAL} 시행령", "제90조" ], [ "#{LOCAL} 시행규칙", "제75조" ] ],
    "인지세"            => [ [ "인지세법", "제3조" ] ]
  }.freeze

  setup { ToolTrust.reset! }

  # 법령 정식명 => 그 법령에 딸린 조문 집합. `raw` 는 세그먼트 원문이라 «제53조» 같은 이어붙은
  # 조문을 담지 않는다 — 해석된 구조에서 읽는다(2026-09-20 실측으로 투영을 정정).
  def articles_by_law
    ToolTrust.for("contract-guarantee").legal_references.each_with_object(Hash.new { |h, k| h[k] = [] }) do |r, out|
      out[r.display_name].concat(Array(r.articles))
    end
  end

  test "서비스가 실제로 하자보수보증금을 공종별로 계산한다 — laws 가 장식이 아님을 먼저 확인" do
    types = S.get_defect_work_types
    assert_operator types.size, :>=, 10
    rates = types.map { |t| t[:rate] }.uniq.sort
    assert_equal [ 2, 3, 5 ], rates, "요율 집합이 바뀌었다 — 근거 조문(규칙 §70)도 함께 재확인해야 한다"
    assert(types.all? { |t| t[:years].to_i.between?(1, 10) }, "존속기간이 영 §69 의 1~10년 범위를 벗어난다")
  end

  test "서비스가 인지세를 실제로 계산한다" do
    assert_operator S::STAMP_TAX_TABLE.size, :>=, 5
    assert(S::STAMP_TAX_TABLE.any? { |r| r[:tax].positive? })
  end

  test "계산하는 모든 축의 근거 조문이 화면 근거에 있다" do
    got = articles_by_law
    COMPUTED.each do |what, pairs|
      pairs.each do |law, article|
        assert_includes got[law], article, "«#{what}» 를 계산하는데 근거 «#{law} #{article}» 가 laws 에 없다"
      end
    end
  end

  test "근거 대조가 실제로 빠진 것을 잡는다" do  # 음성 대조 — 탐지 루프를 그대로 돌린다
    fake = { LOCAL => [ "제15조" ], "#{LOCAL} 시행령" => [ "제51조" ] }
    fake.default = []
    missing = COMPUTED["하자보수보증금"].reject { |law, article| fake[law].include?(article) }
    assert_equal 3, missing.size, "검사식이 죽어 있다 — 빠진 조문을 못 잡는다"
  end

  test "추가한 법령이 모두 원문 링크로 승격된다 — 이름을 지어내지 않았다" do
    refs = ToolTrust.for("contract-guarantee").legal_references
    unresolved = refs.reject(&:resolved?).map(&:law_name)
    assert_empty unresolved, "허용목록에 없어 링크가 안 되는 법령: #{unresolved.join(', ')}"
    names = refs.map(&:canonical_name).compact.uniq
    assert_includes names, "인지세법"
    assert_includes names, "건설산업기본법 시행령"
    assert_includes names, "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙"
  end

  test "basis 문구가 계산 범위를 그대로 말한다" do
    basis = ToolTrust.for("contract-guarantee").basis
    %w[계약보증금 하자보수보증금 지연배상금 인지세].each { |w| assert_includes basis, w }
  end
end
