#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'dotenv/load'

# Configuration
RAILS_API_URL = ENV['RAILS_API_URL']
API_KEY = ENV['RAILS_API_KEY']

class RailsMCPAdapter
  def initialize
    unless RAILS_API_URL
      STDERR.puts "ERROR: RAILS_API_URL environment variable is required"
      exit 1
    end

    unless API_KEY
      STDERR.puts "ERROR: RAILS_API_KEY environment variable is required"
      exit 1
    end

    @api_uri = URI.join(RAILS_API_URL, '/api/v1/mcp')
    @api_key = API_KEY
  end

  def run
    STDOUT.sync = true
    STDERR.sync = true
    
    STDERR.puts "Rails MCP Adapter starting..."
    STDERR.puts "Connecting to: #{RAILS_API_URL}"
    
    # Read JSON-RPC requests from stdin and forward to Rails
    STDIN.each_line do |line|
      next if line.strip.empty?
      
      begin
        request = JSON.parse(line)
        STDERR.puts "Received request: #{request['method']}" if ENV['DEBUG']
        
        # Forward the JSON-RPC request to Rails
        response = forward_to_rails(request)
        
        # Send response back to mcpo via stdout
        STDOUT.puts response.to_json
        STDOUT.flush
      rescue JSON::ParserError => e
        STDERR.puts "Failed to parse JSON: #{e.message}"
        send_error_response(-32700, "Parse error: #{e.message}")
      rescue => e
        STDERR.puts "Error: #{e.message}"
        STDERR.puts e.backtrace.join("\n") if ENV['DEBUG']
        send_error_response(-32603, "Internal error: #{e.message}")
      end
    end
  end

  private

  def forward_to_rails(request)
    http = Net::HTTP.new(@api_uri.host, @api_uri.port)
    http.use_ssl = @api_uri.scheme == 'https'
    http.read_timeout = 30
    http.open_timeout = 10
    
    post_request = Net::HTTP::Post.new(@api_uri)
    post_request['Content-Type'] = 'application/json'
    post_request['Authorization'] = "Bearer #{@api_key}"
    post_request.body = request.to_json
    
    response = http.request(post_request)
    
    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    when Net::HTTPUnauthorized
      STDERR.puts "Authentication failed. Check your RAILS_API_KEY"
      error_response(-32000, "Authentication failed")
    else
      STDERR.puts "HTTP Error: #{response.code} - #{response.message}"
      error_response(-32000, "Server error: #{response.code}")
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    STDERR.puts "Timeout connecting to Rails app: #{e.message}"
    error_response(-32000, "Connection timeout")
  rescue SocketError, Errno::ECONNREFUSED => e
    STDERR.puts "Cannot connect to Rails app: #{e.message}"
    error_response(-32000, "Connection failed")
  rescue => e
    STDERR.puts "Unexpected error: #{e.message}"
    error_response(-32603, "Internal error")
  end

  def error_response(code, message)
    {
      jsonrpc: '2.0',
      error: {
        code: code,
        message: message
      }
    }
  end

  def send_error_response(code, message)
    STDOUT.puts error_response(code, message).to_json
    STDOUT.flush
  end
end

# Run the adapter
RailsMCPAdapter.new.run if __FILE__ == $PROGRAM_NAME