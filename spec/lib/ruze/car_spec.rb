RSpec.describe Ruze::Car do
  subject(:car) { Ruze::Car.new(email, password) }

  context 'with valid email/password' do
    let(:email)    { ENV.fetch('RENAULT_EMAIL') }
    let(:password) { ENV.fetch('RENAULT_PASSWORD') }

    around do |example|
      VCR.use_cassette('gigya_valid_credentials') do
        VCR.use_cassette('kamereon_valid_credentials') do
          example.call
        end
      end
    end

    describe :battery do
      subject { car.battery }

      it { is_expected.to be_a(Hash) }
    end

    describe :cockpit do
      subject { car.cockpit }

      it { is_expected.to be_a(Hash) }
    end

    describe :location do
      subject { car.location }

      it { is_expected.to be_a(Hash) }
    end
  end

  context 'with invalid email/password', vcr: { cassette_name: 'gigya_invalid_credentials' } do
    let(:email)    { 'joe@example.com' }
    let(:password) { 'foobarbaz' }

    describe :battery do
      subject { -> { car.battery } }

      it { fails }
    end

    describe :cockpit do
      subject { -> { car.cockpit } }

      it { fails }
    end

    describe :location do
      subject { -> { car.location } }

      it { fails }
    end

    def fails
      is_expected.to raise_error(Ruze::Error, 'Error in session_cookie_value: invalid loginID or password')
    end
  end

  context 'without email/password' do
    let(:email)    { nil }
    let(:password) { nil }

    describe :battery do
      subject { -> { car.battery } }

      it { fails }
    end

    describe :cockpit do
      subject { -> { car.cockpit } }

      it { fails }
    end

    describe :location do
      subject { -> { car.location } }

      it { fails }
    end

    def fails
      is_expected.to raise_error(ArgumentError)
    end
  end
end
