require 'fraggel'

class FraggelTest < Test::Unit::TestCase
  include Fraggel::Encoder

  attr_reader :client, :response

  class FakeFraggel
    include Fraggel

    attr_reader :sent

    ## Expose @callbacks for tests
    attr_reader :callbacks

    def initialize
      @sent = ""
    end

    def send_data(data)
      @sent << data
    end
  end

  def setup
    @response = []
    @client   = FakeFraggel.new

    # Fake a successful connection
    @client.post_init
  end

  def respond(response)
    client.receive_data(encode(response))
  end

  def test_call_sends_data
    client.call :TEST do
      # Do nothing
    end

    assert_equal encode([1, "TEST"]), client.sent
  end

  def test_call_calls_callback
    callback = Proc.new do |x|
      @response = x
    end

    opid = client.call :TEST, &callback

    respond [opid, 0, :CALLED]

    # Make sure the callback is called
    assert_equal :CALLED, response
    # Make sure the callback is held
    assert_equal callback, client.callbacks[opid]
  end

  def test_done
    opid = client.call :TEST do |err|
      @response = err
    end

    respond [opid, Fraggel::Done]
    assert_equal :done, response
    assert_nil client.callbacks[opid]
  end

  def test_get_entry
    opid = client.get "/ping" do |body, cas, err|
      @response = [body, cas, err]
    end

    respond [opid, 0, ["pong", "99"]]
    assert_equal ["pong", "99", nil], response
  end

  def test_get_error
    opid = client.get "/ping" do |body, cas, err|
      @response = [body, cas, err]
    end

    respond [opid, 0, StandardError.new("test")]
    assert_equal [nil, nil], response[0..1]
    assert_equal StandardError, response[2].class
    assert_equal "ERR: test", response[2].message
  end
end
