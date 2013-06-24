module StripeMock
  class Instance

    # Handlers are ordered by priority
    @@handlers = []

    def self.add_handler(route, name)
      @@handlers << {
        :route => %r{^#{route}$},
        :name => name
      }
    end

    include StripeMock::RequestHandlers::Charges
    include StripeMock::RequestHandlers::Customers
    include StripeMock::RequestHandlers::InvoiceItems
    include StripeMock::RequestHandlers::Plans


    attr_reader :charges, :customers, :plans
    attr_accessor :pending_error, :debug, :strict

    def initialize
      @customers = {}
      @charges = {}
      @plans = {}

      @id_counter = 0
      @pending_error = nil
      @debug = false
      @strict = true
    end

    def mock_request(method, url, api_key, params={}, headers={})
      return {} if method == :xtest

      # Ensure params hash has symbols as keys
      params = Stripe::Util.symbolize_names(params)

      if @debug == true
        puts "[StripeMock req] #{method} #{url}"
        puts "                 #{params}"
      end

      if @pending_error
        raise @pending_error
        @pending_error = nil
      end

      method_url = "#{method} #{url}"
      handler = @@handlers.find {|h| method_url =~ h[:route] }

      if handler
        res = self.send(handler[:name], handler[:route], method_url, params, headers)
        puts "[StripeMock res] #{res}" if @debug == true
        [res, api_key]
      else
        puts "WARNING: Unrecognized method + url: [#{method} #{url}]"
        puts " params: #{params}"
        [{}, api_key]
      end
    end

    private

    def assert_existance(type, id, obj)
      return unless @strict == true

      if obj.nil?
        raise Stripe::InvalidRequestError.new("No such #{type}: #{id}", type.to_s, 400)
      end
    end

    def new_id(prefix)
      # Stripe ids must be strings
      "test_#{prefix}_#{@id_counter += 1}"
    end

  end
end
