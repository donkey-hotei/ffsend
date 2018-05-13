require "base64"
require "filemagic"
require "digest"
require "hkdf"
require "json"
require "lazy_encrypted_file"
require "rest-client"
require "pry"


BASE_URL      = "https://send.firefox.com"
UPLOAD_PATH   = BASE_URL + "/api/upload"
DOWNLOAD_PATH = BASE_URL + "/download"


Metadata =
  Struct.new(:name, :size, :iv, :type) do
    def to_json
      self.to_h.to_json
    end
  end


class FFSend
  class << self
    def upload(file)
      new(file).upload
    end
  end

  def initialize(file)
    @file = file
  end

  def upload
    upload_file
  end

  private

  attr_reader :file

  def upload_file
    begin
      RestClient.post(
        UPLOAD_PATH, lazy_encrypted_file,
        {
          "Authorization" => authorization_header,
          "X-File-Metadata" => file_metadata_header,
          "Content-Type" => "application/octet-stream",
          "Content-Length" => lazy_encrypted_file.size
        }
      )
    rescue RestClient::ExceptionWithResponse => err
      err.response
    end
  end

  def lazy_encrypted_file
    LazyEncryptedFile.new(file, file_cipher)
  end

  def file_metadata_header
    @file_metadata_header ||= Base64.encode64(metadata.to_json)
  end

  def authorization_header
    @authorization_header ||= "send-v1 " + Base64.encode64(auth_key)
  end

  def metadata
    @metadata ||= Metadata.new(
      iv: Base64.encode64(random_iv),
      name: file.path,
      type: mime_type
    )
  end

  def file_cipher
    @file_cipher ||= build_cipher(encrypt_key, random_iv)
  end

  def meta_cipher
    @meta_cipher ||= build_cipher(meta_key, null_iv)
  end

  def mime_type
    @mime_type ||=
      FileMagic.new(FileMagic::MAGIC_MIME)
               .file(file.path)
  end

  def encrypt_key
    @encrypt_key ||=
      HKDF.new(secret, info: "encryption")
          .next_bytes(16)
  end

  def meta_key
    @meta_key ||=
      HKDF.new(secret, info: "metadata")
          .next_bytes(16)
  end

  def auth_key(password = nil)
    @auth_key ||=
      HKDF.new(secret, info: "authentication")
          .next_bytes(64)
  end

  def secret
    @secret ||= Random.new.bytes(16)
  end

  def random_iv
    @random_iv ||= Random.new.bytes(12)
  end

  def null_iv
    @null_iv ||= "\x00" * 12
  end

  def build_cipher(key, iv)
    cipher = OpenSSL::Cipher.new("aes-128-gcm")
    cipher.key = key
    cipher.iv  = iv
    cipher.encrypt
    cipher
  end
end
