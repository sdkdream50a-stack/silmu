audio_url = "https://lh3.googleusercontent.com/notebooklm/ANHLwAxQVqIgUtfXC7W0-vyaIHC-qahQXiuFLCn9a79EHcbZttP927GD_MU3ha9ZQESPQLtazAkXYr4ErDyDe8jhyuBtwqHKYSR5ZaLmeG4RDwpuzwXJzRSDzqiwEN--TjZ-HeXFxoquIIMPyjQ3gNKI-2IESJvfxg=m140-dv"

g = Guide.find_by(slug: "local-subsidy-complete-1")
rm = (g.rich_media || {}).merge("audio_url" => audio_url)
g.update!(rich_media: rm)
puts "audio_url updated: #{g.title}"

# Rails cache 무효화
Rails.cache.delete("guide_topic/local-subsidy-complete-1")
puts "cache cleared"
