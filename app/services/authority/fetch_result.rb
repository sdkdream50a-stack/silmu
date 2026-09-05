# frozen_string_literal: true

# P1.5 §24 — fetch 결과. 실패 종류를 구분한다.
# "사이트 장애"가 "법령 삭제"로 해석되면 안 된다.
module Authority
  FetchResult = Struct.new(
    :ok, :failure_kind, :message, :raw_content, :format, :metadata, :source_url,
    keyword_init: true
  ) do
    def ok? = ok == true
    def failed? = !ok?

    def self.success(raw_content:, format: :text, metadata: {}, source_url: nil)
      new(ok: true, raw_content: raw_content, format: format,
          metadata: metadata, source_url: source_url)
    end

    def self.failure(kind, message)
      raise ArgumentError, "알 수 없는 실패 종류: #{kind}" unless AuthoritySource::FAILURE_KINDS.include?(kind)

      new(ok: false, failure_kind: kind, message: message.to_s, metadata: {})
    end
  end
end
