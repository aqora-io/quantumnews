# typed: false
require "kramdown"
require "kramdown-math-itex2mml"

class Markdowner
  def self.to_html(text, opts = {})
    if text.blank?
      return ""
    end

    # Convert Markdown to HTML using Krakdown
    html = Kramdown::Document.new(text, math_engine: :itex2mml, input: 'GFM').to_html

    html.gsub!(/@(\\w+)/) do |match|
      username = $1
      if User.exists?(username: username)
        "<a href='#{Rails.application.root_url}~#{username}'>#{match}</a>"
      else
        match
      end
    end

    # Parse HTML using Nokogiri
    ng = Nokogiri::HTML5(html)

    # change <h1>, <h2>, etc. headings to just bold tags
    ng.css("h1, h2, h3, h4, h5, h6").each do |h|
      h.name = "strong"
    end

    # This should happen before adding rel=ugc to all links
    convert_images_to_links(ng) unless opts[:allow_images]

    # make links have rel=ugc
    ng.css("a").each do |h|
      h[:rel] = "ugc" unless begin
        URI.parse(h[:href]).host.nil?
      rescue
        false
      end
    end

    ng.to_html
  end

  def self.convert_images_to_links(node)
    node.css("img").each do |img|
      link = Nokogiri::XML::Node.new("a", node)
      link["href"] = img["src"]
      title = img["title"]
      alt = img["alt"]
      link.content = [title, alt, link["href"]].find(&:present?)
      img.replace(link)
    end
  end
end

