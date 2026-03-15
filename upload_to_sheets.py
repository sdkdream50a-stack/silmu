#!/usr/bin/env python3
"""
블로그 포스팅 주제 148개를 Google Sheets에 업로드
사전 준비: pip install gspread google-auth
"""

import csv
import gspread
from google.oauth2.service_account import Credentials
from google.oauth2 import service_account
import os
import sys

CSV_FILE = os.path.join(os.path.dirname(__file__), "blog_topics.csv")

# 카테고리별 배경색 (RGB)
CATEGORY_COLORS = {
    "계약·조달": {"red": 1.0, "green": 0.95, "blue": 0.8},   # 주황 계열
    "예산·회계": {"red": 0.85, "green": 0.95, "blue": 0.85},  # 녹색 계열
    "복무·급여": {"red": 0.85, "green": 0.9, "blue": 1.0},    # 파란 계열
}

SUBCATEGORY_COLORS = {
    "계약/조달":    {"red": 1.0,  "green": 0.97, "blue": 0.9},
    "예산/회계":    {"red": 0.92, "green": 0.98, "blue": 0.92},
    "감사/법령해석": {"red": 0.95, "green": 0.98, "blue": 0.9},
    "시도별 특화":  {"red": 0.9,  "green": 0.97, "blue": 0.9},
    "민원/서식":    {"red": 0.93, "green": 0.98, "blue": 0.93},
    "인사/급여":    {"red": 0.9,  "green": 0.93, "blue": 1.0},
    "복무/출장/여비":{"red": 0.93, "green": 0.95, "blue": 1.0},
    "교육청/교직원": {"red": 0.95, "green": 0.92, "blue": 1.0},
}

