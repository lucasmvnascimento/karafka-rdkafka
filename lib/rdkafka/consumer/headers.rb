module Rdkafka
  class Consumer
    # A message headers
    class Headers
      # Reads a native kafka's message header into ruby's hash
      #
      # @return [Hash<String, String>] a message headers
      #
      # @raise [Rdkafka::RdkafkaError] when fail to read headers
      #
      # @private
      def self.from_native(native_message)
        headers_ptrptr = FFI::MemoryPointer.new(:pointer)
        err = Rdkafka::Bindings.rd_kafka_message_headers(native_message, headers_ptrptr)

        if err == Rdkafka::Bindings::RD_KAFKA_RESP_ERR__NOENT
          return {}
        elsif err != Rdkafka::Bindings::RD_KAFKA_RESP_ERR_NO_ERROR
          raise Rdkafka::RdkafkaError.new(err, "Error reading message headers")
        end

        headers_ptr = headers_ptrptr.read(:pointer).tap { |it| it.autorelease = false }

        name_ptrptr = FFI::MemoryPointer.new(:pointer)
        value_ptrptr = FFI::MemoryPointer.new(:pointer)
        size_ptr = Rdkafka::Bindings::SizePtr.new
        headers = {}

        idx = 0
        loop do
          err = Rdkafka::Bindings.rd_kafka_header_get_all(
            headers_ptr,
            idx,
            name_ptrptr,
            value_ptrptr,
            size_ptr
          )

          if err == Rdkafka::Bindings::RD_KAFKA_RESP_ERR__NOENT
            break
          elsif err != Rdkafka::Bindings::RD_KAFKA_RESP_ERR_NO_ERROR
            raise Rdkafka::RdkafkaError.new(err, "Error reading a message header at index #{idx}")
          end

          name = name_ptrptr.read(:pointer).tap { |it| it.autorelease = false }
          name = name.read_string_to_null

          size = size_ptr[:value]
          value = value_ptrptr.read(:pointer).tap { |it| it.autorelease = false }
          value = value.read_string(size)

          headers[name.to_sym] = value

          idx += 1
        end

        headers
      end
    end
  end
end
