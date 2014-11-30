require 'thor'
require 'plex/autodelete/cleanup'
require 'plex/autodelete/version'
require 'yaml'

module Plex
  module Autodelete
    class CLI < Thor

      @@myplex = {
        host: 'plex.tv',
        port: 443
      }

      desc "cleanup", "Remove all watched episodes from Plex"
      option :host, default: '127.0.0.1', desc: 'The hostname/ip address of the Plex Server'
      option :port, default: 32400, desc: 'The port of the Plex Server'
      option :token, required: true, desc: 'The token of the plex server, generate with "plex-autodelete token"'
      option :skip, type: :array, desc: 'An array of shows to skip, these will not be deleted. Use quotes if show contains spaces/special characters.'
      option :delete, type: :boolean, default: true, desc: 'Skip actual deletion of files, useful for testing settings'
      option :section, type: :numeric, default: 1, desc: 'Which section are your TV shows in?'
      def cleanup
        output_config
        Plex::Autodelete::Cleanup.configure config
        Plex::Autodelete::Cleanup.cleanup
      end

      desc 'token', 'Generate the auth token needed to use "plex-autodelete cleanup"'
      option :username, required: true, desc: 'Your my.plex.tv username (this will not be stored)'
      option :password, required: true, desc: 'Your my.plex.tv password (this will not be stored)'
      def token
        http = Net::HTTP.new(@@myplex[:host], @@myplex[:port])
        http.use_ssl = true
        http.start do |http|
          request = Net::HTTP::Post.new('/users/sign_in.xml', initheader = {'X-Plex-Client-Identifier' =>'Plex Autodelete'})
          request.basic_auth options[:username], options[:password]
          response, data = http.request(request)

          parser = Nori.new
          hash = parser.parse(response.response.body)

          if hash.has_key?('errors')
            hash['errors'].each do |error|
              puts error.to_s
            end
          else
            authentication_token = hash['user']['authentication_token'].to_s
            puts "Authentication Token: #{authentication_token}"
          end
        end
      end

      private
      def output_config
        output = []
        output << "Host:          #{config[:host]}"
        output << "Port:          #{config[:port]}"
        output << "Token:         #{config[:token]}"
        output << "Section:       #{config[:section]}"
        output << "Skip Shows:    #{config[:skip] || 'N/A'}"
        output << "Skip Delete:   #{delete_text}"
        output << "--------------------"
        output << ""
        output = output.join("\n")
        puts output
      end

      def config
        {
          host: options[:host],
          port: options[:port],
          token: options[:token],
          section: options[:section],
          skip: options[:skip],
          delete: options[:delete],
        }
      end

      def delete_text
        options[:delete] ? 'true' : 'false'
      end
    end
  end
end
