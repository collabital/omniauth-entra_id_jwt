require "spec_helper"
require "omniauth/entra_id_jwt"

RSpec.describe OmniAuth::Strategies::EntraIdJWT do
  let(:request) { double("Request", params: {}, cookies: {}, env: {}) }
  let(:app) { ->(_env) { [200, {}, "Hello."] } }

  before :each do
    OmniAuth.config.test_mode = true
    allow(subject).to receive(:request) { request }
  end

  after :each do
    OmniAuth.config.test_mode = false
  end

  describe "#client", mock_client: true do
    describe "client_options.authorize_url" do
      context "default options" do
        subject { strategy_with_options }
        it { expect(subject.client.options[:authorize_url]).to eq("https://login.microsoftonline.com/tenant/oauth2/v2.0/authorize") }
      end # context 'default options' do

      context "provider options" do
        subject { strategy_with_provider }
        it { expect(subject.client.options[:authorize_url]).to eq("https://provider.com/provider_tenant/oauth2/v2.0/authorize") }
      end # context 'provider options' do
    end # describe 'client_options.authorize_url' do

    describe "client_options.token_url" do
      context "default options" do
        subject { strategy_with_options }
        it { expect(subject.client.options[:token_url]).to eq("https://login.microsoftonline.com/tenant/oauth2/v2.0/token") }
      end # context 'default options' do

      context "provider options" do
        subject { strategy_with_provider }
        it { expect(subject.client.options[:token_url]).to eq("https://provider.com/provider_tenant/oauth2/v2.0/token") }
      end # context 'provider options' do
    end # describe 'client_options.token_url' do

    describe "client_id" do
      context "options hash" do
        subject { strategy_with_options }
        before(:each) { subject.client }
        it { expect(subject.options[:client_id]).to eq("id") }
      end # context 'default options' do

      context "provider options" do
        subject { strategy_with_provider }
        before(:each) { subject.client }
        it { expect(subject.options[:client_id]).to eq("provider_id") }
      end
    end # describe 'client_id' do

    describe "client_secret" do
      context "options hash" do
        subject { strategy_with_options }
        it { expect(subject.options[:client_secret]).to eq("secret") }
      end # context 'default options' do

      context "provider options" do
        subject { strategy_with_provider }
        before(:each) { subject.client }
        it { expect(subject.options[:client_secret]).to eq("provider_secret") }
      end

      context "provider error" do
        let(:provider) { err_provider }
        subject { strategy_with_provider }
        it { expect { subject.client }.to raise_error(ArgumentError, "You must provide client_secret") }
      end
    end # describe 'client_secret' do

    describe "token_params.scope" do
      before(:each) { subject.client }

      context "default options" do
        subject { strategy_with_options }
        let(:options) { default_options }
        it { expect(subject.options.token_params[:scope]).to eq("openid profile email") }
      end # context 'default options' do

      context "options hash" do
        subject { strategy_with_options }
        let(:options) { { "scope" => "openid other" }.merge(default_options) }
        it { expect(subject.options.token_params[:scope]).to eq("openid other") }
      end # context 'options hash' do

      context "options params" do
        subject { strategy_with_options }
        let(:request) { double("Request", params: { "scope" => "openid req" }) }
        it { expect(subject.options.token_params[:scope]).to eq("openid req") }
      end # context 'options params' do

      context "provider options" do
        subject { strategy_with_provider }
        it { expect(subject.options.token_params[:scope]).to eq("openid provider") }
      end # context 'provider options' do

      context "provider optional" do
        subject { strategy_with_provider }
        let(:provider) { minimal_provider }
        it { expect(subject.options.token_params[:scope]).to eq("openid profile email") }
      end # context 'provider optional' do
    end # describe 'token_parms.scope' do

    describe "token_params.grant_type" do
      before(:each) { subject.client }

      context "default options" do
        subject { strategy_with_options }
        let(:options) { default_options }
        it { expect(subject.options.token_params[:grant_type]).to eq("urn:ietf:params:oauth:grant-type:jwt-bearer") }
      end # context 'default options' do

      context "options hash" do
        subject { strategy_with_options }
        let(:options) { { "grant_type" => "urn:custom" }.merge(default_options) }
        it { expect(subject.options.token_params[:grant_type]).to eq("urn:custom") }
      end # context 'options hash' do

      context "provider options" do
        subject { strategy_with_provider }
        it { expect(subject.options.token_params[:grant_type]).to eq("urn:provider") }
      end # context 'provider options' do

      context "provider optional" do
        subject { strategy_with_provider }
        let(:provider) { minimal_provider }
        it { expect(subject.options.token_params[:grant_type]).to eq("urn:ietf:params:oauth:grant-type:jwt-bearer") }
      end # context 'provider optional' do
    end # describe 'token_parms.grant_type' do

    describe "token_params.requested_token_use" do
      before(:each) { subject.client }

      context "default options" do
        subject { strategy_with_options }
        let(:options) { default_options }
        it { expect(subject.options.token_params[:requested_token_use]).to eq("on_behalf_of") }
      end # context 'default options' do

      context "options hash" do
        subject { strategy_with_options }
        let(:options) { { "requested_token_use" => "custom_use" }.merge(default_options) }
        it { expect(subject.options.token_params[:requested_token_use]).to eq("custom_use") }
      end # context 'options hash' do

      context "provider options" do
        subject { strategy_with_provider }
        it { expect(subject.options.token_params[:requested_token_use]).to eq("provider_use") }
      end # context 'provider options' do

      context "provider optional" do
        subject { strategy_with_provider }
        let(:provider) { minimal_provider }
        it { expect(subject.options.token_params[:requested_token_use]).to eq("on_behalf_of") }
      end # context 'provider optional' do
    end # describe 'token_parms.requested_token_use' do
  end # describe '#client' do

  describe "#callback_url", mock_client: true do
    subject { strategy_with_options }
    let(:options) { {} }
    it { expect { subject.callback_url }.to raise_error(NotImplementedError) }
  end # describe '#callback_url'

  describe "#callback_phase", mock_client: true, mock_request: true do
    let(:request_code) { { code: token_assertion }.to_json }
    let(:stringio) { StringIO.new request_code }

    before :each do
      allow(request).to receive(:body).and_return(stringio)
    end

    context "valid JWT token" do

      before :each do
        subject.callback_phase
      end

      context "default strategy" do
        subject { strategy_with_options }

        it "expected to call tenant's token endpoint" do
          expect(token_endpoint).to have_been_requested.times(1)
        end

        it_behaves_like "token credentials"
        it_behaves_like "token extra"
        it_behaves_like "token info"
        it_behaves_like "token uid"
        it_behaves_like "resets StringIO"
      end # context 'default strategy'

      context "custom strategy" do
        subject { strategy_with_provider }

        let(:token_grant_type)    { "urn:provider" }
        let(:token_requested_use) { "provider_use" }
        let(:token_scope)         { "openid provider" }
        let(:token_url)           { "https://provider.com/provider_tenant/oauth2/v2.0/token" }
        let(:token_auth)          { "cHJvdmlkZXJfaWQ6cHJvdmlkZXJfc2VjcmV0" }

        it "expected to call tenant's token endpoint" do
          expect(token_endpoint).to have_been_requested.times(1)
        end

        it_behaves_like "token credentials"
        it_behaves_like "token extra"
        it_behaves_like "token info"
        it_behaves_like "token uid"
        it_behaves_like "resets StringIO"
      end # context 'custom strategy'

    end # context 'valid JWT token'

    context 'no valid JWT token' do
      subject { strategy_with_options }

      context "code is not a JWT token" do
        let(:request_code) { { code: "Not JWT" }.to_json }
        it { expect{ subject.callback_phase }.to raise_error(JWT::DecodeError) }
        it "expected not to call token endpoint" do
          expect(token_endpoint).not_to have_been_requested
        end
      end # context 'code is not a JWT token'

      context "request body is not JSON" do
        let(:request_code) { "Not JSON" }
        it { expect{ subject.callback_phase }.to raise_error(JSON::ParserError) }
        it "expected not to call token endpoint" do
          expect(token_endpoint).not_to have_been_requested
        end
      end # context 'request body is not JSON'

    end # context 'no valid JWT token'
  end # describe '#callback_phase'
end
