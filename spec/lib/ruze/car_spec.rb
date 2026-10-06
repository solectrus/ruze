RSpec.describe Ruze::Car do
  subject(:car) { Ruze::Car.new(email, password, device: trusted_device) }

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

  context 'with a reused login' do
    let(:email)    { 'john@example.com' }
    let(:password) { 'secret' }
    let(:gigya)    { instance_double(Ruze::Gigya, person_id: 'person', jwt: 'token') }
    let(:kamereon) { instance_double(Ruze::Kamereon, battery: { 'batteryLevel' => 50 }, reload: nil) }

    before do
      allow(Ruze::Gigya).to receive(:new).and_return(gigya)
      allow(Ruze::Kamereon).to receive(:new).and_return(kamereon)
    end

    it 'logs in once for repeated queries' do
      car.battery
      car.reload
      car.battery

      expect(Ruze::Gigya).to have_received(:new).once
      expect(kamereon).to have_received(:reload).once
      expect(kamereon).to have_received(:battery).twice
    end

    it 'logs in again when the login has expired' do
      calls = 0
      allow(kamereon).to receive(:battery) do
        calls += 1
        raise Ruze::AuthenticationError, 'Error in battery: Unauthorized (401)' if calls > 1

        { 'batteryLevel' => 50 }
      end
      renewed = instance_double(Ruze::Kamereon, battery: { 'batteryLevel' => 60 })
      allow(Ruze::Kamereon).to receive(:new).and_return(kamereon, renewed)

      car.battery
      car.reload

      expect(car.battery).to eq('batteryLevel' => 60)
      expect(Ruze::Gigya).to have_received(:new).twice
    end

    it 'logs the renewed login' do
      calls = 0
      allow(kamereon).to receive(:battery) do
        calls += 1
        raise Ruze::AuthenticationError, 'Error in battery: Unauthorized (401)' if calls > 1

        {}
      end
      allow(Ruze::Kamereon).to receive(:new).and_return(kamereon, instance_double(Ruze::Kamereon, battery: {}))
      logger = spy('logger')
      car = Ruze::Car.new(email, password, device: trusted_device, logger:)

      car.battery
      car.reload
      car.battery

      expect(logger).to have_received(:info).with('Login expired (Error in battery: Unauthorized (401)), logging in again')
      expect(Ruze::Gigya).to have_received(:new).with(email, password, device: an_instance_of(Ruze::Device), logger:).twice
    end

    it 'does not log in again on other errors' do
      calls = 0
      allow(kamereon).to receive(:battery) do
        calls += 1
        raise Ruze::Error, 'Error in battery: Bad Gateway (502)' if calls > 1

        {}
      end

      car.battery
      car.reload

      expect { car.battery }.to raise_error(Ruze::Error, 'Error in battery: Bad Gateway (502)')
      expect(Ruze::Gigya).to have_received(:new).once
    end

    it 'does not retry a fresh login' do
      allow(kamereon).to receive(:battery).and_raise(Ruze::AuthenticationError, 'Error in battery: Unauthorized (401)')

      expect { car.battery }.to raise_error(Ruze::AuthenticationError)
      expect(Ruze::Gigya).to have_received(:new).once
    end
  end

  context 'with invalid email/password', vcr: { cassette_name: 'gigya_invalid_credentials' } do
    let(:email)    { 'joe@example.com' }
    let(:password) { 'foobarbaz' }

    describe :battery do
      subject { car.battery }

      it { fails }
    end

    describe :cockpit do
      subject { car.cockpit }

      it { fails }
    end

    describe :location do
      subject { car.location }

      it { fails }
    end

    def fails
      expect { subject }.to raise_error(Ruze::Error, 'Error in session_cookie_value: invalid loginID or password')
    end
  end

  context 'without email/password' do
    let(:email)    { nil }
    let(:password) { nil }

    describe :battery do
      subject { car.battery }

      it { fails }
    end

    describe :cockpit do
      subject { car.cockpit }

      it { fails }
    end

    describe :location do
      subject { car.location }

      it { fails }
    end

    def fails
      expect { subject }.to raise_error(ArgumentError)
    end
  end
end
