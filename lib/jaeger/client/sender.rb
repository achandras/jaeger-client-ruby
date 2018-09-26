# frozen_string_literal: true

require_relative './sender/transport'
# require_relative './sender/http_transport_pr'
require_relative './sender/http_transport'
require 'socket'
require 'thread'

module Jaeger
  module Client
    class Sender
      def initialize(service_name:, host:, port:, collector:, flush_interval:, logger:, http:)
        @service_name = service_name
        @collector = collector
        @flush_interval = flush_interval
        @logger = logger

        @tags = [
          Jaeger::Thrift::Tag.new(
            'key' => 'jaeger.version',
            'vType' => Jaeger::Thrift::TagType::STRING,
            'vStr' => 'Ruby-' + Jaeger::Client::VERSION
          ),
          Jaeger::Thrift::Tag.new(
            'key' => 'hostname',
            'vType' => Jaeger::Thrift::TagType::STRING,
            'vStr' => Socket.gethostname
          )
        ]
        ipv4 = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }
        unless ipv4.nil?
          @tags << Jaeger::Thrift::Tag.new(
            'key' => 'ip',
            'vType' => Jaeger::Thrift::TagType::STRING,
            'vStr' => ipv4.ip_address
          )
        end

        if http
            transport = HTTPTransport.new(host, port)
        else
            transport = Transport.new(host, port)
        end

        # protocol = ::Thrift::CompactProtocol.new(transport)
        protocol = ::Thrift::BinaryProtocol.new(transport)
        # protocol = ::Thrift::JsonProtocol.new(transport)
        @client = Jaeger::Thrift::Agent::Client.new(protocol)
        # @client = Jaeger::Thrift::Collector::Client.new(protocol)
      end

      def start
        # Sending spans in a separate thread to avoid blocking the main thread.
        @thread = Thread.new do
          loop do
            data = @collector.retrieve
            print data
            puts ""
            emit_batch(data)
            sleep @flush_interval
          end
        end
      end

      def stop
        @thread.terminate if @thread
        emit_batch(@collector.retrieve)
      end

      private

      def emit_batch(thrift_spans)
        return if thrift_spans.empty?

        puts "Emit batch"

        batch = Jaeger::Thrift::Batch.new(
          'process' => Jaeger::Thrift::Process.new(
            'serviceName' => @service_name,
            'tags' => @tags
          ),
          'spans' => thrift_spans
        )

        print batch.inspect
        puts ""

        @client.emitBatch(batch)
      rescue StandardError => error
        @logger.error("Failure while sending a batch of spans: #{error}")
      end
    end
  end
end
