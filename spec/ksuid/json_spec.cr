require "../spec_helper"
require "../../src/ksuid/json"

private class JSONWithKSUID
  include JSON::Serializable

  property value : KSUID
end

describe KSUID do
  context "JSON mapping" do
    it "parses KSUID from JSON" do
      ksuid = JSONWithKSUID.from_json(%({"value": "0o5Fs0EELR0fUjHjbCnEtdUwQe3"}))
      ksuid.should be_a(JSONWithKSUID)
      ksuid.value.should eq(KSUID.from("0o5Fs0EELR0fUjHjbCnEtdUwQe3"))
    end
  end
end
