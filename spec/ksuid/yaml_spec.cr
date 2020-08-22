require "../spec_helper"
require "../../src/ksuid/yaml"

private class YAMLWithKSUID
  include YAML::Serializable

  property value : KSUID
end

describe KSUID do
  context "YAML mapping" do
    it "parses KSUID from YAML" do
      ksuid = YAMLWithKSUID.from_yaml(%(---\nvalue: 0o5Fs0EELR0fUjHjbCnEtdUwQe3\n))
      ksuid.should be_a(YAMLWithKSUID)
      ksuid.value.should eq(KSUID.from("0o5Fs0EELR0fUjHjbCnEtdUwQe3"))
    end
  end
end
