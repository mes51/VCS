class AddCommand < Command
  def self.command
    :add
  end

  def execute(args)
    files = [].tap do |a|
      args.each do |v|
        a.concat(Dir.glob("*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) })
      end
    end
    @repo.indexing files
  end
end
