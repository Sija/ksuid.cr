require "../spec_helper"

describe KSUID::Base62 do
  describe "#decode" do
    it "decodes base 62 numbers that may or may not be zero-padded" do
      5.times do |i|
        encoded = "#{"0" * (i * 3)}awesomesauce"
        decoded = KSUID::Base62.decode(encoded)
        decoded.should eq "1922549000510644890748".to_big_i
      end
    end
  end

  describe "#encode" do
    it "encodes numbers into 27-digit base 62" do
      number = "1922549000510644890748".to_big_i
      encoded = KSUID::Base62.encode(number)
      encoded.should eq "000000000000000awesomesauce"
    end

    it "encodes negative numbers as zero" do
      number = -1
      encoded = KSUID::Base62.encode(number)
      encoded.should eq "000000000000000000000000000"
    end

    it "encodes String" do
      string = "\xFF" * 4
      encoded = KSUID::Base62.encode(string)
      encoded.should eq "0000000000000000000004gfFC3"
    end

    it "encodes Bytes" do
      bytes = Bytes.new(4, 255_u8)
      encoded = KSUID::Base62.encode(bytes)
      encoded.should eq "0000000000000000000004gfFC3"
    end
  end
end
