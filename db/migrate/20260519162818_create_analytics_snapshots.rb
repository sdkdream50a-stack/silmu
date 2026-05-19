# P8 ROI 계측 — GA4 페이지별 지표 스냅샷 저장
#
# 사용: 베이스라인(배포 직전 7~30일 평균)과 배포 후 추이를 같은 테이블에 보관.
# label로 동일 스냅샷 묶음을 식별하고, page_path 단위로 행을 분리.

class CreateAnalyticsSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :analytics_snapshots do |t|
      t.string   :label,       null: false
      t.string   :page_path,   null: false
      t.integer  :days,        null: false
      t.datetime :captured_at, null: false
      t.jsonb    :metrics,     null: false, default: {}
      t.text     :notes
      t.timestamps
    end

    add_index :analytics_snapshots, [ :label, :page_path ]
    add_index :analytics_snapshots, :captured_at
  end
end
