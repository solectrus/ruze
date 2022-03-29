RSpec.describe Ruze::Kamereon do
  subject(:kamereon) { Ruze::Kamereon.new(person_id, gigya_token) }

  context 'with valid credentials', vcr: { cassette_name: 'kamereon_valid_credentials' } do
    let(:person_id)   { gigya.person_id }
    let(:gigya_token) { gigya.jwt }
    let(:gigya)       { Ruze::Gigya.new(email, password) }
    let(:email)       { ENV.fetch('RENAULT_EMAIL') }
    let(:password)    { ENV.fetch('RENAULT_PASSWORD') }

    describe :account_id do
      subject { kamereon.account_id }

      it { is_expected.to be_a(String) }
    end

    describe :vin do
      subject { kamereon.vin }

      it { is_expected.to be_a(String) }
    end

    describe :battery do
      subject { kamereon.battery }

      it { is_expected.to be_a(Hash) }

      it 'has keys' do
        expect(subject.keys).to match_array(
          %w[
            batteryAutonomy
            batteryAvailableEnergy
            batteryCapacity
            batteryLevel
            batteryTemperature
            chargingInstantaneousPower
            chargingRemainingTime
            chargingStatus
            plugStatus
            timestamp
          ]
        )
      end
    end

    describe :cockpit do
      subject { kamereon.cockpit }

      it { is_expected.to be_a(Hash) }

      it 'has keys' do
        expect(subject.keys).to match_array(
          %w[
            fuelAutonomy
            fuelQuantity
            totalMileage
          ]
        )
      end
    end

    describe :location do
      subject { kamereon.location }

      it { is_expected.to be_a(Hash) }

      it 'has keys' do
        expect(subject.keys).to match_array(
          %w[
            gpsDirection
            gpsLatitude
            gpsLongitude
            lastUpdateTime
          ]
        )
      end
    end
  end

  context 'with invalid credentials', vcr: { cassette_name: 'kamereon_invalid_credentials' } do
    let(:person_id)   { '1234567c-1234-1234-1234-123d123e123d' }
    let(:gigya_token) { 'this-is-not-a-token' }

    describe :account_id do
      subject { kamereon.account_id }

      it { fails }
    end

    describe :vehicles do
      subject { kamereon.vehicles }

      it { fails }
    end

    describe :vin do
      subject { kamereon.vin }

      it { fails }
    end

    describe :battery do
      subject { kamereon.battery }

      it { fails }
    end

    describe :cockpit do
      subject { kamereon.cockpit }

      it { fails }
    end

    def fails
      expect { subject }.to raise_error(Ruze::Error, 'Error in accounts: Unauthorized (401)')
    end
  end
end
