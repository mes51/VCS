class Commit
  def initialize(hunks, commit_message)
    if hunks.nil? || hunks.class != Array || hunks.any? { |v| v.class != Hunk }
      raise ArgumentError
    else
      @hunks = hunks
      @commit_message = commit_message
      @commit_date = Time.now
      @hash = Digest::SHA1.hexdigest(Marshal.dump(hunks) + commit_message + @commit_date.to_s)
    end
  end

  attr_reader :hunks
  attr_reader :hash
  attr_reader :commit_message
  attr_reader :commit_date
end
