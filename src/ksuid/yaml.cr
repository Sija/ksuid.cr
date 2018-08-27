require "yaml"
require "../ksuid"

# Adds YAML support to `KSUID` for use in a YAML mapping.
#
# NOTE: `require "ksuid/yaml"` is required to opt-in to this feature.
#
# ```
# require "ksuid"
# require "ksuid/yaml"
#
# class Example
#   YAML.mapping id: KSUID
# end
#
# example = Example.from_yaml(%(---\nid: aWgEPTl1tmebfsQzFP4bxwgy80V\n))
#
# ksuid = KSUID.from("0o5Fs0EELR0fUjHjbCnEtdUwQe3")
# ksuid.to_yaml # => "--- 0o5Fs0EELR0fUjHjbCnEtdUwQe3\n"
# ```

struct KSUID
  def self.new(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
    unless node.is_a?(YAML::Nodes::Scalar)
      node.raise "Expected scalar, not #{node.class}"
    end
    from(node.value)
  end

  def to_yaml(yaml : YAML::Nodes::Builder)
    yaml.scalar(to_s)
  end
end
