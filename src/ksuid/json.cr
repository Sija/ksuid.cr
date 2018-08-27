require "json"
require "../ksuid"

# Adds JSON support to `KSUID` for use in a JSON mapping.
#
# NOTE: `require "ksuid/json"` is required to opt-in to this feature.
#
# ```
# require "ksuid"
# require "ksuid/json"
#
# class Example
#   JSON.mapping id: KSUID
# end
#
# example = Example.from_json(%({"id": "aWgEPTl1tmebfsQzFP4bxwgy80V"}))
#
# ksuid = KSUID.from("0o5Fs0EELR0fUjHjbCnEtdUwQe3")
# ksuid.to_json # => "\"0o5Fs0EELR0fUjHjbCnEtdUwQe3\""
# ```

struct KSUID
  def self.new(pull : JSON::PullParser)
    from(pull.read_string)
  end

  def to_json(json : JSON::Builder)
    json.string(to_s)
  end
end
