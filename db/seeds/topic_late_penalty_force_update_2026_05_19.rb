# 2026-05-19 Phase 3.2 force update
# 운영 DB의 late-penalty 토픽이 매우 stale(1/2,000 구표기·한도 부재) → 시드 본문으로 강제 교체.
# find_or_create_by!를 임시 monkey patch하여 기존 레코드에도 block 실행되도록 변경.
#
# 실행: kamal app exec --reuse 'bin/rails runner "load \"db/seeds/topic_late_penalty_force_update_2026_05_19.rb\""'

Topic.singleton_class.class_eval do
  alias_method :original_find_or_create_by!, :find_or_create_by!
  def find_or_create_by!(attrs, &block)
    t = find_or_initialize_by(attrs)
    block.call(t) if block
    t.save!
    puts "[force-update] Topic #{attrs.values.first.inspect} saved (id=#{t.id})"
    t
  end
end

begin
  load Rails.root.join("db/seeds/topic_late_penalty.rb").to_s
ensure
  Topic.singleton_class.class_eval do
    alias_method :find_or_create_by!, :original_find_or_create_by!
    remove_method :original_find_or_create_by!
  end
end
