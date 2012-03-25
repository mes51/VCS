class Commit
  def initialize(hunks, commit_message)
    if hunks.nil? || hunks.class != Array || hunks.any? { |v| v.class != Hunk }
      raise ArgumentError
    else
      @hunks = hunks
      @hash = Digest::SHA1.hexdigest(Marshal.dump(hunks) + commit_message + Time.now.to_s)
      @commit_message = commit_message
    end
  end

  attr_reader :hunks
  attr_reader :hash
  attr_reader :commit_message
end
