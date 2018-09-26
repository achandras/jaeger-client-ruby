# frozen_string_literal: true

require 'thrift'

module Jaeger
    module Client
        class Sender
            class HTTPTransport

                def initialize(host, port)
                    
                    # @uri = URI(host)
                    # @uri.port = port
                    # @uri.path = "/api/traces"
                    # @uri.query = "format=jaeger.thrift"
                    @uri = URI.parse("http://localhost:14268/api/traces")
                    # @uri = URI.parse("http://lab-ingest.corp.signalfuse.com:8080/v1/trace")

                    print(@uri.to_s)
                    
                    @transport = ::Thrift::HTTPClientTransport.new(@uri.to_s)
                    puts(@transport.to_s)
                    @buffer = ::Thrift::Bytes.empty_byte_buffer
                end

                def write(str)
                    # puts("writing")
                    print(str)
                    @transport.write(::Thrift::Bytes.force_binary_encoding(str))
                    # @transport.write(str)
                rescue Thrift::Exception => tx
                    print 'Thrift::Exception: ', tx.message, "\n"
                end
                
                def flush
                    puts ""
                    puts("flush")
                    @transport.flush()
                    puts @transport.instance_variable_get(:@inbuf).string
                # rescue Thrift::Exception => tx
                #     print 'Thrift::Exception: ', tx.message, "\n"
                end

                def open; end

                def close; end
            end
        end
    end
end
