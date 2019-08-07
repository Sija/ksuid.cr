require "./ksuid/error"
require "./ksuid/utils"
require "./ksuid/base62"

# KSUID stands for K-Sortable Unique IDentifier, a globally unique identifier
# used by [Segment](https://segment.com/blog/a-brief-history-of-the-uuid/).
#
# Distributed systems require unique identifiers to track events throughout
# their subsystems. Many algorithms for generating unique identifiers, like the
# [Snowflake ID](https://blog.twitter.com/2010/announcing-snowflake) system,
# require coordination with a central authority. This is an unacceptable
# constraint in the face of systems that run on client devices, yet we still
# need to be able to generate event identifiers and roughly sort them for
# processing.
#
# The KSUID optimizes this problem into a roughly sortable identifier with
# a high possibility space to reduce the chance of collision. KSUID uses
# a 32-bit timestamp with second-level precision combined with 128 bytes of
# random data for the "payload". The timestamp is based on the Unix epoch, but
# with its base shifted forward from `1970-01-01 00:00:00 UTC` to `2014-05-13
# 16:53:20 UTC`. This is to extend the useful life of the ID format to over
# 100 years.
#
# Because KSUID timestamps use seconds as their unit of precision, they are
# unsuitable to tasks that require extreme levels of precision. If you need
# microsecond-level precision, a format like [ULID](https://github.com/ulid/spec)
# may be more suitable for your use case.
#
# KSUIDs are "roughly sorted". Practically, this means that for any given event
# stream, there may be some events that are ordered in a slightly different way
# than they actually happened. There are two reasons for this. Firstly, the
# format is precise to the second. This means that two events that are
# generated in the same second will be sorted together, but the KSUID with the
# smaller payload value will be sorted first. Secondly, the format is generated
# on the client device using its clock, so KSUID is susceptible to clock shift
# as well. The result of sorting the identifiers is that they will be sorted
# into groups of identifiers that happened in the same second according to
# their generating device.
#
# See the [canonical implementation](https://github.com/segmentio/ksuid) for more information.
#
# ```
# require "ksuid"
#
# # Generate a random KSUID for the present time
# KSUID.new
#
# # Generate a random KSUID for a specific timestamp
# KSUID.new(time: Time.now - 3.hours)
#
# # Parse a KSUID string that you have received
# KSUID.from("0o5Fs0EELR0fUjHjbCnEtdUwQe3")
#
# # Parse a KSUID byte slice that you have received
# KSUID.from(Bytes.new(20, 255_u8))
# ```
struct KSUID
  include Comparable(KSUID)

  VERSION = "0.5.0"

  # KSUID's epoch starts more recently so that the 32-bit number space gives a
  # significantly higher useful lifetime of around 136 years from May 2014.
  # This number (`14e8`) was picked to be easy to remember.
  EPOCH = 14e8.to_u32

  # Timestamp is an `UInt32`.
  TIMESTAMP_SIZE = 4

  # Payload is 16 bytes.
  PAYLOAD_SIZE = 16

  {% begin %}
    # `KSUID`s are 20 bytes:
    # - 00-03 byte: `UInt32` BE UTC `timestamp` with custom epoch
    # - 04-19 byte: random `payload`
    TOTAL_SIZE = {{ TIMESTAMP_SIZE + PAYLOAD_SIZE }}
  {% end %}

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
    new(time.to_utc.to_unix - EPOCH, payload)
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
    Time.unix(timestamp.to_i64 + EPOCH)
  end

  # Returns the `KSUID` as `Bytes`.
  def to_slice : Bytes
    # ameba:disable Lint/ShadowingOuterLocalVar
    io = IO::Memory.new.tap do |io|
      io.write Utils.int_to_bytes(timestamp)
      io.write payload.to_slice
    end
    io.to_slice
  end

  # Returns the `KSUID` as a hex-encoded `String`.
  def raw : String
    to_slice.hexstring.upcase
  end

  # Writes the `KSUID` as a base62-encoded `String` to *io*.
  def to_s(io : IO) : Nil
    io << Base62.encode(to_slice)
  end

  def inspect(io : IO) : Nil
    io << "KSUID("
    to_s(io)
    io << ')'
  end
end
