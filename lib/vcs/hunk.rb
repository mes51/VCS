class Hunk
  def initialize(file, diff, change_mode)
    @file = file
    @diff = diff
    @change_mode = change_mode
  end

  attr_reader :file
  attr_reader :diff
  attr_reader :change_mode
end
