# 브라우저 격리·기능 제한 헤더.
# - Permissions-Policy: 불필요 센서/USB/결제 API 차단 → 악성 iframe·3rd party 스크립트 권한 상승 방지
# - COOP (same-origin): 팝업·opener 링크를 크로스오리진 문서와 격리 → Spectre/side-channel 완화
# - CORP (same-origin): 우리 리소스를 크로스오리진 문서가 load 하는 것을 차단
Rails.application.config.action_dispatch.default_headers.merge!(
  "Permissions-Policy" => [
    "accelerometer=()",
    "camera=()",
    "geolocation=()",
    "gyroscope=()",
    "magnetometer=()",
    "microphone=()",
    "payment=()",
    "usb=()",
    "interest-cohort=()"
  ].join(", "),
  "Cross-Origin-Opener-Policy" => "same-origin",
  "Cross-Origin-Resource-Policy" => "same-origin"
)
