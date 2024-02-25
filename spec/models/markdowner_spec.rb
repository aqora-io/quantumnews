# typed: false

require "rails_helper"

describe Markdowner do
  it "parses simple markdown" do
    expect(Markdowner.to_html("hello there *italics* and **bold**!"))
      .to eq("<p>hello there <em>italics</em> and <strong>bold</strong>!</p>\n")
  end

  it "turns @username into a link if @username exists" do
    create(:user, username: "blahblah")

    expect(Markdowner.to_html("hi @blahblah test"))
      .to eq("<p>hi <a href=\"https://lobste.rs/~blahblah\" rel=\"ugc\">" \
             "@blahblah</a> test</p>\n")

    expect(Markdowner.to_html("hi @flimflam test"))
      .to eq("<p>hi @flimflam test</p>\n")
  end

  # bug#209
  it "keeps punctuation inside of auto-generated links when using brackets" do
    expect(Markdowner.to_html("hi <http://example.com/a.> test"))
      .to eq("<p>hi <a href=\"http://example.com/a.\" rel=\"ugc\">" \
            "http://example.com/a.</a> test</p>\n")
  end

  # bug#242
  it "does not expand @ signs inside urls" do
    create(:user, username: "blahblah")

    expect(Markdowner.to_html("hi http://example.com/@blahblah/ test"))
      .to eq("<p>hi <a href=\"http://example.com/@blahblah/\" rel=\"ugc\">" \
            "http://example.com/@blahblah/</a> test</p>\n")

    expect(Markdowner.to_html("hi [test](http://example.com/@blahblah/)"))
      .to eq("<p>hi <a href=\"http://example.com/@blahblah/\" rel=\"ugc\">" \
        "test</a></p>\n")
  end

  it "correctly adds ugc" do
    expect(Markdowner.to_html("[ex](http://example.com)"))
      .to eq("<p><a href=\"http://example.com\" rel=\"ugc\">" \
            "ex</a></p>\n")

    expect(Markdowner.to_html("[ex](//example.com)"))
      .to eq("<p><a href=\"//example.com\" rel=\"ugc\">" \
            "ex</a></p>\n")

    expect(Markdowner.to_html("[ex](/~abc)"))
      .to eq("<p><a href=\"/~abc\">ex</a></p>\n")
  end

  context "when images are not allowed" do
    subject { Markdowner.to_html(description, allow_images: false) }

    let(:fake_img_url) { "https://lbst.rs/fake.jpg" }

    context "when single inline image in description" do
      let(:description) { "![#{alt_text}](#{fake_img_url} \"#{title_text}\")" }
      let(:alt_text) { nil }
      let(:title_text) { nil }

      def target_html inner_text = nil
        "<p><a href=\"#{fake_img_url}\" rel=\"ugc\">#{inner_text}</a></p>\n"
      end

      context "with no alt text, title text" do
        it "turns inline image into links with the url as the default text" do
          expect(subject).to eq(target_html(fake_img_url))
        end
      end

      context "with title text" do
        let(:title_text) { "title text" }

        it "turns inline image into links with title text" do
          expect(subject).to eq(target_html(title_text))
        end
      end

      context "with alt text" do
        let(:alt_text) { "alt text" }

        it "turns inline image into links with alt text" do
          expect(subject).to eq(target_html(alt_text))
        end
      end

      context "with title text and alt text" do
        let(:title_text) { "title text" }

        it "turns inline image into links, preferring title text" do
          expect(subject).to eq(target_html(title_text))
        end
      end
    end

    context "with multiple inline images in description" do
      let(:description) do
        "![](#{fake_img_url})" \
        "![](#{fake_img_url})" \
        "![alt text](#{fake_img_url})" \
        "![](#{fake_img_url} \"title text\")" \
        "![alt text](#{fake_img_url} \"title text 2\")"
      end

      it "turns all inline images into links" do
        expect(subject).to eq(
          "<p>" \
          "<a href=\"#{fake_img_url}\" rel=\"ugc\">#{fake_img_url}</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"ugc\">#{fake_img_url}</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"ugc\">alt text</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"ugc\">title text</a>" \
          "<a href=\"#{fake_img_url}\" rel=\"ugc\">title text 2</a>" \
          "</p>\n"
        )
      end
    end
  end

  context "when images are allowed" do
    subject { Markdowner.to_html("![](https://lbst.rs/fake.jpg)", allow_images: true) }

    it "allows image tags" do
      expect(subject).to include "<img"
    end
  end

  context "with LaTeX input" do
    subject { described_class.to_html("$$ 5 + 5 $$") }
    let(:expected_html) do
      '<span class="katex"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><mn>5</mn><mo>+</mo><mn>5</mn></mrow><annotation encoding="application/x-tex">5 + 5</annotation></semantics></math></span>'
    end

    it "renders LaTeX to HTML" do
      expect(subject).to include(expected_html)
    end
  end

  context "with complex mathematical expressions" do
    subject { described_class.to_html('$$ \int_{0}^{1} x^2 dx = \frac{1}{3} $$') }
    let(:expected_html) do
      '<span class="katex"><math xmlns="http://www.w3.org/1998/Math/MathML" display="block"><semantics><mrow><msubsup><mo>∫</mo><mn>0</mn><mn>1</mn></msubsup><msup><mi>x</mi><mn>2</mn></msup><mi>d</mi><mi>x</mi><mo>=</mo><mfrac><mn>1</mn><mn>3</mn></mfrac></mrow><annotation encoding="application/x-tex">\int_{0}^{1} x^2 dx = \frac{1}{3}</annotation></semantics></math></span>'
    end

    it "renders complex math expressions correctly" do
      expect(subject).to include(expected_html)
    end
  end

  context "with one line code input" do
    subject {
      described_class.to_html(
      '`code`'
    )}
    let(:expected_html) do
      "<p><code>code</code></p>\n"
    end

    it "renders code input correctly" do
      expect(subject).to include(expected_html)
    end
  end
  context "with multilines code input" do
    subject {
      described_class.to_html(
      '```rs
        fn main() {
            println!("Hello Aquora!");
        }
    ```'
    )}
    let(:expected_html) do
      "<p><code>rs\n        fn main() {\n            println!(\"Hello Aquora!\");\n        }\n   </code></p>\n"
    end

    it "renders code input correctly" do
      expect(subject).to include(expected_html)
    end
  end
end
