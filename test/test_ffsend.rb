require "minitest/autorun"
require "ffsend"

class FFSendTest < Minitest::Test
  attr_reader :test_file

  def setup
    @test_file = "test.bin"
    file = File.open(test_file, "wb")
    data = (0...50).map { ("a".."z").to_a[rand(26)] }.join
    file.write(data)
    file.close
  end

  def test_upload_returns_url_and_token
    file = File.open(test_file)
    url, token = FFSend.upload(file)
    assert url, token != [nil, nil]
  end
end
