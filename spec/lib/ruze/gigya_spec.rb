RSpec.describe Ruze::Gigya do
  subject(:gigya) { Ruze::Gigya.new(email, password, device: trusted_device) }

  context 'with valid email/password', vcr: { cassette_name: 'gigya_valid_credentials' } do
    let(:email)    { ENV.fetch('RENAULT_EMAIL') }
    let(:password) { ENV.fetch('RENAULT_PASSWORD') }

    describe :jwt do
      subject { gigya.jwt }

      it { is_expected.to be_a(String) }
    end

    describe 'renewing the JWT' do
      before { allow(gigya).to receive(:post).and_call_original }

      def jwt_at(time)
        allow(gigya).to receive(:now).and_return(time)
        gigya.jwt
      end

      def jwt_requests
        have_received(:post).with(a_string_ending_with('accounts.getJWT'), anything)
      end

      it 'reuses the JWT until shortly before it expires' do
        jwt_at(1000)
        jwt_at(1839)

        expect(gigya).to jwt_requests.once
      end

      it 'fetches a new JWT shortly before the old one expires' do
        jwt_at(1000)
        jwt_at(1840)

        expect(gigya).to jwt_requests.twice
      end
    end

    describe 'a rejected token' do
      before do
        allow(gigya).to receive_messages(
          session_cookie_value: 'expired',
          post: instance_double(Net::HTTPForbidden, body: '{"errorCode":403005,"errorMessage":"Unauthorized user"}')
        )
      end

      it 'raises AuthenticationError' do
        expect { gigya.jwt }.to raise_error(Ruze::AuthenticationError, 'Error in jwt: Unauthorized user')
      end
    end

    describe 'logging' do
      subject(:gigya) { Ruze::Gigya.new(email, password, device: trusted_device, logger:) }

      let(:logger) { spy('logger') }

      it 'logs the login and the token' do
        gigya.jwt

        expect(logger).to have_received(:info).with('Logging in').ordered
        expect(logger).to have_received(:info).with('Fetching new token').ordered
      end
    end

    describe :person_id do
      subject { gigya.person_id }

      it { is_expected.to eq(ENV.fetch('RENAULT_PERSON_ID')) }
    end

    describe :session_cookie_value do
      subject { gigya.session_cookie_value }

      it { is_expected.to be_a(String) }
    end
  end

  context 'with invalid email/password', vcr: { cassette_name: 'gigya_invalid_credentials' } do
    let(:email)    { 'joe@example.com' }
    let(:password) { 'foobarbaz' }

    describe :jwt do
      subject { gigya.jwt }

      it { fails }
    end

    describe :person_id do
      subject { gigya.person_id }

      it { fails }
    end

    describe :session_cookie_value do
      subject { gigya.session_cookie_value }

      it { fails }
    end

    def fails
      expect { subject }.to raise_error(Ruze::Error, 'Error in session_cookie_value: invalid loginID or password')
    end
  end

  context 'with an untrusted device', vcr: { cassette_name: 'gigya_two_factor_required' } do
    subject(:gigya) { Ruze::Gigya.new(email, password, device: untrusted_device) }

    let(:email)    { ENV.fetch('RENAULT_EMAIL') }
    let(:password) { ENV.fetch('RENAULT_PASSWORD') }
    let(:untrusted_device) { Ruze::Device.new }

    describe :session_cookie_value do
      subject { gigya.session_cookie_value }

      it 'raises TwoFactorRequired' do
        expect { subject }.to raise_error(Ruze::TwoFactorRequired)
      end
    end
  end

  context 'without email/password' do
    let(:email)    { nil }
    let(:password) { nil }

    describe :jwt do
      subject { gigya.jwt }

      it { fails }
    end

    describe :person_id do
      subject { gigya.person_id }

      it { fails }
    end

    describe :session_cookie_value do
      subject { gigya.session_cookie_value }

      it { fails }
    end

    def fails
      expect { subject }.to raise_error(ArgumentError)
    end
  end
end
