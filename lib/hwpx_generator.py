#!/usr/bin/env python3
"""
HWPX 문서 생성기
stdin으로 JSON 데이터를 받아 HWPX 파일을 생성합니다.

사용법: echo '{"mode":"audit_case",...}' | python3 hwpx_generator.py
모드: audit_case | official_document | contract_reason | project_plan | annual_leave
"""
import sys
import json
from hwpx import HwpxDocument


def today_str():
    """오늘 날짜를 한국 공문서 형식으로 반환 (예: 2026. 3. 20.)"""
    from datetime import date
    d = date.today()
    return f"{d.year}. {d.month}. {d.day}."


def generate_audit_case(data, output_path):
    """감사사례 HWPX 문서 생성"""
    doc = HwpxDocument.new()

    title = data.get("title", "감사사례")
    doc.add_paragraph(title)
    doc.add_paragraph("")

    meta_parts = []
    if data.get("category"):
        meta_parts.append(f"카테고리: {data['category']}")
    if data.get("severity"):
        meta_parts.append(f"심각도: {data['severity']}")
    if data.get("legal_basis"):
        meta_parts.append(f"관련 법령: {data['legal_basis']}")
    if meta_parts:
        doc.add_paragraph(" | ".join(meta_parts))
        doc.add_paragraph("")

    issue = data.get("issue", "")
    if issue:
        doc.add_paragraph("■ 지적 사항")
        doc.add_paragraph(issue)
        doc.add_paragraph("")

    checkpoints = data.get("checkpoints", [])
    if checkpoints:
        doc.add_paragraph("■ 체크포인트")
        for cp in checkpoints:
            doc.add_paragraph(f"• {cp}")
        doc.add_paragraph("")

    lesson = data.get("lesson", "")
    if lesson:
        doc.add_paragraph("■ 조치·교훈")
        doc.add_paragraph(lesson)
        doc.add_paragraph("")

    doc.add_paragraph("출처: silmu.kr (실무 법률 가이드)")
    doc.save_to_path(output_path)


def generate_official_document(data, output_path):
    """공문서 HWPX 문서 생성"""
    doc = HwpxDocument.new()

    doc_type_label = data.get("doc_type_label", "공문서")
    doc.add_paragraph(doc_type_label)
    doc.add_paragraph("")

    content = data.get("content", "")
    for line in content.split("\n"):
        doc.add_paragraph(line)

    doc.save_to_path(output_path)


def generate_contract_reason(data, output_path):
    """수의계약 요청(사유)서 HWPX 문서 생성"""
    doc = HwpxDocument.new()

    # 제목
    doc.add_paragraph("수 의 계 약 요 청 (사 유) 서")
    doc.add_paragraph("")

    # 기본 정보 테이블 형태 (텍스트)
    contract_name = data.get("contract_name", "")
    type_label    = data.get("type_label", "")
    budget        = data.get("budget", "")
    budget_korean = data.get("budget_korean", "")
    vat_label     = data.get("vat_label", "")
    company       = data.get("company", "")
    business_no   = data.get("business_no", "")
    delivery      = data.get("delivery", "")
    dept          = data.get("dept", "○○과")
    manager       = data.get("manager", "")
    date_str      = data.get("date_str", today_str())

    rows = [
        ("계약건명",     contract_name),
        ("계약 구분",    type_label),
        ("소요예산",     f"금 {budget}원 ({budget_korean}원) [{vat_label}]"),
    ]
    if company:
        company_str = company
        if business_no:
            company_str += f" (사업자등록번호: {business_no})"
        rows.append(("계약업체", company_str))
    if delivery:
        rows.append(("납품(완료)기한", delivery))
    dept_str = dept
    if manager:
        dept_str += f" / {manager}"
    rows.append(("작성부서", dept_str))
    rows.append(("작성일",   date_str))

    for label, value in rows:
        doc.add_paragraph(f"  {label:<14}  {value}")
    doc.add_paragraph("")

    # 1. 수의계약 사유
    reason_detail = data.get("reason_detail", "")
    doc.add_paragraph("1. 수의계약 사유")
    doc.add_paragraph("")
    for line in reason_detail.split("\n"):
        doc.add_paragraph(f"  {line}")
    doc.add_paragraph("")

    # 2. 법적 근거
    reason_law      = data.get("reason_law", "")
    reason_law_text = data.get("reason_law_text", "")
    doc.add_paragraph("2. 법적 근거")
    doc.add_paragraph("")
    if reason_law:
        doc.add_paragraph(f"  {reason_law}")
    if reason_law_text:
        for line in reason_law_text.split("\n"):
            doc.add_paragraph(f"  {line}")
    doc.add_paragraph("")

    # 3. 추진경위 (있을 때만)
    background = data.get("background", "")
    section_num = 3
    if background:
        doc.add_paragraph(f"{section_num}. 추진경위")
        doc.add_paragraph("")
        for line in background.split("\n"):
            doc.add_paragraph(f"  {line}")
        doc.add_paragraph("")
        section_num += 1

    # 4. 향후 계획
    doc.add_paragraph(f"{section_num}. 향후 계획")
    doc.add_paragraph("")
    doc.add_paragraph(f"  가. 계약업체 선정 및 계약 체결")
    doc.add_paragraph(f"  나. 납품(공사) 진행 및 검수")
    doc.add_paragraph(f"  다. 대금 지급")
    doc.add_paragraph("")

    # 붙임
    doc.add_paragraph("붙임  1. 견적서 사본 1부.  끝.")
    doc.add_paragraph("")
    doc.add_paragraph(f"  {dept_str}")

    doc.save_to_path(output_path)


