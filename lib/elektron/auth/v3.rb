require_relative '../containers/request_context'
require_relative '../utils/hashmap_helper'

module Elektron
  module Auth
    class V3
      include Utils::HashmapHelper

      attr_reader :context, :token_value

      def initialize(auth_conf, request_performer, options = {})
        @auth_conf = clone_hash(auth_conf)
        @options = clone_hash(options)
        @request_performer = request_performer

        request_context = Elektron::Containers::RequestContext.new(
          service_name: 'identity', service_url: auth_conf[:url],
          path: '/v3/auth/tokens', options: @options,
        )

        if (scope.nil? || scope.empty?) && @auth_conf[:token]
          request_context.http_method = :get
          request_context.params = {}
          request_context.options[:headers] ||= {}
          request_context.options[:headers]['X-Auth-Token'] = @auth_conf[:token]
          request_context.options[:headers]['X-Subject-Token'] = @auth_conf[:token]
        elsif (@auth_conf[:application_credential])
          request_context.http_method = :post
          request_context.data = application_credential(@auth_conf[:application_credential])
        else
          request_context.http_method = :post
          request_context.data = credentials
        end

        response = @request_performer.execute(request_context)

        @context = response.body
        @token_value = response.header['x-subject-token']
      end

      def user
        return @user if @user
        @user = {
          'domain' => {},
          'password' => @auth_conf[:password]
        }

        if @auth_conf[:user_name]
          @user['name'] = @auth_conf[:user_name]
        else
          @user['id'] = @auth_conf[:user_id]
        end

        if @auth_conf[:user_domain_name]
          @user['domain']['name'] = @auth_conf[:user_domain_name]
        else
          @user['domain']['id'] = @auth_conf[:user_domain_id]
        end
        @user
      end

      def scope
        return @scope if @scope
        @scope = {}
        if @auth_conf[:scope_project_id]
          @scope['project'] = { 'id' => @auth_conf[:scope_project_id] }
        elsif @auth_conf[:scope_project_name]
          @scope['project'] = { 'name' => @auth_conf[:scope_project_name] }
          if @auth_conf[:scope_project_domain_name]
            @scope['project']['domain'] = {
              'name' => @auth_conf[:scope_project_domain_name]
            }
          elsif @auth_conf[:scope_project_domain_id]
            @scope['project']['domain'] = {
              'id' => @auth_conf[:scope_project_domain_id]
            }
          end
        elsif @auth_conf[:scope_domain_name]
          @scope['domain'] = { 'name' => @auth_conf[:scope_domain_name] }
        elsif @auth_conf[:scope_domain_id]
          @scope['domain'] = { 'id' => @auth_conf[:scope_domain_id] }
        elsif @auth_conf[:unscoped]
          @scope = 'unscoped'
        end
        @scope
      end

      def application_credential(app_cred)
        auth = {
          'identity' =>  {
            'methods' => ['application_credential'],
            'application_credential' => app_cred
          }
        }
        { 'auth' => auth }
      end

      def credentials
        identity = if @auth_conf[:token]
                     {
                       'methods' => ['token'],
                       'token' => { 'id' => @auth_conf[:token] }
                     }
                   else
                     {
                       'methods' => ['password'],
                       'password' => {
                         'user' => user
                       }
                     }
                   end

        auth = {
          'identity' => identity
        }
        scope.length.positive? && auth['scope'] = scope
        { 'auth' => auth }
      end
    end
  end
end
