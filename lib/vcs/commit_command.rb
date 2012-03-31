class CommitCommand < Command
  def self.command
    :commit
  end

  def execute(args)
    @repo.commit args[0]
  end
end