def generate_project_plan(data, output_path):
    """사업계획서 HWPX 문서 생성"""
    doc = HwpxDocument.new()

    # 제목
    doc.add_paragraph("사  업  계  획  서")
    doc.add_paragraph("")

    project_name  = data.get("project_name", "")
    department    = data.get("department", "○○과")
    manager       = data.get("manager", "")
    contact       = data.get("contact", "")
    budget        = data.get("budget", "")
    budget_korean = data.get("budget_korean", "")
    budget_item   = data.get("budget_item", "")
    date_str      = data.get("date_str", today_str())

    # 기본 정보
    rows = [
        ("사 업 명",   project_name),
        ("사업부서",   department),
    ]
    if manager:
        mgr = manager
        if contact:
            mgr += f" ({contact})"
        rows.append(("담당자", mgr))
    rows.append(("작성일", date_str))

    for label, value in rows:
        doc.add_paragraph(f"  {label:<10}  {value}")
    doc.add_paragraph("")

    section_num = 1

    # 1. 사업 필요성
    necessity = data.get("necessity", "")
    doc.add_paragraph(f"{section_num}. 사업 필요성")
    doc.add_paragraph("")
    for line in necessity.split("\n"):
        doc.add_paragraph(f"  {line}")
    doc.add_paragraph("")
    section_num += 1

    # 2. 현황 및 문제점 (선택)
    current_status = data.get("current_status", "")
    if current_status:
        doc.add_paragraph(f"{section_num}. 현황 및 문제점")
        doc.add_paragraph("")
        for line in current_status.split("\n"):
            doc.add_paragraph(f"  {line}")
        doc.add_paragraph("")
        section_num += 1

    # 3. 사업 내용
    content = data.get("content", "")
    doc.add_paragraph(f"{section_num}. 사업 내용")
    doc.add_paragraph("")
    for line in content.split("\n"):
        doc.add_paragraph(f"  {line}")
    doc.add_paragraph("")
    section_num += 1

    # 4. 추진 방법 및 일정 (선택)
    schedule = data.get("schedule", "")
    if schedule:
        doc.add_paragraph(f"{section_num}. 추진 방법 및 일정")
        doc.add_paragraph("")
        for line in schedule.split("\n"):
            doc.add_paragraph(f"  {line}")
        doc.add_paragraph("")
        section_num += 1

    # 5. 소요 예산
    doc.add_paragraph(f"{section_num}. 소요 예산")
    doc.add_paragraph("")
    doc.add_paragraph(f"  금액:    금 {budget}원 ({budget_korean}원)")
    if budget_item:
        doc.add_paragraph(f"  예산과목: {budget_item}")
    doc.add_paragraph("")
    section_num += 1

    # 6. 기대 효과 (선택)
    effect = data.get("effect", "")
    if effect:
        doc.add_paragraph(f"{section_num}. 기대 효과")
        doc.add_paragraph("")
        for line in effect.split("\n"):
            doc.add_paragraph(f"  {line}")
        doc.add_paragraph("")

    # 붙임
    doc.add_paragraph("붙임  1. 견적서 1부")
    doc.add_paragraph("      2. 수의계약 사유서 1부.  끝.")
    doc.add_paragraph("")
    doc.add_paragraph(f"  {department}")

    doc.save_to_path(output_path)


