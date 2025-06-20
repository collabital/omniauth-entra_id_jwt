RSpec.shared_context "request mocks" do
  before :each do
    allow(subject).to receive(:env) { {} }
  end

  let(:tenant_id)           { default_tenant_id }
  let(:token_assertion)     { JWT.encode({tid: tenant_id}, false, 'none') }
  let(:token_grant_type)    { default_token_grant_type }
  let(:token_requested_use) { default_token_requested_use }
  let(:token_scope)         { default_token_scope }

  let(:token_url)           { default_token_url }
  let(:token_auth)          { default_token_auth }

  let(:default_tenant_id)           { "contoso" }
  let(:default_token_grant_type)    { "urn:ietf:params:oauth:grant-type:jwt-bearer" }
  let(:default_token_requested_use) { "on_behalf_of" }
  let(:default_token_scope)         { "openid profile email" }

  let(:default_token_url)           { "https://login.microsoftonline.com/tenant/oauth2/v2.0/token" }
  let(:default_token_auth)          { Base64.encode64("id:secret").strip }

  let(:token_request_body) do
    {
      "assertion" => token_assertion,
      "grant_type" => token_grant_type,
      "requested_token_use" => token_requested_use,
      "scope" => token_scope
    }
  end

  let!(:token_endpoint) do
    stub_request(:post, token_url)
      .with(
        body: token_request_body,
        headers: {
          "Authorization" => "Basic #{token_auth}"
        }
      )
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: token_response_body.to_json
      )
  end

  let(:access_token) { default_access_token }
  let(:id_token)     { default_id_token }

  let(:default_access_token) { "acc3ss_t0k3n" }
  let(:default_id_token)     { "id_t0k3n" }

  let(:token_response_body) do
    {
      "access_token" => access_token,
      "token_type" => "Bearer",
      "expires_in" => 3599,
      "scope" => "https://graph.microsoft.com/user.read",
      "refresh_token" => "AwABAAAAvPM1KaPlrEqdFSBzjqfTGAMxZGUTdM0t4B4",
      "id_token" => id_token
    }
  end

  let(:graph_url) { "https://graph.microsoft.com/v1.0/me" }

  let!(:graph_endpoint) do
    stub_request(:get, graph_url)
      .with(
        headers: {
          "Authorization" => "Bearer #{access_token}"
        }
      )
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: graph_response_body.to_json
      )
  end

  let(:graph_response_body) do
    # Typical response:
    # {
    #   "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users/$entity",
    #   "businessPhones": [
    #     "+1 206 555 0105"
    #   ],
    #   "displayName": "Nestor Wilke",
    #   "givenName": "Nestor",
    #   "jobTitle": "Director",
    #   "mail": "NestorW@contoso.onmicrosoft.com",
    #   "mobilePhone": null,
    #   "officeLocation": "36/2121",
    #   "preferredLanguage": "en-US",
    #   "surname": "Wilke",
    #   "userPrincipalName": "NestorW@contoso.onmicrosoft.com",
    #   "id": "a94f04a8-ad56-45ea-8876-5a468cee4562"
    # }
    {
      "userPrincipalName" => 'Nestor_fabrikam.com#EXT#@contoso.com',
      "mail" => "Nestor@fabrikam.com",
      "givenName" => "Nestor",
      "surname" => "Wilke",
      "displayName" => "Nestor Wilke",
      "mobilePhone" => "+1 206 555 0105"
    }
  end

end

RSpec.configure do |rspec|
  rspec.include_context "request mocks", mock_request: true
end