def load_csv():
    rows = []
    with open(CSV_FILE, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    return rows

def connect_sheets():
    """
    Google Sheets 연결 — 브라우저 OAuth 인증 (Service Account 불필요)
    최초 실행 시 브라우저가 열리고 구글 계정으로 로그인하면 자동 완료
    """
    # gspread.oauth()는 ~/.config/gspread/credentials.json 을 읽고
    # 최초 1회만 브라우저 인증 → 이후 토큰 자동 저장
    try:
        client = gspread.oauth()
        return client
    except Exception as e:
        print("=" * 60)
        print(f"OAuth 인증 실패: {e}")
        print()
        print("수동 설정 방법:")
        print("1. https://console.cloud.google.com → 새 프로젝트 생성")
        print("2. API 라이브러리 → Google Sheets API / Google Drive API 활성화")
        print("3. OAuth 동의 화면 → 외부 선택 → 앱 이름 입력 → 저장")
        print("4. 사용자 인증 정보 → OAuth 2.0 클라이언트 ID → 데스크톱 앱 선택")
        print("5. JSON 다운로드 → ~/.config/gspread/credentials.json 저장")
        print("6. 이 스크립트 다시 실행 (브라우저 인증 창 뜸)")
        print("=" * 60)
        sys.exit(1)

def create_spreadsheet(client, rows):
    # 스프레드시트 생성
    sh = client.create("블로그 포스팅 주제 148선 — silmu.kr")
    ws = sh.sheet1
    ws.update_title("전체목록")

    print(f"스프레드시트 생성: {sh.url}")

    # 헤더
    headers = ["카테고리", "소분류", "번호", "포스팅 제목", "핵심 키워드"]
    all_data = [headers] + [
        [r["카테고리"], r["소분류"], r["번호"], r["포스팅 제목"], r["핵심 키워드"]]
        for r in rows
    ]

    ws.update("A1", all_data)

    # 열 너비 설정
    requests = [
        {"updateDimensionProperties": {
            "range": {"sheetId": ws.id, "dimension": "COLUMNS", "startIndex": 0, "endIndex": 1},
            "properties": {"pixelSize": 110}, "fields": "pixelSize"}},
        {"updateDimensionProperties": {
            "range": {"sheetId": ws.id, "dimension": "COLUMNS", "startIndex": 1, "endIndex": 2},
            "properties": {"pixelSize": 120}, "fields": "pixelSize"}},
        {"updateDimensionProperties": {
            "range": {"sheetId": ws.id, "dimension": "COLUMNS", "startIndex": 2, "endIndex": 3},
            "properties": {"pixelSize": 50}, "fields": "pixelSize"}},
        {"updateDimensionProperties": {
            "range": {"sheetId": ws.id, "dimension": "COLUMNS", "startIndex": 3, "endIndex": 4},
            "properties": {"pixelSize": 500}, "fields": "pixelSize"}},
        {"updateDimensionProperties": {
            "range": {"sheetId": ws.id, "dimension": "COLUMNS", "startIndex": 4, "endIndex": 5},
            "properties": {"pixelSize": 250}, "fields": "pixelSize"}},
    ]

    # 헤더 스타일
    requests.append({
        "repeatCell": {
            "range": {"sheetId": ws.id, "startRowIndex": 0, "endRowIndex": 1},
            "cell": {
                "userEnteredFormat": {
                    "backgroundColor": {"red": 0.2, "green": 0.2, "blue": 0.6},
                    "textFormat": {"foregroundColor": {"red": 1, "green": 1, "blue": 1},
                                   "bold": True, "fontSize": 11},
                    "horizontalAlignment": "CENTER",
                }
            },
            "fields": "userEnteredFormat(backgroundColor,textFormat,horizontalAlignment)"
        }
    })

    # 행 높이 (데이터 행)
    requests.append({
        "updateDimensionProperties": {
            "range": {"sheetId": ws.id, "dimension": "ROWS", "startIndex": 1, "endIndex": len(rows) + 1},
            "properties": {"pixelSize": 28},
            "fields": "pixelSize"
        }
    })

    # 카테고리/소분류별 배경색
    for i, row in enumerate(rows):
        row_idx = i + 1  # 헤더 제외
        cat = row["카테고리"]
        sub = row["소분류"]
        color = SUBCATEGORY_COLORS.get(sub, CATEGORY_COLORS.get(cat, {"red": 1, "green": 1, "blue": 1}))

        requests.append({
            "repeatCell": {
                "range": {"sheetId": ws.id,
                           "startRowIndex": row_idx, "endRowIndex": row_idx + 1,
                           "startColumnIndex": 0, "endColumnIndex": 5},
                "cell": {"userEnteredFormat": {"backgroundColor": color}},
                "fields": "userEnteredFormat.backgroundColor"
            }
        })

    # 테두리
    requests.append({
        "updateBorders": {
            "range": {"sheetId": ws.id,
                       "startRowIndex": 0, "endRowIndex": len(rows) + 1,
                       "startColumnIndex": 0, "endColumnIndex": 5},
            "innerHorizontal": {"style": "SOLID", "color": {"red": 0.8, "green": 0.8, "blue": 0.8}},
            "innerVertical":   {"style": "SOLID", "color": {"red": 0.8, "green": 0.8, "blue": 0.8}},
            "top":    {"style": "SOLID_MEDIUM", "color": {"red": 0.3, "green": 0.3, "blue": 0.3}},
            "bottom": {"style": "SOLID_MEDIUM", "color": {"red": 0.3, "green": 0.3, "blue": 0.3}},
            "left":   {"style": "SOLID_MEDIUM", "color": {"red": 0.3, "green": 0.3, "blue": 0.3}},
            "right":  {"style": "SOLID_MEDIUM", "color": {"red": 0.3, "green": 0.3, "blue": 0.3}},
        }
    })

    # 행 고정 (헤더)
    requests.append({"freezePane": {"frozenRowCount": 1, "sheetId": ws.id}})

    sh.batch_update({"requests": requests})

    # 공유 설정 (링크 있으면 누구나 볼 수 있게)
    sh.share(None, perm_type="anyone", role="reader")

    return sh.url

def main():
    print("CSV 로드 중...")
    rows = load_csv()
    print(f"  총 {len(rows)}개 항목 로드 완료")

    print("Google Sheets 연결 중...")
    client = connect_sheets()

    print("스프레드시트 생성 및 데이터 업로드 중...")
    url = create_spreadsheet(client, rows)

    print()
    print("=" * 60)
    print("완료!")
    print(f"스프레드시트 URL: {url}")
    print("=" * 60)

if __name__ == "__main__":
    main()
