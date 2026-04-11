# 슬러그 변경 시 구 URL → 신 URL 301 리디렉션 매핑
# Search Console 404 오류 해소 목적
class SlugRedirect < ApplicationRecord
  validates :old_slug, :new_slug, :resource_type, presence: true
  validates :old_slug, uniqueness: { scope: :resource_type }

  # 리디렉션 체인 추적 (A→B→C 의 경우 A→C로 직접 매핑)
  def self.resolve(old_slug, resource_type)
    redirect = find_by(old_slug: old_slug, resource_type: resource_type)
    return nil unless redirect

    # 최대 5단계까지 체인 추적
    target = redirect.new_slug
    5.times do
      next_redirect = find_by(old_slug: target, resource_type: resource_type)
      break unless next_redirect
      target = next_redirect.new_slug
    end
    target
  end
end
