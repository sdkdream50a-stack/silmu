class AddFlowchartMermaidToTopics < ActiveRecord::Migration[8.1]
  def change
    add_column :topics, :flowchart_mermaid, :text
  end
end
