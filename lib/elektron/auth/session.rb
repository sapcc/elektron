# forezen_string_literal: true
require_relative './v2'
require_relative './v3'
require_relative './token_context'
require_relative '../errors/unknown_identity_version'
require_relative '../errors/token_expired'
require_relative '../utils/hashmap_helper'

module Elektron
  module Auth
    # Abstract class
    class Session
      include Elektron::TokenContext
      include Utils::HashmapHelper

      VERSIONS = %w[V2 V3].freeze

      def self.version(auth_conf, options)
        if options[:version] && VERSIONS.include?(options[:version].to_s.upcase)
          return options[:version].to_s.upcase
        end

        return 'V2' if auth_conf[:tenant_id] || auth_conf[:tenant_name]
        'V3'
      end

      def initialize(auth_conf, request_performer, options = {})
        @auth_conf = clone_hash(auth_conf)
        @options = deep_merge({}, clone_hash(options))
        @request_performer = request_performer

        if @auth_conf[:token_context] && @auth_conf[:token]
          context = add_default_services(@auth_conf[:token_context])
          current_context(context)
          @token = @auth_conf[:token]
        else
          version = self.class.version(auth_conf, @options)
          raise Elektron::Errors::UnknownIdentityVersion unless version
          @auth_class ||= Object.const_get("Elektron::Auth::#{version}")
          authenticate
        end
      end

      def token
        enforce_valid_token
        @token
      end

      def enforce_valid_token
        return true unless expired?

        unless @auth_class
          # session was created by given token context.
          # In this case there are no user credentials provided and token
          # cannot be renewed automatically.
          raise Elektron::Errors::TokenExpired, 'token has been expired'
        end
        # reauthenticate
        authenticate
      end

      protected

      def add_default_services(context)
        context = context['token'] if context && context['token']
        if context
          context['catalog'] ||= []

          identity_service = context['catalog'].find do |service|
            service['name'] == 'identity' || service['type'] == 'identity'
          end

          if identity_service.nil?
            context['catalog'] << {
              'endpoints' => %w[public internal admin].collect do |interface|
                {
                  'region_id' => @options[:region],
                  'url' => @auth_conf[:url],
                  'region' => @options[:region],
                  'interface' => interface
                }
              end,
              'type' => 'identity',
              'name' => 'keystone'
            }
          end
        end
        context
      end

      def authenticate
        auth = @auth_class.new(@auth_conf, @request_performer, @options)
        context = add_default_services(auth.context)
        current_context(context)
        @token = auth.token_value
      end
    end
  end
end
