# frozen_string_literal: true

require "test_helper"

# F3 (2026-10-05 AdSense readiness) — 출처가 있는 «재구성» 사례의 꼬리 문구가 «가상 시나리오»라고 말하던 모순.
# 규칙: RECONSTRUCTED + 출처 인용 「…」(…p.N…) 이 있을 때만 «공개 사례를 기반으로 재구성한 사례 · 일부 각색» 으로 바꾼다.
#       가상(SIMULATED)은 그대로 «가상 시나리오». 페이지 번호는 본문에 있던 값만 쓴다.
class AuditCaseReconstructionTailTest < ActiveSupport::TestCase
  MIGRATION = Rails.root.join("db/content_migrations/20261005120000_audit_reconstructed_tail_wording.rb")
  TAIL = "> ※ 본 사례는 경기도교육청 「2021 감사사례집」(p.76) 패턴을 기반으로 학습용으로 재구성한 **가상 시나리오**입니다. " \
         "특정 학교의 실제 사례가 아니며 학습·실무 적용을 위한 교육용 자료입니다. 현행 법령 기준일: 지방계약법 2024-02-17 시행본."
  NO_CITE_TAIL = "※ 본 사례는 감사원·자치단체 감사결과보고서에 반복적으로 등장하는 패턴을 기반으로 작성된 **가상 시나리오**입니다."
  DOC = { "url" => "https://www.goe.go.kr/x.pdf", "publisher" => "경기도교육청 감사관실",
          "publication" => "감사사례집", "year" => 2021, "page" => 76 }.freeze

  def build(type, **attrs)
    AuditCase.new({ title: "t", slug: "t-#{SecureRandom.hex(4)}", source_type: type }.merge(attrs))
  end

  # ── 양성: 재구성 + 출처 인용 → 사실대로 ──
  test "reconstructed case with a page citation drops «가상 시나리오» and keeps the cited page and the law-date sentence" do
    out = build("SILMU_RECONSTRUCTED_CASE").presentable_text("본문\n\n#{TAIL}")
    refute_includes out, "가상 시나리오"
    refute_includes out, "실제 사례가 아니며"
    assert_includes out, "「2021 감사사례집」(p.76) 공개 사례를 기반으로 재구성한 사례입니다. 기관·인물·금액 등 일부는 각색했습니다."
    assert_includes out, "현행 법령 기준일: 지방계약법 2024-02-17 시행본."
  end

  test "handles the 교직원 / comma / named-school page variants seen in the seeds" do
    variant = "※ 본 사례는 경기도교육청 「2021 감사사례집」(S고등학교 p.9) 패턴을 기반으로 학습용으로 재구성한 **가상 시나리오**입니다. " \
              "특정 교직원의 실제 사례가 아니며, 학습·실무 적용을 위한 교육용 자료입니다."
    out = AuditCaseProvenance.normalize_reconstruction_tail(variant)
    assert_equal "※ 본 사례는 경기도교육청 「2021 감사사례집」(S고등학교 p.9) 공개 사례를 기반으로 재구성한 사례입니다. 기관·인물·금액 등 일부는 각색했습니다.", out
  end

  # ── 음성대조: 가상·출처 없음·실제는 건드리지 않는다 ──
  test "simulated case keeps «가상 시나리오» (it is true there)" do
    text = "본문 #{TAIL}"
    assert_equal text, build("SILMU_SIMULATED_CASE").presentable_text(text)
  end

  test "reconstructed text without a page citation is not rewritten (no page invented)" do
    assert_equal NO_CITE_TAIL, build("SILMU_RECONSTRUCTED_CASE").presentable_text(NO_CITE_TAIL)
  end

  test "non-reconstructed types are untouched" do
    assert_equal TAIL, build("ACTUAL_AUDIT").presentable_text(TAIL)
    assert_equal TAIL, build(nil).presentable_text(TAIL)
  end

  # ── 출처 한 줄 ──
  test "reconstruction_basis_text uses only stored source fields" do
    ac = build("SILMU_RECONSTRUCTED_CASE", source: DOC)
    assert_equal "경기도교육청 감사관실 「감사사례집」(2021) p.76 기반 재구성 · 기관·인물·금액 등 일부 각색", ac.reconstruction_basis_text

    no_page = build("SILMU_RECONSTRUCTED_CASE", source: DOC.except("page"))
    refute_includes no_page.reconstruction_basis_text, "p."
  end

  test "reconstruction_basis_text is nil for simulated, actual, and source-less reconstructed cases" do
    assert_nil build("SILMU_SIMULATED_CASE", source: DOC).reconstruction_basis_text
    assert_nil build("ACTUAL_AUDIT", source: DOC).reconstruction_basis_text
    assert_nil build("SILMU_RECONSTRUCTED_CASE").reconstruction_basis_text
  end

  # ── 재분류 안전: 문구를 고쳐도 ACTUAL 로 다시 올라가지 않는다 ──
  test "classifier still reads the corrected wording as reconstructed (not ACTUAL_AUDIT)" do
    fixed = AuditCaseProvenance.normalize_reconstruction_tail(TAIL)
    plan = AuditCaseProvenanceClassifier.plan_for(build(nil, source: DOC, detail: fixed))
    assert_equal "SILMU_RECONSTRUCTED_CASE", plan.source_type
  end

  test "POSITIVE CONTROL: classifier still promotes a plain document-backed case to ACTUAL_AUDIT" do
    assert_equal "ACTUAL_AUDIT", AuditCaseProvenanceClassifier.plan_for(build(nil, source: DOC, detail: "원문 발췌")).source_type
  end

  # ── content migration ──
  def create_case(slug, type, detail)
    AuditCase.create!(title: slug, slug: slug, source_type: type, detail: detail, issue: "지적", category: "회계", published: true)
  end

  test "migration: DRY_RUN writes nothing; apply rewrites reconstructed only; second run is a no-op" do
    recon = create_case("goe-2021-f3-recon", "SILMU_RECONSTRUCTED_CASE", "본문\n\n#{TAIL}")
    sim = create_case("sim-f3-case", "SILMU_SIMULATED_CASE", "본문\n\n#{TAIL}")
    recon_nocite = create_case("recon-f3-nocite", "SILMU_RECONSTRUCTED_CASE", NO_CITE_TAIL)

    out, = capture_io do
      ENV["DRY_RUN"] = "1"
      load MIGRATION
    ensure
      ENV.delete("DRY_RUN")
    end
    assert_includes out, "DRY_RUN rows=1 changes=1"
    assert_includes recon.reload.detail, "가상 시나리오", "DRY_RUN 이 DB 를 바꿨다"

    out, = capture_io { load MIGRATION }
    assert_includes out, "rows=1 changes=1"
    assert_includes out, "[residual] recon-f3-nocite", "출처 없는 재구성 잔여 문구를 보고하지 않았다"
    refute_includes recon.reload.detail, "가상 시나리오"
    assert_includes recon.detail, "(p.76) 공개 사례를 기반으로 재구성한 사례입니다."
    assert_includes sim.reload.detail, "가상 시나리오", "가상 사례 본문을 바꿨다"
    assert_equal NO_CITE_TAIL, recon_nocite.reload.detail

    out, = capture_io { load MIGRATION }
    assert_includes out, "rows=0 changes=0"
  ensure
    FileUtils.rm_f(Dir[Rails.root.join("tmp/content_migration_backups/20261005120000_audit_reconstructed_tail_wording-*.json")])
  end
end
