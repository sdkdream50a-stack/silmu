# 계약 실무 참고 지표 서비스
# 값은 수동 입력이며 자동 갱신 작업이 없다. 화면에는 REFERENCE_MONTH를 "○○ 기준"으로 그대로 보여 주고
# "이달"·"매월 업데이트"처럼 최신인 듯한 표현을 쓰지 않는다. 값을 고칠 때 REFERENCE_MONTH도 함께 바꾼다.
class MonthlyIndicatorService
  REFERENCE_MONTH = "2026년 1월".freeze

  INDICATORS = [
    {
      key: :cpi,
      name: "소비자물가지수",
      value: "118.03",
      unit: "(2020=100)",
      change: "+2.0%",
      change_type: :up,
      source: "통계청"
    },
    {
      key: :construction_labor,
      name: "건설업 보통인부 노임",
      value: "171,037",
      unit: "원/일",
      change: "+0.4%",
      change_type: :up,
      source: "대한건설협회"
    },
    {
      key: :base_rate,
      name: "기준금리",
      value: "2.50",
      unit: "%",
      change: "-0.25%p",
      change_type: :down,
      source: "한국은행"
    },
    {
      key: :research_labor,
      name: "학술용역 책임급 인건비",
      value: "83,612",
      unit: "원/일",
      change: "+2.1%",
      change_type: :up,
      source: "행정안전부"
    }
  ].freeze

  def self.current
    {
      reference_month: REFERENCE_MONTH,
      indicators: INDICATORS
    }
  end
end
