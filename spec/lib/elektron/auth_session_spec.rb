describe Elektron::AuthSession do
  auth_conf = {
    user_name: 'test',
    password: 'test',
    user_domain_name: 'Default'
  }

  before :each do
    auth = double('auth V3').as_null_object
    allow(auth).to receive(:context).and_return(ScopedTokenContext.context)
    allow(auth).to receive(:token_value).and_return(ScopedTokenContext.token)
    allow(Elektron::Auth::V3).to receive(:new).and_return(auth)
  end

  describe '::version' do
    context 'version is given via options' do
      it 'should return V2' do
        expect(Elektron::AuthSession.version(auth_conf, version: 'v2')).to eq('V2')
      end

      it 'should accept a symbol' do
        expect(Elektron::AuthSession.version(auth_conf, version: :v2)).to eq('V2')
      end

      it 'should return V3' do
        expect(Elektron::AuthSession.version(auth_conf, version: 'v3')).to eq('V3')
      end

      it 'should return default version' do
        expect(Elektron::AuthSession.version(auth_conf, version: 'v4')).to eq('V3')
      end
    end
  end

  describe '#new' do
    it 'should create a new instance by given token data' do
      expect(Elektron::Auth::V3).not_to receive(:new)
      auth_session = Elektron::AuthSession.new(
        {token_context: {}, token: 'test'}, version: :v3
      )
    end

    it 'should create a new instance by given auth_conf' do
      expect(Elektron::Auth::V3).to receive(:new)
      Elektron::AuthSession.new(auth_conf, version: :v3)
    end
  end

  let(:auth_session) { Elektron::AuthSession.new(auth_conf) }
  let(:context) { auth_session.instance_variable_get(:@context) }

  describe '#expired?' do
    it 'should return true' do
      expect(auth_session.expired?).to eq(true)
    end

    it 'should return false' do
      context['expires_at'] = (Time.now+10).to_s
      expect(auth_session.expired?).to eq(false)
    end
  end

  describe '#token' do
    it 'should call enforce_valid_token' do
      expect(auth_session).to receive(:enforce_valid_token).and_call_original
      auth_session.token
    end

    it 'returns current token value' do
      expect(auth_session.token).to eq(ScopedTokenContext.token)
    end

    it 'reautheticates on expired token' do
      expect(auth_session).to receive(:authenticate).and_call_original
      auth_session.token
    end

    it 'do not reautheticate on valid token' do
      context['expires_at'] = (Time.now+10).to_s
      expect(auth_session).not_to receive(:authenticate).and_call_original
      auth_session.token
    end
  end

  # describe '#catalog' do
  #   it 'should call enforce_valid_token' do
  #     expect(auth_session).to receive(:enforce_valid_token).and_call_original
  #     auth_session.catalog
  #   end
  # end

  describe '#user_id' do
    it 'should not call enforce_valid_token' do
      expect(auth_session).not_to receive(:enforce_valid_token).and_call_original
      auth_session.user_id
    end
  end
end
