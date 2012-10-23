require 'kramdown/parser/kramdown'
require 'middleman-core/sitemap'

module MarkdownExtensions
  class Kramdown::Parser::WikiKramdown < Kramdown::Parser::Kramdown
    def initialize(source, options)
      super
      @app = options[:app]
      # Table parser matches [[a|b]
      @block_parsers.delete :table
      @span_parsers.unshift :wiki_link
    end

    Kramdown::Options.define(:app, Object, nil, '') { |o| o }

    def parse_wiki_link
      @src.pos += @src.matched_size

      page, text = link_target_and_text(@src[1], @src[2])

      if page.start_with? 'img'
        img = Element.new :img
        img.attr['src'] = page
        @tree.children << img
        return
      end

      url = find_page page
      if url
        link = Element.new :a
        link.attr['href'] = url + @src[3]
        add_text(text, link)
        @tree.children << link
      else
        print "Page not found: #{page}\n"
        add_text(text)
      end
    end

    def link_target_and_text(a, b)
      if b.empty?
        return a, a.gsub('_', ' ')
      else
        return b, a
      end
    end

    def find_page name
      suffix = "/#{name}/"
      resource = @app.current_resource
      while resource
        resource.children.each do |r|
          return r.url if r.url.end_with? suffix
        end
        resource = resource.parent
      end
      nil
    end

    define_parser(:wiki_link, /\[\[([^!][^|#]*)\|?([^|#]*)(#?[^#|]*)\]\]/, '\\[\\[[^!]')
  end

  class Kramdown::Converter::Html
    alias_method :old_convert_root, :convert_root

    def convert_root(el, indent)
      result = old_convert_root(el, indent)
      toc_tree = generate_toc_tree(@toc, :ol, {})
      result.prepend convert(toc_tree, 0) unless toc_tree.children.empty?
      result
    end

    def convert_img(el, indent)
      el.attr['src'].prepend '/docs/3.0/'
      "<img#{html_attributes(el.attr)} />"
    end
  end
end
