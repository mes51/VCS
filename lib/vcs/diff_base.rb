class DiffBase
  NULL_FILE = "/dev/null"

  def self.supported
    "*.*"
  end

  def diff(file, reference)
    text = File.open(file, "r").read
    diff = {}
    change_mode = :none
    if Digest::SHA1.digest(text) != Digest::SHA1.digest(reference.to_s)
      diff[:add] = text
      diff[:delete] = reference

      if reference == nil
        change_mode = :create
      elsif file == NULL_FILE
        change_mode = :remove
        diff[:add] = nil
      else
        change_mode = :change
      end
    else
      diff[:add] = ""
      diff[:delete] = ""
    end

    [Hunk.new(file, diff, change_mode, self.class.to_s.to_sym)]
  end

  def apply(data, hunks, direction)
    hunks = hunks.reject{ |h| h.change_mode == :none }
    if direction == :forwerd
      hunks[hunks.length - 1].diff[:add]
    else
      hunks[0].diff[:remove]
    end
  end
end
