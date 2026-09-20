# frozen_string_literal: true

module ReviewLab
  # 업로드 문서 1건을 구조화한 결과. 원본 바이트는 들고 있지 않는다 — 요청이 끝나면 사라진다.
  #
  # label 은 화면 표시명이다. 원본 파일명은 쓰지 않는다
  # («홍길동_견적서.pdf» 처럼 파일명 자체가 개인정보인 경우가 흔하다).
  #
  # segments = [{ text:, locator:, cells: }] — locator 는 사람이 원문에서 찾아갈 수 있는 위치
  # («p.2 12행» / «문단 14» / «표 1 · 3행» / «Sheet1 R7»). cells 는 표 행일 때만 있다.
  class DocumentArtifact
    ROLES = {
      "quote" => "견적서", "comparison_quote" => "비교견적서",
      "notice" => "입찰공고문", "task_order" => "과업지시서", "spec" => "규격서(사양서)",
      "special_terms" => "특수조건", "rfp" => "제안요청서", "cost_sheet" => "산출내역서",
      # P4 — 예산문서 슬라이스
      "project_plan" => "사업계획서", "cost_basis" => "산출기초(산출내역)",
      "other" => "기타 첨부"
    }.freeze

    FORMAT_LABELS = { pdf: "PDF", docx: "DOCX", xlsx: "XLSX", hwpx: "HWPX", image: "이미지" }.freeze

    attr_reader :role, :label, :format, :segments, :status, :error

    def initialize(role:, label:, format:, segments: [], status: :ok, error: nil)
      @role = role
      @label = label
      @format = format
      @segments = segments
      @status = status
      @error = error
    end

    def ok? = status == :ok
    def role_label = ROLES.fetch(role, "문서")
    def format_label = FORMAT_LABELS.fetch(format, "알 수 없음")
    def display_name = "#{label} (#{role_label} · #{format_label})"
    def full_text = segments.map { |s| s[:text] }.join("\n")
  end
end
