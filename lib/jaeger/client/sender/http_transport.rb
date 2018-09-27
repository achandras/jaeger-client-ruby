# frozen_string_literal: true

require 'thrift'

module Jaeger
    module Client
        class Sender
            class HTTPTransport

                def initialize(host:, port:, endpoint: '/api/traces', headers:)
                    
                    @uri = URI(host)
                    @uri.port = port
                    @uri.path = endpoint
                    @uri.query = "format=jaeger.thrift"

                    @transport = ::Thrift::HTTPClientTransport.new(@uri.to_s)

                    @transport.add_headers(headers)
                end

                def emit_batch(batch)
                    write(::Thrift::Serializer.new.serialize(batch))
                    flush
                end

                def write(str)
                    @transport.write(str)
                end
                
                def flush
                    @transport.flush()
                end

                def open; end

                def close; end
            end
        end
    end
end
