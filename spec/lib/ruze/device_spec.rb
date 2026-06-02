RSpec.describe Ruze::Device do
  describe '#load' do
    it 'returns nil by default' do
      expect(described_class.new.load).to be_nil
    end

    it 'returns the seeded gmid/ucid' do
      device = described_class.new(gmid: 'g1', ucid: 'u1')
      expect(device.load).to eq(gmid: 'g1', ucid: 'u1')
    end

    it 'treats blank values as no device' do
      expect(described_class.new(gmid: '', ucid: 'u1').load).to be_nil
      expect(described_class.new(gmid: 'g1', ucid: nil).load).to be_nil
    end
  end

  describe '#save' do
    subject(:device) { described_class.new }

    it 'stores the pair and exposes it' do
      device.save(gmid: 'g1', ucid: 'u1')

      expect(device.load).to eq(gmid: 'g1', ucid: 'u1')
      expect(device.gmid).to eq('g1')
      expect(device.ucid).to eq('u1')
    end
  end
end
