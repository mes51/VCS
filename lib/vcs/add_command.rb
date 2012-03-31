class AddCommand < Command
  def self.command
    :add
  end

  def execute(args)
    @repo.indexing args.map { |f| File.expand_path(f) }
  end
end
