module MarkdownHelper
  def render_markdown(markdown)
    Kramdown::Document.new(markdown, input: 'GFM', hard_wrap: false).to_html
  end
end
