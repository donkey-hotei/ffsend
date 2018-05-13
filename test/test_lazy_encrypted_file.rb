require "hkdf"
require "openssl"
require "minitest/autorun"
require "lazy_encrypted_file"

class LazyEncryptedFileTest < Minitest::Test
  attr_reader :test_file

  def setup
    test_file = File.open("test.bin", "wb")
    data = (0...50).map { ("a".."z").to_a[rand(26)] }.join
    test_file.write(data)
    test_file.close
    @test_file = File.open("test.bin", "rb")
  end

  def test_read_encrypts_successive_chunks_of_file
    plain_chunk = test_file.read(8)
    lazy_encrypted_file = LazyEncryptedFile.new(test_file, cipher)
    encrypted_chunk = lazy_encrypted_file.read(8)

    cipher.reset
    cipher.decrypt

    decrypted_chunk = cipher.update(encrypted_chunk)[0...8]  # remove tag

    assert plain_chunk == decrypted_chunk
  end

  private

  def cipher
    cipher = OpenSSL::Cipher.new("aes-128-gcm")
    cipher.key = key
    cipher.iv  = iv
    cipher.encrypt
    cipher
  end

  def key
    @key ||= Random.new.bytes(16)
  end

  def iv
    @iv ||= Random.new.bytes(12)
  end
end
