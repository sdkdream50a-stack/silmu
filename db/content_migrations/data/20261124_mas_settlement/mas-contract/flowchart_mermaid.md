flowchart TD
  A[구매 수요 발생] --> B[1회 납품요구 구매예산
품목 합산]
  B --> C{2단계경쟁 기준 이상?
중기경쟁제품 1억원
그 외 물품 5천만원}
  C -->|미만| D[종합쇼핑몰에서
업체 골라 납품요구]
  C -->|이상| E{예외 해당?
제49조⑤·제50조}
  E -->|예| D
  E -->|아니오| F{1회 구매예산 5억원 이상?
2027.1.1.부터 그 외 물품은
5천만원 이상}
  F -->|예| G[제안공고]
  F -->|아니오| H[5인 이상 제안요청
부득이하면 2인 이상]
  G --> I[제안서 평가
합산점수 최고 업체]
  H --> I
  I --> D
  D --> J[납품 및 검사]
  J --> K[대금 지급]

  style A fill:#fee2e2,stroke:#ef4444
  style K fill:#dcfce7,stroke:#22c55e
  style H fill:#fef3c7,stroke:#f59e0b
  style G fill:#fef3c7,stroke:#f59e0b
