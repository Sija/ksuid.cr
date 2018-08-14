require "base62"
require "./ksuid/*"

struct KSUID
  include Comparable(KSUID)

  VERSION = "0.1.0"

  # KSUID's epoch starts more recently so that the 32-bit number space gives a
  # significantly higher useful lifetime of around 136 years from May 2014.
  # This number (`14e8`) was picked to be easy to remember.
  EPOCH = 14e8.to_u32

  # Timestamp is an `UInt32`.
  TIMESTAMP_SIZE = 4

  # Payload is 16 bytes.
  PAYLOAD_SIZE = 16

  # `KSUID`s are 20 bytes:
  # - 00-03 byte: `UInt32` BE UTC `timestamp` with custom epoch
  # - 04-19 byte: random `payload`
  TOTAL_SIZE = TIMESTAMP_SIZE + PAYLOAD_SIZE

  # The length of a `KSUID` when string (base62) encoded.
  STRING_ENCODED_SIZE = 27

  # `KSUID` with minimum valid value (`000000000000000000000000000`).
  MIN = from(StaticArray(UInt8, TOTAL_SIZE).new(0_u8))

  # `KSUID` with maximum valid value (`aWgEPTl1tmebfsQzFP4bxwgy80V`).
  MAX = from(StaticArray(UInt8, TOTAL_SIZE).new(255_u8))

  # The 16-byte random payload without the timestamp.
  getter payload : StaticArray(UInt8, PAYLOAD_SIZE)

  # The timestamp portion of the `KSUID` as an `UInt32` which is uncorrected
  # for KSUID's special `EPOCH`.
  getter timestamp : UInt32

  # Converts a base62-encoded `String` into a `KSUID`.
  def self.from(string : String) : KSUID
    unless string.size == STRING_ENCODED_SIZE
      raise Error.new("Valid encoded KSUIDs are #{STRING_ENCODED_SIZE} characters")
    end
    from(Utils.int_to_bytes(Base62.decode(string), 160))
  end

  # Converts `Bytes` into a `KSUID`.
  def self.from(bytes : Bytes) : KSUID
    unless bytes.bytesize == TOTAL_SIZE
      raise Error.new("Valid KSUIDs are #{TOTAL_SIZE} bytes")
    end
    timestamp = Utils.int_from_bytes(bytes[0, TIMESTAMP_SIZE])
    payload = bytes[TIMESTAMP_SIZE, PAYLOAD_SIZE]

    new(timestamp, payload)
  end

  # Converts `StaticArray` into a `KSUID`.
  def self.from(array : StaticArray(UInt8, TOTAL_SIZE)) : KSUID
    from(array.to_slice)
  end

  # Generates a new `KSUID` with given *time* and random `payload`.
  def self.new(time : Time = Time.now)
    new(time, Random::Secure.random_bytes(PAYLOAD_SIZE))
  end

  # Generates a new `KSUID` with given *time* and *payload*.
  def self.new(time : Time, payload : Bytes)
    new(time.to_utc.epoch - EPOCH, payload)
  end

  # Generates a new `KSUID` with given *timestamp* and *payload*.
  def initialize(timestamp : Int, payload : Bytes)
    unless payload.bytesize == PAYLOAD_SIZE
      raise Error.new("Valid KSUID payloads are #{PAYLOAD_SIZE} bytes")
    end
    @timestamp = timestamp.to_u32
    @payload = StaticArray(UInt8, PAYLOAD_SIZE).new { |i| payload[i] }
  end

  def_equals_and_hash @timestamp, @payload

  # Compares the `KSUID` against *other*.
  def <=>(other : KSUID)
    timestamp <=> other.timestamp
  end

  # Returns the timestamp portion of the `KSUID` as a `Time` object.
  def to_time : Time
    Time.epoch(timestamp.to_i64 + EPOCH)
  end

  # Returns the `KSUID` as `Bytes`.
  def uid : Bytes
    # ameba:disable Lint/ShadowingOuterLocalVar
    io = IO::Memory.new.tap do |io|
      io.write Utils.int_to_bytes(timestamp)
      io.write payload.to_slice
    end
    io.to_slice
  end

  # Returns the `KSUID` as a hex-encoded `String`.
  def raw : String
    uid.hexstring.upcase
  end

  # Writes the `KSUID` as a base62-encoded `String` to *io*.
  def to_s(io : IO) : Nil
    io << Base62.encode(uid)
  end

  def inspect(io : IO) : Nil
    io << "KSUID("
    to_s(io)
    io << ')'
  end
end
