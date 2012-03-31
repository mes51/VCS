class Command
  def initialize(path)
    @repo = Repository.new path
  end
end
