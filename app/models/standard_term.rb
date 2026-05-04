class StandardTerm < ApplicationRecord
  validates :term_korean, presence: true, uniqueness: true

  scope :with_synonym, ->(word) { where("synonyms @> ?", [word].to_json) }

  # 비표준어 → 표준어 매핑 캐시 (synonym → term_korean)
  # 13,176건 적재 시 메모리 약 5MB 추정
  def self.synonym_index
    Rails.cache.fetch("standard_terms/synonym_index/v1", expires_in: 1.day) do
      idx = {}
      find_each(batch_size: 500) do |term|
        next if term.synonyms.blank?
        term.synonyms.each do |syn|
          next if syn.blank?
          idx[syn] = term.term_korean
        end
      end
      idx
    end
  end

  def self.expire_synonym_index!
    Rails.cache.delete("standard_terms/synonym_index/v1")
  end
end
