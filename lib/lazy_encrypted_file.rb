class LazyEncryptedFile
  attr_reader :file, :cipher, :taglen, :size

  def initialize(file, cipher, taglen=16)
    @file = file
    @cipher = cipher
    @taglen = taglen
    @size = file.size + taglen

    file.seek(0)
  end

  def read(n_bytes, *args)
    chunk = file.read(n_bytes)
    chunk = encrypt_chunk(chunk) if chunk
    return chunk
  end

  def close
    file.close
  end

  def closed?
    file.closed?
  end

  private

  def encrypt_chunk(chunk)
    cipher.update(chunk) + cipher.final + cipher.auth_tag(taglen)
  end
end
