require "big"

struct KSUID
  module Utils
    extend self

    # Converts *value* into a `BigInt`.
    def int_from_bytes(value : String | Bytes) : BigInt
      value = value.to_slice if value.is_a?(String)
      value.to_a
        .map(&.to_s(2).rjust(8, '0'))
        .join
        .to_big_i(2)
    end

    # Writes *int* into the *io* using network-ordered (big endian) format.
    def int_to_bytes(int : Int, bits : Int32, io : IO) : Int32
      bytes = int
        .to_s(2)
        .rjust(bits, '0')
        .each_char
        .each_slice(8)
        .map(&.join.to_i(2))

      bytes.each do |byte|
        io.write_bytes byte.to_u8, IO::ByteFormat::NetworkEndian
      end
      bytes.size
    end

    # Converts *int* into a network-ordered (big endian) `Bytes`.
    def int_to_bytes(int : Int, bits : Int32 = 32) : Bytes
      IO::Memory.new.tap { |io| int_to_bytes(int, bits, io) }.to_slice
    end
  end
end
