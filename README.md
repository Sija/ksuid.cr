# ksuid.cr [![CI](https://github.com/Sija/ksuid.cr/actions/workflows/ci.yml/badge.svg)](https://github.com/Sija/ksuid.cr/actions/workflows/ci.yml) [![Releases](https://img.shields.io/github/release/Sija/ksuid.cr.svg)](https://github.com/Sija/ksuid.cr/releases) [![License](https://img.shields.io/github/license/Sija/ksuid.cr.svg)](https://github.com/Sija/ksuid.cr/blob/master/LICENSE)

This library implements the [K-Sortable Globally Unique IDs](https://github.com/segmentio/ksuid) from Segment.
The original readme for the Go version of KSUID does a great job of explaining
what they are and how they should be used, so it is excerpted here.

See also the article called [A Brief History of the UUID](https://segment.com/blog/a-brief-history-of-the-uuid/).

# What is a KSUID?

KSUID is for K-Sortable Unique IDentifier. It's a way to generate globally
unique IDs similar to [RFC 4122](https://tools.ietf.org/html/rfc4122) UUIDs,
but contain a time component so they can be "roughly" sorted by time of
creation. The remainder of the KSUID is randomly generated bytes.

# Why use KSUIDs?

Distributed systems often require unique IDs. There are numerous solutions
out there for doing this, so why KSUID?

## 1. Sortable by Timestamp

Unlike the more common choice of UUIDv4, KSUIDs contain a timestamp component
that allows them to be roughly sorted by generation time. This is obviously not
a strong guarantee as it depends on wall clocks, but is still incredibly useful
in practice.

## 2. No Coordination Required

[Snowflake IDs](https://blog.twitter.com/2010/announcing-snowflake) and
derivatives require coordination, which significantly increases the complexity
of implementation and creates operations overhead. While RFC 4122 UUIDv1s do
have a time component, there aren't enough bytes of randomness to provide
strong protections against duplicate ID generation.

KSUIDs use 128-bits of pseudorandom data, which provides a 64-times larger
number space than the 122-bits in the well-accepted RFC 4122 UUIDv4 standard.
The additional timestamp component drives down the extremely rare chance of
duplication to the point of near physical infeasibility, even assuming extreme
clock skew (> 24-hours) that would cause other severe anomalies.

## 3. Lexographically Sortable, Portable Representations

The binary and string representations are lexicographically sortable, which
allows them to be dropped into systems which do not natively support KSUIDs
and retain their k-sortable characteristics.

The string representation is that it is base62-encoded, so that they can "fit"
anywhere alphanumeric strings are accepted.

# How do they work?

KSUIDs are 20-bytes: a 32-bit unsigned integer UTC timestamp and a 128-bit
randomly generated payload. The timestamp uses big-endian encoding, to allow
lexicographic sorting. The timestamp epoch is adjusted to May 13th, 2014,
providing over 100 years of useful life starting at UNIX epoch + 14e8. The
payload uses a cryptographically-strong pseudorandom number generator.

The string representation is fixed at 27-characters encoded using a base62
encoding that also sorts lexicographically.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  ksuid:
    github: Sija/ksuid.cr
```

## Usage

```crystal
require "ksuid"
```

To generate a random KSUID for the present time, use:

```crystal
ksuid = KSUID.new
```

To generate a KSUID for a specific timestamp, use:

```crystal
ksuid = KSUID.new(time: time) # where *time* is a `Time` object
```

If you need to parse a KSUID from a string that you received, use the
conversion method:

```crystal
ksuid = KSUID.from(base62_string)
```

If you need to interpret a series of bytes that you received, use the
conversion method:

```crystal
ksuid = KSUID.from(bytes)
```

### JSON

```crystal
require "ksuid/json"

class Example
  include JSON::Serializable

  property id : KSUID
end

example = Example.from_json(%({"id": "aWgEPTl1tmebfsQzFP4bxwgy80V"}))
# => #<Example:0x10a8723c0 @id=KSUID(aWgEPTl1tmebfsQzFP4bxwgy80V)>

example.to_json
# => "{\"id\":\"aWgEPTl1tmebfsQzFP4bxwgy80V\"}"
```

### YAML

```crystal
require "ksuid/yaml"

class Example
  include YAML::Serializable

  property id : KSUID
end

example = Example.from_yaml(%(---\nid: aWgEPTl1tmebfsQzFP4bxwgy80V\n))
# => #<Example:0x10a8723c0 @id=KSUID(aWgEPTl1tmebfsQzFP4bxwgy80V)>

example.to_yaml
# => "---\nid: aWgEPTl1tmebfsQzFP4bxwgy80V\n"
```

## Contributing

1. Fork it (<https://github.com/Sija/ksuid.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [@Sija](https://github.com/Sija) Sijawusz Pur Rahnama - creator, maintainer
