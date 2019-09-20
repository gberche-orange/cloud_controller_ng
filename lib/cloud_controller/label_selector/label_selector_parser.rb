require 'cloud_controller/label_selector/label_selector_lexer'

module VCAP::CloudController
  class LabelSelectorNode

    attr_accessor :operator, :name, :values

    def initialize(name, op = nil)
      @name = name
      @operator = op
      @values = []
    end

    def add(value)
      @values << value
    end

    def generate
      LabelSelectorRequirement.new(key: @name,
        operator: operator,
        values: @values,
      )
    end
  end

  class LabelSelectorParseError < Exception
    def initialize(msg, input = nil, token = nil)
      if input && token
        msg += ": " + show_token_state(input, token)
      end
      super(msg)
    end

    private

    def show_token_state(s, tok)
      parts = []
      if tok[2] > 0
        start_part = s[0...tok[2]]
        if start_part.size > 30
          start_part = "..." + start_part[-27..-1]
        end
        parts << start_part
      end
      parts << "<<#{tok[1]}>>"
      if tok[2] + tok[1].size < s.size
        end_part = s[(tok[2] + 1)..-1]
        if end_part.size > 30
          end_part = end_part[0..27] + '...'
        end
        parts << end_part
      end
      parts.join('')
    end
  end

  class LabelSelectorParser

    def initialize
      @action_table = {
        at_start: {
          word: Proc.new {
            debugger if !@token
            @node = LabelSelectorNode.new(@token[1]);
            @state = :has_key
          },
          not_op: :has_not_op,
          default: "a key or '!'",
        },
        has_not_op: {
          word: Proc.new {

            debugger if !@token
            @requirements << LabelSelectorNode.new(@token[1], :not_exists);
            @state = :expecting_comma_or_eof},
          default: "a key",
        },
        has_key: {
          equal: Proc.new {@node.operator = @token[0]; @state = :expect_value},
          not_equal: Proc.new {@node.operator = @token[0]; @state = :expect_value},
          word: Proc.new {
            if ['in', 'notin'].member?(@token[1])
              @node.operator = @token[0]
              @state = :expecting_open_paren
            else
              raise LabelSelectorParseError.new("Expecting an operator for key '#{@node.key}'", @input, @token)
            end
          },
          comma: Proc.new {@node.operator = :exists; @requirements << @node; @state = :at_start},
          eof: Proc.new {@node.operator = :exists; @requirements << @node; @done = true},
          default: "a value or the end",
        },
        expect_value: {
          word: Proc.new {@node.values << @token[1]; @requirements << @node; @state = :expecting_comma_or_eof},
          default: "a value",
        },
        expecting_open_paren: {
          open_paren: :expecting_set_value,
          default: "a '('",
        },
        expecting_set_value: {
          word: Proc.new {@node.values << @token[1]; @state = :expecting_comma_or_close_paren},
          default: "a value",
        },
        expecting_comma_or_close_paren: {
          comma: :expecting_set_value,
          close_paren: Proc.new {@requirements << @node; @state = :expecting_comma_or_eof},
          default: "a ',' or ')'",
        },
        expecting_comma_or_eof: {
          comma: :at_start,
          eof: Proc.new {@done = true},
          default: "a ',' or the end"
        },
      }
    end

    attr_accessor :requirements, :errors

    def parse(s)
      @requirements = []
      @errors = []
      raise LabelSelectorParseError.new("empty label selector not allowed") if s.size == 0
      @input = s

      tokens = LabelSelectorLexer.new.scan(s)
      tok = tokens.find {|tok| tok[0] == :error}
      if tok
        raise LabelSelectorParseError.new("invalid label_selector", s, tok)
      end

      tokens = tokens.reject {|tok| tok[0] == :space} + [[:eof, '', s.size],]

      @state = :at_start
      @done = false
      tokens.each do |tok|
        @token = tok
        entry = @action_table[@state]
        if !entry
          raise Exception.new("Internal error: Can't find an entry for #{token.inspect} at state #{@state}")
        end

        if !entry.has_key?(tok[0])
          action = entry[:default]
          raise LabelSelectorParseError.new("expected #{entry[:default]}", s, tok) if action.nil?
        else
          action = entry[tok[0]]
        end

        #debugger
        case action
        when Symbol
          @state = action
        when Proc
          action.call
          break if @done
        when String
          raise LabelSelectorParseError.new(action, s, tok)
        else
          raise LabelSelectorParseError.new("unexpected input", s, tok)
        end
      end

      if !@done
        raise LabelSelectorParseError.new("Expecting completion of the selector, hit the end")
      end
      return true

    rescue LabelSelectorParseError => ex
      @errors << ex.message
      return false
    end

  end
end
