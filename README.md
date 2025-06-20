# OmniAuth::Entra::Id::JWT

OAuth 2 authentication with [Entra ID API](https://learn.microsoft.com/en-us/entra/identity-platform/v2-overview) using the [JWT Bearer flow](https://oauth.net/2/jwt/). In Microsoft Entra, this is referred to as the [On Behalf Of](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-on-behalf-of-flow) flow.i

The rationale for this gem is:

* Several Entra ID gems are no longer supported
* None of these gems support the JWT Bearer flow

The JWT Bearer flow can be used to share credentials between front-end and back-end systems. This allows your application to initially authenticate a user using front-end flows (e.g. Javascript browser or SPA). Completing a JWT Bearer flow then allows a Rails server to make API calls under the user's identity with its own back-end token.

Before using this gem, ensure you can successfully receive a JWT token through your front-end. This can be done using the [Microsoft Authentication Library](https://learn.microsoft.com/en-us/entra/identity-platform/msal-overview) implementation applicable to your front-end framework.

This gem does **not** support more common OAuth2.0 authentication flows, such as [Authorization Code flow](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow) or [Client Credentials flow](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow). **If you do not need to share credentials between the front-end and back-end systems, use another gem such as [omniauth-entra-id](https://github.com/pond/omniauth-entra-id) or [omniauth-oauth2-generic](https://github.com/omniauth/omniauth-oauth2-generic).**

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Add this line to your application's Gemfile:

```ruby
gem UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

Start by reading OmniAuth documentation on a more generic authentication strategy, for example [OAuth2 Generic](https://github.com/omniauth/omniauth-oauth2-generic). Background information can be found at [OmniAuth#Getting-Started](https://github.com/omniauth/omniauth#getting-started).

This gem implements an OmniAuth strategy, and more information can be found at [Using Devise with OmniAuth](https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview). 

> **Note**: Given the POST request to `user_entra_id_jwt_omniauth_token` is made by a front-end script, there is no use for the 'authorize' route (`user_entra_id_jwt_omniauth_authorize`) that is generated automatically by OmniAuth.

### Configuration Storage

You will probably want to store your `client_id` as an environment variable, so that it can be shared between the front-end and back-end parts of your application. You can then store `client_secret` as a [Rails Credential](https://guides.rubyonrails.org/security.html#custom-credentials), as it is only required on the server.

### TL;DR Version

After the gem is installed, the TLDR version using Devise is as follows.

Add OmniAuth fields to your User model:

```bash
rails g migration AddOmniauthToUsers provider:string uid:string
rake db:migrate
```

Configure Devise to use the `entra_id_jwt` strategy:

```ruby
# config/initializers/devise.rb

Devise.setup do |config|
  ...
  config.omniauth(
    :entra_id_jwt,
    {
      client_id:     ENV['ENTRA_CLIENT_ID'],
      client_secret: Rails.application.credentials.entra_client_secret
    }
  )
  ...
end
```

Enable this strategy for your User model:

```ruby
# app/models/user.rb

class User < ApplicationRecord
  ...
  devise :omniauthable, omniauth_providers: %i[entra_id_jwt]
  ...
end
```

Configure a route for the controller:

```ruby
# config/routes.rb

Rails.application.routes.draw do
  ...
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  ...
end
```

Create a controller to receive the route (the code below assumes all content is rendered in Rails, not client-side):

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # See https://github.com/omniauth/omniauth/wiki/FAQ#rails-session-is-clobbered-after-callback-on-developer-strategy
  skip_before_action :verify_authenticity_token, only: :entra_id_jwt

  def entra_id_jwt
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication # this will throw if @user is not activated
      set_flash_message(:notice, :success, kind: "Entra") if is_navigational_format?
    else
      session["devise.entra_data"] = request.env["omniauth.auth"].except(:extra) # Removing extra as it can overflow some session stores
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end
```

Add a `#from_omniauth` method to your User:

```ruby
# app/models/user.rb

class User < ApplicationRecord
  ...
  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name   # assuming the user model has a name
      # If you are using confirmable and the provider(s) you use validate emails, 
      # uncomment the line below to skip the confirmation emails.
      # user.skip_confirmation!
    end
  end
  ...
end
```

Test your application, with some helpful hints in [OmniAuth Integration Testing](https://github.com/omniauth/omniauth/wiki/Integration-Testing).

#### Front End Configuration

Your front-end will need to submit a POST request to the `user_entra_id_jwt_omniauth_callback` route, which is probably something like `/users/auth/entra_id_jwt/callback` unless you have customized this as a Devise route.

The POST request needs to include at least a `code` parameter.

### Configuration options

All of the items listed below are optional, unless noted otherwise. They can be provided either in a static configuration Hash as shown in examples above, or via *read accessor instance methods* in a provider class (more on this later).

| Option | Use |
| ------ | --- |
| `client_id`        | **Mandatory.** Client ID for the 'application' (integration) configured on the Entra side. Found via the Entra UI. |
| `client_secret`    | **Mandatory.** Client secret for the 'application' (integration) configured on the Entra side. Found via the Entra UI. Don't give this if using client assertion flow. |
| `tenant_id`        | Entra Tenant ID for multi-tenanted use. Default is `common`. Forms part of the Entra OAuth URL - `{base}/{tenant_id}/oauth2/v2.0/...` |
| `base_url`         | Location of Entra login page, for specialised requirements; default is `OmniAuth::Strategies::EntraId::BASE_URL` (at the time of writing, this is `https://login.microsoftonline.com`). |
| `authorize_params` | Additional parameters passed as URL query data in the initial OAuth redirection to Microsoft. See below for more. Empty Hash default. |
| `scope`            | If defined, sets (overwriting, if already present) `scope` inside `authorize_params`. Default is `OmniAuth::Strategies::EntraId::DEFAULT_SCOPE` (at the time of writing, this is `'openid profile email'`).  |
| `grant_type`            | If defined, sets (overwriting, if already present) `grant_type` inside `authorize_params`. Default is `urn:ietf:params:oauth:grant-type:jwt-bearer`.  |
| `requested_token_use`            | If defined, sets (overwriting, if already present) `requested_token_use` inside `authorize_params`. Default is `on_behalf_of`.  |

These can be added to the existing configuration:

```ruby
# config/initializers/devise.rb

Devise.setup do |config|
  ...
  config.omniauth(
    :entra_id_jwt,
    {
      client_id:     ENV['ENTRA_CLIENT_ID'],
      client_secret: Rails.application.credentials.entr_client_secret,
      scope: 'openid profile email offline_access'
    }
  )
  ...
end
```

### Dynamic options via a custom provider class

Similar to [OmniAuth::Entra::Id](https://github.com/pond/omniauth-entra-id/tree/master?tab=readme-ov-file#dynamic-options-via-a-custom-provider-class), the options can be made dynamic by implementing a provider class.

```ruby
# config/initializers/devise.rb

Devise.setup do |config|
  ...
  config.omniauth(:entra_id_jwt, EntraIdProvider)
  ...
end
```

and then creating an appropriate provider (here the `scope` is dependent on a request variable):

```ruby
class EntraIdProvider
  def initialize(strategy)
    @strategy = strategy
  end

  def client_id
    ENV['ENTRA_CLIENT_ID']
  end

  def client_secret
    Rails.application.credentials.entra_client_secret
  end

  def scope
    return 'openid profile email offline_access' if @strategy.request.params['offline']
    'openid profile email'
  end
end

```

### Authorize URL

Given the JWT token is already available, there is no use for the `user_entra_id_jwt_omniauth_authorize` route that is generated automatically by OmniAuth. Attempting to access this route will raise a `NotImplementedError`, which you can rescue from if you wish.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/omniauth-entra_id_jwt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/omniauth-entra_id_jwt/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the OmniAuth::Entra::Id::JWT project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/omniauth-entra_id_jwt/blob/main/CODE_OF_CONDUCT.md).
