class Hunk
  def initialize(file, diff, change_mode, diff_class)
    @file = file
    @diff = diff
    @change_mode = change_mode
    @diff_class = diff_class
  end

  attr_reader :file
  attr_reader :diff
  attr_reader :change_mode
  attr_reader :diff_class
end
