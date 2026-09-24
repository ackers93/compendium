# frozen_string_literal: true

class VerseReferenceAutolinker
  SKIP_ANCESTOR_TAGS = %w[a code pre script style].freeze

  def self.call(html)
    new(html).call
  end

  def initialize(html)
    @html = html.to_s
  end

  def call
    return @html if @html.blank?

    fragment = Nokogiri::HTML::DocumentFragment.parse(@html)
    changed = false

    fragment.traverse do |node|
      next unless node.text?
      next if skip_node?(node)

      text = node.text
      matches = VerseReferenceScanner.scan(text, resolve: true)
      next if matches.empty?

      node.replace(build_replacement_html(text, matches))
      changed = true
    end

    changed ? fragment.to_html : @html
  end

  private

  def skip_node?(node)
    node.ancestors.any? { |ancestor| SKIP_ANCESTOR_TAGS.include?(ancestor.name) }
  end

  def build_replacement_html(text, matches)
    parts = []
    cursor = 0

    matches.each do |match|
      if match.start_offset > cursor
        parts << ERB::Util.html_escape(text[cursor...match.start_offset])
      end

      parsed = match.parsed
      href = "/bible_verses/#{ERB::Util.url_encode(parsed.book)}/#{parsed.chapter}/#{parsed.start_verse}"
      parts << %(<a href="#{href}">#{ERB::Util.html_escape(match.text)}</a>)
      cursor = match.end_offset
    end

    parts << ERB::Util.html_escape(text[cursor..]) if cursor < text.length
    parts.join
  end
end
