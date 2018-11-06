require "./spec_helper"

describe KSUID do
  it "MIN" do
    min = KSUID::MIN
    min.timestamp.should eq 0
    min.to_time.should eq Time.utc(2014, 5, 13, 16, 53, 20)
    min.payload.should eq StaticArray(UInt8, KSUID::PAYLOAD_SIZE).new(0_u8)
    min.to_slice.should eq Bytes.new(KSUID::TOTAL_SIZE, 0_u8)
    min.raw.should eq "0000000000000000000000000000000000000000"
    min.to_s.should eq "000000000000000000000000000"
  end

  it "MAX" do
    max = KSUID::MAX
    max.timestamp.should eq 4294967295
    max.to_time.should eq Time.utc(2150, 6, 19, 23, 21, 35)
    max.payload.should eq StaticArray(UInt8, KSUID::PAYLOAD_SIZE).new(255_u8)
    max.to_slice.should eq Bytes.new(KSUID::TOTAL_SIZE, 255_u8)
    max.raw.should eq "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
    max.to_s.should eq "aWgEPTl1tmebfsQzFP4bxwgy80V"
  end

  describe ".from" do
    context "String" do
      it "constructs new KSUID from valid string" do
        string = "0o5Fs0EELR0fUjHjbCnEtdUwQe3"
        ksuid = KSUID.from(string)
        ksuid.to_time.should eq Time.unix(1494985761)
        ksuid.raw.should eq "05A95E21D7B6FE8CD7CFF211704D8E7B9421210B"
        ksuid.to_s.should eq string
      end

      it "fails when given string has incorrect length" do
        expect_raises(KSUID::Error) { KSUID.from("foo") }
      end
    end

    context "Bytes" do
      it "constructs new KSUID from valid byte slice" do
        bytes = Bytes[5_u8, 169_u8, 94_u8, 33_u8, 215_u8, 182_u8, 254_u8,
          140_u8, 215_u8, 207_u8, 242_u8, 17_u8, 112_u8, 77_u8, 142_u8,
          123_u8, 148_u8, 33_u8, 33_u8, 11_u8]
        ksuid = KSUID.from(bytes)
        ksuid.to_time.should eq Time.unix(1494985761)
        ksuid.raw.should eq "05A95E21D7B6FE8CD7CFF211704D8E7B9421210B"
        ksuid.to_slice.should eq bytes
      end

      it "fails when given byte slice has incorrect size" do
        expect_raises(KSUID::Error) { KSUID.from(Bytes.new(3, 255_u8)) }
      end
    end
  end

  describe "#initialize" do
    it "generates KSUID with random payload" do
      ksuid1 = KSUID.new
      ksuid2 = KSUID.new
      ksuid1.should_not eq ksuid2
    end

    it "fails when given payload has incorrect size" do
      expect_raises(KSUID::Error) { KSUID.new(time: Time.now, payload: Bytes.new(3, 255_u8)) }
    end
  end

  describe "#<=>" do
    it "sorts KSUIDs by timestamp" do
      time = Time.now
      ksuid1 = KSUID.new(time: time)
      ksuid2 = KSUID.new(time: time + 1.second)
      [ksuid2, ksuid1].sort.should eq [ksuid1, ksuid2]
    end
  end

  describe "#==" do
    it "compares KSUIDs by timestamp and payload" do
      time = Time.now
      ksuid1 = KSUID.new(time: time)
      ksuid2 = KSUID.new(time: time)
      ksuid1.should_not eq ksuid2
    end
  end

  describe "#inspect" do
    it "shows the string representation for easy understanding" do
      KSUID::MAX.inspect.should contain "aWgEPTl1tmebfsQzFP4bxwgy80V"
    end
  end
end
