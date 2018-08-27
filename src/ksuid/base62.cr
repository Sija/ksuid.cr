require "base62"

struct KSUID
  module Base62
    include ::Base62
    extend self

    protected def padded(str, charset)
      str.rjust(KSUID::STRING_ENCODED_SIZE, charset[0])
    end

    # Padded version of `::Base62#decode`.
    def decode(string : String, charset = CHARSET_DEFAULT) : BigInt
      super(padded(string, charset), charset)
    end

    # Padded version of `::Base62#encode`.
    def encode(number : Int, charset = CHARSET_DEFAULT) : String
      padded(super(number, charset), charset)
    end
  end
end
