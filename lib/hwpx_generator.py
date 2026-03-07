#!/usr/bin/env python3
"""
HWPX 문서 생성기
stdin으로 JSON 데이터를 받아 HWPX 파일을 생성합니다.

사용법: echo '{"mode":"audit_case",...}' | python3 hwpx_generator.py
"""
import sys
import json
from hwpx import HwpxDocument


def generate_audit_case(data, output_path):
    """감사사례 HWPX 문서 생성"""
    doc = HwpxDocument.new()

    # 제목
    title = data.get("title", "감사사례")
    doc.add_paragraph(title)
    doc.add_paragraph("")

    # 메타정보 (카테고리 | 심각도 | 관련법령)
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

    # 지적 사항
    issue = data.get("issue", "")
    if issue:
        doc.add_paragraph("■ 지적 사항")
        doc.add_paragraph(issue)
        doc.add_paragraph("")

    # 체크포인트
    checkpoints = data.get("checkpoints", [])
    if checkpoints:
        doc.add_paragraph("■ 체크포인트")
        for cp in checkpoints:
            doc.add_paragraph(f"• {cp}")
        doc.add_paragraph("")

    # 교훈/조치사항
    lesson = data.get("lesson", "")
    if lesson:
        doc.add_paragraph("■ 조치·교훈")
        doc.add_paragraph(lesson)
        doc.add_paragraph("")

    # 출처
    doc.add_paragraph("출처: silmu.kr (실무 법률 가이드)")

    doc.save_to_path(output_path)


def generate_official_document(data, output_path):
    """공문서 HWPX 문서 생성"""
    doc = HwpxDocument.new()

    # 문서 유형 헤더
    doc_type_label = data.get("doc_type_label", "공문서")
    doc.add_paragraph(doc_type_label)
    doc.add_paragraph("")

    # 공문 내용 (plain text — 줄바꿈 기준으로 단락 분리)
    content = data.get("content", "")
    for line in content.split("\n"):
        doc.add_paragraph(line)

    doc.save_to_path(output_path)


def main():
    try:
        data = json.load(sys.stdin)
        output_path = data.get("output_path")
        mode = data.get("mode", "audit_case")

        if not output_path:
            print("ERROR: output_path missing", file=sys.stderr)
            sys.exit(1)

        if mode == "official_document":
            generate_official_document(data, output_path)
        else:
            generate_audit_case(data, output_path)

        print("OK")
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
