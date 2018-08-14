require "../spec_helper"

describe KSUID::Utils do
  it "can convert between integers and bytes losslessly" do
    value = 123_456_789
    bytes = KSUID::Utils.int_to_bytes(value)
    int = KSUID::Utils.int_from_bytes(bytes)
    int.should eq value
  end

  describe "#int_from_bytes" do
    it "converts String to a BigInt" do
      expected = ("1" * 32).to_big_i(2)
      converted = KSUID::Utils.int_from_bytes("\xFF" * 4)
      converted.should eq expected
    end

    it "converts Bytes to a BigInt" do
      expected = ("1" * 32).to_big_i(2)
      converted = KSUID::Utils.int_from_bytes(Bytes.new(4, 255_u8))
      converted.should eq expected
    end

    it "handles the maximum ksuid" do
      expected = "1461501637330902918203684832716283019655932542975".to_big_i
      converted = KSUID::Utils.int_from_bytes(Bytes.new(20, 255_u8))
      converted.should eq expected
    end
  end

  describe "#int_to_bytes" do
    it "converts BigInt to Bytes" do
      expected = Bytes.new(4, 255_u8)
      converted = KSUID::Utils.int_to_bytes(("1" * 32).to_big_i(2))
      converted.should eq expected
    end
  end
end
