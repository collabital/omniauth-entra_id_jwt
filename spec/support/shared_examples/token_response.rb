RSpec.shared_examples "token credentials" do

  def expiry
    exp = Time.now + token_response_body["expires_in"]
    exp.to_i
  end

  it { expect(subject.credentials["expires"]).to eq       true }
  it { expect(subject.credentials["expires_at"]).to eq    expiry }
  it { expect(subject.credentials["refresh_token"]).to eq token_response_body["refresh_token"] }
  it { expect(subject.credentials["token"]).to eq         token_response_body["access_token"] }
end

RSpec.shared_examples "token extra" do
  it { expect(subject.extra["raw_info"]["display_name"]).to eq        graph_response_body["displayName"] }
  it { expect(subject.extra["raw_info"]["given_name"]).to eq          graph_response_body["givenName"] }
  it { expect(subject.extra["raw_info"]["mail"]).to eq                graph_response_body["mail"] }
  it { expect(subject.extra["raw_info"]["surname"]).to eq             graph_response_body["surname"] }
  it { expect(subject.extra["raw_info"]["user_principal_name"]).to eq graph_response_body["userPrincipalName"] }

  it { expect(subject.extra["params"]["token_type"]).to eq            "Bearer" }
  it { expect(subject.extra["params"]["scope"]).to eq                 token_response_body["scope"] }
  it { expect(subject.extra["params"]["id_token"]).to eq              token_response_body["id_token"] }
  it { expect(subject.extra["aud"]).to eq                             subject.options[:client_id] }
  it { expect(subject.extra["tid"]).to eq                             tenant_id }
end

RSpec.shared_examples "token info" do
  it { expect(subject.info["email"]).to eq      graph_response_body["mail"] }
  it { expect(subject.info["first_name"]).to eq graph_response_body["givenName"] }
  it { expect(subject.info["last_name"]).to eq  graph_response_body["surname"] }
  it { expect(subject.info["name"]).to eq       graph_response_body["displayName"] }
  it { expect(subject.info["phone"]).to eq      graph_response_body["mobilePhone"] }
end

RSpec.shared_examples "token uid" do
  it { expect(subject.uid).to eq                graph_response_body["userPrincipalName"] }
end

RSpec.shared_examples "resets StringIO" do
end
