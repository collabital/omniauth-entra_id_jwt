# frozen_string_literal: true

require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class EntraIdJWT < OmniAuth::Strategies::OAuth2
      BASE_URL = "https://login.microsoftonline.com"

      option :name, "entra_id_jwt"
      option :tenant_provider, nil

      DEFAULT_SCOPE    = "openid profile email"
      COMMON_TENANT_ID = "common"

      # The tenant_provider must return client_id, client_secret and,
      # optionally, tenant_id and base_url.
      #
      args [:tenant_provider]

      def client
        provider = options.tenant_provider ? options.tenant_provider.new(self) : options
        options.client_id = provider.client_id

        unless provider.respond_to?(:client_secret) && provider.client_secret
          raise ArgumentError, "You must provide client_secret"
        end

        options.client_secret = provider.client_secret

        tenant_id = provider.respond_to?(:tenant_id) ? provider.tenant_id : COMMON_TENANT_ID
        base_url =  provider.respond_to?(:base_url) ? provider.base_url : BASE_URL

        options.authorize_params = provider.authorize_params if provider.respond_to?(:authorize_params)
        options.token_params.scope = if defined?(request) && request.params["scope"]
                                       request.params["scope"]
                                     elsif provider.respond_to?(:scope) && provider.scope
                                       provider.scope
                                     else
                                       DEFAULT_SCOPE
                                     end
        oauth2 = "oauth2/v2.0"

        tenanted_endpoint_base_url = "#{base_url}/#{tenant_id}"

        options.client_options.authorize_url = "#{tenanted_endpoint_base_url}/#{oauth2}/authorize"
        options.client_options.token_url     = "#{tenanted_endpoint_base_url}/#{oauth2}/token"

        # On Behalf Of flow requires the default as the grant_type, so should only need to be configured
        # in the provider (if at all).
        options.token_params.grant_type = if provider.respond_to?(:grant_type) && provider.grant_type
                                            provider.grant_type
                                          else
                                            grant_type
                                          end

        # On Behalf Of flow requires the default as the requested_token_use, so should only need to be configured
        # in the provider (if at all).
        options.token_params.requested_token_use = if provider.respond_to?(:requested_token_use) && provider.requested_token_use
                                                     provider.requested_token_use
                                                   else
                                                     requested_token_use
                                                   end

        super
      end

      uid do
        raw_info["userPrincipalName"]
      end

      # As per omniauth-microsoft_graph definition
      # https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
      info do
        {
          "name" =>       [raw_info["givenName"], raw_info["surname"]].join(' '),
          "email" =>      raw_info["mail"],
          "first_name" => raw_info["givenName"],
          "last_name" =>  raw_info["surname"],
          "nickname" =>   raw_info["displayName"],
          "phone" =>      raw_info["mobilePhone"]
        }
      end


      # Although the only extra referred to in https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema
      # is raw_info, include other useful information such as tenant identifier as other keys.
      # Probably best not to merge them all into the raw_info key, so they remain different.
      extra do
        {
          'raw_info' => raw_info,
          'params' => access_token.params,
          'aud' => options.client_id,
          'tid' => @jwt_data["tid"]
        }
      end

      def callback_url
        raise NotImplementedError, "Callback URL is not supported in on behalf of flow"
      end

      def raw_info
        @raw_info = access_token.request(:get, "https://graph.microsoft.com/v1.0/me").parsed if @raw_info.nil?
        @raw_info
      end

      def callback_phase
        options.provider_ignores_state = true
        super
      end

      protected

      def grant_type
        "urn:ietf:params:oauth:grant-type:jwt-bearer"
      end

      def requested_token_use
        "on_behalf_of"
      end

      # This requires examining the request body, as it is almost definitely delivered as
      # ContentType application/json
      def build_access_token
        body = JSON.parse(request.body.read)
        request.body.rewind
        # Need to store the JWT token here, as otherwise the actual tenant (tid)
        # is not found in the subsequent /me API call.
        # Check for tid claim, as it will be useful.
        @jwt_data = JWT.decode(body['code'], nil, false, { required_claims: "tid" })[0]

        client.get_token({ assertion: body['code'] }.merge(token_params))
      end
    end
  end
end

OmniAuth.config.add_camelization 'entra_id_jwt', 'EntraIdJWT'