def generate_annual_leave(data, output_path):
    """연가 계산 결과 HWPX 문서 생성"""
    doc = HwpxDocument.new()

    # 제목
    doc.add_paragraph("연  가  일  수  계  산  결  과")
    doc.add_paragraph("")

    hire_date       = data.get("hire_date", "")
    ref_year        = data.get("ref_year", "")
    service_period  = data.get("service_period", "")
    granted_leave   = data.get("granted_leave", "")
    used_leave      = data.get("used_leave", "0")
    remaining_leave = data.get("remaining_leave", "")
    date_str        = data.get("date_str", today_str())

    # 기본 정보
    rows = [
        ("임 용 일",   hire_date),
        ("기 준 연 도", f"{ref_year}년"),
        ("재직기간",   service_period),
        ("계산일",    date_str),
    ]
    for label, value in rows:
        doc.add_paragraph(f"  {label:<10}  {value}")
    doc.add_paragraph("")

    # 연가 현황
    doc.add_paragraph("1. 연가 현황")
    doc.add_paragraph("")
    doc.add_paragraph(f"  부여 연가:    {granted_leave}일")
    doc.add_paragraph(f"  사용 연가:    {used_leave}일")
    doc.add_paragraph(f"  잔여 연가:    {remaining_leave}일")
    doc.add_paragraph("")

    # 연차수당
    annual_allowance_pay    = data.get("annual_allowance_pay", "")
    annual_allowance_detail = data.get("annual_allowance_detail", "")
    if annual_allowance_pay:
        doc.add_paragraph("2. 연차수당 (미사용 연가수당)")
        doc.add_paragraph("")
        doc.add_paragraph(f"  금액:  {annual_allowance_pay}")
        if annual_allowance_detail:
            doc.add_paragraph(f"  산출:  {annual_allowance_detail}")
        doc.add_paragraph("")

    # 연가보상비
    compensation_pay    = data.get("compensation_pay", "")
    compensation_detail = data.get("compensation_detail", "")
    if compensation_pay:
        section = "3" if annual_allowance_pay else "2"
        doc.add_paragraph(f"{section}. 연가보상비")
        doc.add_paragraph("")
        doc.add_paragraph(f"  금액:  {compensation_pay}")
        if compensation_detail:
            doc.add_paragraph(f"  산출:  {compensation_detail}")
        doc.add_paragraph("")

    # 관련 법령
    doc.add_paragraph("※ 관련 법령: 국가공무원 복무규정 제15조 (연가일수)")
    doc.add_paragraph("   출처: silmu.kr (실무 법률 가이드)")

    doc.save_to_path(output_path)


def main():
    try:
        data = json.load(sys.stdin)
        output_path = data.get("output_path")
        mode = data.get("mode", "audit_case")

        if not output_path:
            print("ERROR: output_path missing", file=sys.stderr)
            sys.exit(1)

        dispatch = {
            "audit_case":        generate_audit_case,
            "official_document": generate_official_document,
            "contract_reason":   generate_contract_reason,
            "project_plan":      generate_project_plan,
            "annual_leave":      generate_annual_leave,
        }

        fn = dispatch.get(mode)
        if fn:
            fn(data, output_path)
        else:
            generate_audit_case(data, output_path)

        print("OK")
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
