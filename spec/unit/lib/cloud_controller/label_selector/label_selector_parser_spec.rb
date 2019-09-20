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
            ['*', '<<*>>'],
            ['*abc', '<<*>>abc'],
            ['abc*', 'abc<<*>>'],
            ['abc*=def', 'abc<<*>>=def'],
            ['abc in (fish  ,?',     %q/abc in (fish  ,<<?>>/],
          ].each_with_index do |pair, index|
            input, expected_message = pair
            result = parser.parse(input)
            expect(result).to be_falsey
            expect(parser.errors.size).to be(1)
            exp = "invalid label_selector: #{expected_message}"
            expect(parser.errors[0]).to eq(exp), "Expected
[[#{exp}]], got
[[#{parser.errors[0]}]]
for input #{index}"
          end
        end
      end

      context 'missing antecedents' do
        it 'complains' do
          [
            ['!<<>>',                'a key'],
            ['!<<,>>',               'a key'],
            ['!abc<<=>>',            %q/a ',' or the end/],
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

          ].each_with_index do |pair, index|
            augmented_input, reduced_expected_message = pair
            input = augmented_input.replace('<<', '').replace('>>', '')
            expected_message = "#{reduced_expected_message}: #{augmented_input}"
            result = parser.parse(input)
            expect(result).to be_falsey
            expect(parser.errors.size).to be(1)
            expect(parser.errors[0]).to eq(expected_message), "Expected
[[#{expected_message}]], got
[[#{parser.errors[0]}]]
for input #{index}"

          end
        end
      end

    end
  end
end
