require 'faraday'
require 'thrift'
module Jaeger
    module Client
        class Sender
            class HTTPTransport < ::Thrift::BaseTransport
                PATH = "/api/traces"
                def initialize(host, port)
                    # uri = "http://localhost:14268"
                    uri = "http://lab-ingest.corp.signalfuse.com:8080"
                    if uri.is_a?(String)
                        @uri = URI.parse(uri)
                    else
                        @uri = uri
                    end
                    # @uri.path = PATH
                    @uri.path = "/v1/trace"
                    @uri.query = "format=jaeger.thrift"
                    @outbuf = ::Thrift::Bytes.empty_byte_buffer
                end
                def emit_batch(batch)
                    write(::Thrift::Serializer.new.serialize(batch))
                    flush
                end
                def write(str)
                    @outbuf << ::Thrift::Bytes.force_binary_encoding(str)
                end
                def flush
                    puts "flush"
                    resp = Faraday.post(@uri.to_s) do |req|
                        req.headers['content-type'] = 'application/x-thrift'
                        req.headers['Process'] = 'test-ruby-collector'
                        req.body = @outbuf
                        puts req.body
                    end
                    puts resp.body
                ensure
                    @outbuf = ::Thrift::Bytes.empty_byte_buffer
                end
                def open; end
                def close; end
            end
        end
    end
end
