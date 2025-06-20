RSpec.shared_context "client mocks" do
  let(:strategy_with_options) do
    OmniAuth::Strategies::EntraIdJWT.new(
      app,
      {
        client_id: "id",
        client_secret: "secret",
        tenant_id: "tenant"
      }.merge(options)
    )
  end

  let(:full_provider) do
    Class.new do
      def initialize(strategy); end

      def client_id
        "provider_id"
      end

      def client_secret
        "provider_secret"
      end

      def tenant_id
        "provider_tenant"
      end

      def authorize_params
        { custom_option: "value" }
      end

      def grant_type
        "urn:provider"
      end

      def requested_token_use
        "provider_use"
      end

      def base_url
        "https://provider.com"
      end

      def scope
        "openid provider"
      end
    end
  end

  let(:minimal_provider) do
    Class.new do
      def initialize(strategy); end

      def client_id
        "provider_id"
      end

      def client_secret
        "provider_secret"
      end

      def tenant_id
        "provider_tenant"
      end
    end
  end

  let(:err_provider) do
    Class.new do
      def initialize(strategy); end

      def client_id
        "provider_id"
      end
    end
  end

  let(:provider) { full_provider }

  let(:strategy_with_provider) do
    OmniAuth::Strategies::EntraIdJWT.new(app, provider)
  end

  let(:default_options) do
    {
      client_id: "id",
      client_secret: "secret"
    }
  end

  let(:options) { default_options }
end

RSpec.configure do |rspec|
  rspec.include_context "client mocks", mock_client: true
end
