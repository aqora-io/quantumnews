# typed : false

require 'kramdown'
require 'kramdown-math-katex'
require 'kramdown-syntax-coderay'
require 'nokogiri'

# Class responsible for converting Markdown to HTML.
class Markdowner
  DEFAULT_MATHS_OPTIONS = {
    katex_js_path: 'extras/katex/katex.min.js',
    output: 'mathml',
    display_mode: true,
    fleqn: true,
    leqno: true,
    delimiters: [
      { left: '$$', right: '$$', display: true },
      { left: '$', right: '$', display: false },
      { left: '\(', right: '\)', display: false },
      { left: '\[', right: '\]', display: true },
      { left: '\\begin{equation}', right: '\\end{equation}', display: true },
      { left: '\\begin{align}', right: '\\end{align}', display: true }
    ]
  }

  def self.to_html(text, options = {})
    return '' if text.blank?

    # Convert Markdown to HTML using Kramdown
    html = Kramdown::Document.new(
      text, math_engine: :katex,
      math_engine_opts: DEFAULT_MATHS_OPTIONS,
      input: 'GFM',
      syntax_highlighter: :coderay,
      syntax_highlighter_opts: {
        line_numbers: 'table',
        bold_every: 5
      },
    ).to_html

    # Example: Replace @username with a link to the user's profile
    html = replace_user_mentions(html)

    # Parse HTML using Nokogiri
    ng = Nokogiri::HTML.fragment(html)

    # Change <h1>, <h2>, etc. headings to just bold tags
    change_headings_to_bold(ng)

    # This should happen before adding rel=ugc to all links
    convert_images_to_links(ng) unless options[:allow_images]

    # Make links have rel=ugc
    make_links_ugc(ng)

    # Return the HTML content
    ng.to_html
  end

  def self.change_headings_to_bold(fragment)
    fragment.css('h1, h2, h3, h4, h5, h6').each do |h|
      h.name = 'strong'
    end
  end

  def self.replace_user_mentions(html)
    html.gsub(%r{(?<!/)@(\w+)}) do |match|
      username = ::Regexp.last_match(1)
      if User.exists?(username: username)
        "<a href='#{Rails.application.root_url}~#{username}'>@#{username}</a>"
      else
        match
      end
    end
  end

  def self.convert_images_to_links(node)
    node.css('img').each do |img|
      link = Nokogiri::XML::Node.new('a', node)
      link['href'] = img['src']
      title = img['title']
      alt = img['alt']
      link.content = [title, alt, link['href']].find(&:present?)
      img.replace(link)
    end
  end

  def self.valid_url?(url)
    URI.parse(url).host.nil?
  rescue StandardError
    false
  end

  def self.make_links_ugc(fragment)
    fragment.css('a').each do |link|
      link[:rel] = 'ugc' unless valid_url?(link[:href])
    end
  end
end
