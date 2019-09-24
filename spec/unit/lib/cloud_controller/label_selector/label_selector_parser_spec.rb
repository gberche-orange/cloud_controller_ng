require 'spec_helper'
require 'cloud_controller/label_selector/label_selector_parser.rb'

module VCAP::CloudController
  RSpec.describe LabelSelectorParser do
    subject(:parser) { LabelSelectorParser.new }

    describe 'parser' do
      let(:input) { '' }

      context 'empty string' do
        it 'complains' do
          result = parser.parse(input)
          expect(result).to be_falsey
          expect(parser.errors.size).to be(1)
          expect(parser.errors).to match_array("empty label selector not allowed")
          expect(parser.requirements).to be_empty
        end
      end

      context 'simple key-test' do
        it 'complains about errors' do
          [
            ['<<*>>'],
            ['<<*>>abc'],
            ['abc<<*>>'],
            ['abc<<*>>=def'],
            [%q/abc in (fish  ,<<?>>/],
          ].each_with_index do |augmented_input, index|
            # debugger
            augmented_input = augmented_input[0]
            input = augmented_input.sub('<<', '').sub('>>', '')
            result = parser.parse(input)
            expect(result).to be_falsey
            expect(parser.errors.size).to be(1)
            exp = "invalid label_selector: #{augmented_input}"
            expect(parser.errors[0]).to eq(exp), "Expected
[[#{exp}]], got
[[#{parser.errors[0]}]]
for input #{index}"
          end
        end
      end

      context 'state table coverage' do
        it 'complains' do
          [
            ['!<<>>',                'a key'],
            ['!<<,>>',               'a key'],
            ['!<<)>>',               'a key'],
            ['<<!=>> chips',           %q/a key or '!' not followed by '='/],
            ['!abc<<=>>',            %q/a ',' or end/],
            ['abc=<<,>>',            'a value'],
            ['abc!=<<,>>',           'a value'],

            ['abc in<<>>',           %q/a '('/],
            ['abc in <<>>',          %q/a '('/],
            ['abc in  <<>>',         %q/a '('/],
            ['abc in<<)>>',          %q/a '('/],
            ['abc in<<,>>',          %q/a '('/],

            ['abc in(<<>>',          'a value'],
            ['abc in (<<>>',         'a value'],
            ['abc in (fish<<>>',     %q/a ',' or ')'/],
            ['abc in (fish  ,<<>>',      %q/a value/],
            ['abc in (fish  ,<<)>>',     %q/a value/],

            ['abc in (fish,beef<<>>',     %q/a ',' or ')'/],
            ['abc in (fish,beef,<<>>',     %q/a value/],
            ['abc in (fish,beef),<<>>',     %q/a key or '!'/],
            ['abc in (fish,beef),<<(>>',     %q/a key or '!'/],

            ['abc notin<<>>',           %q/a '('/],
            ['abc notin <<>>',          %q/a '('/],
            ['abc notin  <<>>',         %q/a '('/],
            ['abc notin<<)>>',          %q/a '('/],
            ['abc notin<<,>>',          %q/a '('/],

            ['abc notin(<<>>',          'a value'],
            ['abc notin (<<>>',         'a value'],
            ['abc notin (fish<<>>',     %q/a ',' or ')'/],
            ['abc notin (fish  ,<<>>',      %q/a value/],
            ['abc notin (fish  ,<<)>>',     %q/a value/],

            ['abc notin (fish,beef<<>>',     %q/a ',' or ')'/],
            ['abc notin (fish,beef,<<>>',     %q/a value/],
            ['abc notin (fish,beef),<<>>',     %q/a key or '!'/],
            ['abc notin (fish,beef),<<(>>',     %q/a key or '!'/],

            ['abc =<<>>',           %q/a value/],
            ['abc = <<>>',          %q/a value/],
            ['abc =  <<>>',         %q/a value/],
            ['abc =<<)>>',          %q/a value/],
            ['abc =<<,>>',          %q/a value/],

            ['abc =<<(>>',          'a value'],
            ['abc = <<(>>',         'a value'],
            ['abc = fish  ,<<>>',      %q/a key or '!'/],
            ['abc = fish  ,<<)>>',     %q/a key or '!'/],
            ['abc = fish,<<>>',     %q/a key or '!'/],
            ['abc = fish<<)>>,',     %q/a ',' or end/],
            ['abc = fish <<(>>,',     %q/a ',' or end/],
            ['abc = fish<<)>>,',     %q/a ',' or end/],
            ['abc = fish <<flakes>>',     %q/a ',' or end/],

            ['abc ==<<>>',           %q/a value/],
            ['abc == <<>>',          %q/a value/],
            ['abc ==  <<>>',         %q/a value/],
            ['abc ==<<)>>',          %q/a value/],
            ['abc ==<<,>>',          %q/a value/],

            ['abc ==<<(>>',          'a value'],
            ['abc == <<(>>',         'a value'],
            ['abc == fish  ,<<>>',      %q/a key or '!'/],
            ['abc == fish  ,<<)>>',     %q/a key or '!'/],
            ['abc == fish,<<>>',     %q/a key or '!'/],
            ['abc == fish<<)>>,',     %q/a ',' or end/],
            ['abc == fish <<(>>,',     %q/a ',' or end/],
            ['abc == fish<<)>>,',     %q/a ',' or end/],
            ['abc == fish <<flakes>>',     %q/a ',' or end/],

            ['abc !=<<>>',           %q/a value/],
            ['abc != <<>>',          %q/a value/],
            ['abc !=  <<>>',         %q/a value/],
            ['abc !=<<)>>',          %q/a value/],
            ['abc !=<<,>>',          %q/a value/],

            ['abc !=<<(>>',          'a value'],
            ['abc != <<(>>',         'a value'],
            ['abc != fish  ,<<>>',      %q/a key or '!'/],
            ['abc != fish  ,<<)>>',     %q/a key or '!'/],
            ['abc != fish,<<>>',     %q/a key or '!'/],
            ['abc != fish<<)>>,',     %q/a ',' or end/],
            ['abc != fish <<(>>,',     %q/a ',' or end/],
            ['abc != fish<<)>>,',     %q/a ',' or end/],
            ['abc != fish <<flakes>>',     %q/a ',' or end/],

            ['fish<<)>>,',     %q/a ',', operator, or end/],
            ['fish <<(>>,',     %q/a ',', operator, or end/],
            ['fish<<)>>,',     %q/a ',', operator, or end/],
            ['fish <<flakes>>',     %q/a ',', operator, or end/],

          ].each_with_index do |pair, index|
            augmented_input, reduced_expected_message = pair
            input = augmented_input.sub('<<', '').sub('>>', '')
            expected_message = "#{reduced_expected_message}: #{augmented_input}"
            result = parser.parse(input)
            expect(result).to be_falsey
            expect(parser.errors.size).to be(1)
            expect(parser.errors[0]).to eq(expected_message), "Expected
[[#{expected_message}]], got
[[#{parser.errors[0]}]]
for input #{index} ('#{augmented_input}' => '#{input}')"

          end
        end
      end


      context 'state table coverage' do
        it 'complains' do
          [
            ['fish <<flakes>>',     %q/a ',', operator, or end/],

          ].each_with_index do |pair, index|
            augmented_input, reduced_expected_message = pair
            input = augmented_input.sub('<<', '').sub('>>', '')
            expected_message = "#{reduced_expected_message}: #{augmented_input}"
            result = parser.parse(input)
            expect(result).to be_falsey
            expect(parser.errors.size).to be(1)
            expect(parser.errors[0]).to eq(expected_message), "Expected
[[#{expected_message}]], got
[[#{parser.errors[0]}]]
for input #{index} ('#{augmented_input}' => '#{input}')"

          end
        end
      end

    end
  end
end
