RSpec.describe Ruze::Gigya do
  subject(:gigya) { Ruze::Gigya.new(email, password) }

  context 'with valid email/password', vcr: { cassette_name: 'gigya_valid_credentials' } do
    let(:email)    { ENV.fetch('RENAULT_EMAIL') }
    let(:password) { ENV.fetch('RENAULT_PASSWORD') }

    describe :jwt do
      subject { gigya.jwt }

      it { is_expected.to be_a(String) }
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
      subject { -> { gigya.jwt } }

      it { fails }
    end

    describe :person_id do
      subject { -> { gigya.person_id } }

      it { fails }
    end

    describe :session_cookie_value do
      subject { -> { gigya.session_cookie_value } }

      it { fails }
    end

    def fails
      is_expected.to raise_error(Ruze::Error, 'Error in session_cookie_value: invalid loginID or password')
    end
  end

  context 'without email/password' do
    let(:email)    { nil }
    let(:password) { nil }

    describe :jwt do
      subject { -> { gigya.jwt } }

      it { fails }
    end

    describe :person_id do
      subject { -> { gigya.person_id } }

      it { fails }
    end

    describe :session_cookie_value do
      subject { -> { gigya.session_cookie_value } }

      it { fails }
    end

    def fails
      is_expected.to raise_error(ArgumentError)
    end
  end
end
