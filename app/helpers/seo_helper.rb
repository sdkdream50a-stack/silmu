module SeoHelper
  def json_ld(data)
    content_tag(:script, json_escape(data.to_json).html_safe, type: "application/ld+json")
  end
end
