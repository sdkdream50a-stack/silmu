class Law < ApplicationRecord
  validates :name, presence: true

  scope :by_name, ->(q) { where("name LIKE ?", "%#{q}%") }
  scope :current, -> { where("effective_date <= ?", Time.zone.today.strftime("%Y%m%d")) }

  # 법제처 API 응답으로 upsert
  def self.upsert_from_api!(data)
    return nil unless data&.dig(:name).present?

    record = find_or_initialize_by(law_id: data[:mst] || data[:name])
    record.assign_attributes(
      name:           data[:name],
      law_type:       data[:law_type],
      ministry:       data[:ministry],
      effective_date: data[:effective_date]
    )
    record.save! if record.new_record? || record.changed?
    record
  end

  def law_go_kr_url
    if law_id.present? && law_id =~ /\A\d+\z/
      "https://www.law.go.kr/LSW/lsInfoP.do?lsiSeq=#{law_id}"
    else
      "https://www.law.go.kr/법령/#{URI.encode_www_form_component(name.gsub(' ', ''))}"
    end
  end
end
